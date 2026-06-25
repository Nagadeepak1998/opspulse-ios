import SwiftUI

struct ReliabilityLabView: View {
    @Environment(OpsStore.self) private var store

    var body: some View {
        List {
            Section {
                Label("Demo-only simulation lab", systemImage: "testtube.2")
                    .font(.headline)
                Text("Simulations modify local deterministic fixtures, consume error budget, generate incidents, and let you practice the runbook-to-resolution flow without touching real infrastructure.")
                    .foregroundStyle(.secondary)
            }

            Section("Scenarios") {
                ForEach(SimulationScenario.allCases) { scenario in
                    Button {
                        Task { await store.runSimulation(scenario) }
                    } label: {
                        HStack {
                            Label(scenario.displayName, systemImage: symbol(for: scenario))
                            Spacer()
                            Image(systemName: "play.circle")
                                .foregroundStyle(.secondary)
                        }
                    }
                    .accessibilityIdentifier("simulation-\(scenario.rawValue)")
                }
            }

            Section("Reset") {
                Button(role: .destructive) {
                    Task { await store.resetDemoData() }
                } label: {
                    Label("Restore deterministic demo data", systemImage: "arrow.counterclockwise")
                }
                .accessibilityIdentifier("reset-demo-data")
            }
        }
        .navigationTitle("Reliability Lab")
    }

    private func symbol(for scenario: SimulationScenario) -> String {
        switch scenario {
        case .apiLatencySpike: "speedometer"
        case .databaseSaturation: "cylinder.split.1x2"
        case .authenticationErrorSpike: "person.badge.key"
        case .failedDeployment: "shippingbox.and.arrow.backward"
        case .regionalOutage: "globe.americas"
        }
    }
}
