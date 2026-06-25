import Foundation

enum OpsFormat {
    static func percent(_ value: Double, places: Int = 2) -> String {
        "\(value.rounded(toPlaces: places))%"
    }

    static func ratio(_ value: Double) -> String {
        "\(value.rounded(toPlaces: 2))x"
    }

    static func milliseconds(_ value: Double) -> String {
        "\(Int(value.rounded())) ms"
    }

    static func duration(_ interval: TimeInterval?) -> String {
        PostIncidentReport.format(interval)
    }

    static func date(_ date: Date) -> String {
        date.formatted(date: .abbreviated, time: .shortened)
    }
}
