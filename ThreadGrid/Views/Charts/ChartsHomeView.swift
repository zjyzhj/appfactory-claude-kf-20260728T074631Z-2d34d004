import SwiftUI

/// tab_charts — pattern library: hero, status groups, search, empty/loading/error.
struct ChartsHomeView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var searchText = ""
    @State private var appeared = false
    @State private var chartForDetail: Chart?

    private var filteredCharts: [Chart] {
        guard !searchText.trimmingCharacters(in: .whitespaces).isEmpty else { return store.charts }
        return store.charts.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
    }

    private var grouped: [(ChartStatus, [Chart])] {
        let order: [ChartStatus] = [.active, .draft, .finished]
        return order.compactMap { status in
            let charts = filteredCharts.filter { $0.status == status }
            return charts.isEmpty ? nil : (status, charts)
        }
    }

    var body: some View {
        ZStack {
            Theme.ScreenBackground()

            switch store.loadState {
            case .loading:
                loadingState
            case .failed:
                errorState
            case .loaded:
                if store.charts.isEmpty {
                    emptyState
                } else {
                    libraryContent
                }
            }
        }
        .navigationTitle("ThreadGrid")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    SettingsView()
                } label: {
                    Image(systemName: "gearshape")
                        .accessibilityLabel("Settings")
                }
            }
        }
        .navigationDestination(item: $chartForDetail) { chart in
            ChartDetailView(chartId: chart.id)
        }
        .onAppear {
            // mot_entry_weave: hero fade + cards weave in with weaveStagger.
            withAnimation(Motion.weave(reduceMotion: reduceMotion)) {
                appeared = true
            }
            consumePendingChartOpen()
        }
        .onChange(of: store.chartIdToOpen) { _, _ in
            consumePendingChartOpen()
        }
    }

    private func consumePendingChartOpen() {
        guard let id = store.chartIdToOpen, let chart = store.chart(with: id) else { return }
        store.chartIdToOpen = nil
        chartForDetail = chart
    }

    // MARK: - States

    private var loadingState: some View {
        VStack(spacing: 16) {
            ProgressView()
                .controlSize(.large)
            Text("Winding the bobbins…")
                .font(.subheadline)
                .foregroundStyle(Theme.inkSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var errorState: some View {
        VStack(spacing: 20) {
            Image(systemName: "rectangle.grid.3x3")
                .font(.system(size: 44))
                .foregroundStyle(Theme.threadRed)
            Text("Something went wrong. Your work is saved — please try again.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(Theme.ink)
            Button("Retry") {
                store.load()
            }
            .buttonStyle(Theme.PrimaryButtonStyle())
            .frame(maxWidth: 240)
        }
        .padding(32)
    }

    // mot_empty_guide: breathing illustration + guidance (static under Reduce Motion).
    private var emptyState: some View {
        ScrollView {
            VStack(spacing: 24) {
                Spacer(minLength: 24)

                BreathingEmptyIllustration()

                VStack(spacing: 10) {
                    Text("Your hoop is waiting")
                        .font(Theme.titleFont(30))
                        .foregroundStyle(Theme.ink)
                    Text("No charts yet — turn a photo into your first pattern.")
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(Theme.inkSecondary)
                        .padding(.horizontal, 32)
                }

                Button {
                    store.selectedTab = .create
                } label: {
                    Label("Create your first chart", systemImage: "plus")
                }
                .buttonStyle(Theme.PrimaryButtonStyle())
                .padding(.horizontal, 40)

                Button {
                    store.selectedTab = .create
                } label: {
                    Text("Start from a blank grid")
                }
                .buttonStyle(Theme.SecondaryButtonStyle())
                .padding(.horizontal, 40)

                Spacer(minLength: 40)
            }
        }
        .scrollDismissesKeyboard(.interactively)
    }

    private var libraryContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                heroSection
                    .opacity(appeared ? 1 : 0)

                statusChips

                searchField

                ForEach(Array(grouped.enumerated()), id: \.element.0) { groupIndex, group in
                    let (status, charts) = group
                    VStack(alignment: .leading, spacing: 10) {
                        Text(status.sectionTitle)
                            .font(Theme.headlineSerif(18))
                            .foregroundStyle(Theme.ink)
                            .padding(.horizontal, 20)
                        ForEach(Array(charts.enumerated()), id: \.element.id) { index, chart in
                            Button {
                                chartForDetail = chart
                            } label: {
                                ChartCardView(chart: chart)
                            }
                            .buttonStyle(.plain)
                            .padding(.horizontal, 20)
                            // mot_entry_weave: cards weave in row by row.
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 14)
                            .animation(
                                Motion.weave(reduceMotion: reduceMotion)?.delay(Motion.entryDelay(index: groupIndex * 2 + index, reduceMotion: reduceMotion)),
                                value: appeared
                            )
                        }
                    }
                }

                if filteredCharts.isEmpty {
                    noSearchResults
                }

                Spacer(minLength: 24)
            }
            .padding(.top, 8)
        }
        .scrollDismissesKeyboard(.interactively)
    }

    // ACC-VIS-HERO: brand hero on first screen, data or no data.
    private var heroSection: some View {
        ZStack(alignment: .bottomLeading) {
            Image("charts_hero")
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity)
                .frame(height: 210)
                .clipped()
                .overlay(
                    LinearGradient(
                        colors: [.clear, .black.opacity(0.35)],
                        startPoint: .center,
                        endPoint: .bottom
                    )
                )
            VStack(alignment: .leading, spacing: 2) {
                Text("ThreadGrid")
                    .font(Theme.titleFont(34, weight: .bold))
                    .foregroundStyle(.white)
                Text("My stitching atelier.")
                    .font(Theme.mono(13))
                    .foregroundStyle(.white.opacity(0.9))
            }
            .padding(18)
        }
        .frame(height: 210)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .padding(.horizontal, 20)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("ThreadGrid. My stitching atelier.")
    }

    private var statusChips: some View {
        let inProgress = store.charts.filter { $0.status == .active }.count
        let finished = store.charts.filter { $0.status == .finished }.count
        return HStack(spacing: 12) {
            StatusChip(icon: "circle.grid.cross", label: "In progress", count: inProgress)
            StatusChip(icon: "checkmark.seal", label: "Finished", count: finished)
        }
        .padding(.horizontal, 20)
    }

    private var searchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Theme.inkSecondary)
            TextField("Search charts", text: $searchText)
                .submitLabel(.search)
                .onSubmit {
                    hideKeyboard()
                }
        }
        .padding(.horizontal, 14)
        .frame(minHeight: 44)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Theme.card)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Theme.hairline, lineWidth: 1)
        )
        .padding(.horizontal, 20)
    }

    private var noSearchResults: some View {
        VStack(spacing: 12) {
            Text("No charts match “\(searchText)”.")
                .font(.subheadline)
                .foregroundStyle(Theme.inkSecondary)
            Button("Clear search") {
                searchText = ""
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(Theme.indigo)
            .frame(minHeight: 44)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 24)
    }

    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

private struct StatusChip: View {
    let icon: String
    let label: String
    let count: Int

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(Theme.indigo)
            Text("\(label) · \(count)")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Theme.ink)
        }
        .padding(.horizontal, 14)
        .frame(minHeight: 38)
        .background(
            Capsule().fill(Theme.card)
        )
        .overlay(
            Capsule().stroke(Theme.hairline, lineWidth: 1)
        )
    }
}

/// Empty-library illustration with the mot_empty_guide breathing float
/// (±4pt over 2.5s; static under Reduce Motion).
struct BreathingEmptyIllustration: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var breathing = false

    var body: some View {
        Group {
            if UIImage(named: "charts_empty_illustration") != nil {
                Image("charts_empty_illustration")
                    .resizable()
                    .scaledToFit()
            } else {
                // Declared fallback: SF Symbol on brand-tinted disc.
                ZStack {
                    Circle()
                        .fill(Theme.threadRed.opacity(0.12))
                    Image(systemName: "photo.on.rectangle")
                        .font(.system(size: 56))
                        .foregroundStyle(Theme.threadRed)
                }
            }
        }
        .frame(width: 230, height: 230)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .offset(y: breathing ? -4 : 4)
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
                breathing = true
            }
        }
        .accessibilityLabel("An empty embroidery hoop waiting for a pattern")
    }
}
