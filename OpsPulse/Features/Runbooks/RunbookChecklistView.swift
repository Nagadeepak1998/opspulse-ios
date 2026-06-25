import SwiftUI

struct RunbookChecklistView: View {
    @Environment(OpsStore.self) private var store
    var runbook: Runbook

    var body: some View {
        SectionPanel(title: runbook.title, systemImage: "checklist.checked") {
            Text("Owner: \(runbook.owner) · Last reviewed \(OpsFormat.date(runbook.lastReviewed))")
                .font(.caption)
                .foregroundStyle(.secondary)

            ForEach(runbook.steps.sorted { $0.order < $1.order }) { step in
                HStack(alignment: .top, spacing: 12) {
                    Button {
                        Task {
                            await store.completeRunbookStep(
                                runbookID: runbook.id,
                                stepID: step.id,
                                isComplete: !step.isComplete
                            )
                        }
                    } label: {
                        Image(systemName: step.isComplete ? "checkmark.square.fill" : "square")
                            .font(.title3)
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("runbook-step-\(step.id)")
                    .accessibilityLabel(step.isComplete ? "Mark step incomplete" : "Mark step complete")

                    VStack(alignment: .leading, spacing: 5) {
                        Text("\(step.order). \(step.title)")
                            .font(.subheadline.weight(.semibold))
                        Text(step.detail)
                            .foregroundStyle(.secondary)
                        if let command = step.safeCommand {
                            Text(command)
                                .font(.caption.monospaced())
                                .textSelection(.enabled)
                                .padding(8)
                                .background(.secondary.opacity(0.10), in: RoundedRectangle(cornerRadius: 6))
                                .accessibilityLabel("Reference command \(command)")
                        }
                    }
                }
                Divider()
            }

            Text("Reference commands are displayed for education only. OpsPulse never executes infrastructure commands.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
