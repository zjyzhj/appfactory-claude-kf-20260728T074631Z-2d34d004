import SwiftUI

/// chart_export — result card (free) + printable PDF (1 Export Credit).
/// Credit deduction happens only after a successful PDF render; balance 0
/// routes to credit_shop and resumes afterwards (ACC-009).
struct ChartExportView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let chartId: UUID

    enum ExportState: Equatable {
        case choosingFormat
        case rendering
        case savedToPhotos
        case sharedPDF
        case insufficientCredits
        case deniedPhotoWrite
        case failed
    }

    @State private var state: ExportState = .choosingFormat
    @State private var showCreditShop = false
    @State private var pendingPDFAfterShop = false
    @State private var shareItems: [Any]?
    @State private var pullOffset: CGFloat = 0
    @State private var showCheckmark = false

    private var chart: Chart? {
        store.chart(with: chartId)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.ScreenBackground()
                if let chart {
                    content(chart)
                }
            }
            .navigationTitle("Export chart")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .sheet(isPresented: $showCreditShop, onDismiss: resumePendingPDFIfNeeded) {
                CreditShopView()
                    .environmentObject(store)
            }
            .sheet(isPresented: shareSheetBinding) {
                if let shareItems {
                    ShareSheet(items: shareItems)
                }
            }
        }
    }

    @ViewBuilder
    private func content(_ chart: Chart) -> some View {
        ScrollView {
            VStack(spacing: 18) {
                // Card preview (result card render, ~50% viewport).
                Image(uiImage: cardImage(chart))
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 380)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Theme.hairline, lineWidth: 1)
                    )
                    .padding(.horizontal, 20)
                    .offset(y: pullOffset) // mot_export_pull: card pulls upward on success

                Text("Chart card preview")
                    .font(.caption)
                    .foregroundStyle(Theme.inkSecondary)

                if let banner = successBanner {
                    successBannerView(banner)
                }

                if state == .insufficientCredits {
                    insufficientCreditsCard
                }

                if state == .deniedPhotoWrite {
                    deniedWriteCard(chart)
                }

                if state == .failed {
                    errorCard
                }

                // Format rows.
                formatRow(
                    icon: "photo",
                    title: "Result Card",
                    subtitle: "PNG pattern card · free"
                ) {
                    exportImageCard(chart)
                }

                formatRow(
                    icon: "doc.richtext",
                    title: "Printable Chart PDF",
                    subtitle: "Multi-page chart + key · 1 Export Credit"
                ) {
                    exportPDF(chart)
                }

                // Balance row → credit_shop.
                HStack {
                    Image(systemName: "circle.circle")
                        .foregroundStyle(Theme.threadRed)
                    Text("Export credits: \(store.ledger.balance)")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Theme.ink)
                    Spacer()
                    Button("Get more") {
                        showCreditShop = true
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.indigo)
                    .frame(minHeight: 44)
                }
                .padding(.horizontal, 20)

                Spacer(minLength: 20)
            }
            .padding(.top, 12)
        }
        .overlay {
            if state == .rendering {
                ZStack {
                    Color.black.opacity(0.25).ignoresSafeArea()
                    VStack(spacing: 12) {
                        ProgressView()
                            .controlSize(.large)
                        Text("Rendering your chart…")
                            .font(.subheadline)
                            .foregroundStyle(.white)
                    }
                    .padding(24)
                    .background(RoundedRectangle(cornerRadius: 16).fill(.ultraThinMaterial))
                }
            }
        }
    }

    private func formatRow(icon: String, title: String, subtitle: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(Theme.indigo, lineWidth: 1.5)
                        .frame(width: 44, height: 44)
                    Image(systemName: icon)
                        .foregroundStyle(Theme.indigo)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(Theme.headlineSerif(17))
                        .foregroundStyle(Theme.ink)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(Theme.inkSecondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(Theme.inkSecondary)
            }
            .padding(14)
            .atelierCard()
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 20)
        .disabled(state == .rendering)
    }

    // MARK: - Result card (free)

    private func exportImageCard(_ chart: Chart) {
        state = .rendering
        let card = cardImage(chart)
        Task {
            let outcome = await PhotoLibraryWriter.saveToPhotos(card)
            switch outcome {
            case .saved:
                store.recordExport(chartId: chart.id, kind: .imageCard)
                Haptics.mediumTap()
                withAnimation(Motion.pull(reduceMotion: reduceMotion)) {
                    state = .savedToPhotos
                    pullOffset = -14
                    showCheckmark = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
                    withAnimation(Motion.weave(reduceMotion: reduceMotion)) {
                        pullOffset = 0
                    }
                }
            case .denied:
                state = .deniedPhotoWrite
            case .failed:
                state = .failed
            }
        }
    }

    private func deniedWriteCard(_ chart: Chart) -> some View {
        VStack(spacing: 10) {
            Text("Couldn't save to Photos. You can share the image instead.")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundStyle(Theme.ink)
            HStack(spacing: 12) {
                Button("Share") {
                    shareItems = [cardImage(chart)]
                    store.recordExport(chartId: chart.id, kind: .imageCard)
                }
                .buttonStyle(Theme.SecondaryButtonStyle())
                Button("Retry") {
                    exportImageCard(chart)
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Theme.indigo)
                .frame(minHeight: 44)
            }
        }
        .padding(16)
        .atelierCard()
        .padding(.horizontal, 20)
    }

    // MARK: - Printable PDF (1 credit)

    private func exportPDF(_ chart: Chart) {
        guard store.ledger.balance >= CreditCatalog.printablePDFCost else {
            state = .insufficientCredits
            return
        }
        state = .rendering
        Task.detached(priority: .userInitiated) {
            let pdfData = ExportEngine.makePrintablePDF(chart: chart)
            await MainActor.run {
                // Deduction only after a successful render (checklist §9).
                // Capture the funding purchase first so the export record can
                // trace back to the StoreKit transaction that paid for it.
                let fundingTransactionId = store.fundingStorekitTransactionIdForNextSpend
                store.consumeCredits(CreditCatalog.printablePDFCost, note: "Printable PDF · \(chart.title)")
                store.recordExport(chartId: chart.id, kind: .printablePDF, storekitTransactionId: fundingTransactionId)
                let tempURL = FileManager.default.temporaryDirectory
                    .appendingPathComponent("ThreadGrid-\(chart.title.replacingOccurrences(of: " ", with: "-")).pdf")
                try? pdfData.write(to: tempURL)
                shareItems = [tempURL]
                Haptics.mediumTap()
                withAnimation(Motion.pull(reduceMotion: reduceMotion)) {
                    state = .sharedPDF
                    showCheckmark = true
                }
            }
        }
    }

    private var insufficientCreditsCard: some View {
        VStack(spacing: 10) {
            Text("Printable charts use 1 Export Credit. Get more to print.")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundStyle(Theme.ink)
            HStack(spacing: 12) {
                Button("Get Credits") {
                    pendingPDFAfterShop = true
                    showCreditShop = true
                }
                .buttonStyle(Theme.SecondaryButtonStyle())
                Button("Cancel") {
                    state = .choosingFormat
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Theme.inkSecondary)
                .frame(minHeight: 44)
            }
        }
        .padding(16)
        .atelierCard()
        .padding(.horizontal, 20)
    }

    private func resumePendingPDFIfNeeded() {
        guard pendingPDFAfterShop else { return }
        pendingPDFAfterShop = false
        if let chart, store.ledger.balance >= CreditCatalog.printablePDFCost {
            exportPDF(chart)
        } else {
            state = .choosingFormat
        }
    }

    private var errorCard: some View {
        VStack(spacing: 10) {
            Text("Something went wrong. Your work is saved — please try again.")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundStyle(Theme.ink)
            Button("Try again") {
                state = .choosingFormat
            }
            .buttonStyle(Theme.SecondaryButtonStyle())
        }
        .padding(16)
        .atelierCard()
        .padding(.horizontal, 20)
    }

    // MARK: - Success feedback

    private var successBanner: String? {
        switch state {
        case .savedToPhotos: return "Saved to Photos."
        case .sharedPDF: return "Your printable chart is ready."
        default: return nil
        }
    }

    private func successBannerView(_ text: String) -> some View {
        HStack(spacing: 10) {
            if showCheckmark {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(Theme.sage)
                    .transition(.scale.combined(with: .opacity))
            }
            Text(text)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Theme.ink)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Capsule().fill(Theme.sage.opacity(0.14)))
        .padding(.horizontal, 20)
    }

    private var shareSheetBinding: Binding<Bool> {
        Binding(
            get: { shareItems != nil },
            set: { if !$0 { shareItems = nil } }
        )
    }

    private func cardImage(_ chart: Chart) -> UIImage {
        let finishedPhoto = chart.finishedPhotoPath.flatMap { store.loadSandboxPhoto(relativePath: $0) }
        return ExportEngine.makeResultCard(chart: chart, finishedPhoto: finishedPhoto)
    }
}
