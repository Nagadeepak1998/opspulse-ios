import Foundation
import Testing
@testable import OpsPulseCore

@Suite("Codable fixtures")
struct CodingTests {
    @Test func fixtureSnapshotRoundTripsThroughJSON() throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let snapshot = DemoFixtures.snapshot()
        let data = try encoder.encode(snapshot)
        let decoded = try decoder.decode(OpsPulseSnapshot.self, from: data)

        #expect(decoded.services.count == 6)
        #expect(decoded.incidents.count == 2)
        #expect(decoded.runbooks.count == 5)
        #expect(decoded.services.first?.name == snapshot.services.first?.name)
    }
}
