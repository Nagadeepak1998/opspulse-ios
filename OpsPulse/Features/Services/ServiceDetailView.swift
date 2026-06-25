import Charts
import SwiftUI

struct ServiceDetailView: View {
    @Environment(OpsStore.self) private var store
    var serviceID: String

    var body: some View {
        if let service = store.service(id: serviceID) {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    ServiceHeader(service: service)
                    SLOStatusPanel(service: service)
                    MetricsCharts(service: service)
                    deployments(service)
                    relatedIncidents(service)
                    runbooks(service)
                    owner(service)
                }
                .padding()
            }
            .navigationTitle(service.name)
            .navigationBarTitleDisplayMode(.inline)
        } else {
            EmptyStateView(title: "Service not found", message: "The selected service is not available in the current snapshot.", systemImage: "server.rack")
        }
    }

    private func deployments(_ service: OpsService) -> some View {
        SectionPanel(title: "Recent Deployment", systemImage: "shippingbox") {
            Text(service.recentDeployment.version)
                .font(.headline)
            Text(service.recentDeployment.summary)
                .foregroundStyle(.secondary)
            Text(OpsFormat.date(service.recentDeployment.deployedAt))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func relatedIncidents(_ service: OpsService) -> some View {
        SectionPanel(title: "Related Incidents", systemImage: "exclamationmark.triangle") {
            let incidents = store.relatedIncidents(for: service.id)
            if incidents.isEmpty {
                Text("No related incidents in the demo dataset.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(incidents) { incident in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(incident.title)
                            .font(.subheadline.weight(.semibold))
                        Text("\(incident.severity.displayName) · \(incident.status.displayName)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Divider()
                }
            }
        }
    }

    private func runbooks(_ service: OpsService) -> some View {
        SectionPanel(title: "Linked Runbooks", systemImage: "checklist") {
            ForEach(service.runbookIDs, id: \.self) { runbookID in
                if let runbook = store.runbook(id: runbookID) {
                    Text(runbook.title)
                    Text("Owner: \(runbook.owner) · Reviewed \(OpsFormat.date(runbook.lastReviewed))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private func owner(_ service: OpsService) -> some View {
        SectionPanel(title: "Owner", systemImage: "person.2") {
            Text(service.ownerContact.team)
                .font(.headline)
            Text("On-call: \(service.ownerContact.primaryOnCall)")
            Text("Escalation: \(service.ownerContact.escalationPolicy)")
            Text(service.ownerContact.slackChannel)
                .foregroundStyle(.secondary)
        }
    }
}

private struct ServiceHeader: View {
    var service: OpsService

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                StatusBadge(status: service.status)
                Text(service.environment.displayName)
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(.secondary.opacity(0.12), in: Capsule())
            }
            Text(service.owner)
                .font(.headline)
                .foregroundStyle(.secondary)
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 145), spacing: 12)], spacing: 12) {
                MetricCard(title: "Availability", value: OpsFormat.percent(service.currentAvailability), subtitle: "SLO \(OpsFormat.percent(service.availabilitySLO, places: 2))", systemImage: "checkmark.seal")
                MetricCard(title: "Error Rate", value: OpsFormat.percent(service.errorRate, places: 3), subtitle: "Current request failures", systemImage: "waveform.path.ecg")
                MetricCard(title: "P95", value: OpsFormat.milliseconds(service.p95Latency), subtitle: "Tail latency", systemImage: "speedometer")
                MetricCard(title: "Saturation", value: OpsFormat.percent(service.saturation, places: 1), subtitle: "Resource pressure", systemImage: "memorychip")
            }
        }
    }
}

private struct SLOStatusPanel: View {
    var service: OpsService

    var body: some View {
        let slo = SLOCalculator.snapshot(for: service)
        SectionPanel(title: "SLO Status", systemImage: "target") {
            HStack {
                BurnRateBadge(classification: slo.classification)
                Spacer()
                Text(OpsFormat.ratio(slo.burnRate))
                    .font(.title3.weight(.bold))
            }
            Text(slo.explanation)
                .foregroundStyle(.secondary)
            Text("Permitted failure: \(OpsFormat.percent(slo.permittedFailurePercentage, places: 3)) · Remaining budget: \(OpsFormat.percent(slo.remainingBudgetRatio * 100, places: 1))")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

private struct MetricsCharts: View {
    var service: OpsService

    var body: some View {
        VStack(spacing: 16) {
            ChartPanel(title: "Availability", points: service.availabilityHistory, suffix: "%")
            ChartPanel(title: "Error Rate", points: service.errorRateHistory, suffix: "%")
            ChartPanel(title: "P95 Latency", points: service.latencyP95History, suffix: "ms")
            ChartPanel(title: "Error Budget", points: service.errorBudgetHistory.map { MetricPoint(id: $0.id, timestamp: $0.timestamp, value: $0.value * 100) }, suffix: "%")
        }
    }
}

private struct ChartPanel: View {
    var title: String
    var points: [MetricPoint]
    var suffix: String

    var body: some View {
        SectionPanel(title: title, systemImage: "chart.xyaxis.line") {
            Chart(points) { point in
                LineMark(
                    x: .value("Time", point.timestamp),
                    y: .value(title, point.value)
                )
                PointMark(
                    x: .value("Time", point.timestamp),
                    y: .value(title, point.value)
                )
            }
            .frame(height: 190)
            .chartXAxis(.hidden)
            .accessibilityLabel("\(title) history chart")
            if let latest = points.last {
                Text("Latest: \(latest.value.rounded(toPlaces: 2))\(suffix)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

struct SectionPanel<Content: View>: View {
    var title: String
    var systemImage: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: systemImage)
                .font(.headline)
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8))
    }
}
