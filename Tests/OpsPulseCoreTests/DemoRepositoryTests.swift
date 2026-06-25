import Testing
@testable import OpsPulseCore

@Suite("Demo repository")
struct DemoRepositoryTests {
    @Test func reliabilityOverviewAggregatesServicesAndIncidents() {
        let snapshot = DemoFixtures.snapshot()

        let overview = DemoOpsRepository.overview(from: snapshot)

        #expect(overview.productionStatus == .degraded)
        #expect(overview.stagingStatus == .healthy)
        #expect(overview.healthyServices == 4)
        #expect(overview.degradedServices == 2)
        #expect(overview.activeP2 == 1)
        #expect(overview.activeP3 == 0)
        #expect(overview.meanTimeToAcknowledge != nil)
        #expect(overview.lastSuccessfulDeployment != nil)
    }

    @Test func simulationGeneratesIncidentAndConsumesBudget() async throws {
        let repository = DemoOpsRepository(dateProvider: FixedDateProvider(DemoClock.minutes(100)))
        let before = await repository.snapshot()
        let beforeService = before.services.first { $0.id == "api-gateway" }!
        let beforeBudget = SLOCalculator.snapshot(for: beforeService).remainingBudgetRatio

        let after = try await repository.runSimulation(.apiLatencySpike)
        let incident = after.incidents.first { $0.id == "INC-DEMO-API-LATENCY" }
        let afterService = after.services.first { $0.id == "api-gateway" }!
        let afterBudget = SLOCalculator.snapshot(for: afterService).remainingBudgetRatio

        #expect(incident?.status == .triggered)
        #expect(afterService.status == .degraded)
        #expect(afterService.openIncidentIDs.contains("INC-DEMO-API-LATENCY"))
        #expect(afterBudget < beforeBudget)
    }

    @Test func resetRestoresDeterministicFixtures() async throws {
        let repository = DemoOpsRepository(dateProvider: FixedDateProvider(DemoClock.minutes(100)))
        _ = try await repository.runSimulation(.regionalOutage)

        let reset = await repository.reset()

        #expect(reset.incidents.first { $0.id == "INC-DEMO-REGIONAL-OUTAGE" } == nil)
        #expect(reset.services.first { $0.id == "api-gateway" }?.status == .degraded)
    }

    @Test func runbookStepCompletionIsPersistedInRepositoryState() async throws {
        let repository = DemoOpsRepository(dateProvider: FixedDateProvider(DemoClock.minutes(100)))
        let runbook = try await repository.completeRunbookStep(
            runbookID: "runbook-api-latency",
            stepID: "step-1-confirm-customer-impact",
            isComplete: true
        )

        #expect(runbook.steps.first?.isComplete == true)
        let snapshot = await repository.snapshot()
        #expect(snapshot.runbooks.first { $0.id == "runbook-api-latency" }?.steps.first?.isComplete == true)
    }
}
