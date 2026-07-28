import SwiftUI

/// tab_stitch — routes to the active chart's session, or guides selection.
struct StitchTabView: View {
    @EnvironmentObject private var store: AppStore

    private var activeChart: Chart? {
        guard let id = store.activeChartId else { return nil }
        return store.chart(with: id)
    }

    private var stitchableCharts: [Chart] {
        store.charts.filter { $0.status != .finished }
    }

    var body: some View {
        ZStack {
            Theme.ScreenBackground()
            if let activeChart {
                StitchSessionView(chartId: activeChart.id)
            } else {
                pickerContent
            }
        }
        .navigationTitle("Stitch")
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private var pickerContent: some View {
        if stitchableCharts.isEmpty {
            // no_active_chart
            VStack(spacing: 20) {
                Image(systemName: "circle.grid.cross")
                    .font(.system(size: 48))
                    .foregroundStyle(Theme.threadRed)
                Text("Nothing on the hoop yet")
                    .font(Theme.titleFont(24))
                    .foregroundStyle(Theme.ink)
                Text("Create a chart, then come back to stitch it cell by cell.")
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Theme.inkSecondary)
                    .padding(.horizontal, 40)
                Button {
                    store.selectedTab = .create
                } label: {
                    Label("Create a chart", systemImage: "plus")
                }
                .buttonStyle(Theme.PrimaryButtonStyle())
                .padding(.horizontal, 48)
            }
        } else {
            // picking
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    Text("Pick a chart to stitch")
                        .font(Theme.titleFont(24))
                        .foregroundStyle(Theme.ink)
                        .padding(.horizontal, 20)
                        .padding(.top, 12)
                    ForEach(stitchableCharts) { chart in
                        Button {
                            store.setActiveChart(chart.id)
                        } label: {
                            ChartCardView(chart: chart)
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 20)
                    }
                }
            }
        }
    }
}

/// stitch_session — cell marking, current-thread filter, progress ring,
/// finish detection, celebration, finished-piece photo (F6/F7).
struct StitchSessionView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let chartId: UUID

    @State private var filterColorIndex: Int?
    @State private var selectedCell: Int?
    @State private var showCelebration = false
    @State private var celebrationFired = false
    @State private var showFinishedPhotoSheet = false

    private var chart: Chart? {
        store.chart(with: chartId)
    }

    var body: some View {
        ZStack {
            if let chart {
                sessionContent(chart)
            } else {
                ContentUnavailableView("Chart not found", systemImage: "rectangle.grid.3x3")
            }

            if showCelebration, let chart {
                FinishCelebrationView(
                    chart: chart,
                    onAddPhoto: {
                        showCelebration = false
                        showFinishedPhotoSheet = true
                    },
                    onDone: {
                        showCelebration = false
                        store.selectedTab = .charts
                        store.chartIdToOpen = chart.id
                    }
                )
            }
        }
        .sheet(isPresented: $showFinishedPhotoSheet) {
            if let chart {
                FinishedPhotoSheet(chartId: chart.id)
                    .environmentObject(store)
            }
        }
    }

    @ViewBuilder
    private func sessionContent(_ chart: Chart) -> some View {
        VStack(spacing: 0) {
            // Header: progress ring + counts.
            HStack(spacing: 14) {
                ProgressRing(progress: chart.progress, size: 58, lineWidth: 6)
                VStack(alignment: .leading, spacing: 3) {
                    Text(chart.title)
                        .font(Theme.headlineSerif(19))
                        .foregroundStyle(Theme.ink)
                        .lineLimit(1)
                    Text("\(chart.stitchedCount) / \(chart.totalCells) stitches")
                        .font(Theme.mono(13))
                        .foregroundStyle(Theme.inkSecondary)
                }
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)

            GridCanvasView(
                chart: chart,
                mode: .stitch(stitched: chart.stitchedCellIndices, filterColorIndex: filterColorIndex),
                showSymbols: true,
                reduceMotion: reduceMotion,
                onCellInteracted: { cell in
                    handleMark(cell: cell, in: chart)
                },
                onSelectionChange: { cell in
                    selectedCell = cell
                }
            )
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            // Current-thread chips (filter).
            currentThreadBar(chart)
        }
    }

    @ViewBuilder
    private func currentThreadBar(_ chart: Chart) -> some View {
        VStack(spacing: 8) {
            if let filter = filterColorIndex,
               let paletteColor = chart.palette.first(where: { $0.colorIndex == filter }) {
                let left = remainingCount(colorIndex: filter, in: chart)
                HStack(spacing: 10) {
                    Circle()
                        .fill(Color(hexString: DMCLibrary.shared.thread(for: paletteColor.dmcCode)?.hex ?? "#999999"))
                        .frame(width: 26, height: 26)
                    VStack(alignment: .leading, spacing: 1) {
                        Text("DMC \(paletteColor.dmcCode)")
                            .font(Theme.mono(13, weight: .semibold))
                            .foregroundStyle(Theme.ink)
                        Text("\(left) left")
                            .font(.caption)
                            .foregroundStyle(Theme.inkSecondary)
                    }
                    Spacer()
                    Button("Show all") {
                        filterColorIndex = nil
                    }
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.indigo)
                    .frame(minHeight: 36)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .atelierCard()
                .padding(.horizontal, 20)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(chart.palette.sorted(by: { $0.stitchCount > $1.stitchCount })) { color in
                        let thread = DMCLibrary.shared.thread(for: color.dmcCode)
                        let isSelected = filterColorIndex == color.colorIndex
                        Button {
                            filterColorIndex = isSelected ? nil : color.colorIndex
                            Haptics.lightTap()
                        } label: {
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(Color(hexString: thread?.hex ?? "#999999"))
                                    .frame(width: 16, height: 16)
                                Text(color.dmcCode)
                                    .font(Theme.mono(11, weight: .medium))
                                    .foregroundStyle(Theme.ink)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                            .background(
                                Capsule().fill(isSelected ? Theme.indigo.opacity(0.15) : Theme.card)
                            )
                            .overlay(
                                Capsule().stroke(isSelected ? Theme.indigo : Theme.hairline, lineWidth: isSelected ? 1.5 : 1)
                            )
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Filter DMC \(color.dmcCode)")
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 10)
            }
        }
        .background(Theme.card.opacity(0.6))
    }

    private func remainingCount(colorIndex: Int, in chart: Chart) -> Int {
        var left = 0
        for (index, byte) in chart.cells.enumerated() where Int(byte) == colorIndex {
            if !chart.stitchedCellIndices.contains(index) { left += 1 }
        }
        return left
    }

    private func handleMark(cell: Int, in chart: Chart) {
        store.toggleStitch(chartId: chart.id, cellIndex: cell)
        Haptics.lightTap()

        // Finish detection: last cell fires the celebration (mot_success_finish).
        if let updated = store.chart(with: chart.id),
           updated.stitchedCount == updated.totalCells,
           updated.totalCells > 0,
           !celebrationFired {
            celebrationFired = true
            store.markFinished(chartId: chart.id)
            Haptics.success()
            withAnimation(Motion.weave(reduceMotion: reduceMotion)) {
                showCelebration = true
            }
        }
        if let updated = store.chart(with: chart.id), updated.stitchedCount < updated.totalCells {
            celebrationFired = false
        }
    }
}

/// mot_success_finish: border "stitches around" the chart (1.2s trim stroke) +
/// confetti particles + success haptic. Reduce Motion: static banner.
private struct FinishCelebrationView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let chart: Chart
    let onAddPhoto: () -> Void
    let onDone: () -> Void

    @State private var trim: CGFloat = 0
    @State private var particles: [ConfettiParticle] = []

    var body: some View {
        ZStack {
            Color.black.opacity(0.35)
                .ignoresSafeArea()

            VStack(spacing: 18) {
                ZStack {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(Theme.card)
                    // The stitching border stroke.
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .trim(from: 0, to: trim)
                        .stroke(Theme.threadRed, style: StrokeStyle(lineWidth: 4, lineCap: .round, dash: [12, 8]))
                        .padding(6)

                    VStack(spacing: 14) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 54))
                            .foregroundStyle(Theme.sage)
                        Text("Finished!")
                            .font(Theme.titleFont(30))
                            .foregroundStyle(Theme.ink)
                        Text("\(chart.totalCells) stitches — nice work.")
                            .font(.subheadline)
                            .foregroundStyle(Theme.inkSecondary)
                        HStack(spacing: 12) {
                            Button("Add a finished photo", action: onAddPhoto)
                                .buttonStyle(Theme.PrimaryButtonStyle())
                            Button("Not now", action: onDone)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Theme.inkSecondary)
                                .frame(minHeight: 44)
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(28)
                }
                .padding(.horizontal, 28)

                if !particles.isEmpty {
                    ConfettiView(particles: particles)
                        .allowsHitTesting(false)
                }
            }
        }
        .onAppear {
            if reduceMotion {
                trim = 1 // static banner equivalent
            } else {
                withAnimation(.easeOut(duration: Motion.celebrateDuration)) {
                    trim = 1
                }
                particles = ConfettiParticle.spawn(count: 26)
            }
        }
        .accessibilityElement(children: .contain)
    }
}

private struct ConfettiParticle: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    var color: Color
    var size: CGFloat
    var drift: CGFloat

    static func spawn(count: Int) -> [ConfettiParticle] {
        let colors: [Color] = [Theme.threadRed, Theme.indigo, Theme.sage, Theme.amber]
        return (0..<count).map { i in
            ConfettiParticle(
                x: CGFloat.random(in: 0.1...0.9),
                y: CGFloat.random(in: 0.05...0.4),
                color: colors[i % colors.count],
                size: CGFloat.random(in: 5...9),
                drift: CGFloat.random(in: 30...90)
            )
        }
    }
}

private struct ConfettiView: View {
    let particles: [ConfettiParticle]
    @State private var animate = false

    var body: some View {
        GeometryReader { proxy in
            ForEach(particles) { particle in
                CrossStitchMark()
                    .fill(particle.color)
                    .frame(width: particle.size, height: particle.size)
                    .position(
                        x: proxy.size.width * particle.x,
                        y: proxy.size.height * particle.y + (animate ? particle.drift : 0)
                    )
                    .opacity(animate ? 0 : 1)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: Motion.celebrateDuration)) {
                animate = true
            }
        }
    }
}

private struct CrossStitchMark: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width * 0.28
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.move(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        return path.strokedPath(StrokeStyle(lineWidth: w, lineCap: .round))
    }
}
