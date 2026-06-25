import SwiftUI

@main
struct OpsPulseApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @State private var store = OpsStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(store)
                .task {
                    await store.bootstrap()
                    applyScreenshotRouteIfNeeded()
                }
                .onOpenURL { url in
                    store.handleDeepLink(url)
                }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .background {
                Task { await store.persistSnapshot() }
            }
        }
    }

    private func applyScreenshotRouteIfNeeded() {
        let arguments = ProcessInfo.processInfo.arguments
        guard let routeIndex = arguments.firstIndex(of: "--screenshot-route"),
              arguments.indices.contains(arguments.index(after: routeIndex)) else {
            return
        }

        let route = arguments[arguments.index(after: routeIndex)]
        if let url = URL(string: "opspulse://\(route)") {
            store.handleDeepLink(url)
        }
    }
}
