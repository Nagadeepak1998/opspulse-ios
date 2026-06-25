import SwiftUI

struct ServiceCatalogView: View {
    @Environment(OpsStore.self) private var store
    @State private var searchText = ""

    var body: some View {
        List(filteredServices) { service in
            NavigationLink(value: service.id) {
                ServiceRow(service: service)
            }
            .accessibilityIdentifier("service-\(service.id)")
        }
        .overlay {
            if filteredServices.isEmpty {
                EmptyStateView(title: "No services", message: "Try a different search term.", systemImage: "magnifyingglass")
            }
        }
        .navigationTitle("Services")
        .searchable(text: $searchText, prompt: "Search services or owners")
    }

    private var filteredServices: [OpsService] {
        guard !searchText.isEmpty else { return store.snapshot.services }
        return store.snapshot.services.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.owner.localizedCaseInsensitiveContains(searchText) ||
            $0.environment.displayName.localizedCaseInsensitiveContains(searchText)
        }
    }
}

private struct ServiceRow: View {
    var service: OpsService

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text(service.name)
                    .font(.headline)
                Spacer()
                StatusBadge(status: service.status)
            }
            Text("\(service.owner) · \(service.environment.displayName)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            let slo = SLOCalculator.snapshot(for: service)
            HStack {
                Label(OpsFormat.percent(service.currentAvailability), systemImage: "checkmark.seal")
                Label(OpsFormat.ratio(slo.burnRate), systemImage: "flame")
                Label("\(service.openIncidentIDs.count) open", systemImage: "exclamationmark.triangle")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
    }
}
