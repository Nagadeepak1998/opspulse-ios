import Foundation

public enum IncidentWorkflowError: Error, Equatable, LocalizedError, Sendable {
    case invalidTransition(from: IncidentStatus, to: IncidentStatus)
    case incidentAlreadyResolved
    case commanderRequired

    public var errorDescription: String? {
        switch self {
        case let .invalidTransition(from, to):
            "Cannot transition incident from \(from.displayName) to \(to.displayName)."
        case .incidentAlreadyResolved:
            "Resolved incidents cannot be changed."
        case .commanderRequired:
            "Assign an incident commander before moving into investigation."
        }
    }
}

public enum IncidentWorkflow {
    public static func acknowledge(_ incident: Incident, at date: Date, by commander: String?) throws -> Incident {
        var updated = try transition(incident, to: .acknowledged, at: date)
        if let commander, !commander.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            updated.commander = commander
        }
        updated.timeline.append(TimelineEvent(timestamp: date, author: "OpsPulse", message: "Incident acknowledged."))
        return updated
    }

    public static func transition(_ incident: Incident, to nextStatus: IncidentStatus, at date: Date) throws -> Incident {
        guard incident.status != .resolved else { throw IncidentWorkflowError.incidentAlreadyResolved }
        guard incident.status.validNextStates.contains(nextStatus) else {
            throw IncidentWorkflowError.invalidTransition(from: incident.status, to: nextStatus)
        }
        if nextStatus == .investigating, incident.commander?.isEmpty ?? true {
            throw IncidentWorkflowError.commanderRequired
        }

        var updated = incident
        updated.status = nextStatus
        switch nextStatus {
        case .acknowledged:
            updated.acknowledgedAt = updated.acknowledgedAt ?? date
        case .mitigating:
            updated.mitigatedAt = updated.mitigatedAt ?? date
        case .resolved:
            updated.resolvedAt = updated.resolvedAt ?? date
        case .triggered, .investigating, .monitoring:
            break
        }
        updated.timeline.append(TimelineEvent(timestamp: date, author: "OpsPulse", message: "Status changed to \(nextStatus.displayName)."))
        return updated
    }

    public static func addTimelineNote(_ note: String, author: String, at date: Date, to incident: Incident) -> Incident {
        var updated = incident
        updated.timeline.append(TimelineEvent(timestamp: date, author: author, message: note))
        return updated
    }

    public static func assignCommander(_ commander: String, at date: Date, to incident: Incident) -> Incident {
        var updated = incident
        updated.commander = commander
        updated.timeline.append(TimelineEvent(timestamp: date, author: "OpsPulse", message: "\(commander) assigned as incident commander."))
        return updated
    }

    public static func durations(for incident: Incident, detectedAt: Date? = nil) -> IncidentDurations {
        let detectionAnchor = detectedAt ?? incident.startedAt
        let acknowledgment = incident.acknowledgedAt.map { $0.timeIntervalSince(incident.startedAt) }
        let mitigation = incident.mitigatedAt.map { $0.timeIntervalSince(incident.startedAt) }
        let recovery = incident.resolvedAt.map { $0.timeIntervalSince(incident.startedAt) }
        return IncidentDurations(
            detection: incident.startedAt.timeIntervalSince(detectionAnchor),
            acknowledgment: acknowledgment,
            mitigation: mitigation,
            recovery: recovery
        )
    }
}
