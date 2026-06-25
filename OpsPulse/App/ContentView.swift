import SwiftUI

enum AppTab: String, CaseIterable, Identifiable {
    case overview
    case services
    case incidents
    case lab
    case settings

    var id: String { rawValue }

    var title: String {
        switch self {
        case .overview: "Overview"
        case .services: "Services"
        case .incidents: "Incidents"
        case .lab: "Lab"
        case .settings: "Settings"
        }
    }

    var symbol: String {
        switch self {
        case .overview: "gauge.with.dots.needle.67percent"
        case .services: "server.rack"
        case .incidents: "exclamationmark.triangle"
        case .lab: "testtube.2"
        case .settings: "gearshape"
        }
    }
}

struct ContentView: View {
    @Environment(OpsStore.self) private var store

    var body: some View {
        @Bindable var store = store

        TabView(selection: $store.selectedTab) {
            NavigationStack {
                ReliabilityOverviewView()
            }
            .tabItem { Label(AppTab.overview.title, systemImage: AppTab.overview.symbol) }
            .tag(AppTab.overview)

            NavigationStack(path: $store.servicePath) {
                ServiceCatalogView()
                    .navigationDestination(for: String.self) { serviceID in
                        ServiceDetailView(serviceID: serviceID)
                    }
            }
            .tabItem { Label(AppTab.services.title, systemImage: AppTab.services.symbol) }
            .tag(AppTab.services)

            NavigationStack(path: $store.incidentPath) {
                IncidentListView()
                    .navigationDestination(for: String.self) { incidentID in
                        IncidentDetailView(incidentID: incidentID)
                    }
            }
            .tabItem { Label(AppTab.incidents.title, systemImage: AppTab.incidents.symbol) }
            .tag(AppTab.incidents)

            NavigationStack {
                ReliabilityLabView()
            }
            .tabItem { Label(AppTab.lab.title, systemImage: AppTab.lab.symbol) }
            .tag(AppTab.lab)

            NavigationStack {
                SettingsView()
            }
            .tabItem { Label(AppTab.settings.title, systemImage: AppTab.settings.symbol) }
            .tag(AppTab.settings)
        }
        .overlay(alignment: .top) {
            if let message = store.bannerMessage {
                BannerView(message: message)
                    .padding()
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }
}
