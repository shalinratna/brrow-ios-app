//
//  BookingDetailView.swift
//  Brrow
//
//  Detailed view of a booking with management options
//

import SwiftUI

struct BookingDetailView: View {
    let booking: Booking

    @Environment(\.dismiss) private var dismiss
    @StateObject private var bookingService = BookingService.shared
    @State private var showingCancellation = false
    @State private var showingMessages = false
    @State private var cancellationReason = ""

    private var startDate: Date {
        ISO8601DateFormatter().date(from: booking.startDate) ?? Date()
    }

    private var endDate: Date {
        ISO8601DateFormatter().date(from: booking.endDate) ?? Date()
    }

    private var canCancel: Bool {
        booking.status == .pending || booking.status == .confirmed
    }

    private var canMessage: Bool {
        booking.status != .cancelled && booking.status != .declined
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    bookingHeaderView

                    // Status Section
                    statusSectionView

                    // Dates & Times
                    datesTimesView

                    // Location & Pickup
                    locationView

                    // Pricing
                    pricingView

                    // Special Requests
                    if let requests = booking.specialRequests, !requests.isEmpty {
                        specialRequestsView(requests)
                    }

                    // Owner/Renter Info
                    userInfoView

                    // Action Buttons
                    actionButtonsView
                }
                .padding()
            }
            .navigationTitle("Booking Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingCancellation) {
                CancellationView(booking: booking, reason: $cancellationReason)
            }
            .sheet(isPresented: $showingMessages) {
                BookingMessagesView(booking: booking)
            }
        }
    }

    private var bookingHeaderView: some View {
        VStack(spacing: 16) {
            HStack {
                BrrowAsyncImage(url: booking.listing?.images.first?.url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Color(.systemGray5))
                }
                .frame(width: 100, height: 100)
                .cornerRadius(12)

                VStack(alignment: .leading, spacing: 8) {
                    Text(booking.listing?.title ?? "Item")
                        .font(.title2)
                        .fontWeight(.bold)

                    if let location = booking.listing?.location {
                        HStack {
                            Image(systemName: "location.fill")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(location.city)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }

                    Text("Booking #\(booking.id.prefix(8))")
                        .font(.caption.monospaced())
                        .foregroundColor(.secondary)
                }

                Spacer()
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    private var statusSectionView: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Status")
                    .font(.headline)
                Spacer()
                BookingStatusBadge(status: booking.status)
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "clock.fill")
                        .foregroundColor(.blue)
                    Text("Created")
                    Spacer()
                    Text(ISO8601DateFormatter().date(from: booking.createdAt)?.formatted() ?? "Unknown")
                        .foregroundColor(.secondary)
                }

                if let confirmedAt = booking.confirmedAt {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Confirmed")
                        Spacer()
                        Text(ISO8601DateFormatter().date(from: confirmedAt)?.formatted() ?? "Unknown")
                            .foregroundColor(.secondary)
                    }
                }

                if let cancelledAt = booking.cancelledAt {
                    HStack {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.red)
                        Text("Cancelled")
                        Spacer()
                        Text(ISO8601DateFormatter().date(from: cancelledAt)?.formatted() ?? "Unknown")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .font(.subheadline)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }

    private var datesTimesView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Rental Period")
                .font(.headline)

            VStack(spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Check-in")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(startDate.formatted(date: .abbreviated, time: .omitted))
                            .font(.subheadline)
                            .fontWeight(.medium)
                        if let pickupTime = booking.pickupTime {
                            Text("at \(pickupTime)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    Spacer()

                    Image(systemName: "arrow.right")
                        .foregroundColor(.secondary)

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Check-out")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(endDate.formatted(date: .abbreviated, time: .omitted))
                            .font(.subheadline)
                            .fontWeight(.medium)
                        if let dropoffTime = booking.dropoffTime {
                            Text("at \(dropoffTime)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                let days = Calendar.current.dateComponents([.day], from: startDate, to: endDate).day ?? 1
                Text("\(days) day\(days == 1 ? "" : "s")")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }

    private var locationView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Pickup Location")
                .font(.headline)

            if let location = booking.listing?.location {
                VStack(alignment: .leading, spacing: 8) {
                    Text(location.address)
                        .font(.subheadline)
                    Text("\(location.city), \(location.state) \(location.zipCode)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Button("Get Directions") {
                        // Open maps
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }

    private var pricingView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Payment Summary")
                .font(.headline)

            VStack(spacing: 12) {
                PriceRow(label: "Subtotal", amount: booking.totalAmount - booking.platformFee - booking.brrowProtectionFee)
                PriceRow(label: "Platform fee", amount: booking.platformFee)
                PriceRow(label: "Brrow Protection", amount: booking.brrowProtectionFee)

                Divider()

                HStack {
                    Text("Total")
                        .font(.headline)
                        .fontWeight(.bold)
                    Spacer()
                    Text("$\(Int(booking.totalAmount))")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                }
            }

            if booking.status == .pending {
                Text("Payment will be processed after the owner accepts your request.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else if booking.status == .confirmed {
                Text("Payment has been authorized and will be charged at pickup.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }

    private func specialRequestsView(_ requests: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Special Requests")
                .font(.headline)

            Text(requests)
                .font(.subheadline)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }

    private var userInfoView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Owner")
                .font(.headline)

            if let owner = booking.owner {
                HStack {
                    Circle()
                        .fill(Color.blue.opacity(0.1))
                        .frame(width: 50, height: 50)
                        .overlay(
                            Text(owner.name.prefix(1).uppercased())
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(.blue)
                        )

                    VStack(alignment: .leading, spacing: 4) {
                        Text(owner.name)
                            .font(.subheadline)
                            .fontWeight(.medium)

                        if let rating = owner.averageRating {
                            HStack(spacing: 4) {
                                Image(systemName: "star.fill")
                                    .font(.caption)
                                    .foregroundColor(.yellow)
                                Text("\(rating, specifier: "%.1f")")
                                    .font(.caption)
                                if let reviews = owner.totalReviews {
                                    Text("(\(reviews) reviews)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }

                        if owner.isVerified {
                            HStack(spacing: 4) {
                                Image(systemName: "checkmark.seal.fill")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                                Text("Verified")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                        }
                    }

                    Spacer()

                    if canMessage {
                        Button("Message") {
                            showingMessages = true
                        }
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(16)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }

    private var actionButtonsView: some View {
        VStack(spacing: 12) {
            if booking.status == .pending {
                Button("Cancel Request") {
                    showingCancellation = true
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.red.opacity(0.1))
                .foregroundColor(.red)
                .cornerRadius(12)
            } else if booking.status == .confirmed {
                VStack(spacing: 12) {
                    Button("View on Calendar") {
                        // Navigate to calendar
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)

                    Button("Cancel Booking") {
                        showingCancellation = true
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .foregroundColor(.red)
                    .cornerRadius(12)
                }
            }

            if canMessage {
                Button("Contact Owner") {
                    showingMessages = true
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.systemGray5))
                .foregroundColor(.primary)
                .cornerRadius(12)
            }
        }
    }
}

// MARK: - Cancellation View

struct CancellationView: View {
    let booking: Booking
    @Binding var reason: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Cancel Booking")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("Please let us know why you're cancelling this booking.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                VStack(alignment: .leading, spacing: 12) {
                    Text("Reason for cancellation")
                        .font(.headline)

                    TextEditor(text: $reason)
                        .frame(minHeight: 100)
                        .padding(8)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                }

                Text("Cancellation Policy: \(booking.cancellationPolicy.description)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)

                Spacer()

                VStack(spacing: 12) {
                    Button("Cancel Booking") {
                        Task {
                            try await BookingService.shared.cancelBooking(booking.id, reason: reason)
                            dismiss()
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(12)

                    Button("Keep Booking") {
                        dismiss()
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemGray5))
                    .foregroundColor(.primary)
                    .cornerRadius(12)
                }
            }
            .padding()
            .navigationTitle("Cancel Booking")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Messages View

struct BookingMessagesView: View {
    let booking: Booking
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            VStack {
                Text("Messages feature coming soon...")
                    .foregroundColor(.secondary)
            }
            .navigationTitle("Messages")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Preview

struct BookingDetailView_Previews: PreviewProvider {
    static var previews: some View {
        BookingDetailView(booking: Booking(
            id: "booking_1",
            bookerId: "user_1",
            ownerId: "owner_1",
            listingId: "listing_1",
            startDate: ISO8601DateFormatter().string(from: Date()),
            endDate: ISO8601DateFormatter().string(from: Date().addingTimeInterval(86400 * 2)),
            totalAmount: 150.0,
            platformFee: 4.5,
            brrowProtectionFee: 15.0,
            status: .confirmed,
            bookingType: .rental,
            specialRequests: "Please include the tripod",
            pickupLocation: nil,
            dropoffLocation: nil,
            pickupTime: "10:00",
            dropoffTime: "18:00",
            isInstantBook: true,
            requiresApproval: false,
            cancellationPolicy: .flexible,
            createdAt: ISO8601DateFormatter().string(from: Date()),
            updatedAt: ISO8601DateFormatter().string(from: Date()),
            confirmedAt: ISO8601DateFormatter().string(from: Date()),
            cancelledAt: nil,
            cancellationReason: nil,
            booker: nil,
            owner: BookingUser(
                id: "owner_1",
                name: "Alice Johnson",
                profileImageUrl: nil,
                averageRating: 4.9,
                totalReviews: 23,
                isVerified: true,
                responseRate: 0.98,
                responseTime: "30 minutes"
            ),
            listing: nil,
            payments: nil,
            messages: nil,
            reviews: nil
        ))
    }
}