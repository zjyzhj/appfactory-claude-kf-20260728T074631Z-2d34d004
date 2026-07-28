import SwiftUI
import WebKit

/// settings — credit balance, privacy explainer, legal webviews, about.
struct SettingsView: View {
    @EnvironmentObject private var store: AppStore
    @State private var showCreditShop = false

    var body: some View {
        ZStack {
            Theme.ScreenBackground()
            List {
                Section("Export Credits") {
                    Button {
                        showCreditShop = true
                    } label: {
                        HStack {
                            Image(systemName: "circle.circle")
                                .foregroundStyle(Theme.threadRed)
                            Text("Balance")
                                .foregroundStyle(Theme.ink)
                            Spacer()
                            Text("\(store.ledger.balance) credits")
                                .font(Theme.mono(13, weight: .medium))
                                .foregroundStyle(Theme.inkSecondary)
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(Theme.inkSecondary)
                        }
                        .frame(minHeight: 44)
                    }
                }

                Section("Privacy") {
                    NavigationLink {
                        PrivacyExplainerView()
                    } label: {
                        Label("Privacy in ThreadGrid", systemImage: "hand.raised.fill")
                            .foregroundStyle(Theme.ink)
                            .frame(minHeight: 44)
                    }
                    NavigationLink {
                        LegalWebView(title: "Privacy Policy", url: LegalURLs.privacyPolicy)
                    } label: {
                        Label("Privacy Policy", systemImage: "doc.text.fill")
                            .foregroundStyle(Theme.ink)
                            .frame(minHeight: 44)
                    }
                    NavigationLink {
                        LegalWebView(title: "User Agreement", url: LegalURLs.userAgreement)
                    } label: {
                        Label("User Agreement", systemImage: "doc.plaintext.fill")
                            .foregroundStyle(Theme.ink)
                            .frame(minHeight: 44)
                    }
                }

                Section("About") {
                    HStack {
                        Text("Version")
                            .foregroundStyle(Theme.ink)
                        Spacer()
                        Text("1.0")
                            .foregroundStyle(Theme.inkSecondary)
                    }
                    .frame(minHeight: 44)
                    HStack {
                        Text("Made for stitchers")
                            .foregroundStyle(Theme.ink)
                        Spacer()
                        Text("Photos never leave this device")
                            .font(.caption)
                            .foregroundStyle(Theme.inkSecondary)
                    }
                    .frame(minHeight: 44)
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("Settings")
        .sheet(isPresented: $showCreditShop) {
            CreditShopView()
                .environmentObject(store)
        }
    }
}

/// Two independent HTTPS legal documents (checklist §10).
enum LegalURLs {
    static let privacyPolicy = URL(string: "https://threadgrid.app/legal/privacy")!
    static let userAgreement = URL(string: "https://threadgrid.app/legal/terms")!
}

/// WKWebView with loading + failure/retry states.
struct LegalWebView: View {
    let title: String
    let url: URL

    @State private var didFail = false
    @State private var isLoading = true
    @State private var reloadToken = 0

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            WebViewRepresentable(
                url: url,
                reloadToken: reloadToken,
                isLoading: $isLoading,
                didFail: $didFail
            )
            if isLoading && !didFail {
                VStack(spacing: 10) {
                    ProgressView()
                    Text("Loading \(title)…")
                        .font(.caption)
                        .foregroundStyle(Theme.inkSecondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Theme.background)
            }
            if didFail {
                VStack(spacing: 14) {
                    Image(systemName: "wifi.exclamationmark")
                        .font(.system(size: 36))
                        .foregroundStyle(Theme.amber)
                    Text("Couldn't load this page. Check your connection and try again.")
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(Theme.ink)
                        .padding(.horizontal, 32)
                    Button("Retry") {
                        didFail = false
                        isLoading = true
                        reloadToken += 1
                    }
                    .buttonStyle(Theme.SecondaryButtonStyle())
                    .padding(.horizontal, 64)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Theme.background)
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct WebViewRepresentable: UIViewRepresentable {
    let url: URL
    let reloadToken: Int
    @Binding var isLoading: Bool
    @Binding var didFail: Bool

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        webView.load(URLRequest(url: url))
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        if context.coordinator.lastReloadToken != reloadToken {
            context.coordinator.lastReloadToken = reloadToken
            webView.load(URLRequest(url: url))
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(isLoading: $isLoading, didFail: $didFail)
    }

    final class Coordinator: NSObject, WKNavigationDelegate {
        @Binding var isLoading: Bool
        @Binding var didFail: Bool
        var lastReloadToken = 0

        init(isLoading: Binding<Bool>, didFail: Binding<Bool>) {
            _isLoading = isLoading
            _didFail = didFail
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            isLoading = false
            didFail = false
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            isLoading = false
            didFail = true
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            isLoading = false
            didFail = true
        }
    }
}

/// In-app privacy explainer (ACC-011): all data local, how deletion works.
struct PrivacyExplainerView: View {
    var body: some View {
        ZStack {
            Theme.ScreenBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    privacyRow(
                        icon: "iphone",
                        title: "Everything stays on this device",
                        body: "Charts, stitching progress, photos, and credits live in the app's sandbox. There is no account, no cloud sync, and no analytics."
                    )
                    privacyRow(
                        icon: "camera.fill",
                        title: "Camera",
                        body: "Used only when you take a photo for a chart or a finished piece. Nothing is recorded or uploaded."
                    )
                    privacyRow(
                        icon: "photo.on.rectangle",
                        title: "Photo library",
                        body: "Read only when you pick a photo to chart. Written only when you save a result card. You can keep stitching without either."
                    )
                    privacyRow(
                        icon: "trash.fill",
                        title: "Deleting your data",
                        body: "Delete a chart to remove its grid, progress, exports, and photo copies. Deleting the app removes everything."
                    )
                }
                .padding(20)
            }
        }
        .navigationTitle("Privacy in ThreadGrid")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func privacyRow(icon: String, title: String, body: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(Theme.threadRed)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(Theme.headlineSerif(16))
                    .foregroundStyle(Theme.ink)
                Text(body)
                    .font(.subheadline)
                    .foregroundStyle(Theme.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
