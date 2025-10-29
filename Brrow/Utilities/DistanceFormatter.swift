//
//  DistanceFormatter.swift
//  Brrow
//
//  Distance formatting utilities for US units (feet/miles)
//

import Foundation
import CoreLocation

struct DistanceFormatter {

    /// Convert meters to feet
    static func metersToFeet(_ meters: Double) -> Double {
        return meters * 3.28084
    }

    /// Convert meters to miles
    static func metersToMiles(_ meters: Double) -> Double {
        return meters * 0.000621371
    }

    /// Convert feet to meters
    static func feetToMeters(_ feet: Double) -> Double {
        return feet / 3.28084
    }

    /// Convert miles to meters
    static func milesToMeters(_ miles: Double) -> Double {
        return miles / 0.000621371
    }

    /// Format distance in appropriate US units (feet or miles)
    /// - Parameter meters: Distance in meters
    /// - Returns: Formatted string like "150 ft" or "2.3 mi"
    static func formatDistance(_ meters: Double) -> String {
        let miles = metersToMiles(meters)

        if miles < 0.25 {
            // Show in feet if less than quarter mile
            let feet = Int(round(metersToFeet(meters)))
            return "\(feet) ft"
        } else {
            // Show in miles with 1 decimal place
            return String(format: "%.1f mi", miles)
        }
    }

    /// Format distance between two coordinates
    static func formatDistance(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> String {
        let fromLocation = CLLocation(latitude: from.latitude, longitude: from.longitude)
        let toLocation = CLLocation(latitude: to.latitude, longitude: to.longitude)
        let distanceMeters = fromLocation.distance(from: toLocation)
        return formatDistance(distanceMeters)
    }

    /// Check if distance is within threshold
    /// - Parameters:
    ///   - meters: Distance in meters
    ///   - thresholdMiles: Threshold in miles
    /// - Returns: True if within threshold
    static func isWithinDistance(_ meters: Double, thresholdMiles: Double) -> Bool {
        let miles = metersToMiles(meters)
        return miles <= thresholdMiles
    }

    /// Proximity threshold in meters (328 feet / 0.062 miles / ~100 meters)
    static let proximityThresholdMeters: Double = 100.0

    /// Maximum manual override distance in miles
    static let maxManualOverrideMiles: Double = 50.0

    /// Maximum manual override distance in meters
    static let maxManualOverrideMeters: Double = milesToMeters(maxManualOverrideMiles)
}
