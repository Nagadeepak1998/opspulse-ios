import AppIntents

struct ShowCriticalIncidentsIntent: AppIntent {
    static let title: LocalizedStringResource = "Show Critical Incidents"
    static let description = IntentDescription("Open OpsPulse to the active incident queue.")
    static let openAppWhenRun = true

    func perform() async throws -> some IntentResult {
        .result()
    }
}

struct ShowHighBurnRateServicesIntent: AppIntent {
    static let title: LocalizedStringResource = "Show Services With High Burn Rate"
    static let description = IntentDescription("Open OpsPulse to the service catalog for SLO review.")
    static let openAppWhenRun = true

    func perform() async throws -> some IntentResult {
        .result()
    }
}

struct OpsPulseShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: ShowCriticalIncidentsIntent(),
            phrases: ["Show critical incidents in \(.applicationName)"],
            shortTitle: "Critical Incidents",
            systemImageName: "exclamationmark.triangle"
        )
        AppShortcut(
            intent: ShowHighBurnRateServicesIntent(),
            phrases: ["Show high burn rate services in \(.applicationName)"],
            shortTitle: "High Burn Rate",
            systemImageName: "flame"
        )
    }
}
