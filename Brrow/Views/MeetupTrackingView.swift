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
    let onMeetupNotFound: (() -> Void)?  // Callback when meetup is deleted/expired

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
    @State private var showManualArrivalAlert = false
    @State private var userDistanceFromMeetup: Double?
    @State private var showingOverrideWarning = false
    @State private var calculatedDistance: Double = 0

    @State private var cancellables = Set<AnyCancellable>()

    var body: some View {
        ZStack {
            // Check if meetup is expired
            if let meetup = meetup, meetup.expiresAt < Date() {
                // Expired Meetup View
                VStack(spacing: Theme.Spacing.lg) {
                    Spacer()

                    Image(systemName: "clock.badge.exclamationmark")
                        .font(.system(size: 60))
                        .foregroundColor(Theme.Colors.error)

                    Text("Meetup Expired")
                        .font(Theme.Typography.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(Theme.Colors.text)

                    VStack(spacing: Theme.Spacing.sm) {
                        Text("This meetup expired on \(meetup.expiresAt, style: .date) at \(meetup.expiresAt, style: .time)")
                            .font(Theme.Typography.body)
                            .foregroundColor(Theme.Colors.error)
                            .multilineTextAlignment(.center)

                        Text("The transaction will be automatically cancelled and funds released. Please reschedule to continue.")
                            .font(Theme.Typography.body)
                            .foregroundColor(Theme.Colors.secondaryText)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, Theme.Spacing.xl)

                    Button(action: {
                        // Dismiss and return to transaction detail
                        dismiss()
                    }) {
                        Text("Go Back to Reschedule")
                            .font(Theme.Typography.body)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Theme.Colors.primary)
                            .cornerRadius(Theme.CornerRadius.md)
                    }
                    .padding(.horizontal, Theme.Spacing.xl)

                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Theme.Colors.background)
            } else {
                // Normal Tracking View
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

        return ZStack(alignment: .bottom) {
            Map(coordinateRegion: $region, annotationItems: annotations) { item in
                MapMarker(coordinate: item.coordinate, tint: item.color)
            }
            .edgesIgnoringSafeArea(.all)

            // Distance display overlay
            if let meetupLoc = meetup.meetupLocation,
               let userLocation = locationService.currentLocation {
                let meetupLocation = CLLocation(latitude: meetupLoc.latitude, longitude: meetupLoc.longitude)
                let distanceMeters = userLocation.distance(from: meetupLocation)
                let distanceMiles = DistanceFormatter.metersToMiles(distanceMeters)

                VStack(spacing: 4) {
                    HStack(spacing: 8) {
                        Image(systemName: "location.circle.fill")
                            .foregroundColor(distanceColor(for: distanceMiles))
                        Text(DistanceFormatter.formatDistance(distanceMeters))
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(distanceColor(for: distanceMiles))
                        Text("to meetup")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.9))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        Capsule()
                            .fill(Color.black.opacity(0.75))
                            .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
                    )
                }
                .padding(.bottom, 160) // Position above bottom card
            }
        }
    }

    // Distance color coding
    private func distanceColor(for miles: Double) -> Color {
        if miles < 0.1 {
            return Theme.Colors.success  // Green: < 0.1 miles
        } else if miles < 0.5 {
            return Theme.Colors.warning  // Yellow: 0.1 - 0.5 miles
        } else {
            return Theme.Colors.error    // Red: > 0.5 miles
        }
    }


    // MARK: - Status Card
    private func statusCard(for meetup: Meetup) -> some View {
        VStack(spacing: Theme.Spacing.md) {
            // Status Header with glassmorphism
            VStack(spacing: Theme.Spacing.sm) {
                HStack {
                    // Status icon with background
                    Image(systemName: meetup.status.icon)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(statusColor(for: meetup.status))
                        .frame(width: 44, height: 44)
                        .background(statusColor(for: meetup.status).opacity(0.1))
                        .clipShape(Circle())

                    VStack(alignment: .leading, spacing: 2) {
                        Text(meetup.status.displayName)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.primary)

                        // Subtitle based on status
                        if let proximityStatus = proximityStatus, proximityStatus.bothArrived {
                            Text("Ready to verify")
                                .font(.system(size: 14))
                                .foregroundColor(Theme.Colors.success)
                        } else {
                            Text("In progress")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                        }
                    }

                    Spacer()
                }

                // Distance Info
                if let proximityStatus = proximityStatus {
                    Divider()
                    distanceInfo(proximityStatus, for: meetup)
                }

                // Time Info
                Divider()
                timeInfo(for: meetup)
            }
            .padding(Theme.Spacing.lg)
            .background(
                // Glassmorphism effect
                ZStack {
                    // Blur background
                    Color.white.opacity(0.7)

                    // Gradient overlay
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.white.opacity(0.25),
                            Color.white.opacity(0.1)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }
                .background(.ultraThinMaterial)
            )
            .cornerRadius(20)
            .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 10)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.white.opacity(0.5), lineWidth: 1)
            )
        }
        .padding(.horizontal, Theme.Spacing.md)
    }

    // MARK: - Distance Info
    private func distanceInfo(_ status: ProximityStatus, for meetup: Meetup) -> some View {
        let currentUserId = AuthManager.shared.currentUser?.id
        let isBuyer = currentUserId == meetup.buyerId
        let myDistanceMeters = isBuyer ? status.buyerDistance : status.sellerDistance

        return VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            if let distanceMeters = myDistanceMeters {
                let distanceDouble = Double(distanceMeters)
                let formattedDistance = DistanceFormatter.formatDistance(distanceDouble)
                let isWithinProximity = distanceDouble <= DistanceFormatter.proximityThresholdMeters

                HStack {
                    Image(systemName: "location.fill")
                        .foregroundColor(isWithinProximity ? Theme.Colors.success : Theme.Colors.primary)
                    Text("You: \(formattedDistance) away")
                        .font(Theme.Typography.body)
                        .foregroundColor(Theme.Colors.text)
                    if isWithinProximity {
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

            // Only show expiration status after initial load to avoid "expired" flash
            if !isLoading {
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
                    if proximityStatus != nil {
                        Text("Waiting for both users to arrive at the meetup location...")
                            .font(Theme.Typography.body)
                            .foregroundColor(Theme.Colors.secondaryText)

                        // Manual "I'm here" button
                        if !isUserArrived(meetup: meetup) {
                            Button(action: {
                                handleManualArrival(meetup: meetup)
                            }) {
                                HStack {
                                    Image(systemName: "location.fill")
                                    Text("I'm Here")
                                }
                                .font(Theme.Typography.body)
                                .foregroundColor(Theme.Colors.primary)
                                .padding(.vertical, Theme.Spacing.sm)
                                .padding(.horizontal, Theme.Spacing.md)
                            }
                            .buttonStyle(.bordered)
                        }
                    } else {
                        Text("Loading location status...")
                            .font(Theme.Typography.body)
                            .foregroundColor(Theme.Colors.secondaryText)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(Theme.Spacing.md)
                .background(Theme.Colors.cardBackground)
                .cornerRadius(Theme.CornerRadius.card)
            }
        }
        .alert("⚠️ Location Override", isPresented: $showingOverrideWarning) {
            Button("Cancel", role: .cancel) { }
            Button("Yes, I'm Here", role: .destructive) {
                confirmManualArrival(meetup: meetup)
            }
        } message: {
            let distanceMiles = DistanceFormatter.metersToMiles(calculatedDistance)
            let distanceText = String(format: "%.1f", distanceMiles)
            Text("""
            You're currently \(distanceText) miles away from the meetup location.

            Are you sure you want to mark yourself as arrived? This should only be used if:
            • You're at the correct location but GPS is inaccurate
            • You've arranged an alternative meetup spot
            • The other party has confirmed the change

            Misusing this feature may result in account suspension.
            """)
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
                                    print("🔍 [MEETUP TRACKING] Meetup deleted/expired - dismissing immediately")

                                    // Notify parent that meetup is invalid (parent will handle dismissal)
                                    onMeetupNotFound?()
                                    return
                                }
                            case .serverError(let message):
                                // Also check server errors for "not found"
                                if message.lowercased().contains("not found") {
                                    print("🔍 [MEETUP TRACKING] Meetup deleted/expired - dismissing immediately")

                                    // Notify parent that meetup is invalid (parent will handle dismissal)
                                    onMeetupNotFound?()
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

        let currentUserId = AuthManager.shared.currentUser?.id
        let isBuyer = currentUserId == meetup.buyerId

        var minLat = meetupLoc.latitude
        var maxLat = meetupLoc.latitude
        var minLon = meetupLoc.longitude
        var maxLon = meetupLoc.longitude

        // Only include current user's location, not the other user's
        if isBuyer, let buyerLoc = meetup.buyerLocation {
            minLat = min(minLat, buyerLoc.latitude)
            maxLat = max(maxLat, buyerLoc.latitude)
            minLon = min(minLon, buyerLoc.longitude)
            maxLon = max(maxLon, buyerLoc.longitude)
        } else if !isBuyer, let sellerLoc = meetup.sellerLocation {
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

    // MARK: - Manual Arrival Functions

    private func isUserArrived(meetup: Meetup) -> Bool {
        let currentUserId = AuthManager.shared.currentUser?.id
        let isBuyer = currentUserId == meetup.buyerId

        if let proximityStatus = proximityStatus {
            return isBuyer ? proximityStatus.buyerArrived : proximityStatus.sellerArrived
        }
        return false
    }

    private func handleManualArrival(meetup: Meetup) {
        // Calculate distance from user to meetup location
        guard let userLocation = locationService.currentLocation,
              let meetupLoc = meetup.meetupLocation else {
            // If we can't get locations, show warning
            calculatedDistance = 0
            showingOverrideWarning = true
            return
        }

        let meetupLocation = CLLocation(latitude: meetupLoc.latitude, longitude: meetupLoc.longitude)
        let distanceMeters = userLocation.distance(from: meetupLocation)
        calculatedDistance = distanceMeters

        // Check if within 50 meters (0.03 miles)
        let proximityThresholdMeters: Double = 50.0

        if distanceMeters > proximityThresholdMeters {
            // Show override warning alert
            showingOverrideWarning = true
        } else {
            // Within acceptable range, confirm directly
            confirmManualArrival(meetup: meetup)
        }
    }

    private func confirmManualArrival(meetup: Meetup) {
        // Call API to manually mark user as arrived
        meetupService.manualArrival(meetupId: meetup.id)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        errorMessage = "Failed to mark arrival: \(error.localizedDescription)"
                        showError = true
                    }
                },
                receiveValue: { updatedMeetup in
                    self.meetup = updatedMeetup
                    // Refresh proximity status
                    checkProximityStatus()
                }
            )
            .store(in: &cancellables)
    }

    private func buildAnnotations(for meetup: Meetup) -> [MapMarkerItem] {
        var items: [MapMarkerItem] = []

        let currentUserId = AuthManager.shared.currentUser?.id
        let isBuyer = currentUserId == meetup.buyerId

        // Meetup destination location (ORANGE pin, larger, static)
        if let meetupLoc = meetup.meetupLocation {
            items.append(MapMarkerItem(
                coordinate: meetupLoc.coordinate,
                label: "Meetup",
                icon: "mappin.circle.fill",
                color: Theme.Colors.accentOrange,
                userId: nil // Meetup location, not a user
            ))
        }

        // Buyer location (BLUE if current user, RED if other party)
        if let buyerLoc = meetup.buyerLocation {
            let isCurrentUser = isBuyer
            items.append(MapMarkerItem(
                coordinate: buyerLoc.coordinate,
                label: isCurrentUser ? "You" : "Other Party",
                icon: "location.fill",
                color: isCurrentUser ? Theme.Colors.accentBlue : Theme.Colors.accent,
                userId: meetup.buyerId
            ))
        }

        // Seller location (BLUE if current user, RED if other party)
        if let sellerLoc = meetup.sellerLocation {
            let isCurrentUser = !isBuyer
            items.append(MapMarkerItem(
                coordinate: sellerLoc.coordinate,
                label: isCurrentUser ? "You" : "Other Party",
                icon: "location.fill",
                color: isCurrentUser ? Theme.Colors.accentBlue : Theme.Colors.accent,
                userId: meetup.sellerId
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
    let userId: String? // nil for meetup location, user ID for user pins
}

// MARK: - Preview
struct MeetupTrackingView_Previews: PreviewProvider {
    static var previews: some View {
        MeetupTrackingView(meetupId: "test-meetup-id", onVerificationReady: nil, onMeetupNotFound: nil)
    }
}
