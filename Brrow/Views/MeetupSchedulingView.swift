//
//  MeetupSchedulingView.swift
//  Brrow
//
//  Created by Claude on 1/6/25.
//

import SwiftUI
import MapKit
import Combine

struct MeetupSchedulingView: View {
    let transactionId: String
    let onMeetupScheduled: ((Meetup) -> Void)?

    @Environment(\.dismiss) private var dismiss
    @StateObject private var meetupService = MeetupService.shared
    @StateObject private var locationService = LocationService.shared

    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    @State private var selectedCoordinate: CLLocationCoordinate2D?
    @State private var selectedAddress = ""
    @State private var searchText = ""
    @State private var searchResults: [MKMapItem] = []
    @State private var scheduledTime = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
    @State private var notes = ""
    @State private var isScheduling = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showSuccess = false
    @State private var isSearching = false

    @State private var cancellables = Set<AnyCancellable>()

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: Theme.Spacing.md) {
                    // Map View
                    mapSection

                    // Location Search
                    locationSearchSection

                    // Search Results
                    if !searchResults.isEmpty {
                        searchResultsSection
                    }

                    // Date/Time Picker
                    dateTimeSection

                    // Notes
                    notesSection

                    // Schedule Button
                    scheduleButton
                }
                .padding(Theme.Spacing.md)
            }
            .navigationTitle("Schedule Meetup")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(Theme.Colors.text)
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
            .alert("Meetup Scheduled!", isPresented: $showSuccess) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Your meetup has been scheduled successfully.")
            }
            .onAppear {
                setupInitialLocation()
            }
        }
    }

    // MARK: - Map Section
    private var mapSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Select Location")
                .font(Theme.Typography.headline)
                .foregroundColor(Theme.Colors.text)

            Map(coordinateRegion: $region, annotationItems: selectedCoordinate != nil ? [MapPoint(coordinate: selectedCoordinate!)] : []) { item in
                MapMarker(coordinate: item.coordinate, tint: Theme.Colors.primary)
            }
            .frame(height: 300)
            .cornerRadius(Theme.CornerRadius.card)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.card)
                    .stroke(Theme.Colors.border, lineWidth: 1)
            )
            .onTapGesture { location in
                // Note: MapKit tap gesture doesn't provide coordinate directly
                // Users should use search instead
            }

            if !selectedAddress.isEmpty {
                HStack {
                    Image(systemName: "mappin.circle.fill")
                        .foregroundColor(Theme.Colors.primary)
                    Text(selectedAddress)
                        .font(Theme.Typography.body)
                        .foregroundColor(Theme.Colors.secondaryText)
                    Spacer()
                }
                .padding(Theme.Spacing.sm)
                .background(Theme.Colors.secondaryBackground)
                .cornerRadius(Theme.CornerRadius.sm)
            }
        }
    }

    // MARK: - Location Search Section
    private var locationSearchSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(Theme.Colors.secondaryText)
                TextField("Search for a location", text: $searchText)
                    .font(Theme.Typography.body)
                    .foregroundColor(Theme.Colors.text)
                    .onChange(of: searchText) { _ in
                        performSearch()
                    }

                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                        searchResults = []
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(Theme.Colors.secondaryText)
                    }
                }
            }
            .padding(Theme.Spacing.sm)
            .background(Theme.Colors.inputBackground)
            .cornerRadius(Theme.CornerRadius.sm)

            Button(action: useCurrentLocation) {
                HStack {
                    Image(systemName: "location.fill")
                    Text("Use Current Location")
                }
                .font(Theme.Typography.body)
                .foregroundColor(Theme.Colors.primary)
            }
        }
    }

    // MARK: - Search Results Section
    private var searchResultsSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            ForEach(searchResults, id: \.self) { item in
                Button(action: {
                    selectLocation(item)
                }) {
                    VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                        Text(item.name ?? "Unknown")
                            .font(Theme.Typography.body)
                            .foregroundColor(Theme.Colors.text)
                        if let address = item.placemark.title {
                            Text(address)
                                .font(Theme.Typography.footnote)
                                .foregroundColor(Theme.Colors.secondaryText)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(Theme.Spacing.sm)
                    .background(Theme.Colors.secondaryBackground)
                    .cornerRadius(Theme.CornerRadius.sm)
                }
            }
        }
    }

    // MARK: - Date/Time Section
    private var dateTimeSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Meetup Time")
                .font(Theme.Typography.headline)
                .foregroundColor(Theme.Colors.text)

            DatePicker("", selection: $scheduledTime, in: Date()...)
                .datePickerStyle(.graphical)
                .padding(Theme.Spacing.sm)
                .background(Theme.Colors.secondaryBackground)
                .cornerRadius(Theme.CornerRadius.card)
        }
    }

    // MARK: - Notes Section
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Notes (Optional)")
                .font(Theme.Typography.headline)
                .foregroundColor(Theme.Colors.text)

            TextEditor(text: $notes)
                .font(Theme.Typography.body)
                .foregroundColor(Theme.Colors.text)
                .frame(height: 100)
                .padding(Theme.Spacing.sm)
                .background(Theme.Colors.inputBackground)
                .cornerRadius(Theme.CornerRadius.sm)
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.CornerRadius.sm)
                        .stroke(Theme.Colors.border, lineWidth: 1)
                )
        }
    }

    // MARK: - Schedule Button
    private var scheduleButton: some View {
        Button(action: scheduleMeetup) {
            if isScheduling {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
            } else {
                Text("Schedule Meetup")
            }
        }
        .primaryButtonStyle()
        .disabled(selectedCoordinate == nil || isScheduling)
        .opacity(selectedCoordinate == nil ? 0.5 : 1.0)
    }

    // MARK: - Helper Functions
    private func setupInitialLocation() {
        if let userLocation = locationService.currentLocation {
            region.center = userLocation.coordinate
        } else {
            locationService.requestLocationPermission()
            locationService.startUpdatingLocation()
        }
    }

    private func useCurrentLocation() {
        guard let location = locationService.currentLocation else {
            errorMessage = "Unable to get current location. Please enable location services."
            showError = true
            return
        }

        selectedCoordinate = location.coordinate
        region.center = location.coordinate

        // Reverse geocode to get address
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            if let placemark = placemarks?.first {
                selectedAddress = formatAddress(from: placemark)
            }
        }
    }

    private func performSearch() {
        guard !searchText.isEmpty else {
            searchResults = []
            return
        }

        isSearching = true
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchText
        request.region = region

        let search = MKLocalSearch(request: request)
        search.start { response, error in
            isSearching = false
            if let response = response {
                searchResults = response.mapItems
            }
        }
    }

    private func selectLocation(_ item: MKMapItem) {
        selectedCoordinate = item.placemark.coordinate
        selectedAddress = item.placemark.title ?? ""
        region.center = item.placemark.coordinate
        searchResults = []
        searchText = ""
    }

    private func formatAddress(from placemark: CLPlacemark) -> String {
        var components: [String] = []
        if let name = placemark.name {
            components.append(name)
        }
        if let locality = placemark.locality {
            components.append(locality)
        }
        if let state = placemark.administrativeArea {
            components.append(state)
        }
        return components.joined(separator: ", ")
    }

    private func scheduleMeetup() {
        guard let coordinate = selectedCoordinate else {
            errorMessage = "Please select a location first."
            showError = true
            return
        }

        guard !selectedAddress.isEmpty else {
            errorMessage = "Unable to determine address. Please try selecting the location again."
            showError = true
            return
        }

        isScheduling = true

        meetupService.scheduleMeetup(
            transactionId: transactionId,
            location: coordinate,
            address: selectedAddress,
            scheduledTime: scheduledTime,
            notes: notes.isEmpty ? nil : notes
        )
        .receive(on: DispatchQueue.main)
        .sink(
            receiveCompletion: { completion in
                isScheduling = false
                if case .failure(let error) = completion {
                    errorMessage = error.localizedDescription
                    showError = true
                }
            },
            receiveValue: { meetup in
                onMeetupScheduled?(meetup)
                showSuccess = true
            }
        )
        .store(in: &cancellables)
    }
}

// MARK: - Map Point Helper
private struct MapPoint: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
}

// MARK: - Preview
#Preview {
    MeetupSchedulingView(transactionId: "test-transaction-id", onMeetupScheduled: nil)
}
