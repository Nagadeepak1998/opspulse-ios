import Foundation
import Observation

@MainActor
@Observable
final class OpsStore {
    var snapshot: OpsPulseSnapshot = DemoFixtures.snapshot()
    var selectedTab: AppTab = .overview
    var servicePath: [String] = []
    var incidentPath: [String] = []
    var isLoading = false
    var isDemoMode = true
    var liveBaseURL = "https://localhost:8080"
    var lastConnectionStatus = "Not tested"
    var lastError: String?
    var bannerMessage: String?

    private let repository: any OpsRepository
    private let persistence: AppSnapshotPersistence
    private let tokenStore: SecureTokenStore
    private let notificationScheduler: LocalIncidentNotificationScheduling

    init(
        repository: any OpsRepository = DemoOpsRepository(),
        persistence: AppSnapshotPersistence = .defaultStore(),
        tokenStore: SecureTokenStore = KeychainTokenStore(),
        notificationScheduler: LocalIncidentNotificationScheduling = LocalIncidentNotificationScheduler()
    ) {
        self.repository = repository
        self.persistence = persistence
        self.tokenStore = tokenStore
        self.notificationScheduler = notificationScheduler
    }

    var overview: ReliabilityOverview {
        DemoOpsRepository.overview(from: snapshot)
    }

    var activeIncidents: [Incident] {
        snapshot.incidents
            .filter { $0.status != .resolved }
            .sorted { $0.severity == $1.severity ? $0.startedAt > $1.startedAt : $0.severity < $1.severity }
    }

    var resolvedIncidents: [Incident] {
        snapshot.incidents
            .filter { $0.status == .resolved }
            .sorted { ($0.resolvedAt ?? $0.startedAt) > ($1.resolvedAt ?? $1.startedAt) }
    }

    func bootstrap() async {
        if let persisted = await persistence.load() {
            snapshot = persisted
        } else {
            await refresh()
        }
    }

    func refresh() async {
        isLoading = true
        defer { isLoading = false }
        do {
            snapshot = try await repository.refresh()
            await persistence.save(snapshot)
        } catch {
            showError(error)
        }
    }

    func persistSnapshot() async {
        await persistence.save(snapshot)
    }

    func resetDemoData() async {
        snapshot = await repository.reset()
        await persistence.save(snapshot)
        showBanner("Demo data reset")
    }

    func runSimulation(_ scenario: SimulationScenario) async {
        do {
            let beforeIDs = Set(snapshot.incidents.map(\.id))
            snapshot = try await repository.runSimulation(scenario)
            await persistence.save(snapshot)
            if let newIncident = snapshot.incidents.first(where: { !beforeIDs.contains($0.id) }) {
                showBanner("\(scenario.displayName) generated \(newIncident.severity.displayName)")
                await notificationScheduler.scheduleCriticalIncidentIfNeeded(newIncident)
                selectedTab = .incidents
                incidentPath = [newIncident.id]
            }
        } catch {
            showError(error)
        }
    }

    func acknowledgeIncident(_ incidentID: String, commander: String) async {
        do {
            let incident = try await repository.acknowledgeIncident(id: incidentID, commander: commander)
            replaceIncident(incident)
            await persistence.save(snapshot)
        } catch {
            showError(error)
        }
    }

    func assignCommander(_ commander: String, incidentID: String) async {
        do {
            let incident = try await repository.assignCommander(commander, incidentID: incidentID)
            replaceIncident(incident)
            await persistence.save(snapshot)
        } catch {
            showError(error)
        }
    }

    func transitionIncident(_ incidentID: String, to status: IncidentStatus) async {
        do {
            let incident = try await repository.transitionIncident(id: incidentID, to: status)
            replaceIncident(incident)
            snapshot = await repository.snapshot()
            await persistence.save(snapshot)
        } catch {
            showError(error)
        }
    }

    func addTimelineNote(_ note: String, author: String, incidentID: String) async {
        do {
            let trimmed = note.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { return }
            let incident = try await repository.addTimelineNote(trimmed, author: author, incidentID: incidentID)
            replaceIncident(incident)
            await persistence.save(snapshot)
        } catch {
            showError(error)
        }
    }

    func completeRunbookStep(runbookID: String, stepID: String, isComplete: Bool) async {
        do {
            let runbook = try await repository.completeRunbookStep(runbookID: runbookID, stepID: stepID, isComplete: isComplete)
            replaceRunbook(runbook)
            await persistence.save(snapshot)
        } catch {
            showError(error)
        }
    }

    func saveToken(_ token: String) {
        do {
            try tokenStore.save(token)
            showBanner("Token stored in Keychain")
        } catch {
            showError(error)
        }
    }

    func clearToken() {
        do {
            try tokenStore.delete()
            showBanner("Token removed")
        } catch {
            showError(error)
        }
    }

    func testLiveConnection() async {
        guard let baseURL = URL(string: liveBaseURL), baseURL.scheme?.hasPrefix("http") == true else {
            lastConnectionStatus = OpsAPIError.invalidBaseURL.localizedDescription
            return
        }

        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = 12
        let api = HTTPOpsAPI(
            baseURL: baseURL,
            session: URLSession(configuration: configuration),
            tokenProvider: KeychainTokenProvider(tokenStore: tokenStore)
        )

        do {
            let response = try await api.health()
            lastConnectionStatus = "Connected: \(response.status) \(response.version)"
        } catch {
            lastConnectionStatus = error.localizedDescription
        }
    }

    func service(id: String) -> OpsService? {
        snapshot.services.first { $0.id == id }
    }

    func incident(id: String) -> Incident? {
        snapshot.incidents.first { $0.id == id }
    }

    func runbook(id: String) -> Runbook? {
        snapshot.runbooks.first { $0.id == id }
    }

    func relatedIncidents(for serviceID: String) -> [Incident] {
        snapshot.incidents.filter { $0.affectedServiceIDs.contains(serviceID) }
    }

    func handleDeepLink(_ url: URL) {
        guard url.scheme == "opspulse" else { return }
        switch url.host {
        case "incidents":
            selectedTab = .incidents
            if let id = url.pathComponents.dropFirst().first {
                incidentPath = [id]
            }
        case "services":
            selectedTab = .services
            if let id = url.pathComponents.dropFirst().first {
                servicePath = [id]
            }
        case "lab":
            selectedTab = .lab
        default:
            selectedTab = .overview
        }
    }

    private func replaceIncident(_ incident: Incident) {
        if let index = snapshot.incidents.firstIndex(where: { $0.id == incident.id }) {
            snapshot.incidents[index] = incident
        }
    }

    private func replaceRunbook(_ runbook: Runbook) {
        if let index = snapshot.runbooks.firstIndex(where: { $0.id == runbook.id }) {
            snapshot.runbooks[index] = runbook
        }
    }

    private func showError(_ error: Error) {
        lastError = error.localizedDescription
        showBanner(error.localizedDescription)
    }

    private func showBanner(_ message: String) {
        bannerMessage = message
        Task { [weak self] in
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            await MainActor.run {
                if self?.bannerMessage == message {
                    self?.bannerMessage = nil
                }
            }
        }
    }
}
