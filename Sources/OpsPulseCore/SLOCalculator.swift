import Foundation

public struct ErrorBudgetSnapshot: Codable, Equatable, Sendable {
    public var sloTarget: Double
    public var currentAvailability: Double
    public var permittedFailurePercentage: Double
    public var consumedBudgetPercentagePoints: Double
    public var remainingBudgetPercentagePoints: Double
    public var remainingBudgetRatio: Double
    public var burnRate: Double
    public var classification: BurnRateClassification
    public var explanation: String
}

public enum SLOCalculator {
    public static func permittedFailurePercentage(sloTarget: Double) -> Double {
        max(0, 100 - sloTarget)
    }

    public static func consumedBudgetPercentagePoints(sloTarget: Double, currentAvailability: Double) -> Double {
        max(0, sloTarget - currentAvailability)
    }

    public static func remainingBudgetPercentagePoints(sloTarget: Double, currentAvailability: Double) -> Double {
        let permittedFailure = permittedFailurePercentage(sloTarget: sloTarget)
        let consumed = consumedBudgetPercentagePoints(sloTarget: sloTarget, currentAvailability: currentAvailability)
        return max(0, permittedFailure - consumed)
    }

    public static func burnRate(errorRate: Double, sloTarget: Double) -> Double {
        let permittedFailure = permittedFailurePercentage(sloTarget: sloTarget)
        guard permittedFailure > 0 else { return .infinity }
        return errorRate / permittedFailure
    }

    public static func classifyBurnRate(_ burnRate: Double) -> BurnRateClassification {
        switch burnRate {
        case ..<1:
            .normal
        case ..<2:
            .elevated
        case ..<5:
            .high
        default:
            .critical
        }
    }

    public static func snapshot(for service: OpsService) -> ErrorBudgetSnapshot {
        let permitted = permittedFailurePercentage(sloTarget: service.availabilitySLO)
        let consumed = consumedBudgetPercentagePoints(
            sloTarget: service.availabilitySLO,
            currentAvailability: service.currentAvailability
        )
        let remaining = max(0, permitted - consumed)
        let remainingRatio = permitted == 0 ? 0 : remaining / permitted
        let burn = burnRate(errorRate: service.errorRate, sloTarget: service.availabilitySLO)
        let classification = classifyBurnRate(burn)
        let explanation = explanation(
            serviceName: service.name,
            remainingRatio: remainingRatio,
            burnRate: burn,
            classification: classification
        )

        return ErrorBudgetSnapshot(
            sloTarget: service.availabilitySLO,
            currentAvailability: service.currentAvailability,
            permittedFailurePercentage: permitted,
            consumedBudgetPercentagePoints: consumed,
            remainingBudgetPercentagePoints: remaining,
            remainingBudgetRatio: remainingRatio,
            burnRate: burn,
            classification: classification,
            explanation: explanation
        )
    }

    private static func explanation(
        serviceName: String,
        remainingRatio: Double,
        burnRate: Double,
        classification: BurnRateClassification
    ) -> String {
        let remainingPercent = (remainingRatio * 100).rounded(toPlaces: 1)
        let burn = burnRate.rounded(toPlaces: 2)
        switch classification {
        case .normal:
            return "\(serviceName) is within its SLO budget with \(remainingPercent)% remaining and a \(burn)x burn rate."
        case .elevated:
            return "\(serviceName) is consuming budget faster than normal: \(remainingPercent)% remains at a \(burn)x burn rate."
        case .high:
            return "\(serviceName) needs active attention because budget burn is high: \(remainingPercent)% remains at \(burn)x."
        case .critical:
            return "\(serviceName) is at critical SLO risk with \(remainingPercent)% budget remaining and a \(burn)x burn rate."
        }
    }
}

extension Double {
    public func rounded(toPlaces places: Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}
