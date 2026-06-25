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
}
