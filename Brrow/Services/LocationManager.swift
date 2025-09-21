//
//  LocationManager.swift
//  Brrow
//
//  Location services manager for handling GPS, permissions, and location updates
//

import Foundation
import CoreLocation
import Combine
import UIKit

class LocationManager: NSObject, ObservableObject {
    static let shared = LocationManager()
    
    // MARK: - Published Properties
    @Published var currentLocation: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var isLocationAvailable = false
    @Published var locationError: LocationError?
    @Published var address: String = ""
    @Published var city: String = ""
    @Published var state: String = ""
    @Published var zipCode: String = ""
    @Published var country: String = "US"
    
    // Nearby items
    @Published var nearbyListings: Int = 0
    @Published var nearbyGarageSales: Int = 0
    @Published var matchingSeeks: Int = 0
    
    // MARK: - Private Properties
    private let locationManager = CLLocationManager()
    private let geocoder = CLGeocoder()
    private var locationUpdateTimer: Timer?
    private var lastLocationUpdate: Date?
    private let minimumUpdateInterval: TimeInterval = 30 // 30 seconds between updates
    
    // MARK: - Error Types
    enum LocationError: LocalizedError {
        case denied
        case restricted
        case unknown
        case networkError
        
        var errorDescription: String? {
            switch self {
            case .denied:
                return "Location access denied. Please enable in Settings."
            case .restricted:
                return "Location access is restricted."
            case .unknown:
                return "Unable to determine location."
            case .networkError:
                return "Network error while updating location."
            }
        }
    }
    
    // MARK: - Initialization
    override init() {
        super.init()
        setupLocationManager()
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 100 // Update every 100 meters
        locationManager.pausesLocationUpdatesAutomatically = true
        locationManager.activityType = .other
        
        // Check initial authorization status
        authorizationStatus = locationManager.authorizationStatus
    }
    
    // MARK: - Public Methods
    func requestLocationPermission() {
        switch authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            locationError = authorizationStatus == .denied ? .denied : .restricted
        case .authorizedWhenInUse, .authorizedAlways:
            startLocationUpdates()
        @unknown default:
            locationError = .unknown
        }
    }

    // Async version that waits for permission result
    func requestLocationPermissionAsync() async -> Bool {
        return await withCheckedContinuation { continuation in
            // If already authorized, return immediately
            if authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways {
                continuation.resume(returning: true)
                return
            }

            // If already denied/restricted, return false
            if authorizationStatus == .denied || authorizationStatus == .restricted {
                continuation.resume(returning: false)
                return
            }

            // Store continuation to resume when permission changes
            permissionContinuation = continuation

            // Request permission
            locationManager.requestWhenInUseAuthorization()
        }
    }

    // Helper property to track async permission requests
    private var permissionContinuation: CheckedContinuation<Bool, Never>?
    
    func startLocationUpdates() {
        guard authorizationStatus == .authorizedWhenInUse || 
              authorizationStatus == .authorizedAlways else {
            requestLocationPermission()
            return
        }
        
        locationManager.startUpdatingLocation()
        isLocationAvailable = true
        
        // Start periodic location updates to server
        startPeriodicUpdates()
    }
    
    func stopLocationUpdates() {
        locationManager.stopUpdatingLocation()
        stopPeriodicUpdates()
        isLocationAvailable = false
    }
    
    func requestSingleLocation() {
        locationManager.requestLocation()
    }

    // Get current location with automatic permission request
    func getCurrentLocationAsync() async -> CLLocation? {
        // First check if we have permission
        let hasPermission = await requestLocationPermissionAsync()
        guard hasPermission else { return nil }

        // If we already have a current location, return it
        if let location = currentLocation {
            return location
        }

        // Otherwise request a new location update
        return await withCheckedContinuation { continuation in
            locationContinuation = continuation
            locationManager.requestLocation()
        }
    }

    // Helper property to track async location requests
    private var locationContinuation: CheckedContinuation<CLLocation?, Never>?
    
    // MARK: - Server Updates
    private func startPeriodicUpdates() {
        locationUpdateTimer?.invalidate()
        locationUpdateTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
            self.updateLocationOnServer()
        }
    }
    
    private func stopPeriodicUpdates() {
        locationUpdateTimer?.invalidate()
        locationUpdateTimer = nil
    }
    
    func updateLocationOnServer(searchRadius: Double = 10) {
        guard let location = currentLocation else { return }
        
        // Throttle updates
        if let lastUpdate = lastLocationUpdate,
           Date().timeIntervalSince(lastUpdate) < minimumUpdateInterval {
            return
        }
        
        Task {
            do {
                let response = try await APIClient.shared.updateLocation(
                    latitude: location.coordinate.latitude,
                    longitude: location.coordinate.longitude,
                    accuracy: location.horizontalAccuracy,
                    address: address,
                    city: city,
                    state: state,
                    country: country,
                    zipCode: zipCode,
                    searchRadius: searchRadius
                )
                
                if let data = response["data"] as? [String: Any],
                   let nearby = data["nearby"] as? [String: Any] {
                    DispatchQueue.main.async {
                        self.nearbyListings = nearby["listings"] as? Int ?? 0
                        self.nearbyGarageSales = nearby["garage_sales"] as? Int ?? 0
                        self.matchingSeeks = nearby["matching_seeks"] as? Int ?? 0
                    }
                }
                
                lastLocationUpdate = Date()
            } catch {
                print("Failed to update location on server: \(error)")
            }
        }
    }
    
    // MARK: - Geocoding
    private func reverseGeocode(location: CLLocation) {
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
            guard let self = self,
                  let placemark = placemarks?.first else { return }
            
            DispatchQueue.main.async {
                self.address = [
                    placemark.subThoroughfare,
                    placemark.thoroughfare
                ].compactMap { $0 }.joined(separator: " ")
                
                self.city = placemark.locality ?? ""
                self.state = placemark.administrativeArea ?? ""
                self.zipCode = placemark.postalCode ?? ""
                self.country = placemark.isoCountryCode ?? "US"
            }
        }
    }
    
    // MARK: - Distance Calculation
    func distance(from location: CLLocation) -> Double? {
        guard let current = currentLocation else { return nil }
        return current.distance(from: location)
    }
    
    func distanceString(from location: CLLocation) -> String {
        guard let distanceMeters = distance(from: location) else {
            return "Unknown distance"
        }
        
        let distanceKm = distanceMeters / 1000
        
        if distanceKm < 1 {
            return String(format: "%.0f m", distanceMeters)
        } else if distanceKm < 10 {
            return String(format: "%.1f km", distanceKm)
        } else {
            return String(format: "%.0f km", distanceKm)
        }
    }
    
    // MARK: - Search Nearby
    func searchNearby(radius: Double = 10, 
                     type: String = "all",
                     category: String? = nil,
                     minPrice: Double? = nil,
                     maxPrice: Double? = nil,
                     sort: String = "distance") async throws -> [String: Any] {
        
        guard let location = currentLocation else {
            throw LocationError.unknown
        }
        
        return try await APIClient.shared.searchByLocation(
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude,
            radius: radius,
            type: type,
            category: category,
            minPrice: minPrice,
            maxPrice: maxPrice,
            sort: sort
        )
    }
}

// MARK: - CLLocationManagerDelegate
extension LocationManager: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus

        switch authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            startLocationUpdates()
            locationError = nil
            // Resume async permission request with success
            permissionContinuation?.resume(returning: true)
            permissionContinuation = nil
        case .denied:
            locationError = .denied
            isLocationAvailable = false
            // Resume async permission request with failure
            permissionContinuation?.resume(returning: false)
            permissionContinuation = nil
        case .restricted:
            locationError = .restricted
            isLocationAvailable = false
            // Resume async permission request with failure
            permissionContinuation?.resume(returning: false)
            permissionContinuation = nil
        case .notDetermined:
            break
        @unknown default:
            locationError = .unknown
            // Resume async permission request with failure
            permissionContinuation?.resume(returning: false)
            permissionContinuation = nil
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }

        // Filter out invalid or old locations
        let howRecent = location.timestamp.timeIntervalSinceNow
        guard abs(howRecent) < 5.0 else { return }

        // Check if location is accurate enough
        guard location.horizontalAccuracy > 0 && location.horizontalAccuracy < 100 else { return }

        currentLocation = location
        reverseGeocode(location: location)

        // Resume async location request if waiting
        locationContinuation?.resume(returning: location)
        locationContinuation = nil

        // Update server with new location
        updateLocationOnServer()
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location manager error: \(error)")

        if let clError = error as? CLError {
            switch clError.code {
            case .denied:
                locationError = .denied
            case .network:
                locationError = .networkError
            default:
                locationError = .unknown
            }
        }

        // Resume async location request with failure
        locationContinuation?.resume(returning: nil)
        locationContinuation = nil
    }
}

// MARK: - Location Permission Helper
extension LocationManager {
    static func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }

    var permissionStatusText: String {
        switch authorizationStatus {
        case .notDetermined:
            return "Location permission not requested"
        case .restricted:
            return "Location access restricted"
        case .denied:
            return "Location access denied"
        case .authorizedWhenInUse:
            return "Location access when in use"
        case .authorizedAlways:
            return "Location access always"
        @unknown default:
            return "Unknown location status"
        }
    }

    // Check if we can show "Use Current Location" button
    var canUseCurrentLocation: Bool {
        return CLLocationManager.locationServicesEnabled() &&
               authorizationStatus != .denied &&
               authorizationStatus != .restricted
    }

    // Check if location is authorized and ready
    var isLocationAuthorized: Bool {
        return authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways
    }
}