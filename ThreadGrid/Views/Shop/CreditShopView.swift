import SwiftUI
import StoreKit

/// credit_shop — consumable Export Credit packs (yanran catalog).
/// Value-first copy, cancel always available, past purchases are never
/// re-credited (consumables), product IDs never shown (internal only).
struct CreditShopView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss

    @State private var manager: CreditShopManager?

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.ScreenBackground()
                if let manager {
                    shopContent(manager)
                } else {
                    ProgressView()
                        .controlSize(.large)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .navigationTitle("Export Credits")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
        .onAppear {
            if manager == nil {
                let created = CreditShopManager(appStore: store)
                manager = created
                Task { await created.loadProducts() }
            }
        }
    }

    @ViewBuilder
    private func shopContent(_ manager: CreditShopManager) -> some View {
        ScrollView {
            VStack(spacing: 16) {
                // Balance header.
                VStack(spacing: 6) {
                    Text("\(store.ledger.balance)")
                        .font(Theme.titleFont(44, weight: .bold))
                        .foregroundStyle(Theme.threadRed)
                    Text("credits on your spool")
                        .font(.subheadline)
                        .foregroundStyle(Theme.inkSecondary)
                    Text("Each printable chart PDF uses 1 credit. Everything else stays free.")
                        .font(.caption)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(Theme.inkSecondary)
                        .padding(.horizontal, 32)
                }
                .padding(.top, 12)

                // Purchase feedback.
                switch manager.purchaseState {
                case .success(let amount):
                    successBanner(amount: amount, manager: manager)
                case .failed:
                    failedBanner(manager: manager)
                default:
                    EmptyView()
                }

                if manager.productsLoadFailed {
                    VStack(spacing: 8) {
                        Text("Couldn't reach the store. Showing reference prices — retry to buy.")
                            .font(.caption)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(Theme.inkSecondary)
                        Button("Retry") {
                            Task { await manager.loadProducts() }
                        }
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Theme.indigo)
                        .frame(minHeight: 36)
                    }
                    .padding(.horizontal, 20)
                }

                // Product rows (verbatim yanran catalog amounts).
                ForEach(CreditCatalog.displayedProducts) { product in
                    productRow(product, manager: manager)
                }

                Text("Credits are consumed only when a printable PDF is actually exported. Purchases are processed by the App Store.")
                    .font(.caption2)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Theme.inkSecondary)
                    .padding(.horizontal, 28)
                    .padding(.top, 4)

                Spacer(minLength: 24)
            }
        }
    }

    private func productRow(_ product: CreditCatalog.Product, manager: CreditShopManager) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 8) {
                    Text("\(product.amount) credits")
                        .font(.headline)
                        .foregroundStyle(Theme.ink)
                    if product.promotion {
                        Text("Special offer")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(Capsule().fill(Theme.sage))
                    }
                }
                Text("About \(product.amount) printable charts")
                    .font(.caption)
                    .foregroundStyle(Theme.inkSecondary)
            }
            Spacer()
            Button {
                Task { await manager.purchase(product) }
            } label: {
                if case .purchasing(let id) = manager.purchaseState, id == product.productID {
                    ProgressView()
                        .frame(minWidth: 76, minHeight: 36)
                } else {
                    Text(manager.displayPrice(for: product))
                        .font(.subheadline.weight(.semibold))
                        .frame(minWidth: 76, minHeight: 36)
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(Theme.threadRed)
            .disabled(isPurchasing(manager))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .atelierCard()
        .padding(.horizontal, 20)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(product.amount) credits, \(manager.displayPrice(for: product))")
    }

    private func isPurchasing(_ manager: CreditShopManager) -> Bool {
        if case .purchasing = manager.purchaseState { return true }
        return false
    }

    private func successBanner(amount: Int, manager: CreditShopManager) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(Theme.sage)
            Text("Credits added. Happy stitching! (+\(amount))")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Theme.ink)
            Spacer()
            Button("OK") {
                manager.resetToBrowsing()
            }
            .font(.caption.weight(.bold))
            .foregroundStyle(Theme.indigo)
            .frame(minHeight: 32)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Capsule().fill(Theme.sage.opacity(0.14)))
        .padding(.horizontal, 20)
        .onAppear { Haptics.success() }
    }

    private func failedBanner(manager: CreditShopManager) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(Theme.amber)
            Text("Purchase didn't go through. You were not charged.")
                .font(.subheadline)
                .foregroundStyle(Theme.ink)
            Spacer()
            Button("OK") {
                manager.resetToBrowsing()
            }
            .font(.caption.weight(.bold))
            .foregroundStyle(Theme.indigo)
            .frame(minHeight: 32)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Capsule().fill(Theme.amber.opacity(0.14)))
        .padding(.horizontal, 20)
    }
}
