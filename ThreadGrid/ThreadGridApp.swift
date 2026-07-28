import SwiftUI

@main
struct ThreadGridApp: App {
    @StateObject private var store = AppStore()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environmentObject(store)
                .tint(Theme.threadRed)
                .onChange(of: scenePhase) { _, newPhase in
                    if newPhase == .background || newPhase == .inactive {
                        store.flush()
                    }
                }
        }
    }
}

struct RootTabView: View {
    @EnvironmentObject private var store: AppStore

    var body: some View {
        TabView(selection: $store.selectedTab) {
            NavigationStack {
                ChartsHomeView()
            }
            .tabItem {
                Label("Charts", systemImage: "square.grid.3x3")
            }
            .tag(AppTab.charts)

            NavigationStack {
                CreateWizardView()
            }
            .tabItem {
                Label("Create", systemImage: "plus.circle")
            }
            .tag(AppTab.create)

            NavigationStack {
                StitchTabView()
            }
            .tabItem {
                Label("Stitch", systemImage: "circle.grid.cross")
            }
            .tag(AppTab.stitch)

            NavigationStack {
                ThreadsView()
            }
            .tabItem {
                Label("Threads", systemImage: "swatchpalette")
            }
            .tag(AppTab.threads)
        }
        .background(Theme.background.ignoresSafeArea())
    }
}
