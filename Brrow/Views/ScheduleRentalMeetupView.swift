//
//  ScheduleRentalMeetupView.swift
//  Brrow
//
//  Created by Claude on 1/14/25.
//

import SwiftUI
import MapKit
import CoreLocation
import Combine

struct ScheduleRentalMeetupView: View {
    let bookingId: String
    let meetupType: MeetupType
    let suggestedLocation: MeetupLocation?
    let suggestedTime: Date

    var onScheduled: (Meetup) -> Void

    @StateObject private var locationManager: LocationManager
    @StateObject private var rentalService = RentalBookingService.shared

    @State private var selectedLocation: CLLocationCoordinate2D
    @State private var address: String = ""
    @State private var selectedDate: Date
    @State private var notes: String = ""
    @State private var isScheduling = false
    @State private var errorMessage: String?
    @State private var region: MKCoordinateRegion
    @State private var isSearchingAddress = false

    @Environment(\.dismiss) private var dismiss

    init(
        bookingId: String,
        meetupType: MeetupType,
        suggestedLocation: MeetupLocation?,
        suggestedTime: Date,
        onScheduled: @escaping (Meetup) -> Void
    ) {
        self.bookingId = bookingId
        self.meetupType = meetupType
        self.suggestedLocation = suggestedLocation
        self.suggestedTime = suggestedTime
        self.onScheduled = onScheduled

        // Initialize LocationManager
        _locationManager = StateObject(wrappedValue: LocationManager())

        // Initialize location and date
        let initialLocation = suggestedLocation?.coordinate ?? CLLocationCoordinate2D(
            latitude: 37.7749,
            longitude: -122.4194
        )
        _selectedLocation = State(initialValue: initialLocation)
        _selectedDate = State(initialValue: suggestedTime)
        _region = State(initialValue: MKCoordinateRegion(
            center: initialLocation,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        ))

        if let suggestedAddress = suggestedLocation?.address {
            _address = State(initialValue: suggestedAddress)
        }
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    headerSection

                    // Date & Time Selection
                    dateTimeSection

                    // Location Selection
                    locationSection

                    // Map
                    mapSection

                    // Notes
                    notesSection

                    // Schedule Button
                    Button {
                        scheduleMe etup()
                    } label: {
                        if isScheduling {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                        } else {
                            Text("Schedule \(meetupType.displayName) Meetup")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                        }
                    }
                    .background(isScheduling ? Color.gray : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .disabled(isScheduling || address.isEmpty)
                }
                .padding()
            }
            .navigationTitle("Schedule \(meetupType.displayName)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Error", isPresented: .constant(errorMessage != nil)) {
                Button("OK") {
                    errorMessage = nil
                }
            } message: {
                if let error = errorMessage {
                    Text(error)
                }
            }
        }
    }

    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 8) {
            Image(systemName: meetupType.icon)
                .font(.largeTitle)
                .foregroundColor(.blue)

            Text("Schedule \(meetupType.displayName) Meetup")
                .font(.title2)
                .fontWeight(.bold)

            Text(meetupType == .pickup ?
                "Coordinate with the other party to pick up the rental item." :
                "Coordinate with the other party to return the rental item.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    // MARK: - Date & Time Section
    private var dateTimeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Date & Time", systemImage: "calendar")
                .font(.headline)
                .fontWeight(.bold)

            DatePicker(
                "Meetup Time",
                selection: $selectedDate,
                in: Date()...,
                displayedComponents: [.date, .hourAndMinute]
            )
            .datePickerStyle(.compact)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    // MARK: - Location Section
    private var locationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Location", systemImage: "mappin.and.ellipse")
                .font(.headline)
                .fontWeight(.bold)

            // Address Input
            VStack(alignment: .leading, spacing: 4) {
                Text("Address")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                TextField("Enter meetup address", text: $address)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit {
                        geocodeAddress()
                    }
            }

            // Quick Location Buttons
            HStack(spacing: 12) {
                Button {
                    useCurrentLocation()
                } label: {
                    HStack {
                        Image(systemName: "location.fill")
                        Text("Current")
                    }
                    .font(.subheadline)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.blue.opacity(0.1))
                    .foregroundColor(.blue)
                    .cornerRadius(8)
                }

                if let suggested = suggestedLocation {
                    Button {
                        useSuggestedLocation()
                    } label: {
                        HStack {
                            Image(systemName: "star.fill")
                            Text("Suggested")
                        }
                        .font(.subheadline)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.purple.opacity(0.1))
                        .foregroundColor(.purple)
                        .cornerRadius(8)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    // MARK: - Map Section
    private var mapSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Selected Location")
                .font(.headline)
                .fontWeight(.bold)
                .padding(.horizontal)

            Map(coordinateRegion: $region, annotationItems: [MapPin(coordinate: selectedLocation)]) { pin in
                MapMarker(coordinate: pin.coordinate, tint: .blue)
            }
            .frame(height: 250)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        }
    }

    // MARK: - Notes Section
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Additional Notes", systemImage: "note.text")
                .font(.headline)
                .fontWeight(.bold)

            TextEditor(text: $notes)
                .frame(height: 100)
                .padding(8)
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(.systemGray4), lineWidth: 1)
                )

            Text("Add any special instructions or details about the meetup.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    // MARK: - Helper Functions
    private func useCurrentLocation() {
        locationManager.requestLocation()

        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            if let location = locationManager.location {
                selectedLocation = location.coordinate
                region = MKCoordinateRegion(
                    center: location.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                )
                reverseGeocodeLocation(location.coordinate)
            }
        }
    }

    private func useSuggestedLocation() {
        guard let suggested = suggestedLocation else { return }
        selectedLocation = suggested.coordinate
        region = MKCoordinateRegion(
            center: suggested.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )
        if let suggestedAddress = suggested.address {
            address = suggestedAddress
        }
    }

    private func geocodeAddress() {
        isSearchingAddress = true
        let geocoder = CLGeocoder()

        geocoder.geocodeAddressString(address) { placemarks, error in
            isSearchingAddress = false

            if let error = error {
                errorMessage = "Failed to find location: \(error.localizedDescription)"
                return
            }

            if let placemark = placemarks?.first,
               let location = placemark.location {
                selectedLocation = location.coordinate
                region = MKCoordinateRegion(
                    center: location.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                )
            }
        }
    }

    private func reverseGeocodeLocation(_ coordinate: CLLocationCoordinate2D) {
        let geocoder = CLGeocoder()
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)

        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            if let placemark = placemarks?.first {
                var addressParts: [String] = []

                if let street = placemark.thoroughfare {
                    addressParts.append(street)
                }
                if let city = placemark.locality {
                    addressParts.append(city)
                }
                if let state = placemark.administrativeArea {
                    addressParts.append(state)
                }

                address = addressParts.joined(separator: ", ")
            }
        }
    }

    private func scheduleMeetup() {
        guard !address.isEmpty else {
            errorMessage = "Please enter a location address."
            return
        }

        isScheduling = true

        let meetupLocation = MeetupLocation(
            latitude: selectedLocation.latitude,
            longitude: selectedLocation.longitude,
            address: address
        )

        let publisher: AnyPublisher<Meetup, Error>

        if meetupType == .pickup {
            publisher = rentalService.schedulePickupMeetup(
                bookingId: bookingId,
                location: meetupLocation,
                scheduledTime: selectedDate,
                notes: notes.isEmpty ? nil : notes
            )
        } else {
            publisher = rentalService.scheduleReturnMeetup(
                bookingId: bookingId,
                location: meetupLocation,
                scheduledTime: selectedDate,
                notes: notes.isEmpty ? nil : notes
            )
        }

        publisher
            .sink { completion in
                isScheduling = false
                if case .failure(let error) = completion {
                    errorMessage = error.localizedDescription
                }
            } receiveValue: { meetup in
                onScheduled(meetup)
            }
            .store(in: &cancellables)
    }

    @State private var cancellables = Set<AnyCancellable>()
}

// MARK: - MapPin Helper
private struct MapPin: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
}

// MARK: - LocationManager
class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()

    @Published var location: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
    }

    func requestLocation() {
        manager.requestWhenInUseAuthorization()
        manager.requestLocation()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        location = locations.first
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error.localizedDescription)")
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
    }
}

// MARK: - Preview
struct ScheduleRentalMeetupView_Previews: PreviewProvider {
    static var previews: some View {
        ScheduleRentalMeetupView(
            bookingId: "test-booking-id",
            meetupType: .pickup,
            suggestedLocation: nil,
            suggestedTime: Date()
        ) { _ in }
    }
}
