import CoreLocation
import Foundation
import NOCTOCore

struct ProximityRankedVenue: Identifiable {
    let venue: Venue
    let distanceMeters: CLLocationDistance
    let score: Double

    var id: UUID { venue.id }

    var distanceLabel: String {
        if distanceMeters < 1000 {
            return "\(Int(distanceMeters.rounded())) m"
        }
        return String(format: "%.1f km", distanceMeters / 1000)
    }
}

enum ProximityRanker {
    static func rank(
        venues: [Venue],
        from location: CLLocationCoordinate2D,
        now: Date = Date()
    ) -> [ProximityRankedVenue] {
        venues
            .map { venue in
                let distance = distanceMeters(from: location, to: venue)
                return ProximityRankedVenue(
                    venue: venue,
                    distanceMeters: distance,
                    score: score(venue: venue, distanceMeters: distance, now: now)
                )
            }
            .sorted { lhs, rhs in
                if lhs.score == rhs.score {
                    return lhs.venue.name.localizedCaseInsensitiveCompare(rhs.venue.name) == .orderedAscending
                }
                return lhs.score > rhs.score
            }
    }

    private static func distanceMeters(
        from location: CLLocationCoordinate2D,
        to venue: Venue
    ) -> CLLocationDistance {
        let userLocation = CLLocation(latitude: location.latitude, longitude: location.longitude)
        let venueLocation = CLLocation(latitude: venue.latitude, longitude: venue.longitude)
        return userLocation.distance(from: venueLocation)
    }

    private static func score(
        venue: Venue,
        distanceMeters: CLLocationDistance,
        now: Date
    ) -> Double {
        let proximityScore = max(0, 100 - min(distanceMeters / 100, 100))
        let typeScore: Double = venue.type == .club ? 6 : 0
        let availabilityScore = isOpenNow(venue, now: now) ? 10.0 : 0

        return proximityScore * 0.84 + typeScore + availabilityScore
    }

    private static func isOpenNow(_ venue: Venue, now: Date) -> Bool {
        guard
            let opening = Venue.hourMinuteTuple(from: venue.workingHours, at: 0),
            let closing = Venue.hourMinuteTuple(from: venue.workingHours, at: 1)
        else {
            return false
        }

        let components = Calendar.current.dateComponents([.hour, .minute], from: now)
        guard let hour = components.hour, let minute = components.minute else { return false }

        let currentMinutes = hour * 60 + minute
        let openingMinutes = opening.h * 60 + opening.m
        var closingMinutes = closing.h * 60 + closing.m

        if closingMinutes <= openingMinutes {
            closingMinutes += 24 * 60
        }

        var normalizedCurrent = currentMinutes
        if closingMinutes > 24 * 60 && currentMinutes < openingMinutes {
            normalizedCurrent += 24 * 60
        }

        return normalizedCurrent >= openingMinutes && normalizedCurrent <= closingMinutes
    }
}
