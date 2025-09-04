//
//  LocationService.swift
//  Brrow
//
//  Created by Shalin Ratna on 7/16/25.
//

import Foundation
import CoreLocation
import MapKit
import Combine

class LocationService: NSObject, ObservableObject {
    static let shared = LocationService()
    
    @Published var currentLocation: CLLocation?
    @Published var currentAddress: String?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var error: String?
    @Published var isGeocoding = false
    
    private let locationManager = CLLocationManager()
    private let geocoder = CLGeocoder()
    private var cancellables = Set<AnyCancellable>()
    
    // Standard address format
    struct FormattedAddress {
        let streetNumber: String?
        let streetName: String?
        let city: String
        let state: String
        let zipCode: String
        let country: String
        
        var fullAddress: String {
            var components: [String] = []
            
            // Add street address
            if let streetNumber = streetNumber, let streetName = streetName {
                components.append("\(streetNumber) \(streetName)")
            } else if let streetName = streetName {
                components.append(streetName)
            }
            
            // Add city, state zip
            components.append("\(city), \(state) \(zipCode)")
            
            return components.joined(separator: ", ")
        }
        
        var shortAddress: String {
            return "\(city), \(state)"
        }
        
        var standardFormat: String {
            // Ensures consistent format for database storage
            return fullAddress
        }
    }
    
    override init() {
        super.init()
        setupLocationManager()
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        locationManager.distanceFilter = 100 // meters
    }
    
    func requestLocationPermission() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    func startUpdatingLocation() {
        locationManager.startUpdatingLocation()
    }
    
    func stopUpdatingLocation() {
        locationManager.stopUpdatingLocation()
    }
    
    // Get nearby items within radius
    func getNearbyItems<T: GeoLocatable>(items: [T], radius: Double) -> [T] {
        guard let userLocation = currentLocation else { return [] }
        
        return items.filter { item in
            let itemLocation = CLLocation(latitude: item.latitude, longitude: item.longitude)
            let distance = userLocation.distance(from: itemLocation)
            return distance <= radius * 1000 // Convert km to meters
        }.sorted { item1, item2 in
            let loc1 = CLLocation(latitude: item1.latitude, longitude: item1.longitude)
            let loc2 = CLLocation(latitude: item2.latitude, longitude: item2.longitude)
            return userLocation.distance(from: loc1) < userLocation.distance(from: loc2)
        }
    }
    
    // Reverse geocode location to address
    func getAddress(from location: CLLocation) -> AnyPublisher<String, Error> {
        Future { [weak self] promise in
            self?.geocoder.reverseGeocodeLocation(location) { placemarks, error in
                if let error = error {
                    promise(.failure(error))
                    return
                }
                
                if let placemark = placemarks?.first {
                    let address = [
                        placemark.subThoroughfare,
                        placemark.thoroughfare,
                        placemark.locality,
                        placemark.administrativeArea,
                        placemark.postalCode
                    ]
                        .compactMap { $0 }
                        .joined(separator: " ")
                    promise(.success(address))
                } else {
                    promise(.failure(NSError(domain: "LocationService", code: -1, userInfo: [NSLocalizedDescriptionKey: "No address found"])))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    // Forward geocode address to coordinates
    func getCoordinates(from address: String) -> AnyPublisher<CLLocationCoordinate2D, Error> {
        Future { [weak self] promise in
            self?.geocoder.geocodeAddressString(address) { placemarks, error in
                if let error = error {
                    promise(.failure(error))
                    return
                }
                
                if let location = placemarks?.first?.location?.coordinate {
                    promise(.success(location))
                } else {
                    promise(.failure(NSError(domain: "LocationService", code: -1, userInfo: [NSLocalizedDescriptionKey: "No coordinates found"])))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    // Enhanced geocoding with formatted address
    func geocodeAndFormat(address: String) -> AnyPublisher<(coordinate: CLLocationCoordinate2D, formatted: FormattedAddress), Error> {
        Future { [weak self] promise in
            self?.isGeocoding = true
            self?.geocoder.geocodeAddressString(address) { placemarks, error in
                self?.isGeocoding = false
                
                if let error = error {
                    promise(.failure(error))
                    return
                }
                
                guard let placemark = placemarks?.first,
                      let location = placemark.location else {
                    promise(.failure(NSError(domain: "LocationService", code: -1, userInfo: [NSLocalizedDescriptionKey: "No location found for address"])))
                    return
                }
                
                let formatted = FormattedAddress(
                    streetNumber: placemark.subThoroughfare,
                    streetName: placemark.thoroughfare,
                    city: placemark.locality ?? "",
                    state: placemark.administrativeArea ?? "",
                    zipCode: placemark.postalCode ?? "",
                    country: placemark.country ?? "USA"
                )
                
                promise(.success((location.coordinate, formatted)))
            }
        }
        .eraseToAnyPublisher()
    }
    
    // Validate and format address components
    func validateAndFormatAddress(street: String, city: String, state: String?, zipCode: String) -> AnyPublisher<FormattedAddress, Error> {
        // Build address string
        var addressComponents = [street, city]
        if let state = state {
            addressComponents.append(state)
        }
        addressComponents.append(zipCode)
        let fullAddress = addressComponents.joined(separator: ", ")
        
        return geocodeAndFormat(address: fullAddress)
            .map { $0.formatted }
            .eraseToAnyPublisher()
    }
    
    // Get current location and format address
    func getCurrentLocationFormatted() -> AnyPublisher<(location: CLLocation, formatted: FormattedAddress), Error> {
        guard let location = currentLocation else {
            return Fail(error: NSError(domain: "LocationService", code: -1, userInfo: [NSLocalizedDescriptionKey: "No current location available"]))
                .eraseToAnyPublisher()
        }
        
        return Future { [weak self] promise in
            self?.geocoder.reverseGeocodeLocation(location) { placemarks, error in
                if let error = error {
                    promise(.failure(error))
                    return
                }
                
                guard let placemark = placemarks?.first else {
                    promise(.failure(NSError(domain: "LocationService", code: -1, userInfo: [NSLocalizedDescriptionKey: "No address found"])))
                    return
                }
                
                let formatted = FormattedAddress(
                    streetNumber: placemark.subThoroughfare,
                    streetName: placemark.thoroughfare,
                    city: placemark.locality ?? "",
                    state: placemark.administrativeArea ?? "",
                    zipCode: placemark.postalCode ?? "",
                    country: placemark.country ?? "USA"
                )
                
                promise(.success((location, formatted)))
            }
        }
        .eraseToAnyPublisher()
    }
    
    // Get region for map display
    func getRegion(for items: [GeoLocatable], defaultLocation: CLLocationCoordinate2D? = nil) -> MKCoordinateRegion {
        let locations = items.map { CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude) }
        
        if locations.isEmpty {
            if let defaultLocation = defaultLocation {
                return MKCoordinateRegion(
                    center: defaultLocation,
                    span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                )
            } else {
                // Default to San Francisco if no location available
                return MKCoordinateRegion(
                    center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
                    span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                )
            }
        }
        
        let latitudes = locations.map { $0.latitude }
        let longitudes = locations.map { $0.longitude }
        
        let minLat = latitudes.min()!
        let maxLat = latitudes.max()!
        let minLong = longitudes.min()!
        let maxLong = longitudes.max()!
        
        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLong + maxLong) / 2
        )
        
        let span = MKCoordinateSpan(
            latitudeDelta: max(maxLat - minLat, 0.05) * 1.5,
            longitudeDelta: max(maxLong - minLong, 0.05) * 1.5
        )
        
        return MKCoordinateRegion(center: center, span: span)
    }
    
    // Track location events
    private func trackLocationEvent(_ eventName: String, metadata: [String: String] = [:]) {
        let event = AnalyticsEvent(
            eventName: eventName,
            eventType: "location",
            userId: AuthManager.shared.currentUser?.apiId,
            sessionId: AuthManager.shared.sessionId,
            timestamp: ISO8601DateFormatter().string(from: Date()),
            metadata: metadata.merging([
                "platform": "ios",
                "has_location": String(currentLocation != nil)
            ]) { current, _ in current }
        )
        
        APIClient.shared.trackAnalytics(event: event)
            .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
            .store(in: &cancellables)
    }
}

// MARK: - CLLocationManagerDelegate
extension LocationService: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            manager.startUpdatingLocation()
            trackLocationEvent("location_authorized")
        case .denied, .restricted:
            error = "Location access denied"
            trackLocationEvent("location_denied")
        default:
            break
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        currentLocation = location
        
        // Get address for current location
        getAddress(from: location)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.error = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] address in
                    self?.currentAddress = address
                }
            )
            .store(in: &cancellables)
        
        trackLocationEvent("location_updated", metadata: [
            "accuracy": String(location.horizontalAccuracy),
            "speed": String(location.speed)
        ])
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        self.error = error.localizedDescription
        trackLocationEvent("location_error", metadata: ["error": error.localizedDescription])
    }
}

// MARK: - GeoLocatable Protocol
protocol GeoLocatable {
    var latitude: Double { get }
    var longitude: Double { get }
}