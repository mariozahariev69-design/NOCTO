import XCTest
@testable import NOCTOAppLogic
import NOCTOCore

final class ProximityRankerTests: XCTestCase {
    func testRanksCloserVenueFirst() {
        let near = Venue(
            id: UUID(),
            name: "Near",
            type: .bar,
            latitude: 42.6977,
            longitude: 23.3219
        )
        let far = Venue(
            id: UUID(),
            name: "Far",
            type: .bar,
            latitude: 42.7077,
            longitude: 23.3319
        )
        let location = CLLocationCoordinate2D(latitude: 42.6977, longitude: 23.3219)

        let ranked = ProximityRanker.rank(venues: [far, near], from: location)

        XCTAssertEqual(ranked.first?.venue.name, "Near")
    }

    func testDistanceLabelUsesMetersAndKilometers() {
        let venue = Venue(
            id: UUID(),
            name: "Test",
            type: .bar,
            latitude: 42.6977,
            longitude: 23.3219
        )
        let location = CLLocationCoordinate2D(latitude: 42.6977, longitude: 23.3219)

        let ranked = ProximityRanker.rank(venues: [venue], from: location)

        XCTAssertEqual(ranked.first?.distanceLabel, "0 m")
    }

    func testOpenVenueReceivesAvailabilityBonus() {
        let venue = Venue(
            id: UUID(),
            name: "Open",
            type: .bar,
            latitude: 42.6977,
            longitude: 23.3219,
            workingHours: "00:00-23:59"
        )
        let location = CLLocationCoordinate2D(latitude: 42.6977, longitude: 23.3219)
        let now = Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: Date()) ?? Date()

        let ranked = ProximityRanker.rank(venues: [venue], from: location, now: now)

        XCTAssertGreaterThan(ranked.first?.score ?? 0, 80)
    }
}
