import SwiftUI

/// Shared circular progress ring used across cards, detail, and stitch session.
struct ProgressRing: View {
    let progress: Double
    var size: CGFloat = 44
    var lineWidth: CGFloat = 4
    var showsLabel: Bool = true

    var body: some View {
        ZStack {
            Circle()
                .stroke(Theme.threadRed.opacity(0.15), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: max(0, min(1, progress)))
                .stroke(Theme.threadRed, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
            if showsLabel {
                Text("\(Int((progress * 100).rounded()))%")
                    .font(.system(size: size * 0.24, weight: .semibold, design: .rounded))
                    .foregroundStyle(Theme.ink)
                    .minimumScaleFactor(0.5)
            }
        }
        .frame(width: size, height: size)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Progress \(Int((progress * 100).rounded())) percent")
    }
}

/// System share sheet wrapper.
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

/// Small stitched-divider ornament used between sections.
struct StitchDivider: View {
    var body: some View {
        HStack(spacing: 8) {
            Rectangle().fill(Theme.hairline).frame(height: 1)
            Text("✕ ✕ ✕")
                .font(.system(size: 10))
                .foregroundStyle(Theme.threadRed.opacity(0.6))
            Rectangle().fill(Theme.hairline).frame(height: 1)
        }
        .accessibilityHidden(true)
    }
}
