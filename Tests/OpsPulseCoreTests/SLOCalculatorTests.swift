import Testing
@testable import OpsPulseCore

@Suite("SLO calculator")
struct SLOCalculatorTests {
    @Test func errorBudgetMathIsDerivedFromServiceMetrics() {
        let service = DemoFixtures.services().first { $0.id == "api-gateway" }!

        let snapshot = SLOCalculator.snapshot(for: service)

        #expect(abs(snapshot.permittedFailurePercentage - 0.1) < 0.0001)
        #expect(abs(snapshot.consumedBudgetPercentagePoints - 0.04) < 0.0001)
        #expect(abs(snapshot.remainingBudgetPercentagePoints - 0.06) < 0.0001)
        #expect(abs(snapshot.remainingBudgetRatio - 0.6) < 0.0001)
        #expect(abs(snapshot.burnRate - 0.8) < 0.0001)
        #expect(snapshot.classification == .normal)
        #expect(snapshot.explanation.contains("API Gateway"))
    }

    @Test func burnRateClassificationBoundaries() {
        #expect(SLOCalculator.classifyBurnRate(0.99) == .normal)
        #expect(SLOCalculator.classifyBurnRate(1.0) == .elevated)
        #expect(SLOCalculator.classifyBurnRate(2.0) == .high)
        #expect(SLOCalculator.classifyBurnRate(5.0) == .critical)
    }
}
