import SwiftUI

/// chart_editor — per-cell paint, color swap, eraser, undo/redo (≥20 steps),
/// pinch/pan canvas, DMC palette strip. Every mutation persists immediately
/// (ACC-004). The canvas never auto-plays animations (design.md §Forbidden).
struct ChartEditorView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let chartId: UUID

    enum Tool: String, CaseIterable {
        case paint = "Paint"
        case eraser = "Eraser"
        case swap = "Swap"
    }

    @State private var tool: Tool = .paint
    @State private var selectedColorIndex: Int = 0
    @State private var undoStack: [(cells: Data, palette: [ChartColor])] = []
    @State private var redoStack: [(cells: Data, palette: [ChartColor])] = []
    @State private var strokeSnapshot: (cells: Data, palette: [ChartColor])?
    @State private var selectedCell: Int?
    @State private var showSwapSheet = false
    @State private var swapSourceIndex: Int?
    @State private var showColorPicker = false

    private var chart: Chart? {
        store.chart(with: chartId)
    }

    /// Fabric color (first palette entry, DMC Blanc) — the eraser target.
    private var fabricColorIndex: Int { 0 }

    var body: some View {
        ZStack {
            Theme.ScreenBackground()
            if let chart {
                editorContent(chart)
            } else {
                ContentUnavailableView("Chart not found", systemImage: "rectangle.grid.3x3")
            }
        }
        .navigationTitle(chart?.title ?? "Edit")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 4) {
                    Button {
                        undo()
                    } label: {
                        Image(systemName: "arrow.uturn.backward")
                    }
                    .disabled(undoStack.isEmpty)
                    .accessibilityLabel("Undo")

                    Button {
                        redo()
                    } label: {
                        Image(systemName: "arrow.uturn.forward")
                    }
                    .disabled(redoStack.isEmpty)
                    .accessibilityLabel("Redo")
                }
            }
        }
        .sheet(isPresented: $showSwapSheet) {
            if let chart {
                SwapColorSheet(chart: chart, initialSource: swapSourceIndex) { source, replacement in
                    performSwap(source: source, replacement: replacement)
                }
                .presentationDetents([.large])
            }
        }
        .sheet(isPresented: $showColorPicker) {
            DMCColorPickerSheet(excluding: chart?.palette.map(\.dmcCode) ?? []) { thread in
                addColor(thread)
            }
            .presentationDetents([.large])
        }
    }

    @ViewBuilder
    private func editorContent(_ chart: Chart) -> some View {
        VStack(spacing: 0) {
            // R·C indicator.
            if let selectedCell {
                let row = Chart.row(of: selectedCell, width: chart.widthCells) + 1
                let col = Chart.column(of: selectedCell, width: chart.widthCells) + 1
                Text("R\(row) · C\(col)")
                    .font(Theme.mono(13, weight: .medium))
                    .foregroundStyle(Theme.ink)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(Theme.card))
                    .padding(.top, 8)
            } else {
                Text("Pinch to zoom · drag to paint")
                    .font(.caption)
                    .foregroundStyle(Theme.inkSecondary)
                    .padding(.top, 8)
            }

            GridCanvasView(
                chart: chart,
                mode: .edit(selectedColorIndex: effectivePaintIndex(chart)),
                showSymbols: true,
                reduceMotion: reduceMotion,
                onCellInteracted: { cell in
                    handlePaint(cell: cell, in: chart)
                },
                onSelectionChange: { cell in
                    selectedCell = cell
                }
            )
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            // Tool picker.
            Picker("Tool", selection: $tool) {
                ForEach(Tool.allCases, id: \.self) { t in
                    Text(t.rawValue).tag(t)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 20)
            .onChange(of: tool) { _, newTool in
                if newTool == .swap {
                    showSwapSheet = true
                    tool = .paint
                }
            }

            // Palette strip: swatches with DMC codes (color never sole carrier).
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(chart.palette) { color in
                        let thread = DMCLibrary.shared.thread(for: color.dmcCode)
                        Button {
                            selectedColorIndex = color.colorIndex
                            Haptics.lightTap()
                        } label: {
                            VStack(spacing: 4) {
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .fill(Color(hexString: thread?.hex ?? "#999999"))
                                    .frame(width: 44, height: 44)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                                            .stroke(
                                                selectedColorIndex == color.colorIndex ? Theme.indigo : Theme.hairline,
                                                lineWidth: selectedColorIndex == color.colorIndex ? 3 : 1
                                            )
                                    )
                                    .overlay {
                                        Text(color.symbol)
                                            .font(.system(size: 16, weight: .bold))
                                            .foregroundStyle(contrastSymbolColor(hex: thread?.hex))
                                    }
                                Text(color.dmcCode)
                                    .font(Theme.mono(11))
                                    .foregroundStyle(Theme.ink)
                            }
                            .frame(minWidth: 48)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("DMC \(color.dmcCode), \(thread?.name ?? ""), \(color.stitchCount) stitches")
                    }

                    Button {
                        showColorPicker = true
                    } label: {
                        VStack(spacing: 4) {
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(style: StrokeStyle(lineWidth: 1.5, dash: [5, 4]))
                                .foregroundStyle(Theme.indigo)
                                .frame(width: 44, height: 44)
                                .overlay {
                                    Image(systemName: "plus")
                                        .foregroundStyle(Theme.indigo)
                                }
                            Text("Add")
                                .font(Theme.mono(11))
                                .foregroundStyle(Theme.indigo)
                        }
                        .frame(minWidth: 48)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Add a DMC color")
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
            }
            .background(Theme.card)
        }
    }

    private func effectivePaintIndex(_ chart: Chart) -> Int {
        switch tool {
        case .eraser:
            return fabricColorIndex
        default:
            if chart.palette.contains(where: { $0.colorIndex == selectedColorIndex }) {
                return selectedColorIndex
            }
            return chart.palette.first?.colorIndex ?? 0
        }
    }

    // MARK: - Mutations (with undo)

    private func handlePaint(cell: Int, in chart: Chart) {
        if strokeSnapshot == nil {
            // First cell of a stroke — snapshot for undo.
            strokeSnapshot = (chart.cells, chart.palette)
        }
        let paintIndex = effectivePaintIndex(chart)
        guard chart.colorIndex(at: cell) != paintIndex else { return }

        var cells = chart.cells
        cells[cell] = UInt8(clamping: paintIndex)
        store.applyEdit(chartId: chart.id, cells: cells, palette: chart.palette)

        // Close the stroke after a short idle gap so a drag = one undo step.
        scheduleStrokeCommit()
    }

    @State private var strokeCommitTask: Task<Void, Never>?

    private func scheduleStrokeCommit() {
        strokeCommitTask?.cancel()
        strokeCommitTask = Task {
            try? await Task.sleep(nanoseconds: 450_000_000)
            guard !Task.isCancelled else { return }
            await MainActor.run {
                commitStroke()
            }
        }
    }

    private func commitStroke() {
        guard let snapshot = strokeSnapshot else { return }
        undoStack.append(snapshot)
        if undoStack.count > 30 { undoStack.removeFirst() }
        redoStack.removeAll()
        strokeSnapshot = nil
    }

    private func performSwap(source: Int, replacement: DMCThread) {
        guard let chart else { return }
        commitStroke()
        undoStack.append((chart.cells, chart.palette))
        if undoStack.count > 30 { undoStack.removeFirst() }
        redoStack.removeAll()

        var palette = chart.palette
        var cells = chart.cells

        let targetIndex: Int
        if let existing = palette.first(where: { $0.dmcCode == replacement.dmcCode }) {
            targetIndex = existing.colorIndex
        } else {
            let newIndex = (palette.map(\.colorIndex).max() ?? -1) + 1
            targetIndex = newIndex
            let usedSymbols = Set(palette.map(\.symbol))
            let symbol = DMCLibrary.symbolPool.first(where: { !usedSymbols.contains($0) })
                ?? DMCLibrary.symbolPool[newIndex % DMCLibrary.symbolPool.count]
            palette.append(ChartColor(colorIndex: newIndex, dmcCode: replacement.dmcCode, symbol: symbol, stitchCount: 0))
        }

        for i in cells.indices where cells[i] == UInt8(clamping: source) {
            cells[i] = UInt8(clamping: targetIndex)
        }

        // Drop palette entries that no longer appear on the grid.
        store.applyEdit(chartId: chart.id, cells: cells, palette: palette)
        if var updated = store.chart(with: chart.id) {
            updated.recomputeStitchCounts()
            let used = Set(updated.cells.map { Int($0) })
            updated.palette.removeAll { !used.contains($0.colorIndex) }
            store.updateChart(updated)
        }
        selectedColorIndex = targetIndex
    }

    private func addColor(_ thread: DMCThread) {
        guard let chart else { return }
        commitStroke()
        undoStack.append((chart.cells, chart.palette))
        redoStack.removeAll()

        var palette = chart.palette
        let newIndex = (palette.map(\.colorIndex).max() ?? -1) + 1
        let usedSymbols = Set(palette.map(\.symbol))
        let symbol = DMCLibrary.symbolPool.first(where: { !usedSymbols.contains($0) })
            ?? DMCLibrary.symbolPool[newIndex % DMCLibrary.symbolPool.count]
        palette.append(ChartColor(colorIndex: newIndex, dmcCode: thread.dmcCode, symbol: symbol, stitchCount: 0))
        store.applyEdit(chartId: chart.id, cells: chart.cells, palette: palette)
        selectedColorIndex = newIndex
    }

    private func undo() {
        commitStroke()
        guard let chart, let snapshot = undoStack.popLast() else { return }
        redoStack.append((chart.cells, chart.palette))
        store.applyEdit(chartId: chart.id, cells: snapshot.cells, palette: snapshot.palette)
    }

    private func redo() {
        guard let chart, let snapshot = redoStack.popLast() else { return }
        undoStack.append((chart.cells, chart.palette))
        store.applyEdit(chartId: chart.id, cells: snapshot.cells, palette: snapshot.palette)
    }

    private func contrastSymbolColor(hex: String?) -> Color {
        let rgb = DMCThread.parse(hex: hex ?? "#999999")
        let luminance = 0.2126 * rgb.r + 0.7152 * rgb.g + 0.0722 * rgb.b
        return luminance > 0.6 ? Color.black.opacity(0.75) : Color.white.opacity(0.92)
    }
}

/// Swap tool: pick which palette color to replace, then the DMC replacement.
private struct SwapColorSheet: View {
    @Environment(\.dismiss) private var dismiss
    let chart: Chart
    let initialSource: Int?
    let onSwap: (Int, DMCThread) -> Void

    @State private var source: Int?

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.ScreenBackground()
                if let source {
                    DMCColorPickerSheet(excluding: []) { thread in
                        dismiss()
                        onSwap(source, thread)
                    }
                    .navigationTitle("Replace with…")
                } else {
                    ScrollView {
                        VStack(spacing: 10) {
                            Text("Which color should be replaced?")
                                .font(.subheadline)
                                .foregroundStyle(Theme.inkSecondary)
                                .padding(.top, 8)
                            ForEach(chart.palette) { color in
                                let thread = DMCLibrary.shared.thread(for: color.dmcCode)
                                Button {
                                    self.source = color.colorIndex
                                } label: {
                                    HStack(spacing: 12) {
                                        Circle()
                                            .fill(Color(hexString: thread?.hex ?? "#999999"))
                                            .frame(width: 26, height: 26)
                                        Text("DMC \(color.dmcCode) · \(thread?.name ?? "")")
                                            .font(.subheadline.weight(.medium))
                                            .foregroundStyle(Theme.ink)
                                        Spacer()
                                        Text("\(color.stitchCount) stitches")
                                            .font(Theme.mono(11))
                                            .foregroundStyle(Theme.inkSecondary)
                                    }
                                    .padding(12)
                                    .atelierCard()
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    .navigationTitle("Swap a color")
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .onAppear {
            source = initialSource
        }
    }
}

/// Searchable DMC library picker.
struct DMCColorPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    let excluding: [String]
    let onPick: (DMCThread) -> Void

    @State private var query = ""

    private var results: [DMCThread] {
        let library = DMCLibrary.shared.threads.filter { !excluding.contains($0.dmcCode) }
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return library }
        return library.filter {
            $0.dmcCode.localizedCaseInsensitiveContains(trimmed)
                || $0.name.localizedCaseInsensitiveContains(trimmed)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.ScreenBackground()
                List(results) { thread in
                    Button {
                        dismiss()
                        onPick(thread)
                    } label: {
                        HStack(spacing: 12) {
                            Circle()
                                .fill(Color(hexString: thread.hex))
                                .frame(width: 26, height: 26)
                                .overlay(Circle().stroke(Theme.hairline, lineWidth: 1))
                            Text("DMC \(thread.dmcCode)")
                                .font(Theme.mono(13, weight: .medium))
                                .foregroundStyle(Theme.ink)
                            Text(thread.name)
                                .font(.subheadline)
                                .foregroundStyle(Theme.inkSecondary)
                        }
                        .frame(minHeight: 44)
                    }
                    .listRowBackground(Theme.card)
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .searchable(text: $query, prompt: "Code or name")
                .scrollDismissesKeyboard(.immediately)
            }
            .navigationTitle("DMC threads")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
