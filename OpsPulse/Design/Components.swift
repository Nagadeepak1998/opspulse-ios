import SwiftUI

struct MetricCard: View {
    var title: String
    var value: String
    var subtitle: String
    var systemImage: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: systemImage)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title2.weight(.bold))
                .lineLimit(2)
                .minimumScaleFactor(0.75)
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(3)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8))
        .accessibilityElement(children: .combine)
    }
}

struct StatusBadge: View {
    var status: ServiceStatus

    var body: some View {
        Label(status.displayName, systemImage: symbol)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .foregroundStyle(foreground)
            .background(background, in: Capsule())
            .accessibilityLabel("Status \(status.displayName)")
    }

    private var symbol: String {
        switch status {
        case .healthy: "checkmark.circle.fill"
        case .degraded: "exclamationmark.triangle.fill"
        case .unavailable: "xmark.octagon.fill"
        }
    }

    private var foreground: Color {
        switch status {
        case .healthy: .green
        case .degraded: .orange
        case .unavailable: .red
        }
    }

    private var background: Color {
        foreground.opacity(0.14)
    }
}

struct SeverityBadge: View {
    var severity: IncidentSeverity

    var body: some View {
        Label(severity.displayName, systemImage: severity == .p1 ? "flame.fill" : "exclamationmark.circle.fill")
            .font(.caption.weight(.bold))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .foregroundStyle(color)
            .background(color.opacity(0.14), in: Capsule())
            .accessibilityLabel("Severity \(severity.displayName)")
    }

    private var color: Color {
        switch severity {
        case .p1: .red
        case .p2: .orange
        case .p3: .blue
        }
    }
}

struct BurnRateBadge: View {
    var classification: BurnRateClassification

    var body: some View {
        Label(classification.displayName, systemImage: symbol)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .foregroundStyle(color)
            .background(color.opacity(0.14), in: Capsule())
            .accessibilityLabel("Burn rate \(classification.displayName)")
    }

    private var symbol: String {
        switch classification {
        case .normal: "checkmark.seal.fill"
        case .elevated: "arrow.up.forward.circle.fill"
        case .high: "flame.fill"
        case .critical: "exclamationmark.octagon.fill"
        }
    }

    private var color: Color {
        switch classification {
        case .normal: .green
        case .elevated: .yellow
        case .high: .orange
        case .critical: .red
        }
    }
}

struct BannerView: View {
    var message: String

    var body: some View {
        Label(message, systemImage: "info.circle.fill")
            .font(.callout.weight(.semibold))
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
            .shadow(radius: 8)
            .accessibilityAddTraits(.isStaticText)
    }
}

struct EmptyStateView: View {
    var title: String
    var message: String
    var systemImage: String

    var body: some View {
        ContentUnavailableView(title, systemImage: systemImage, description: Text(message))
            .padding()
    }
}
