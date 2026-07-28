import SwiftUI

/// Pattern card in the library list: real grid-render thumbnail (not the
/// source photo, not an SF Symbol), title, meta, and progress ring (F1).
struct ChartCardView: View {
    let chart: Chart

    var body: some View {
        HStack(spacing: 14) {
            Image(uiImage: thumbnail)
                .resizable()
                .interpolation(.none)
                .scaledToFill()
                .frame(width: 76, height: 76)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(Theme.hairline, lineWidth: 1)
                )
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text(chart.title)
                    .font(Theme.headlineSerif(18))
                    .foregroundStyle(Theme.ink)
                    .lineLimit(1)
                Text("\(chart.palette.count) colors · \(chart.widthCells) × \(chart.heightCells)")
                    .font(Theme.mono(12))
                    .foregroundStyle(Theme.inkSecondary)
                statusBadge
            }

            Spacer(minLength: 8)

            ProgressRing(progress: chart.progress, size: 48)
        }
        .padding(14)
        .atelierCard()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(chart.title), \(chart.palette.count) colors, \(chart.widthCells) by \(chart.heightCells), \(Int((chart.progress * 100).rounded())) percent stitched")
    }

    private var thumbnail: UIImage {
        ChartRenderer.image(chart: chart, style: .thumbnail)
    }

    private var statusBadge: some View {
        let (text, color): (String, Color) = {
            switch chart.status {
            case .active: return ("In progress", Theme.indigo)
            case .draft: return ("Draft", Theme.inkSecondary)
            case .finished: return ("Finished", Theme.sage)
            }
        }()
        return Text(text)
            .font(.caption.weight(.semibold))
            .foregroundStyle(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Capsule().fill(color.opacity(0.12)))
    }
}
