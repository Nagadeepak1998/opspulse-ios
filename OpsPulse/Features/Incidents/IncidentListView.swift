import SwiftUI

struct IncidentListView: View {
    @Environment(OpsStore.self) private var store

    var body: some View {
        List {
            Section("Active") {
                if store.activeIncidents.isEmpty {
                    Text("No active incidents.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(store.activeIncidents) { incident in
                        NavigationLink(value: incident.id) {
                            IncidentRow(incident: incident)
                        }
                        .accessibilityIdentifier("incident-\(incident.id)")
                    }
                }
            }

            Section("Resolved") {
                ForEach(store.resolvedIncidents) { incident in
                    NavigationLink(value: incident.id) {
                        IncidentRow(incident: incident)
                    }
                }
            }
        }
        .navigationTitle("Incidents")
    }
}

private struct IncidentRow: View {
    var incident: Incident

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text(incident.title)
                    .font(.headline)
                Spacer()
                SeverityBadge(severity: incident.severity)
            }
            Text("\(incident.status.displayName) · Commander: \(incident.commander ?? "Unassigned")")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text("Started \(OpsFormat.date(incident.startedAt))")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
    }
}
