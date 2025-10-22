//
//  MeetupSchedulingView.swift
//  Brrow
//
//  Enhanced with modern UI, animations, and Brrow theme
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
    @State private var showDatePicker = false
    @State private var animateSelection = false
    @State private var showConfirmation = false

    @State private var cancellables = Set<AnyCancellable>()

    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [
                        Theme.Colors.primary.opacity(0.03),
                        Color.white
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Header with icon
                        headerSection

                        // Map View with enhanced styling
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
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
            }
            .navigationTitle("Schedule Meetup")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        HStack(spacing: 4) {
                            Image(systemName: "xmark")
                                .font(.system(size: 14, weight: .semibold))
                            Text("Cancel")
                                .font(.system(size: 16, weight: .medium))
                        }
                        .foregroundColor(Theme.Colors.text)
                    }
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
            .alert("Meetup Scheduled!", isPresented: $showSuccess) {
                Button("Done") {
                    dismiss()
                }
            } message: {
                Text("Your meetup has been scheduled successfully. You'll receive a notification with the details.")
            }
            .sheet(isPresented: $showConfirmation) {
                if let coordinate = selectedCoordinate {
                    MeetupConfirmationSheet(
                        location: coordinate,
                        address: selectedAddress,
                        scheduledTime: scheduledTime,
                        notes: notes.isEmpty ? nil : notes,
                        onConfirm: {
                            showConfirmation = false
                            scheduleMeetup()
                        },
                        onCancel: {
                            showConfirmation = false
                        }
                    )
                }
            }
            .onAppear {
                setupInitialLocation()
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1)) {
                    animateSelection = true
                }
            }
        }
    }

    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Theme.Colors.primary.opacity(0.2),
                                Theme.Colors.primary.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 64, height: 64)
                    .scaleEffect(animateSelection ? 1.0 : 0.8)

                Image(systemName: "mappin.and.ellipse")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Theme.Colors.primary, Theme.Colors.primary.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .scaleEffect(animateSelection ? 1.0 : 0.8)
            }
            .animation(.spring(response: 0.6, dampingFraction: 0.7), value: animateSelection)

            Text("Set meetup location and time")
                .font(.system(size: 15))
                .foregroundColor(.secondary)
                .opacity(animateSelection ? 1.0 : 0.0)
                .animation(.easeOut(duration: 0.3).delay(0.2), value: animateSelection)
        }
        .padding(.top, 8)
        .padding(.bottom, 4)
    }

    // MARK: - Map Section
    private var mapSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "map.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Theme.Colors.primary)

                Text("Meetup Location")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(Theme.Colors.text)

                Spacer()

                if selectedCoordinate != nil {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(Theme.Colors.primary)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: selectedCoordinate != nil)

            Map(coordinateRegion: $region, annotationItems: selectedCoordinate != nil ? [MapPoint(coordinate: selectedCoordinate!)] : []) { item in
                MapMarker(coordinate: item.coordinate, tint: Theme.Colors.primary)
            }
            .frame(height: 280)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 4)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        selectedCoordinate != nil ? Theme.Colors.primary.opacity(0.3) : Color.clear,
                        lineWidth: 2
                    )
                    .animation(.easeInOut(duration: 0.3), value: selectedCoordinate != nil)
            )

            if !selectedAddress.isEmpty {
                HStack(spacing: 12) {
                    Image(systemName: "mappin.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(Theme.Colors.primary)

                    Text(selectedAddress)
                        .font(.system(size: 15))
                        .foregroundColor(Theme.Colors.text)
                        .lineLimit(2)

                    Spacer()
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Theme.Colors.primary.opacity(0.06))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Theme.Colors.primary.opacity(0.2), lineWidth: 1)
                )
                .transition(.move(edge: .top).combined(with: .opacity))
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: selectedAddress)
            }
        }
    }

    // MARK: - Location Search Section
    private var locationSearchSection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Theme.Colors.secondaryText)

                TextField("Search for a location", text: $searchText)
                    .font(.system(size: 16))
                    .foregroundColor(Theme.Colors.text)
                    .onChange(of: searchText) { _ in
                        performSearch()
                    }

                if isSearching {
                    ProgressView()
                        .scaleEffect(0.8)
                        .transition(.opacity)
                } else if !searchText.isEmpty {
                    Button(action: {
                        withAnimation(.easeOut(duration: 0.2)) {
                            searchText = ""
                            searchResults = []
                        }
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 18))
                            .foregroundColor(Theme.Colors.secondaryText)
                    }
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(14)
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(searchText.isEmpty ? Color.clear : Theme.Colors.primary.opacity(0.2), lineWidth: 1)
                    .animation(.easeInOut(duration: 0.2), value: searchText.isEmpty)
            )
            .animation(.default, value: isSearching)

            Button(action: useCurrentLocation) {
                HStack(spacing: 8) {
                    Image(systemName: "location.fill")
                        .font(.system(size: 15, weight: .semibold))
                    Text("Use Current Location")
                        .font(.system(size: 15, weight: .semibold))
                }
                .foregroundColor(Theme.Colors.primary)
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Theme.Colors.primary.opacity(0.08))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Theme.Colors.primary.opacity(0.3), lineWidth: 1)
                )
            }
        }
    }

    // MARK: - Search Results Section
    private var searchResultsSection: some View {
        VStack(spacing: 8) {
            ForEach(searchResults, id: \.self) { item in
                Button(action: {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        selectLocation(item)
                    }
                    HapticManager.impact(style: .light)
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "mappin.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(Theme.Colors.primary)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.name ?? "Unknown")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(Theme.Colors.text)
                            if let address = item.placemark.title {
                                Text(address)
                                    .font(.system(size: 13))
                                    .foregroundColor(Theme.Colors.secondaryText)
                                    .lineLimit(1)
                            }
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(Theme.Colors.secondaryText)
                    }
                    .padding(12)
                    .background(Color.white)
                    .cornerRadius(10)
                    .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
                }
                .buttonStyle(ScaleButtonStyle())
            }
        }
        .transition(.move(edge: .top).combined(with: .opacity))
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: searchResults.count)
    }

    // MARK: - Date/Time Section
    private var dateTimeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "calendar")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Theme.Colors.primary)

                Text("Meetup Time")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(Theme.Colors.text)

                Spacer()

                Button(action: {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        showDatePicker.toggle()
                    }
                }) {
                    HStack(spacing: 6) {
                        Text(scheduledTime, style: .date)
                            .font(.system(size: 14, weight: .medium))
                        Text(scheduledTime, style: .time)
                            .font(.system(size: 14, weight: .medium))
                        Image(systemName: showDatePicker ? "chevron.up" : "chevron.down")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundColor(Theme.Colors.primary)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Theme.Colors.primary.opacity(0.08))
                    )
                }
            }

            if showDatePicker {
                DatePicker("", selection: $scheduledTime, in: Date()...)
                    .datePickerStyle(.graphical)
                    .padding(12)
                    .background(Color(.systemGray6))
                    .cornerRadius(14)
                    .transition(.asymmetric(
                        insertion: .move(edge: .top).combined(with: .opacity),
                        removal: .move(edge: .top).combined(with: .opacity)
                    ))
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: showDatePicker)
    }

    // MARK: - Notes Section
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "note.text")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Theme.Colors.primary)

                Text("Notes (Optional)")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(Theme.Colors.text)
            }

            ZStack(alignment: .topLeading) {
                if notes.isEmpty {
                    Text("Add any special instructions or details...")
                        .font(.system(size: 15))
                        .foregroundColor(Color(.systemGray3))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                }

                TextEditor(text: $notes)
                    .font(.system(size: 15))
                    .foregroundColor(Theme.Colors.text)
                    .frame(height: 100)
                    .padding(8)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(notes.isEmpty ? Color.clear : Theme.Colors.primary.opacity(0.2), lineWidth: 1)
                            .animation(.easeInOut(duration: 0.2), value: notes.isEmpty)
                    )
            }
        }
    }

    // MARK: - Schedule Button
    private var scheduleButton: some View {
        Button(action: {
            HapticManager.impact(style: .medium)
            showConfirmation = true
        }) {
            HStack(spacing: 10) {
                if isScheduling {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.9)
                } else {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18, weight: .semibold))
                    Text("Schedule Meetup")
                        .font(.system(size: 17, weight: .semibold))
                }
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                LinearGradient(
                    colors: selectedCoordinate == nil ? [Color.gray, Color.gray.opacity(0.8)] : [Theme.Colors.primary, Theme.Colors.primary.opacity(0.8)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(14)
            .shadow(
                color: selectedCoordinate == nil ? Color.clear : Theme.Colors.primary.opacity(0.3),
                radius: 8,
                x: 0,
                y: 4
            )
        }
        .disabled(selectedCoordinate == nil || isScheduling)
        .opacity(selectedCoordinate == nil ? 0.6 : 1.0)
        .padding(.top, 8)
        .padding(.bottom, 16)
        .animation(.easeInOut(duration: 0.2), value: selectedCoordinate != nil)
        .animation(.easeInOut(duration: 0.2), value: isScheduling)
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
            errorMessage = "Unable to get current location. Please enable location services in Settings."
            showError = true
            return
        }

        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            selectedCoordinate = location.coordinate
            region.center = location.coordinate
        }

        // Reverse geocode to get address
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            if let placemark = placemarks?.first {
                withAnimation(.easeOut(duration: 0.3)) {
                    selectedAddress = formatAddress(from: placemark)
                }
            }
        }

        HapticManager.impact(style: .medium)
    }

    private func performSearch() {
        guard !searchText.isEmpty else {
            withAnimation(.easeOut(duration: 0.2)) {
                searchResults = []
            }
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
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    searchResults = response.mapItems
                }
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
                HapticManager.notification(type: .success)
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

// MARK: - Scale Button Style
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Preview
#Preview {
    MeetupSchedulingView(transactionId: "test-transaction-id", onMeetupScheduled: nil)
}
