import SwiftUI

/// tab_threads — DMC library browse/search, stash skein counts, and the
/// per-chart thread list with missing-thread highlight (F8).
struct ThreadsView: View {
    @EnvironmentObject private var store: AppStore

    @State private var query = ""
    @State private var selectedChartId: UUID?

    private var library: [DMCThread] {
        let all = DMCLibrary.shared.threads
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return all }
        return all.filter {
            $0.dmcCode.localizedCaseInsensitiveContains(trimmed)
                || $0.name.localizedCaseInsensitiveContains(trimmed)
        }
    }

    private var selectedChart: Chart? {
        if let id = selectedChartId { return store.chart(with: id) }
        if let activeId = store.activeChartId, let active = store.chart(with: activeId) { return active }
        return store.charts.first
    }

    var body: some View {
        ZStack {
            Theme.ScreenBackground()
            List {
                if let chart = selectedChart, !chart.palette.isEmpty {
                    Section {
                        Picker("Chart", selection: Binding(
                            get: { selectedChartId ?? chart.id },
                            set: { selectedChartId = $0 }
                        )) {
                            ForEach(store.charts) { c in
                                Text(c.title).tag(c.id)
                            }
                        }
                        .pickerStyle(.menu)

                        ForEach(chart.palette.sorted(by: { $0.stitchCount > $1.stitchCount })) { color in
                            chartUsageRow(color)
                        }
                    } header: {
                        Text("Thread needs · \(chart.title)")
                    }
                }

                if !store.stash.isEmpty {
                    Section("My stash") {
                        ForEach(stashEntries, id: \.dmcCode) { entry in
                            threadRow(entry.thread, owned: entry.skeins)
                        }
                    }
                }

                Section("DMC library") {
                    ForEach(library) { thread in
                        threadRow(thread, owned: store.skeinsOwned(for: thread.dmcCode))
                    }
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .searchable(text: $query, prompt: "Search DMC code or name")
            .scrollDismissesKeyboard(.immediately)
        }
        .navigationTitle("Threads")
    }

    private var stashEntries: [(dmcCode: String, skeins: Int, thread: DMCThread)] {
        store.stash
            .filter { $0.value > 0 }
            .compactMap { code, skeins in
                guard let thread = DMCLibrary.shared.thread(for: code) else { return nil }
                return (code, skeins, thread)
            }
            .sorted { $0.thread.dmcCode.localizedStandardCompare($1.thread.dmcCode) == .orderedAscending }
    }

    @ViewBuilder
    private func chartUsageRow(_ color: ChartColor) -> some View {
        let thread = DMCLibrary.shared.thread(for: color.dmcCode)
        let owned = store.skeinsOwned(for: color.dmcCode)
        let neededText = ExportEngine.estimatedSkeinsText(for: color.stitchCount)
        HStack(spacing: 12) {
            swatch(thread)
            VStack(alignment: .leading, spacing: 2) {
                Text("DMC \(color.dmcCode)")
                    .font(Theme.mono(13, weight: .medium))
                    .foregroundStyle(Theme.ink)
                Text(thread?.name ?? "")
                    .font(.caption)
                    .foregroundStyle(Theme.inkSecondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(color.stitchCount) sts · \(neededText) sk")
                    .font(Theme.mono(11))
                    .foregroundStyle(Theme.inkSecondary)
                if owned > 0 {
                    Text("Have \(owned)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Theme.sage)
                } else {
                    Text("Missing")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Theme.amber)
                }
            }
            Stepper("", value: Binding(
                get: { owned },
                set: { store.setSkeinsOwned($0, for: color.dmcCode) }
            ), in: 0...99)
            .labelsHidden()
            .frame(maxWidth: 90)
        }
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private func threadRow(_ thread: DMCThread, owned: Int) -> some View {
        HStack(spacing: 12) {
            swatch(thread)
            VStack(alignment: .leading, spacing: 2) {
                Text("DMC \(thread.dmcCode)")
                    .font(Theme.mono(13, weight: .medium))
                    .foregroundStyle(Theme.ink)
                Text(thread.name)
                    .font(.caption)
                    .foregroundStyle(Theme.inkSecondary)
            }
            Spacer()
            Stepper("", value: Binding(
                get: { owned },
                set: { store.setSkeinsOwned($0, for: thread.dmcCode) }
            ), in: 0...99)
            .labelsHidden()
            .frame(maxWidth: 90)
            if owned > 0 {
                Text("\(owned)")
                    .font(Theme.mono(13, weight: .semibold))
                    .foregroundStyle(Theme.indigo)
                    .frame(minWidth: 24)
            }
        }
        .frame(minHeight: 44)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("DMC \(thread.dmcCode), \(thread.name), \(owned) skeins owned")
    }

    private func swatch(_ thread: DMCThread?) -> some View {
        Circle()
            .fill(Color(hexString: thread?.hex ?? "#999999"))
            .frame(width: 26, height: 26)
            .overlay(Circle().stroke(Theme.hairline, lineWidth: 1))
    }
}
