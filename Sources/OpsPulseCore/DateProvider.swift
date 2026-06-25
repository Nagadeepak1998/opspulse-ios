import Foundation

public protocol DateProvider: Sendable {
    func now() -> Date
}

public struct SystemDateProvider: DateProvider {
    public init() {}
    public func now() -> Date { Date() }
}

public struct FixedDateProvider: DateProvider {
    public var date: Date

    public init(_ date: Date) {
        self.date = date
    }

    public func now() -> Date { date }
}

public enum DemoClock {
    public static let base = Date(timeIntervalSince1970: 1_735_689_600) // 2025-01-01 00:00:00 UTC

    public static func minutes(_ minutes: Int) -> Date {
        base.addingTimeInterval(TimeInterval(minutes * 60))
    }
}
