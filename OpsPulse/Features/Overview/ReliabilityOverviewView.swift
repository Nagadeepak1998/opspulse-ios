import SwiftUI

struct ReliabilityOverviewView: View {
    @Environment(OpsStore.self) private var store

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                environmentStatus
                metricsGrid
                activeIncidentSummary
                serviceHealthSummary
            }
            .padding()
        }
        .navigationTitle("OpsPulse")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Task { await store.refresh() }
                } label: {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
                .accessibilityLabel("Refresh reliability overview")
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Mobile SRE Incident Commander")
                .font(.title2.weight(.bold))
            Text("Demo mode is deterministic and offline. Live mode is available from Settings when an API endpoint exists.")
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var environmentStatus: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Production")
                    .font(.headline)
                StatusBadge(status: store.overview.productionStatus)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            VStack(alignment: .leading, spacing: 8) {
                Text("Staging")
                    .font(.headline)
                StatusBadge(status: store.overview.stagingStatus)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var metricsGrid: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 155), spacing: 12)], spacing: 12) {
            MetricCard(title: "Availability", value: OpsFormat.percent(store.overview.overallAvailability), subtitle: "Average across tracked services", systemImage: "checkmark.seal")
            MetricCard(title: "Budget Remaining", value: OpsFormat.percent(store.overview.errorBudgetRemaining * 100, places: 1), subtitle: "Average remaining SLO budget", systemImage: "battery.75percent")
            MetricCard(title: "Burn Rate", value: OpsFormat.ratio(store.overview.burnRate), subtitle: "Average current consumption", systemImage: "flame")
            MetricCard(title: "MTTA", value: OpsFormat.duration(store.overview.meanTimeToAcknowledge), subtitle: "Mean time to acknowledge", systemImage: "timer")
            MetricCard(title: "MTTR", value: OpsFormat.duration(store.overview.meanTimeToRecovery), subtitle: "Mean time to recovery", systemImage: "wrench.and.screwdriver")
            MetricCard(title: "Last Deploy", value: store.overview.lastSuccessfulDeployment?.version ?? "None", subtitle: store.overview.lastSuccessfulDeployment.map { OpsFormat.date($0.deployedAt) } ?? "No successful deploy", systemImage: "shippingbox")
        }
    }

    private var activeIncidentSummary: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Active Incidents")
                .font(.headline)
            HStack {
                MetricCard(title: "P1", value: "\(store.overview.activeP1)", subtitle: "Critical", systemImage: "flame.fill")
                MetricCard(title: "P2", value: "\(store.overview.activeP2)", subtitle: "Major", systemImage: "exclamationmark.triangle")
                MetricCard(title: "P3", value: "\(store.overview.activeP3)", subtitle: "Minor", systemImage: "info.circle")
            }
        }
    }

    private var serviceHealthSummary: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Service Health")
                .font(.headline)
            HStack {
                MetricCard(title: "Healthy", value: "\(store.overview.healthyServices)", subtitle: "No current action", systemImage: "checkmark.circle")
                MetricCard(title: "Degraded", value: "\(store.overview.degradedServices)", subtitle: "Needs attention", systemImage: "exclamationmark.triangle")
                MetricCard(title: "Unavailable", value: "\(store.overview.unavailableServices)", subtitle: "Customer impact likely", systemImage: "xmark.octagon")
            }
        }
    }
}
