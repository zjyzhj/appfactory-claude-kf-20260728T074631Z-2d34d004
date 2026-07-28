import SwiftUI

/// chart_detail — single chart overview: big grid render, progress, thread
/// needs, finished photo, and actions (Stitch / Edit / Export / Delete).
struct ChartDetailView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss

    let chartId: UUID

    @State private var showExport = false
    @State private var showDeleteConfirm = false
    @State private var showEditor = false

    private var chart: Chart? {
        store.chart(with: chartId)
    }

    var body: some View {
        ZStack {
            Theme.ScreenBackground()
            if let chart {
                detailContent(chart)
            } else {
                ContentUnavailableView(
                    "Chart not found",
                    systemImage: "rectangle.grid.3x3",
                    description: Text("It may have been deleted.")
                )
            }
        }
        .navigationTitle(chart?.title ?? "Chart")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showExport) {
            if let chart {
                ChartExportView(chartId: chart.id)
                    .environmentObject(store)
            }
        }
        .navigationDestination(isPresented: $showEditor) {
            if let chart {
                ChartEditorView(chartId: chart.id)
            }
        }
        .confirmationDialog(
            "Delete this chart? Its stitching progress will be removed.",
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("Delete chart", role: .destructive) {
                if let chart {
                    store.deleteChart(chart)
                }
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    @ViewBuilder
    private func detailContent(_ chart: Chart) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                // Big grid render (chart_thumbnail slot, 30–50% of viewport).
                Image(uiImage: ChartRenderer.image(chart: chart, style: .detail))
                    .resizable()
                    .interpolation(.none)
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .frame(maxHeight: 420)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Theme.hairline, lineWidth: 1)
                    )
                    .padding(.horizontal, 20)
                    .accessibilityLabel("Chart grid render of \(chart.title)")

                // Progress + meta row.
                HStack(spacing: 16) {
                    ProgressRing(progress: chart.progress, size: 64, lineWidth: 6)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(chart.stitchedCount) / \(chart.totalCells) stitches")
                            .font(Theme.mono(15, weight: .medium))
                            .foregroundStyle(Theme.ink)
                        Text("\(chart.widthCells) × \(chart.heightCells) · \(chart.palette.count) colors")
                            .font(Theme.mono(12))
                            .foregroundStyle(Theme.inkSecondary)
                        Text(chart.createdAt.formatted(date: .abbreviated, time: .omitted))
                            .font(.caption)
                            .foregroundStyle(Theme.inkSecondary)
                    }
                    Spacer()
                }
                .padding(.horizontal, 20)

                // Finished piece photo (finished_piece_photo slot).
                if let photoPath = chart.finishedPhotoPath,
                   let photo = store.loadSandboxPhoto(relativePath: photoPath) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Finished piece")
                            .font(Theme.headlineSerif(17))
                            .foregroundStyle(Theme.ink)
                        Image(uiImage: photo)
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: .infinity)
                            .frame(height: 200)
                            .clipped()
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .padding(.horizontal, 20)
                }

                threadNeeds(chart)

                // Actions.
                VStack(spacing: 12) {
                    Button {
                        store.setActiveChart(chart.id)
                        store.selectedTab = .stitch
                    } label: {
                        Label(chart.stitchedCount > 0 ? "Resume stitching" : "Start stitching",
                              systemImage: "circle.grid.cross")
                    }
                    .buttonStyle(Theme.PrimaryButtonStyle())

                    HStack(spacing: 12) {
                        Button {
                            showEditor = true
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                        .buttonStyle(Theme.SecondaryButtonStyle())

                        Button {
                            showExport = true
                        } label: {
                            Label("Export", systemImage: "square.and.arrow.up")
                        }
                        .buttonStyle(Theme.SecondaryButtonStyle())
                    }

                    Button(role: .destructive) {
                        showDeleteConfirm = true
                    } label: {
                        Label("Delete chart", systemImage: "trash")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Theme.threadRed)
                            .frame(maxWidth: .infinity)
                            .frame(minHeight: 44)
                    }
                }
                .padding(.horizontal, 20)

                Spacer(minLength: 24)
            }
            .padding(.top, 12)
        }
    }

    @ViewBuilder
    private func threadNeeds(_ chart: Chart) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Thread needs")
                .font(Theme.headlineSerif(17))
                .foregroundStyle(Theme.ink)
            ForEach(chart.palette.prefix(5)) { color in
                let thread = DMCLibrary.shared.thread(for: color.dmcCode)
                let owned = store.skeinsOwned(for: color.dmcCode)
                let needed = ExportEngine.estimatedSkeinsText(for: color.stitchCount)
                HStack(spacing: 12) {
                    Circle()
                        .fill(Color(hexString: thread?.hex ?? "#999999"))
                        .frame(width: 22, height: 22)
                        .overlay(Circle().stroke(Theme.hairline, lineWidth: 1))
                    Text("DMC \(color.dmcCode)")
                        .font(Theme.mono(13, weight: .medium))
                        .foregroundStyle(Theme.ink)
                    Text(thread?.name ?? "")
                        .font(.caption)
                        .foregroundStyle(Theme.inkSecondary)
                        .lineLimit(1)
                    Spacer()
                    Text("\(needed) skeins")
                        .font(Theme.mono(12))
                        .foregroundStyle(Theme.inkSecondary)
                    if owned > 0 {
                        Label("Have \(owned)", systemImage: "checkmark.circle.fill")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Theme.sage)
                            .labelStyle(.titleAndIcon)
                    } else {
                        Label("Missing", systemImage: "exclamationmark.circle.fill")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Theme.amber)
                            .labelStyle(.titleAndIcon)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Theme.card)
                )
            }
            if chart.palette.count > 5 {
                Text("See the Threads tab for the full list.")
                    .font(.caption)
                    .foregroundStyle(Theme.inkSecondary)
            }
        }
        .padding(.horizontal, 20)
    }
}
