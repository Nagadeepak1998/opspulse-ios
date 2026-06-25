import Foundation

public enum PostIncidentReport {
    public static func markdown(
        incident: Incident,
        services: [OpsService],
        runbook: Runbook?,
        generatedAt: Date = Date()
    ) -> String {
        let formatter = ISO8601DateFormatter()
        let affected = services
            .filter { incident.affectedServiceIDs.contains($0.id) }
            .map(\.name)
            .joined(separator: ", ")
        let durations = IncidentWorkflow.durations(for: incident)
        let timeline = incident.timeline
            .sorted { $0.timestamp < $1.timestamp }
            .map { "- \(formatter.string(from: $0.timestamp)) — \($0.author): \($0.message)" }
            .joined(separator: "\n")

        return """
        # Post-Incident Review: \(incident.title)

        Generated: \(formatter.string(from: generatedAt))

        ## Summary
        - Incident ID: \(incident.id)
        - Severity: \(incident.severity.displayName)
        - Status: \(incident.status.displayName)
        - Incident Commander: \(incident.commander ?? "Unassigned")
        - Affected Services: \(affected.isEmpty ? "Unknown" : affected)
        - Runbook: \(runbook?.title ?? incident.runbookID)

        ## Customer Impact
        \(incident.customerImpact)

        ## Timeline
        \(timeline)

        ## Timing
        - Detection time: \(format(durations.detection))
        - Acknowledgment time: \(format(durations.acknowledgment))
        - Mitigation time: \(format(durations.mitigation))
        - Resolution time: \(format(durations.recovery))
        - MTTA: \(format(durations.acknowledgment))
        - MTTR: \(format(durations.recovery))

        ## Contributing Factors
        \(markdownList(incident.contributingFactors))

        ## What Went Well
        \(markdownList(incident.wentWell))

        ## What Could Be Improved
        \(markdownList(incident.improvements))

        ## Follow-Up Actions
        \(markdownList(incident.followUpActions))

        ## Safety Note
        OpsPulse displays reference commands for education only. It does not execute infrastructure changes.
        """
    }

    public static func format(_ interval: TimeInterval?) -> String {
        guard let interval else { return "Not available" }
        let minutes = Int(interval / 60)
        let seconds = Int(interval.truncatingRemainder(dividingBy: 60))
        if minutes >= 60 {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            return "\(hours)h \(remainingMinutes)m"
        }
        return "\(minutes)m \(seconds)s"
    }

    private static func markdownList(_ items: [String]) -> String {
        if items.isEmpty { return "- Not recorded" }
        return items.map { "- \($0)" }.joined(separator: "\n")
    }
}
