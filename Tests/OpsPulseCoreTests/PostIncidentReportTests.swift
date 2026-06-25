import Testing
@testable import OpsPulseCore

@Suite("Post-incident report")
struct PostIncidentReportTests {
    @Test func markdownReportContainsTimingImpactAndFollowUpSections() {
        let snapshot = DemoFixtures.snapshot()
        let incident = snapshot.incidents.first { $0.id == "INC-2025-0005" }!
        let runbook = snapshot.runbooks.first { $0.id == incident.runbookID }

        let markdown = PostIncidentReport.markdown(
            incident: incident,
            services: snapshot.services,
            runbook: runbook,
            generatedAt: DemoClock.minutes(0)
        )

        #expect(markdown.contains("# Post-Incident Review: Authentication retries elevated after token cache miss"))
        #expect(markdown.contains("## Customer Impact"))
        #expect(markdown.contains("- MTTA: 6m 0s"))
        #expect(markdown.contains("- MTTR: 39m 0s"))
        #expect(markdown.contains("## Follow-Up Actions"))
        #expect(markdown.contains("does not execute infrastructure changes"))
    }
}
