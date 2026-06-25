import Foundation

public enum RepositoryError: Error, Equatable, LocalizedError, Sendable {
    case serviceNotFound(String)
    case incidentNotFound(String)
    case runbookNotFound(String)
    case runbookStepNotFound(String)

    public var errorDescription: String? {
        switch self {
        case let .serviceNotFound(id): "Service not found: \(id)"
        case let .incidentNotFound(id): "Incident not found: \(id)"
        case let .runbookNotFound(id): "Runbook not found: \(id)"
        case let .runbookStepNotFound(id): "Runbook step not found: \(id)"
        }
    }
}

public protocol OpsRepository: Sendable {
    func snapshot() async -> OpsPulseSnapshot
    func refresh() async throws -> OpsPulseSnapshot
    func reset() async -> OpsPulseSnapshot
    func acknowledgeIncident(id: String, commander: String) async throws -> Incident
    func assignCommander(_ commander: String, incidentID: String) async throws -> Incident
    func transitionIncident(id: String, to status: IncidentStatus) async throws -> Incident
    func addTimelineNote(_ note: String, author: String, incidentID: String) async throws -> Incident
    func completeRunbookStep(runbookID: String, stepID: String, isComplete: Bool) async throws -> Runbook
    func runSimulation(_ scenario: SimulationScenario) async throws -> OpsPulseSnapshot
}

public actor DemoOpsRepository: OpsRepository {
    private var currentSnapshot: OpsPulseSnapshot
    private let dateProvider: DateProvider

    public init(snapshot: OpsPulseSnapshot = DemoFixtures.snapshot(), dateProvider: DateProvider = SystemDateProvider()) {
        self.currentSnapshot = snapshot
        self.dateProvider = dateProvider
    }

    public func snapshot() async -> OpsPulseSnapshot {
        currentSnapshot
    }

    public func refresh() async throws -> OpsPulseSnapshot {
        try await Task.sleep(nanoseconds: 250_000_000)
        return currentSnapshot
    }

    public func reset() async -> OpsPulseSnapshot {
        currentSnapshot = DemoFixtures.snapshot()
        return currentSnapshot
    }

    public func acknowledgeIncident(id: String, commander: String) async throws -> Incident {
        let index = try incidentIndex(id)
        let updated = try IncidentWorkflow.acknowledge(currentSnapshot.incidents[index], at: dateProvider.now(), by: commander)
        currentSnapshot.incidents[index] = updated
        return updated
    }

    public func assignCommander(_ commander: String, incidentID: String) async throws -> Incident {
        let index = try incidentIndex(incidentID)
        let updated = IncidentWorkflow.assignCommander(commander, at: dateProvider.now(), to: currentSnapshot.incidents[index])
        currentSnapshot.incidents[index] = updated
        return updated
    }

    public func transitionIncident(id: String, to status: IncidentStatus) async throws -> Incident {
        let index = try incidentIndex(id)
        let updated = try IncidentWorkflow.transition(currentSnapshot.incidents[index], to: status, at: dateProvider.now())
        currentSnapshot.incidents[index] = updated
        if status == .resolved {
            removeOpenIncident(id)
            restoreResolvedServices(for: updated.affectedServiceIDs)
        }
        return updated
    }

    public func addTimelineNote(_ note: String, author: String, incidentID: String) async throws -> Incident {
        let index = try incidentIndex(incidentID)
        let updated = IncidentWorkflow.addTimelineNote(note, author: author, at: dateProvider.now(), to: currentSnapshot.incidents[index])
        currentSnapshot.incidents[index] = updated
        return updated
    }

    public func completeRunbookStep(runbookID: String, stepID: String, isComplete: Bool) async throws -> Runbook {
        let runbookIndex = try runbookIndex(runbookID)
        guard let stepIndex = currentSnapshot.runbooks[runbookIndex].steps.firstIndex(where: { $0.id == stepID }) else {
            throw RepositoryError.runbookStepNotFound(stepID)
        }
        currentSnapshot.runbooks[runbookIndex].steps[stepIndex].isComplete = isComplete
        return currentSnapshot.runbooks[runbookIndex]
    }

    public func runSimulation(_ scenario: SimulationScenario) async throws -> OpsPulseSnapshot {
        let incident = simulatedIncident(for: scenario, at: dateProvider.now())
        currentSnapshot.incidents.insert(incident, at: 0)

        for serviceID in incident.affectedServiceIDs {
            guard let serviceIndex = currentSnapshot.services.firstIndex(where: { $0.id == serviceID }) else { continue }
            currentSnapshot.services[serviceIndex] = degrade(currentSnapshot.services[serviceIndex], scenario: scenario, incidentID: incident.id)
        }

        return currentSnapshot
    }

    public static func overview(from snapshot: OpsPulseSnapshot) -> ReliabilityOverview {
        let activeIncidents = snapshot.incidents.filter { $0.status != .resolved }
        let productionServices = snapshot.services.filter { $0.environment == .production }
        let stagingServices = snapshot.services.filter { $0.environment == .staging }
        let availability = snapshot.services.isEmpty ? 100 : snapshot.services.map(\.currentAvailability).reduce(0, +) / Double(snapshot.services.count)
        let budgetSnapshots = snapshot.services.map(SLOCalculator.snapshot(for:))
        let averageRemaining = budgetSnapshots.isEmpty ? 1 : budgetSnapshots.map(\.remainingBudgetRatio).reduce(0, +) / Double(budgetSnapshots.count)
        let averageBurn = budgetSnapshots.isEmpty ? 0 : budgetSnapshots.map(\.burnRate).reduce(0, +) / Double(budgetSnapshots.count)
        let acknowledged = snapshot.incidents.compactMap { IncidentWorkflow.durations(for: $0).acknowledgment }
        let recovered = snapshot.incidents.compactMap { IncidentWorkflow.durations(for: $0).recovery }
        let successfulDeployments = snapshot.services
            .map(\.recentDeployment)
            .filter { $0.status.localizedCaseInsensitiveContains("succeeded") }
            .sorted { $0.deployedAt > $1.deployedAt }

        return ReliabilityOverview(
            productionStatus: aggregateStatus(productionServices),
            stagingStatus: aggregateStatus(stagingServices),
            healthyServices: snapshot.services.filter { $0.status == .healthy }.count,
            degradedServices: snapshot.services.filter { $0.status == .degraded }.count,
            unavailableServices: snapshot.services.filter { $0.status == .unavailable }.count,
            activeP1: activeIncidents.filter { $0.severity == .p1 }.count,
            activeP2: activeIncidents.filter { $0.severity == .p2 }.count,
            activeP3: activeIncidents.filter { $0.severity == .p3 }.count,
            overallAvailability: availability,
            errorBudgetRemaining: averageRemaining,
            burnRate: averageBurn,
            meanTimeToAcknowledge: acknowledged.isEmpty ? nil : acknowledged.reduce(0, +) / Double(acknowledged.count),
            meanTimeToRecovery: recovered.isEmpty ? nil : recovered.reduce(0, +) / Double(recovered.count),
            lastSuccessfulDeployment: successfulDeployments.first
        )
    }

    private static func aggregateStatus(_ services: [OpsService]) -> ServiceStatus {
        if services.contains(where: { $0.status == .unavailable }) { return .unavailable }
        if services.contains(where: { $0.status == .degraded }) { return .degraded }
        return .healthy
    }

    private func incidentIndex(_ id: String) throws -> Int {
        guard let index = currentSnapshot.incidents.firstIndex(where: { $0.id == id }) else {
            throw RepositoryError.incidentNotFound(id)
        }
        return index
    }

    private func runbookIndex(_ id: String) throws -> Int {
        guard let index = currentSnapshot.runbooks.firstIndex(where: { $0.id == id }) else {
            throw RepositoryError.runbookNotFound(id)
        }
        return index
    }

    private func removeOpenIncident(_ id: String) {
        currentSnapshot.services = currentSnapshot.services.map { service in
            var updated = service
            updated.openIncidentIDs.removeAll { $0 == id }
            return updated
        }
    }

    private func restoreResolvedServices(for serviceIDs: [String]) {
        currentSnapshot.services = currentSnapshot.services.map { service in
            guard serviceIDs.contains(service.id), service.openIncidentIDs.isEmpty else { return service }
            var updated = service
            updated.status = .healthy
            updated.currentAvailability = max(updated.currentAvailability, updated.availabilitySLO + 0.01)
            updated.errorRate = min(updated.errorRate, SLOCalculator.permittedFailurePercentage(sloTarget: updated.availabilitySLO) * 0.4)
            return updated
        }
    }

    private func simulatedIncident(for scenario: SimulationScenario, at date: Date) -> Incident {
        switch scenario {
        case .apiLatencySpike:
            return simulationIncident(
                id: "INC-DEMO-API-LATENCY",
                title: "Demo API latency spike",
                severity: .p2,
                services: ["api-gateway", "orders-service"],
                runbook: "runbook-api-latency",
                impact: "Demo customers experience slow API responses.",
                date: date
            )
        case .databaseSaturation:
            return simulationIncident(
                id: "INC-DEMO-DB-SATURATION",
                title: "Demo database connection exhaustion",
                severity: .p1,
                services: ["postgres-cluster", "orders-service"],
                runbook: "runbook-db-connections",
                impact: "Demo checkout and order reads are delayed by database pressure.",
                date: date
            )
        case .authenticationErrorSpike:
            return simulationIncident(
                id: "INC-DEMO-AUTH-ERRORS",
                title: "Demo authentication error spike",
                severity: .p2,
                services: ["auth-service"],
                runbook: "runbook-auth-failures",
                impact: "Demo users may need to retry sign-in.",
                date: date
            )
        case .failedDeployment:
            return simulationIncident(
                id: "INC-DEMO-FAILED-DEPLOY",
                title: "Demo failed deployment rollback",
                severity: .p2,
                services: ["api-gateway"],
                runbook: "runbook-rollback",
                impact: "Demo release health checks failed after a rollout.",
                date: date
            )
        case .regionalOutage:
            return simulationIncident(
                id: "INC-DEMO-REGIONAL-OUTAGE",
                title: "Demo regional outage",
                severity: .p1,
                services: ["api-gateway", "auth-service", "payments-service", "orders-service"],
                runbook: "runbook-api-latency",
                impact: "Demo traffic in one region is unavailable until traffic is shifted.",
                date: date
            )
        }
    }

    private func simulationIncident(
        id: String,
        title: String,
        severity: IncidentSeverity,
        services: [String],
        runbook: String,
        impact: String,
        date: Date
    ) -> Incident {
        let uniqueID = currentSnapshot.incidents.contains(where: { $0.id == id }) ? "\(id)-\(currentSnapshot.incidents.count + 1)" : id
        return Incident(
            id: uniqueID,
            title: title,
            severity: severity,
            affectedServiceIDs: services,
            status: .triggered,
            commander: nil,
            startedAt: date,
            acknowledgedAt: nil,
            mitigatedAt: nil,
            resolvedAt: nil,
            customerImpact: impact,
            timeline: [
                TimelineEvent(timestamp: date, author: "Reliability Lab", message: "Demo-only simulation generated this incident.")
            ],
            runbookID: runbook,
            relatedDeploymentID: nil,
            contributingFactors: ["Synthetic demo scenario changed service metrics."],
            wentWell: ["The demo workflow provides deterministic incident evidence."],
            improvements: ["Practice commander assignment and runbook execution in demo mode."],
            followUpActions: ["Reset demo data or export the post-incident review."]
        )
    }

    private func degrade(_ service: OpsService, scenario: SimulationScenario, incidentID: String) -> OpsService {
        var updated = service
        updated.status = scenario == .regionalOutage ? .unavailable : .degraded
        updated.currentAvailability = max(0, service.currentAvailability - (scenario == .regionalOutage ? 1.4 : 0.18))
        updated.errorRate += scenario == .authenticationErrorSpike ? 0.22 : 0.08
        updated.p95Latency += scenario == .apiLatencySpike ? 950 : 280
        updated.p99Latency += scenario == .apiLatencySpike ? 1_600 : 500
        updated.saturation = min(100, service.saturation + (scenario == .databaseSaturation ? 34 : 16))
        if !updated.openIncidentIDs.contains(incidentID) {
            updated.openIncidentIDs.append(incidentID)
        }
        let now = dateProvider.now()
        updated.availabilityHistory.append(MetricPoint(id: "sim-availability-\(incidentID)", timestamp: now, value: updated.currentAvailability.rounded(toPlaces: 3)))
        updated.errorRateHistory.append(MetricPoint(id: "sim-error-\(incidentID)", timestamp: now, value: updated.errorRate.rounded(toPlaces: 3)))
        updated.latencyP95History.append(MetricPoint(id: "sim-latency-\(incidentID)", timestamp: now, value: updated.p95Latency.rounded(toPlaces: 3)))
        updated.errorBudgetHistory.append(MetricPoint(id: "sim-budget-\(incidentID)", timestamp: now, value: SLOCalculator.snapshot(for: updated).remainingBudgetRatio.rounded(toPlaces: 3)))
        return updated
    }
}
