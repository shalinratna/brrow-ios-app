//
//  RentalDetailView.swift
//  Brrow
//
//  Created by Claude on 1/14/25.
//

import SwiftUI
import MapKit
import Combine

struct RentalDetailView: View {
    let booking: RentalBooking

    @StateObject private var rentalService = RentalBookingService.shared
    @StateObject private var meetupService = MeetupService.shared
    @State private var pickupMeetup: Meetup?
    @State private var returnMeetup: Meetup?
    @State private var isLoadingMeetups = false
    @State private var showSchedulePickup = false
    @State private var showScheduleReturn = false
    @State private var errorMessage: String?
    @State private var lateFees: Double?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header Card
                headerCard

                // Timeline Card
                timelineCard

                // Other User Card
                if let otherUser = booking.otherUser {
                    userCard(user: otherUser)
                }

                // Pickup Meetup Card
                if let pickup = pickupMeetup {
                    meetupCard(meetup: pickup, type: .pickup)
                } else if booking.canSchedulePickup {
                    scheduleMeetupPromptCard(type: .pickup)
                }

                // Return Meetup Card
                if let returnM = returnMeetup {
                    meetupCard(meetup: returnM, type: .return)
                } else if booking.canScheduleReturn {
                    scheduleMeetupPromptCard(type: .return)
                }

                // Late Fees Card (if applicable)
                if booking.isLateReturn, let fees = booking.lateFees ?? lateFees {
                    lateFeesCard(amount: fees)
                }

                // Damage Review Card (if applicable)
                if booking.status == .pendingDamageReview {
                    damageReviewCard
                }

                // Rental Details Card
                rentalDetailsCard

                // Action Buttons
                actionButtons
            }
            .padding()
        }
        .navigationTitle("Rental Details")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadMeetups()
            if booking.isLateReturn && booking.lateFees == nil {
                calculateLateFees()
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
        .sheet(isPresented: $showSchedulePickup) {
            if booking.canSchedulePickup {
                ScheduleRentalMeetupView(
                    bookingId: booking.id,
                    meetupType: .pickup,
                    suggestedLocation: booking.pickupLocation,
                    suggestedTime: booking.startDate
                ) { meetup in
                    pickupMeetup = meetup
                    showSchedulePickup = false
                }
            }
        }
        .sheet(isPresented: $showScheduleReturn) {
            if booking.canScheduleReturn {
                ScheduleRentalMeetupView(
                    bookingId: booking.id,
                    meetupType: .return,
                    suggestedLocation: booking.dropoffLocation,
                    suggestedTime: booking.endDate
                ) { meetup in
                    returnMeetup = meetup
                    showScheduleReturn = false
                }
            }
        }
    }

    // MARK: - Header Card
    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Listing Image
            if let listing = booking.listing,
               let firstImage = listing.listingImages?.first {
                AsyncImage(url: URL(string: firstImage.imageUrl)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                }
                .frame(height: 200)
                .clipped()
                .cornerRadius(12)
            }

            // Title and Status
            VStack(alignment: .leading, spacing: 8) {
                Text(booking.listing?.title ?? "Rental Booking")
                    .font(.title2)
                    .fontWeight(.bold)

                HStack {
                    Image(systemName: booking.status.icon)
                        .foregroundColor(statusColor)
                    Text(booking.status.displayName)
                        .foregroundColor(statusColor)
                        .fontWeight(.medium)
                }

                // Dates
                HStack {
                    VStack(alignment: .leading) {
                        Text("Start Date")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(booking.startDate, style: .date)
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }

                    Spacer()

                    Image(systemName: "arrow.right")
                        .foregroundColor(.secondary)

                    Spacer()

                    VStack(alignment: .trailing) {
                        Text("End Date")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(booking.endDate, style: .date)
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                }
                .padding(.top, 4)

                // Duration and Cost
                HStack {
                    Label(booking.rentalDuration, systemImage: "calendar")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Spacer()

                    Text(booking.totalCost)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }
            }
            .padding(.horizontal, 4)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    // MARK: - Timeline Card
    private var timelineCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Rental Timeline")
                .font(.headline)
                .fontWeight(.bold)

            VStack(spacing: 0) {
                // Step 1: Requested
                timelineStep(
                    title: "Booking Requested",
                    isCompleted: true,
                    isCurrent: booking.status == .pending,
                    showLine: true
                )

                // Step 2: Confirmed
                timelineStep(
                    title: "Booking Confirmed",
                    isCompleted: ![.pending, .declined, .cancelled, .expired].contains(booking.status),
                    isCurrent: booking.status == .confirmed,
                    showLine: true,
                    timestamp: booking.confirmedAt
                )

                // Step 3: Pickup Scheduled
                timelineStep(
                    title: "Pickup Scheduled",
                    isCompleted: pickupMeetup != nil && ![.pending, .confirmed, .declined, .cancelled, .expired].contains(booking.status),
                    isCurrent: booking.status == .readyForPickup,
                    showLine: true,
                    timestamp: pickupMeetup?.scheduledTime
                )

                // Step 4: Picked Up
                timelineStep(
                    title: "Item Picked Up",
                    isCompleted: [.active, .readyForReturn, .returned, .pendingDamageReview, .completed].contains(booking.status),
                    isCurrent: booking.status == .inProgress,
                    showLine: true,
                    timestamp: booking.actualPickupTime
                )

                // Step 5: Active Rental
                timelineStep(
                    title: "Rental Active",
                    isCompleted: [.readyForReturn, .returned, .pendingDamageReview, .completed].contains(booking.status),
                    isCurrent: booking.status == .active,
                    showLine: true
                )

                // Step 6: Return Scheduled
                timelineStep(
                    title: "Return Scheduled",
                    isCompleted: returnMeetup != nil && [.returned, .pendingDamageReview, .completed].contains(booking.status),
                    isCurrent: booking.status == .readyForReturn,
                    showLine: true,
                    timestamp: returnMeetup?.scheduledTime
                )

                // Step 7: Returned & Verified
                timelineStep(
                    title: "Returned & Verified",
                    isCompleted: [.returned, .completed].contains(booking.status),
                    isCurrent: [.returned, .pendingDamageReview, .completed].contains(booking.status),
                    showLine: false,
                    timestamp: booking.actualReturnTime
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    // MARK: - Timeline Step
    private func timelineStep(
        title: String,
        isCompleted: Bool,
        isCurrent: Bool,
        showLine: Bool,
        timestamp: Date? = nil
    ) -> some View {
        HStack(alignment: .top, spacing: 12) {
            // Icon and Line
            VStack(spacing: 0) {
                ZStack {
                    Circle()
                        .fill(isCompleted ? Color.green : (isCurrent ? Color.blue : Color.gray.opacity(0.3)))
                        .frame(width: 24, height: 24)

                    if isCompleted {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    } else if isCurrent {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 8, height: 8)
                    }
                }

                if showLine {
                    Rectangle()
                        .fill(isCompleted ? Color.green.opacity(0.3) : Color.gray.opacity(0.3))
                        .frame(width: 2, height: 40)
                }
            }

            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(isCurrent ? .semibold : .regular)
                    .foregroundColor(isCompleted || isCurrent ? .primary : .secondary)

                if let timestamp = timestamp {
                    Text(timestamp, style: .relative)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()
        }
    }

    // MARK: - User Card
    private func userCard(user: User) -> some View {
        HStack(spacing: 12) {
            // Profile Picture
            if let profileUrl = user.profilePictureUrl {
                AsyncImage(url: URL(string: profileUrl)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Circle()
                        .fill(Color.gray.opacity(0.2))
                }
                .frame(width: 50, height: 50)
                .clipShape(Circle())
            } else {
                Circle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Text(String(user.username.prefix(1)).uppercased())
                            .font(.title3)
                            .foregroundColor(.white)
                    )
            }

            // User Info
            VStack(alignment: .leading, spacing: 4) {
                Text(booking.currentUserRole == "Renter" ? "Owner" : "Renter")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text(user.displayName ?? user.username)
                    .font(.headline)

                if let rating = user.rating {
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.caption)
                            .foregroundColor(.yellow)
                        Text(String(format: "%.1f", rating))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Spacer()

            // Contact Button
            Button {
                // TODO: Navigate to chat
            } label: {
                Image(systemName: "message.fill")
                    .foregroundColor(.blue)
                    .padding(8)
                    .background(Color.blue.opacity(0.1))
                    .clipShape(Circle())
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    // MARK: - Meetup Card
    private func meetupCard(meetup: Meetup, type: MeetupType) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: type.icon)
                    .foregroundColor(.blue)
                Text("\(type.displayName) Meetup")
                    .font(.headline)
                    .fontWeight(.bold)

                Spacer()

                Image(systemName: meetup.status.icon)
                    .foregroundColor(meetupStatusColor(meetup.status))
            }

            Divider()

            // Status
            HStack {
                Text("Status")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
                Text(meetup.status.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(meetupStatusColor(meetup.status))
            }

            // Scheduled Time
            if let scheduledTime = meetup.scheduledTime {
                HStack {
                    Text("Scheduled")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(scheduledTime, style: .date)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Text(scheduledTime, style: .time)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
            }

            // Location
            if let location = meetup.meetupLocation {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Location")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    if let address = location.address {
                        Text(address)
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }

                    // Mini Map
                    Map(coordinateRegion: .constant(MKCoordinateRegion(
                        center: location.coordinate,
                        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                    )), annotationItems: [location]) { loc in
                        MapMarker(coordinate: loc.coordinate, tint: .blue)
                    }
                    .frame(height: 150)
                    .cornerRadius(8)
                    .allowsHitTesting(false)
                }
            }

            // Notes
            if let notes = meetup.notes, !notes.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Notes")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text(notes)
                        .font(.subheadline)
                }
            }

            // Action Button
            if meetup.status == .scheduled {
                Button {
                    // TODO: Navigate to meetup tracking view
                } label: {
                    HStack {
                        Image(systemName: "location.fill")
                        Text("Track Meetup")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    // MARK: - Schedule Meetup Prompt Card
    private func scheduleMeetupPromptCard(type: MeetupType) -> some View {
        VStack(spacing: 12) {
            Image(systemName: type.icon)
                .font(.largeTitle)
                .foregroundColor(.blue.opacity(0.6))

            Text("Schedule \(type.displayName) Meetup")
                .font(.headline)

            Text("Coordinate with the \(booking.currentUserRole == "Renter" ? "owner" : "renter") to schedule your \(type.displayName.lowercased()) meetup.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button {
                if type == .pickup {
                    showSchedulePickup = true
                } else {
                    showScheduleReturn = true
                }
            } label: {
                Text("Schedule Now")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    // MARK: - Late Fees Card
    private func lateFeesCard(amount: Double) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                Text("Late Return Fee")
                    .font(.headline)
                    .fontWeight(.bold)

                Spacer()

                Text(String(format: "$%.2f", amount))
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.orange)
            }

            Divider()

            Text("This rental was returned late. The late fee has been automatically calculated and will be processed accordingly.")
                .font(.subheadline)
                .foregroundColor(.secondary)

            if let calculatedAt = booking.lateFeeCalculatedAt {
                HStack {
                    Text("Calculated")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(calculatedAt, style: .relative)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
        )
    }

    // MARK: - Damage Review Card
    private var damageReviewCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "exclamationmark.shield.fill")
                    .foregroundColor(.red)
                Text("Damage Review in Progress")
                    .font(.headline)
                    .fontWeight(.bold)

                Spacer()
            }

            Divider()

            Text("A damage claim has been filed for this rental. Payment is on hold while the claim is being reviewed. You will be notified once the review is complete.")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.red.opacity(0.1))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.red.opacity(0.3), lineWidth: 1)
        )
    }

    // MARK: - Rental Details Card
    private var rentalDetailsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Rental Details")
                .font(.headline)
                .fontWeight(.bold)

            Divider()

            detailRow(label: "Rental Period", value: booking.rentalDuration)
            detailRow(label: "Daily Rate", value: booking.dailyRateDisplay)
            detailRow(label: "Subtotal", value: String(format: "$%.2f", booking.subtotal))
            detailRow(label: "Platform Fee", value: String(format: "$%.2f", booking.platformFee))
            detailRow(label: "Protection Fee", value: String(format: "$%.2f", booking.brrowProtectionFee))

            if booking.ownerOptedInsurance {
                detailRow(label: "Insurance Fee", value: String(format: "$%.2f", booking.ownerInsuranceFee))
            }

            Divider()

            HStack {
                Text("Total Amount")
                    .font(.headline)
                Spacer()
                Text(booking.totalCost)
                    .font(.headline)
                    .fontWeight(.bold)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    private func detailRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }

    // MARK: - Action Buttons
    private var actionButtons: some View {
        VStack(spacing: 12) {
            if booking.canSchedulePickup {
                Button {
                    showSchedulePickup = true
                } label: {
                    Text("Schedule Pickup Meetup")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }

            if booking.canScheduleReturn {
                Button {
                    showScheduleReturn = true
                } label: {
                    Text("Schedule Return Meetup")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }

            if booking.status == .confirmed || booking.status == .readyForPickup {
                Button(role: .destructive) {
                    // TODO: Cancel booking
                } label: {
                    Text("Cancel Booking")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.red.opacity(0.1))
                        .foregroundColor(.red)
                        .cornerRadius(10)
                }
            }
        }
    }

    // MARK: - Helper Functions
    private func loadMeetups() {
        isLoadingMeetups = true

        rentalService.getBookingMeetups(bookingId: booking.id)
            .sink { completion in
                isLoadingMeetups = false
                if case .failure(let error) = completion {
                    errorMessage = error.localizedDescription
                }
            } receiveValue: { data in
                pickupMeetup = data.pickupMeetup
                returnMeetup = data.returnMeetup
            }
            .store(in: &cancellables)
    }

    private func calculateLateFees() {
        rentalService.calculateLateFees(bookingId: booking.id)
            .sink { completion in
                if case .failure(let error) = completion {
                    print("Failed to calculate late fees: \(error)")
                }
            } receiveValue: { fees in
                lateFees = fees
            }
            .store(in: &cancellables)
    }

    private var statusColor: Color {
        switch booking.status.color {
        case "green": return .green
        case "blue": return .blue
        case "orange": return .orange
        case "red": return .red
        case "purple": return .purple
        case "gray": return .gray
        default: return .gray
        }
    }

    private func meetupStatusColor(_ status: MeetupStatus) -> Color {
        switch status {
        case .scheduled: return .blue
        case .buyerArrived, .sellerArrived: return .orange
        case .bothArrived: return .purple
        case .verified, .completed: return .green
        case .cancelled, .expired: return .red
        }
    }

    @State private var cancellables = Set<AnyCancellable>()
}

// MARK: - MeetupLocation Identifiable Extension
extension MeetupLocation: Identifiable {
    var id: String {
        "\(latitude),\(longitude)"
    }
}

// MARK: - Preview
struct RentalDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            RentalDetailView(booking: .mockBooking)
        }
    }
}

// MARK: - Mock Data
extension RentalBooking {
    static var mockBooking: RentalBooking {
        // This would need to be implemented with mock data for preview
        fatalError("Mock data not implemented")
    }
}
