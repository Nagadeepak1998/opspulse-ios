import Testing
@testable import OpsPulseCore

@Suite("Incident workflow")
struct IncidentWorkflowTests {
    @Test func validIncidentTransitionsAndDurations() throws {
        var incident = Incident(
            id: "INC-TEST",
            title: "Test incident",
            severity: .p1,
            affectedServiceIDs: ["api-gateway"],
            status: .triggered,
            commander: nil,
            startedAt: DemoClock.minutes(0),
            acknowledgedAt: nil,
            mitigatedAt: nil,
            resolvedAt: nil,
            customerImpact: "Test impact",
            timeline: [],
            runbookID: "runbook-api-latency",
            relatedDeploymentID: nil
        )

        incident = try IncidentWorkflow.acknowledge(incident, at: DemoClock.minutes(5), by: "Naga")
        incident = IncidentWorkflow.assignCommander("Naga", at: DemoClock.minutes(6), to: incident)
        incident = try IncidentWorkflow.transition(incident, to: .investigating, at: DemoClock.minutes(10))
        incident = try IncidentWorkflow.transition(incident, to: .mitigating, at: DemoClock.minutes(19))
        incident = try IncidentWorkflow.transition(incident, to: .monitoring, at: DemoClock.minutes(31))
        incident = try IncidentWorkflow.transition(incident, to: .resolved, at: DemoClock.minutes(45))

        let durations = IncidentWorkflow.durations(for: incident)
        #expect(incident.status == .resolved)
        #expect(durations.acknowledgment == 300)
        #expect(durations.mitigation == 1_140)
        #expect(durations.recovery == 2_700)
    }

    @Test func invalidTransitionIsRejected() {
        let incident = DemoFixtures.incidents().first { $0.id == "INC-2025-0007" }!

        #expect(throws: IncidentWorkflowError.invalidTransition(from: .investigating, to: .resolved)) {
            try IncidentWorkflow.transition(incident, to: .resolved, at: DemoClock.minutes(0))
        }
    }

    @Test func commanderIsRequiredBeforeInvestigation() throws {
        let triggered = DemoFixtures.incidents().first { $0.id == "INC-2025-0007" }!
        var incident = triggered
        incident.status = .acknowledged
        incident.commander = nil

        #expect(throws: IncidentWorkflowError.commanderRequired) {
            try IncidentWorkflow.transition(incident, to: .investigating, at: DemoClock.minutes(0))
        }
    }
}
