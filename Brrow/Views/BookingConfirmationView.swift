//
//  BookingConfirmationView.swift
//  Brrow
//
//  Booking confirmation and payment flow
//

import SwiftUI

struct BookingConfirmationView: View {
    let listing: Listing
    let startDate: Date
    let endDate: Date
    let totalPrice: Double
    let specialRequests: String
    let pickupTime: Date
    let dropoffTime: Date

    @Environment(\.dismiss) private var dismiss
    @StateObject private var bookingService = BookingService.shared
    @State private var isSubmitting = false
    @State private var showingSuccess = false
    @State private var errorMessage: String?
    @State private var agreedToTerms = false

    private var daysBetween: Int {
        Calendar.current.dateComponents([.day], from: startDate, to: endDate).day ?? 0
    }

    private var dailyRate: Double {
        listing.dailyRate ?? listing.price
    }

    private var subtotal: Double {
        dailyRate * Double(daysBetween)
    }

    private var platformFee: Double {
        subtotal * 0.03
    }

    private var protectionFee: Double {
        subtotal * 0.10
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    confirmationHeaderView

                    // Booking Details
                    bookingDetailsView

                    // Pricing Summary
                    pricingSummaryView

                    // Special Requests
                    if !specialRequests.isEmpty {
                        specialRequestsSummaryView
                    }

                    // Times
                    timesSummaryView

                    // Terms & Conditions
                    termsView

                    // Confirm Button
                    confirmButtonView
                }
                .padding()
            }
            .navigationTitle("Confirm Booking")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Error", isPresented: .constant(errorMessage != nil)) {
                Button("OK") { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
            .alert("Booking Confirmed!", isPresented: $showingSuccess) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Your booking request has been sent to the owner. You'll receive a notification when they respond.")
            }
        }
    }

    private var confirmationHeaderView: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 48))
                .foregroundColor(.green)

            Text("Review Your Booking")
                .font(.title2)
                .fontWeight(.bold)

            Text("Please review the details below before confirming your booking request.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    private var bookingDetailsView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Booking Details")
                .font(.headline)

            HStack {
                AsyncImage(url: URL(string: listing.images.first?.url ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Color(.systemGray5))
                }
                .frame(width: 60, height: 60)
                .cornerRadius(8)

                VStack(alignment: .leading, spacing: 4) {
                    Text(listing.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    Text(listing.location.city)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }

            VStack(spacing: 12) {
                BookingDetailRow(label: "Check-in", value: startDate.formatted(date: .abbreviated, time: .omitted))
                BookingDetailRow(label: "Check-out", value: endDate.formatted(date: .abbreviated, time: .omitted))
                BookingDetailRow(label: "Duration", value: "\(daysBetween) day\(daysBetween == 1 ? "" : "s")")
                BookingDetailRow(label: "Total guests", value: "1")
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }

    private var pricingSummaryView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Price Breakdown")
                .font(.headline)

            VStack(spacing: 12) {
                PriceRow(label: "$\(Int(dailyRate)) × \(daysBetween) day\(daysBetween == 1 ? "" : "s")", amount: subtotal)
                PriceRow(label: "Platform fee", amount: platformFee)
                PriceRow(label: "Brrow Protection", amount: protectionFee)

                Divider()

                HStack {
                    Text("Total (USD)")
                        .font(.headline)
                        .fontWeight(.bold)
                    Spacer()
                    Text("$\(Int(totalPrice))")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                }
            }

            Text("You'll be charged $\(Int(totalPrice * 0.2)) now as a deposit. The remaining $\(Int(totalPrice * 0.8)) will be charged after the owner accepts your request.")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.top, 8)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }

    private var specialRequestsSummaryView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Special Requests")
                .font(.headline)

            Text(specialRequests)
                .font(.subheadline)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }

    private var timesSummaryView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Pickup & Dropoff Times")
                .font(.headline)

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Pickup")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(pickupTime.formatted(date: .omitted, time: .shortened))
                        .font(.subheadline)
                        .fontWeight(.medium)
                }

                Spacer()

                Image(systemName: "arrow.right")
                    .foregroundColor(.secondary)

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("Dropoff")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(dropoffTime.formatted(date: .omitted, time: .shortened))
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }

    private var termsView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Button {
                    agreedToTerms.toggle()
                } label: {
                    Image(systemName: agreedToTerms ? "checkmark.square.fill" : "square")
                        .foregroundColor(agreedToTerms ? .blue : .gray)
                        .font(.title3)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("I agree to the Brrow Terms of Service and Cancellation Policy")
                        .font(.subheadline)

                    HStack {
                        Button("Terms of Service") {
                            // Open terms
                        }
                        .font(.caption)

                        Text("•")
                            .foregroundColor(.secondary)
                            .font(.caption)

                        Button("Cancellation Policy") {
                            // Open cancellation policy
                        }
                        .font(.caption)
                    }
                }

                Spacer()
            }

            Text("By booking, you agree to pay the total amount shown. Cancellation policies and terms apply.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    private var confirmButtonView: some View {
        VStack(spacing: 12) {
            Button {
                submitBooking()
            } label: {
                HStack {
                    if isSubmitting {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                    Text(isSubmitting ? "Processing..." : "Confirm and Pay")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(agreedToTerms && !isSubmitting ? Color.blue : Color.gray)
                .foregroundColor(.white)
                .cornerRadius(12)
                .font(.headline)
            }
            .disabled(!agreedToTerms || isSubmitting)

            Text("Your payment method will be charged $\(Int(totalPrice * 0.2)) now")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    private func submitBooking() {
        guard !isSubmitting else { return }

        isSubmitting = true
        errorMessage = nil

        Task {
            do {
                let formatter = ISO8601DateFormatter()
                let request = CreateBookingRequest(
                    listingId: listing.id,
                    startDate: formatter.string(from: startDate),
                    endDate: formatter.string(from: endDate),
                    specialRequests: specialRequests.isEmpty ? nil : specialRequests,
                    pickupLocation: nil,
                    dropoffLocation: nil,
                    pickupTime: pickupTime.formatted(date: .omitted, time: .shortened),
                    dropoffTime: dropoffTime.formatted(date: .omitted, time: .shortened),
                    totalGuests: 1,
                    agreedToTerms: agreedToTerms
                )

                let _ = try await bookingService.createBooking(request)

                await MainActor.run {
                    isSubmitting = false
                    showingSuccess = true
                }

            } catch {
                await MainActor.run {
                    isSubmitting = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}

// MARK: - Supporting Views

struct BookingDetailRow: View {
    let label: String
    let value: String

    var body: some View {
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
}

// MARK: - Preview

struct BookingConfirmationView_Previews: PreviewProvider {
    static var previews: some View {
        BookingConfirmationView(
            listing: Listing.example,
            startDate: Date(),
            endDate: Date().addingTimeInterval(86400 * 2),
            totalPrice: 162.0,
            specialRequests: "Please include the tripod",
            pickupTime: Date(),
            dropoffTime: Date()
        )
    }
}