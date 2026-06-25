import Foundation

public enum ServiceEnvironment: String, Codable, CaseIterable, Sendable {
    case production
    case staging

    public var displayName: String {
        switch self {
        case .production: "Production"
        case .staging: "Staging"
        }
    }
}

public enum ServiceStatus: String, Codable, CaseIterable, Sendable {
    case healthy
    case degraded
    case unavailable

    public var displayName: String {
        switch self {
        case .healthy: "Healthy"
        case .degraded: "Degraded"
        case .unavailable: "Unavailable"
        }
    }
}

public enum IncidentSeverity: String, Codable, CaseIterable, Comparable, Sendable {
    case p1
    case p2
    case p3

    public var displayName: String { rawValue.uppercased() }

    private var rank: Int {
        switch self {
        case .p1: 0
        case .p2: 1
        case .p3: 2
        }
    }

    public static func < (lhs: IncidentSeverity, rhs: IncidentSeverity) -> Bool {
        lhs.rank < rhs.rank
    }
}

public enum IncidentStatus: String, Codable, CaseIterable, Sendable {
    case triggered
    case acknowledged
    case investigating
    case mitigating
    case monitoring
    case resolved

    public var displayName: String {
        switch self {
        case .triggered: "Triggered"
        case .acknowledged: "Acknowledged"
        case .investigating: "Investigating"
        case .mitigating: "Mitigating"
        case .monitoring: "Monitoring"
        case .resolved: "Resolved"
        }
    }

    public var validNextStates: [IncidentStatus] {
        switch self {
        case .triggered: [.acknowledged]
        case .acknowledged: [.investigating]
        case .investigating: [.mitigating]
        case .mitigating: [.monitoring]
        case .monitoring: [.resolved]
        case .resolved: []
        }
    }
}

public enum BurnRateClassification: String, Codable, CaseIterable, Sendable {
    case normal
    case elevated
    case high
    case critical

    public var displayName: String {
        switch self {
        case .normal: "Normal"
        case .elevated: "Elevated"
        case .high: "High"
        case .critical: "Critical"
        }
    }
}

public struct MetricPoint: Codable, Equatable, Identifiable, Sendable {
    public var id: String
    public var timestamp: Date
    public var value: Double

    public init(id: String = UUID().uuidString, timestamp: Date, value: Double) {
        self.id = id
        self.timestamp = timestamp
        self.value = value
    }
}

public struct Deployment: Codable, Equatable, Identifiable, Sendable {
    public var id: String
    public var version: String
    public var environment: ServiceEnvironment
    public var deployedAt: Date
    public var status: String
    public var summary: String

    public init(
        id: String,
        version: String,
        environment: ServiceEnvironment,
        deployedAt: Date,
        status: String,
        summary: String
    ) {
        self.id = id
        self.version = version
        self.environment = environment
        self.deployedAt = deployedAt
        self.status = status
        self.summary = summary
    }
}

public struct RunbookStep: Codable, Equatable, Identifiable, Sendable {
    public var id: String
    public var order: Int
    public var title: String
    public var detail: String
    public var safeCommand: String?
    public var isComplete: Bool

    public init(
        id: String,
        order: Int,
        title: String,
        detail: String,
        safeCommand: String? = nil,
        isComplete: Bool = false
    ) {
        self.id = id
        self.order = order
        self.title = title
        self.detail = detail
        self.safeCommand = safeCommand
        self.isComplete = isComplete
    }
}

public struct Runbook: Codable, Equatable, Identifiable, Sendable {
    public var id: String
    public var title: String
    public var owner: String
    public var lastReviewed: Date
    public var steps: [RunbookStep]

    public init(id: String, title: String, owner: String, lastReviewed: Date, steps: [RunbookStep]) {
        self.id = id
        self.title = title
        self.owner = owner
        self.lastReviewed = lastReviewed
        self.steps = steps
    }
}

public struct TimelineEvent: Codable, Equatable, Identifiable, Sendable {
    public var id: String
    public var timestamp: Date
    public var author: String
    public var message: String

    public init(id: String = UUID().uuidString, timestamp: Date, author: String, message: String) {
        self.id = id
        self.timestamp = timestamp
        self.author = author
        self.message = message
    }
}

public struct TeamContact: Codable, Equatable, Sendable {
    public var team: String
    public var slackChannel: String
    public var escalationPolicy: String
    public var primaryOnCall: String

    public init(team: String, slackChannel: String, escalationPolicy: String, primaryOnCall: String) {
        self.team = team
        self.slackChannel = slackChannel
        self.escalationPolicy = escalationPolicy
        self.primaryOnCall = primaryOnCall
    }
}

public struct OpsService: Codable, Equatable, Identifiable, Sendable {
    public var id: String
    public var name: String
    public var owner: String
    public var environment: ServiceEnvironment
    public var status: ServiceStatus
    public var availabilitySLO: Double
    public var currentAvailability: Double
    public var errorRate: Double
    public var p50Latency: Double
    public var p95Latency: Double
    public var p99Latency: Double
    public var saturation: Double
    public var recentDeployment: Deployment
    public var openIncidentIDs: [String]
    public var runbookIDs: [String]
    public var availabilityHistory: [MetricPoint]
    public var errorRateHistory: [MetricPoint]
    public var latencyP95History: [MetricPoint]
    public var errorBudgetHistory: [MetricPoint]
    public var ownerContact: TeamContact

    public init(
        id: String,
        name: String,
        owner: String,
        environment: ServiceEnvironment,
        status: ServiceStatus,
        availabilitySLO: Double,
        currentAvailability: Double,
        errorRate: Double,
        p50Latency: Double,
        p95Latency: Double,
        p99Latency: Double,
        saturation: Double,
        recentDeployment: Deployment,
        openIncidentIDs: [String],
        runbookIDs: [String],
        availabilityHistory: [MetricPoint],
        errorRateHistory: [MetricPoint],
        latencyP95History: [MetricPoint],
        errorBudgetHistory: [MetricPoint],
        ownerContact: TeamContact
    ) {
        self.id = id
        self.name = name
        self.owner = owner
        self.environment = environment
        self.status = status
        self.availabilitySLO = availabilitySLO
        self.currentAvailability = currentAvailability
        self.errorRate = errorRate
        self.p50Latency = p50Latency
        self.p95Latency = p95Latency
        self.p99Latency = p99Latency
        self.saturation = saturation
        self.recentDeployment = recentDeployment
        self.openIncidentIDs = openIncidentIDs
        self.runbookIDs = runbookIDs
        self.availabilityHistory = availabilityHistory
        self.errorRateHistory = errorRateHistory
        self.latencyP95History = latencyP95History
        self.errorBudgetHistory = errorBudgetHistory
        self.ownerContact = ownerContact
    }
}

public struct Incident: Codable, Equatable, Identifiable, Sendable {
    public var id: String
    public var title: String
    public var severity: IncidentSeverity
    public var affectedServiceIDs: [String]
    public var status: IncidentStatus
    public var commander: String?
    public var startedAt: Date
    public var acknowledgedAt: Date?
    public var mitigatedAt: Date?
    public var resolvedAt: Date?
    public var customerImpact: String
    public var timeline: [TimelineEvent]
    public var runbookID: String
    public var relatedDeploymentID: String?
    public var contributingFactors: [String]
    public var wentWell: [String]
    public var improvements: [String]
    public var followUpActions: [String]

    public init(
        id: String,
        title: String,
        severity: IncidentSeverity,
        affectedServiceIDs: [String],
        status: IncidentStatus,
        commander: String?,
        startedAt: Date,
        acknowledgedAt: Date?,
        mitigatedAt: Date?,
        resolvedAt: Date?,
        customerImpact: String,
        timeline: [TimelineEvent],
        runbookID: String,
        relatedDeploymentID: String?,
        contributingFactors: [String] = [],
        wentWell: [String] = [],
        improvements: [String] = [],
        followUpActions: [String] = []
    ) {
        self.id = id
        self.title = title
        self.severity = severity
        self.affectedServiceIDs = affectedServiceIDs
        self.status = status
        self.commander = commander
        self.startedAt = startedAt
        self.acknowledgedAt = acknowledgedAt
        self.mitigatedAt = mitigatedAt
        self.resolvedAt = resolvedAt
        self.customerImpact = customerImpact
        self.timeline = timeline
        self.runbookID = runbookID
        self.relatedDeploymentID = relatedDeploymentID
        self.contributingFactors = contributingFactors
        self.wentWell = wentWell
        self.improvements = improvements
        self.followUpActions = followUpActions
    }
}

public struct IncidentDurations: Codable, Equatable, Sendable {
    public var detection: TimeInterval
    public var acknowledgment: TimeInterval?
    public var mitigation: TimeInterval?
    public var recovery: TimeInterval?

    public init(detection: TimeInterval, acknowledgment: TimeInterval?, mitigation: TimeInterval?, recovery: TimeInterval?) {
        self.detection = detection
        self.acknowledgment = acknowledgment
        self.mitigation = mitigation
        self.recovery = recovery
    }
}

public struct ReliabilityOverview: Codable, Equatable, Sendable {
    public var productionStatus: ServiceStatus
    public var stagingStatus: ServiceStatus
    public var healthyServices: Int
    public var degradedServices: Int
    public var unavailableServices: Int
    public var activeP1: Int
    public var activeP2: Int
    public var activeP3: Int
    public var overallAvailability: Double
    public var errorBudgetRemaining: Double
    public var burnRate: Double
    public var meanTimeToAcknowledge: TimeInterval?
    public var meanTimeToRecovery: TimeInterval?
    public var lastSuccessfulDeployment: Deployment?
}

public enum SimulationScenario: String, Codable, CaseIterable, Identifiable, Sendable {
    case apiLatencySpike
    case databaseSaturation
    case authenticationErrorSpike
    case failedDeployment
    case regionalOutage

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .apiLatencySpike: "API latency spike"
        case .databaseSaturation: "Database saturation"
        case .authenticationErrorSpike: "Authentication error spike"
        case .failedDeployment: "Failed deployment"
        case .regionalOutage: "Regional outage"
        }
    }
}

public struct OpsPulseSnapshot: Codable, Equatable, Sendable {
    public var services: [OpsService]
    public var incidents: [Incident]
    public var runbooks: [Runbook]

    public init(services: [OpsService], incidents: [Incident], runbooks: [Runbook]) {
        self.services = services
        self.incidents = incidents
        self.runbooks = runbooks
    }
}
