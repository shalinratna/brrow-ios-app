//
//  MeetupTrackingView.swift
//  Brrow
//
//  Created by Claude on 1/6/25.
//

import SwiftUI
import MapKit
import Combine

struct MeetupTrackingView: View {
    let meetupId: String
    let onVerificationReady: ((Meetup) -> Void)?

    @Environment(\.dismiss) private var dismiss
    @StateObject private var meetupService = MeetupService.shared
    @StateObject private var locationService = LocationService.shared

    @State private var meetup: Meetup?
    @State private var proximityStatus: ProximityStatus?
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )
    @State private var isLoading = true
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var locationUpdateTimer: Timer?
    @State private var proximityCheckTimer: Timer?

    @State private var cancellables = Set<AnyCancellable>()

    var body: some View {
        ZStack {
            // Map View
            if let meetup = meetup {
                mapView(for: meetup)
            } else {
                Theme.Colors.background
            }

            // Overlay UI
            VStack {
                // Status Card
                if let meetup = meetup {
                    statusCard(for: meetup)
                        .padding(Theme.Spacing.md)
                }

                Spacer()

                // Bottom Action Card
                if let meetup = meetup {
                    bottomActionCard(for: meetup)
                        .padding(Theme.Spacing.md)
                }
            }

            // Loading Overlay
            if isLoading {
                Color.black.opacity(0.3)
                    .edgesIgnoringSafeArea(.all)
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)
            }
        }
        .navigationTitle("Track Meetup")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "xmark")
                        .font(.body)
                        .foregroundColor(Theme.Colors.text)
                }
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .onAppear {
            setupTracking()
        }
        .onDisappear {
            stopTracking()
        }
    }

    // MARK: - Map View
    private func mapView(for meetup: Meetup) -> some View {
        let annotations = buildAnnotations(for: meetup)

        return Map(coordinateRegion: $region, annotationItems: annotations) { item in
            MapMarker(coordinate: item.coordinate, tint: item.color)
        }
        .edgesIgnoringSafeArea(.all)
    }

    // MARK: - Status Card
    private func statusCard(for meetup: Meetup) -> some View {
        VStack(spacing: Theme.Spacing.sm) {
            // Status Header
            HStack {
                Image(systemName: meetup.status.icon)
                    .foregroundColor(statusColor(for: meetup.status))
                Text(meetup.status.displayName)
                    .font(Theme.Typography.headline)
                    .foregroundColor(Theme.Colors.text)
                Spacer()
            }

            Divider()

            // Distance Info
            if let proximityStatus = proximityStatus {
                distanceInfo(proximityStatus, for: meetup)
            }

            // Time Info
            timeInfo(for: meetup)
        }
        .padding(Theme.Spacing.md)
        .background(Theme.Colors.cardBackground)
        .cornerRadius(Theme.CornerRadius.card)
        .shadow(color: Theme.Shadows.card, radius: Theme.Shadows.cardRadius, x: 0, y: 2)
    }

    // MARK: - Distance Info
    private func distanceInfo(_ status: ProximityStatus, for meetup: Meetup) -> some View {
        let currentUserId = AuthManager.shared.currentUser?.id
        let isBuyer = currentUserId == meetup.buyerId
        let myDistance = isBuyer ? status.buyerDistance : status.sellerDistance
        let otherDistance = isBuyer ? status.sellerDistance : status.buyerDistance

        return VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            if let distance = myDistance {
                HStack {
                    Image(systemName: "location.fill")
                        .foregroundColor(distance <= 100 ? Theme.Colors.success : Theme.Colors.primary)
                    Text("You: \(distance)m away")
                        .font(Theme.Typography.body)
                        .foregroundColor(Theme.Colors.text)
                    if distance <= 100 {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(Theme.Colors.success)
                    }
                }
            }

            if let distance = otherDistance {
                HStack {
                    Image(systemName: "person.fill")
                        .foregroundColor(distance <= 100 ? Theme.Colors.success : Theme.Colors.secondaryText)
                    Text("\(meetup.otherUser?.username ?? "Other user"): \(distance)m away")
                        .font(Theme.Typography.body)
                        .foregroundColor(Theme.Colors.text)
                    if distance <= 100 {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(Theme.Colors.success)
                    }
                }
            }

            if status.bothArrived {
                HStack {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundColor(Theme.Colors.success)
                    Text("Both users have arrived!")
                        .font(Theme.Typography.body)
                        .fontWeight(.semibold)
                        .foregroundColor(Theme.Colors.success)
                }
                .padding(.top, Theme.Spacing.xs)
            }
        }
    }

    // MARK: - Time Info
    private func timeInfo(for meetup: Meetup) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            if let scheduledTime = meetup.scheduledTime {
                HStack {
                    Image(systemName: "clock")
                        .foregroundColor(Theme.Colors.secondaryText)
                    Text("Scheduled: \(scheduledTime, style: .date) at \(scheduledTime, style: .time)")
                        .font(Theme.Typography.footnote)
                        .foregroundColor(Theme.Colors.secondaryText)
                }
            }

            let timeRemaining = meetup.expiresAt.timeIntervalSince(Date())
            if timeRemaining > 0 {
                HStack {
                    Image(systemName: "hourglass")
                        .foregroundColor(timeRemaining < 86400 ? Theme.Colors.warning : Theme.Colors.secondaryText)
                    Text("Expires in \(formattedTimeRemaining(timeRemaining))")
                        .font(Theme.Typography.footnote)
                        .foregroundColor(timeRemaining < 86400 ? Theme.Colors.warning : Theme.Colors.secondaryText)
                }
            } else {
                HStack {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundColor(Theme.Colors.error)
                    Text("Meetup expired")
                        .font(Theme.Typography.footnote)
                        .foregroundColor(Theme.Colors.error)
                }
            }
        }
    }

    // MARK: - Bottom Action Card
    private func bottomActionCard(for meetup: Meetup) -> some View {
        VStack(spacing: Theme.Spacing.md) {
            if meetup.canVerify {
                Button(action: {
                    onVerificationReady?(meetup)
                }) {
                    HStack {
                        Image(systemName: "checkmark.seal.fill")
                        Text("Start Verification")
                    }
                }
                .primaryButtonStyle()
            } else if meetup.status == .verified || meetup.status == .completed {
                VStack(spacing: Theme.Spacing.sm) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 48))
                        .foregroundColor(Theme.Colors.success)
                    Text("Verification Complete!")
                        .font(Theme.Typography.headline)
                        .foregroundColor(Theme.Colors.text)
                }
                .frame(maxWidth: .infinity)
                .padding(Theme.Spacing.md)
                .background(Theme.Colors.cardBackground)
                .cornerRadius(Theme.CornerRadius.card)
            } else {
                VStack(spacing: Theme.Spacing.sm) {
                    if let proximityStatus = proximityStatus {
                        if !proximityStatus.buyerArrived && !proximityStatus.sellerArrived {
                            Text("Waiting for users to arrive...")
                        } else if proximityStatus.buyerArrived && !proximityStatus.sellerArrived {
                            Text("Buyer has arrived. Waiting for seller...")
                        } else if !proximityStatus.buyerArrived && proximityStatus.sellerArrived {
                            Text("Seller has arrived. Waiting for buyer...")
                        }
                    } else {
                        Text("Loading location status...")
                    }
                }
                .font(Theme.Typography.body)
                .foregroundColor(Theme.Colors.secondaryText)
                .frame(maxWidth: .infinity)
                .padding(Theme.Spacing.md)
                .background(Theme.Colors.cardBackground)
                .cornerRadius(Theme.CornerRadius.card)
            }
        }
    }

    // MARK: - Helper Functions
    private func setupTracking() {
        isLoading = true

        // Request location permission
        locationService.requestLocationPermission()
        locationService.startUpdatingLocation()

        // Load meetup details
        loadMeetup()

        // Start location updates every 10 seconds
        locationUpdateTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { _ in
            updateLocation()
        }

        // Check proximity status every 5 seconds
        proximityCheckTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
            checkProximityStatus()
        }
    }

    private func stopTracking() {
        locationUpdateTimer?.invalidate()
        proximityCheckTimer?.invalidate()
        locationService.stopUpdatingLocation()
    }

    private func loadMeetup() {
        meetupService.getMeetup(meetupId: meetupId)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    isLoading = false

                    if case .failure(let error) = completion {
                        // Check if it's a BrrowAPIError (meetup not found/deleted)
                        if let apiError = error as? BrrowAPIError {
                            switch apiError {
                            case .validationError(let message):
                                // 404 errors come as validation errors with "not found" message
                                if message.lowercased().contains("not found") || message.lowercased().contains("meetup") {
                                    print("🔍 [MEETUP TRACKING] Meetup deleted/expired - showing friendly message")
                                    errorMessage = "This meetup no longer exists. It may have been cancelled or expired."
                                    showError = true

                                    // Auto-dismiss after showing error
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                        dismiss()
                                    }
                                    return
                                }
                            case .serverError(let message):
                                // Also check server errors for "not found"
                                if message.lowercased().contains("not found") {
                                    print("🔍 [MEETUP TRACKING] Meetup deleted/expired - showing friendly message")
                                    errorMessage = "This meetup no longer exists. It may have been cancelled or expired."
                                    showError = true

                                    // Auto-dismiss after showing error
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                        dismiss()
                                    }
                                    return
                                }
                            default:
                                break
                            }
                        }

                        // Default error handling for all other cases
                        print("🔍 [MEETUP TRACKING] Error loading meetup: \(error.localizedDescription)")
                        errorMessage = error.localizedDescription
                        showError = true
                    }
                },
                receiveValue: { loadedMeetup in
                    self.meetup = loadedMeetup
                    updateMapRegion(for: loadedMeetup)
                    checkProximityStatus()
                }
            )
            .store(in: &cancellables)
    }

    private func updateLocation() {
        guard let location = locationService.currentLocation else { return }

        meetupService.updateLocation(meetupId: meetupId, location: location.coordinate)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { data in
                    self.meetup = data.meetup
                    updateMapRegion(for: data.meetup)
                }
            )
            .store(in: &cancellables)
    }

    private func checkProximityStatus() {
        meetupService.getProximityStatus(meetupId: meetupId)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { status in
                    self.proximityStatus = status
                }
            )
            .store(in: &cancellables)
    }

    private func updateMapRegion(for meetup: Meetup) {
        guard let meetupLoc = meetup.meetupLocation else {
            // If no meetup location, center on user's location or default
            if let userLocation = locationService.currentLocation {
                region = MKCoordinateRegion(
                    center: userLocation.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                )
            }
            return
        }

        var minLat = meetupLoc.latitude
        var maxLat = meetupLoc.latitude
        var minLon = meetupLoc.longitude
        var maxLon = meetupLoc.longitude

        if let buyerLoc = meetup.buyerLocation {
            minLat = min(minLat, buyerLoc.latitude)
            maxLat = max(maxLat, buyerLoc.latitude)
            minLon = min(minLon, buyerLoc.longitude)
            maxLon = max(maxLon, buyerLoc.longitude)
        }

        if let sellerLoc = meetup.sellerLocation {
            minLat = min(minLat, sellerLoc.latitude)
            maxLat = max(maxLat, sellerLoc.latitude)
            minLon = min(minLon, sellerLoc.longitude)
            maxLon = max(maxLon, sellerLoc.longitude)
        }

        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )

        let span = MKCoordinateSpan(
            latitudeDelta: max((maxLat - minLat) * 1.5, 0.01),
            longitudeDelta: max((maxLon - minLon) * 1.5, 0.01)
        )

        region = MKCoordinateRegion(center: center, span: span)
    }

    private func buildAnnotations(for meetup: Meetup) -> [MapMarkerItem] {
        var items: [MapMarkerItem] = []

        // Meetup location (only if exists)
        if let meetupLoc = meetup.meetupLocation {
            items.append(MapMarkerItem(
                coordinate: meetupLoc.coordinate,
                label: "Meetup",
                icon: "mappin.circle.fill",
                color: Theme.Colors.primary
            ))
        }

        // Current user location
        let currentUserId = AuthManager.shared.currentUser?.id
        let isBuyer = currentUserId == meetup.buyerId

        if isBuyer, let buyerLoc = meetup.buyerLocation {
            items.append(MapMarkerItem(
                coordinate: buyerLoc.coordinate,
                label: "You",
                icon: "location.fill",
                color: Theme.Colors.accentBlue
            ))
        } else if !isBuyer, let sellerLoc = meetup.sellerLocation {
            items.append(MapMarkerItem(
                coordinate: sellerLoc.coordinate,
                label: "You",
                icon: "location.fill",
                color: Theme.Colors.accentBlue
            ))
        }

        // Other user location
        if isBuyer, let sellerLoc = meetup.sellerLocation {
            items.append(MapMarkerItem(
                coordinate: sellerLoc.coordinate,
                label: meetup.sellers?.username ?? "Seller",
                icon: "person.fill",
                color: Theme.Colors.accentOrange
            ))
        } else if !isBuyer, let buyerLoc = meetup.buyerLocation {
            items.append(MapMarkerItem(
                coordinate: buyerLoc.coordinate,
                label: meetup.buyers?.username ?? "Buyer",
                icon: "person.fill",
                color: Theme.Colors.accentOrange
            ))
        }

        return items
    }

    private func statusColor(for status: MeetupStatus) -> Color {
        switch status {
        case .scheduled:
            return Theme.Colors.primary
        case .buyerArrived, .sellerArrived:
            return Theme.Colors.warning
        case .bothArrived:
            return Theme.Colors.success
        case .verified, .completed:
            return Theme.Colors.success
        case .cancelled:
            return Theme.Colors.error
        case .expired:
            return Theme.Colors.secondaryText
        }
    }

    private func formattedTimeRemaining(_ seconds: TimeInterval) -> String {
        let days = Int(seconds / 86400)
        let hours = Int((seconds.truncatingRemainder(dividingBy: 86400)) / 3600)
        let minutes = Int((seconds.truncatingRemainder(dividingBy: 3600)) / 60)

        if days > 0 {
            return "\(days)d \(hours)h"
        } else if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

// MARK: - Map Marker Item
private struct MapMarkerItem: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
    let label: String
    let icon: String
    let color: Color
}

// MARK: - Preview
struct MeetupTrackingView_Previews: PreviewProvider {
    static var previews: some View {
        MeetupTrackingView(meetupId: "test-meetup-id", onVerificationReady: nil)
    }
}
