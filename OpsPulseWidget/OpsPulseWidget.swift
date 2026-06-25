import SwiftUI
import WidgetKit

struct OpsPulseWidgetEntry: TimelineEntry {
    let date: Date
    let activeIncidents: Int
    let criticalServices: Int
    let headline: String
}

struct OpsPulseWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> OpsPulseWidgetEntry {
        OpsPulseWidgetEntry(date: .now, activeIncidents: 1, criticalServices: 2, headline: "OpsPulse demo")
    }

    func getSnapshot(in context: Context, completion: @escaping (OpsPulseWidgetEntry) -> Void) {
        completion(OpsPulseWidgetEntry(date: .now, activeIncidents: 1, criticalServices: 2, headline: "1 active P2"))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<OpsPulseWidgetEntry>) -> Void) {
        let entry = OpsPulseWidgetEntry(date: .now, activeIncidents: 1, criticalServices: 2, headline: "Demo incident queue")
        completion(Timeline(entries: [entry], policy: .after(.now.addingTimeInterval(900))))
    }
}

struct OpsPulseWidgetView: View {
    var entry: OpsPulseWidgetEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("OpsPulse", systemImage: "gauge.with.dots.needle.67percent")
                .font(.headline)
            Text(entry.headline)
                .font(.subheadline.weight(.semibold))
            HStack {
                Label("\(entry.activeIncidents)", systemImage: "exclamationmark.triangle")
                Label("\(entry.criticalServices)", systemImage: "flame")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            Spacer()
            Text("Tap for incidents")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .containerBackground(.background, for: .widget)
        .widgetURL(URL(string: "opspulse://incidents"))
        .accessibilityElement(children: .combine)
    }
}

@main
struct OpsPulseWidgetBundle: WidgetBundle {
    var body: some Widget {
        OpsPulseIncidentWidget()
    }
}

struct OpsPulseIncidentWidget: Widget {
    let kind = "OpsPulseWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: OpsPulseWidgetProvider()) { entry in
            OpsPulseWidgetView(entry: entry)
        }
        .configurationDisplayName("OpsPulse Incidents")
        .description("Shows active incident and critical service counts.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
