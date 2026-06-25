import SwiftUI

struct IncidentDetailView: View {
    @Environment(OpsStore.self) private var store
    var incidentID: String
    @State private var commander = ""
    @State private var timelineNote = ""

    var body: some View {
        if let incident = store.incident(id: incidentID) {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    summary(incident)
                    commanderPanel(incident)
                    transitionPanel(incident)
                    timingPanel(incident)
                    if let runbook = store.runbook(id: incident.runbookID) {
                        RunbookChecklistView(runbook: runbook)
                    }
                    timelinePanel(incident)
                    reportPanel(incident)
                }
                .padding()
            }
            .navigationTitle(incident.id)
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                commander = incident.commander ?? ""
            }
        } else {
            EmptyStateView(title: "Incident not found", message: "The selected incident is not available in the current snapshot.", systemImage: "exclamationmark.triangle")
        }
    }

    private func summary(_ incident: Incident) -> some View {
        SectionPanel(title: incident.title, systemImage: "exclamationmark.triangle") {
            HStack {
                SeverityBadge(severity: incident.severity)
                Text(incident.status.displayName)
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(.secondary.opacity(0.12), in: Capsule())
            }
            Text(incident.customerImpact)
                .foregroundStyle(.secondary)
            let serviceNames = store.snapshot.services
                .filter { incident.affectedServiceIDs.contains($0.id) }
                .map(\.name)
                .joined(separator: ", ")
            Text("Affected: \(serviceNames)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func commanderPanel(_ incident: Incident) -> some View {
        SectionPanel(title: "Incident Commander", systemImage: "person.crop.circle.badge.checkmark") {
            TextField("Commander name", text: $commander)
                .textFieldStyle(.roundedBorder)
                .accessibilityLabel("Incident commander")
            HStack {
                Button {
                    Task { await store.assignCommander(commander, incidentID: incident.id) }
                } label: {
                    Label("Assign", systemImage: "person.badge.plus")
                }
                .buttonStyle(.bordered)
                .disabled(commander.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || incident.status == .resolved)

                if incident.status == .triggered {
                    Button {
                        Task { await store.acknowledgeIncident(incident.id, commander: commander) }
                    } label: {
                        Label("Acknowledge", systemImage: "checkmark.circle")
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(commander.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .accessibilityIdentifier("acknowledge-incident")
                }
            }
        }
    }

    private func transitionPanel(_ incident: Incident) -> some View {
        SectionPanel(title: "State Transition", systemImage: "arrow.triangle.branch") {
            if incident.status.validNextStates.isEmpty {
                Text("Incident is resolved.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(incident.status.validNextStates, id: \.self) { status in
                    Button {
                        Task { await store.transitionIncident(incident.id, to: status) }
                    } label: {
                        Label("Move to \(status.displayName)", systemImage: "arrow.right.circle")
                    }
                    .buttonStyle(.borderedProminent)
                    .accessibilityIdentifier("transition-\(status.rawValue)")
                }
                Text("Invalid transitions are blocked by the domain workflow.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func timingPanel(_ incident: Incident) -> some View {
        let durations = IncidentWorkflow.durations(for: incident)
        return SectionPanel(title: "Timing", systemImage: "timer") {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), spacing: 12)], spacing: 12) {
                MetricCard(title: "Ack", value: OpsFormat.duration(durations.acknowledgment), subtitle: "Acknowledgment", systemImage: "hand.raised")
                MetricCard(title: "Mitigation", value: OpsFormat.duration(durations.mitigation), subtitle: "First mitigation", systemImage: "wrench")
                MetricCard(title: "Recovery", value: OpsFormat.duration(durations.recovery), subtitle: "MTTR", systemImage: "checkmark.seal")
            }
        }
    }

    private func timelinePanel(_ incident: Incident) -> some View {
        SectionPanel(title: "Timeline", systemImage: "clock.arrow.circlepath") {
            TextField("Add timeline note", text: $timelineNote, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(2...4)
            Button {
                let note = timelineNote
                timelineNote = ""
                Task { await store.addTimelineNote(note, author: commander.isEmpty ? "Demo User" : commander, incidentID: incident.id) }
            } label: {
                Label("Add Note", systemImage: "plus.message")
            }
            .buttonStyle(.bordered)
            .disabled(timelineNote.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || incident.status == .resolved)

            ForEach(incident.timeline.sorted { $0.timestamp > $1.timestamp }) { event in
                VStack(alignment: .leading, spacing: 4) {
                    Text(event.message)
                        .font(.subheadline)
                    Text("\(event.author) · \(OpsFormat.date(event.timestamp))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Divider()
            }
        }
    }

    private func reportPanel(_ incident: Incident) -> some View {
        let markdown = PostIncidentReport.markdown(
            incident: incident,
            services: store.snapshot.services,
            runbook: store.runbook(id: incident.runbookID)
        )
        return SectionPanel(title: "Post-Incident Review", systemImage: "doc.text") {
            Text("Generate a Markdown report after or during resolution. The report is shared through the standard iOS share sheet.")
                .foregroundStyle(.secondary)
            ShareLink(item: markdown) {
                Label("Share Markdown", systemImage: "square.and.arrow.up")
            }
            .buttonStyle(.borderedProminent)
            Text(markdown)
                .font(.caption.monospaced())
                .foregroundStyle(.secondary)
                .lineLimit(10)
                .textSelection(.enabled)
        }
    }
}
