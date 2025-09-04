//
//  Location.swift
//  Brrow
//
//  Created by Shalin Ratna on 7/16/25.
//

import Foundation
import CoreLocation

// MARK: - Location Model (Codable for API)
struct Location: Codable {
    let address: String
    let city: String
    let state: String
    let zipCode: String
    let country: String
    let latitude: Double
    let longitude: Double
    
    enum CodingKeys: String, CodingKey {
        case address, city, state, country, latitude, longitude
        case zipCode = "zip_code"
    }
    
    // Regular initializer
    init(address: String, city: String, state: String, zipCode: String, country: String, latitude: Double, longitude: Double) {
        self.address = address
        self.city = city
        self.state = state
        self.zipCode = zipCode
        self.country = country
        self.latitude = round(latitude * 1000000) / 1000000
        self.longitude = round(longitude * 1000000) / 1000000
    }
    
    // Custom decoder to handle coordinate precision issues
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        address = try container.decodeIfPresent(String.self, forKey: .address) ?? ""
        city = try container.decodeIfPresent(String.self, forKey: .city) ?? ""
        state = try container.decodeIfPresent(String.self, forKey: .state) ?? ""
        zipCode = try container.decodeIfPresent(String.self, forKey: .zipCode) ?? ""
        country = try container.decodeIfPresent(String.self, forKey: .country) ?? "US"
        
        // Handle latitude with precision rounding
        let latValue = try container.decode(Double.self, forKey: .latitude)
        latitude = round(latValue * 1000000) / 1000000  // Round to 6 decimal places
        
        // Handle longitude with precision rounding  
        let lonValue = try container.decode(Double.self, forKey: .longitude)
        longitude = round(lonValue * 1000000) / 1000000  // Round to 6 decimal places
    }
    
    // Custom encoder
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(address, forKey: .address)
        try container.encode(city, forKey: .city)
        try container.encode(state, forKey: .state)
        try container.encode(zipCode, forKey: .zipCode)
        try container.encode(country, forKey: .country)
        try container.encode(round(latitude * 1000000) / 1000000, forKey: .latitude)
        try container.encode(round(longitude * 1000000) / 1000000, forKey: .longitude)
    }
    
    // Helper method to create CLLocation
    func toCLLocation() -> CLLocation {
        return CLLocation(latitude: latitude, longitude: longitude)
    }
    
    // Helper method to calculate distance from another location
    func distance(from location: Location) -> Double {
        let from = CLLocation(latitude: latitude, longitude: longitude)
        let to = CLLocation(latitude: location.latitude, longitude: location.longitude)
        return from.distance(from: to)
    }
    
    // Format location as a readable string
    var formattedAddress: String {
        return "\(address), \(city), \(state) \(zipCode)"
    }
    
    // Short format for display in lists
    var shortFormat: String {
        return "\(city), \(state)"
    }
}