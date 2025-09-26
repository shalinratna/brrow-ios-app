//
//  MyBookingsView.swift
//  Brrow
//
//  View and manage user bookings
//

import SwiftUI

struct MyBookingsView: View {
    @StateObject private var bookingService = BookingService.shared
    @State private var selectedTab = 0
    @State private var showingFilters = false
    @State private var selectedBooking: Booking?

    private let tabs = ["All", "Upcoming", "Active", "Past"]

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Tab Selector
                tabSelectorView

                // Bookings List
                if bookingService.isLoading && bookingService.myBookings.isEmpty {
                    loadingView
                } else if filteredBookings.isEmpty {
                    emptyStateView
                } else {
                    bookingsListView
                }
            }
            .navigationTitle("My Bookings")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingFilters = true
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                    }
                }
            }
            .sheet(isPresented: $showingFilters) {
                BookingFiltersView()
            }
            .sheet(item: $selectedBooking) { booking in
                BookingDetailView(booking: booking)
            }
            .task {
                await loadBookings()
            }
            .refreshable {
                await loadBookings()
            }
        }
    }

    private var tabSelectorView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 20) {
                ForEach(Array(tabs.enumerated()), id: \.offset) { index, tab in
                    Button {
                        selectedTab = index
                    } label: {
                        VStack(spacing: 8) {
                            Text(tab)
                                .font(.subheadline)
                                .fontWeight(selectedTab == index ? .semibold : .regular)
                                .foregroundColor(selectedTab == index ? .blue : .secondary)

                            Rectangle()
                                .fill(selectedTab == index ? Color.blue : Color.clear)
                                .frame(height: 2)
                        }
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
    }

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
            Text("Loading bookings...")
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 60))
                .foregroundColor(.gray)

            VStack(spacing: 8) {
                Text("No Bookings")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("When you book items, they'll appear here")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
            }

            Button("Browse Items") {
                // Navigate to marketplace
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    private var bookingsListView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(filteredBookings) { booking in
                    BookingRowView(booking: booking) {
                        selectedBooking = booking
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
    }

    private var filteredBookings: [Booking] {
        let now = Date()

        switch selectedTab {
        case 1: // Upcoming
            return bookingService.myBookings.filter { booking in
                if let startDate = ISO8601DateFormatter().date(from: booking.startDate) {
                    return startDate > now && (booking.status == .confirmed || booking.status == .pending)
                }
                return false
            }
        case 2: // Active
            return bookingService.myBookings.filter { booking in booking.status == .active }
        case 3: // Past
            return bookingService.myBookings.filter { booking in
                booking.status == .completed || booking.status == .cancelled ||
                (booking.status == .confirmed && ISO8601DateFormatter().date(from: booking.endDate) ?? Date() < now)
            }
        default: // All
            return bookingService.myBookings
        }
    }

    private func loadBookings() async {
        do {
            try await bookingService.fetchMyBookings()
        } catch {
            print("Failed to load bookings: \(error)")
        }
    }
}

// MARK: - Booking Row View

struct BookingRowView: View {
    let booking: Booking
    let onTap: () -> Void

    private var startDate: Date {
        ISO8601DateFormatter().date(from: booking.startDate) ?? Date()
    }

    private var endDate: Date {
        ISO8601DateFormatter().date(from: booking.endDate) ?? Date()
    }

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 16) {
                HStack(alignment: .top, spacing: 12) {
                    // Image
                    BrrowAsyncImage(url: booking.listing?.images.first?.url) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Rectangle()
                            .fill(Color(.systemGray5))
                    }
                    .frame(width: 80, height: 80)
                    .cornerRadius(12)

                    // Content
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(booking.listing?.title ?? "Item")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)

                            Spacer()

                            BookingStatusBadge(status: booking.status)
                        }

                        if let location = booking.listing?.location {
                            Text(location.city)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }

                        HStack {
                            Image(systemName: "calendar")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            Text("\(startDate.formatted(date: .abbreviated, time: .omitted)) - \(endDate.formatted(date: .abbreviated, time: .omitted))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        HStack {
                            Text("$\(Int(booking.totalAmount))")
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .foregroundColor(.green)

                            Spacer()

                            if let ownerName = booking.owner?.name {
                                Text("with \(ownerName)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }

                // Action Buttons (if applicable)
                if booking.status == .pending {
                    HStack(spacing: 12) {
                        Button("Cancel Request") {
                            cancelBooking()
                        }
                        .font(.caption)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                        .background(Color(.systemGray5))
                        .cornerRadius(16)

                        Spacer()

                        Text("Waiting for approval")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                } else if booking.status == .confirmed {
                    HStack {
                        Button("View Details") {
                            onTap()
                        }
                        .font(.caption)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .cornerRadius(16)

                        Spacer()

                        Button("Cancel Booking") {
                            cancelBooking()
                        }
                        .font(.caption)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                        .background(Color.red.opacity(0.1))
                        .foregroundColor(.red)
                        .cornerRadius(16)
                    }
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func cancelBooking() {
        Task {
            do {
                try await BookingService.shared.cancelBooking(booking.id, reason: "User cancellation")
            } catch {
                print("Failed to cancel booking: \(error)")
            }
        }
    }
}

// MARK: - Booking Status Badge

struct BookingStatusBadge: View {
    let status: BookingStatus

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: status.icon)
                .font(.caption2)

            Text(status.displayName)
                .font(.caption)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color(status.color).opacity(0.1))
        .foregroundColor(Color(status.color))
        .cornerRadius(8)
    }
}

// MARK: - Booking Filters View

struct BookingFiltersView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            VStack {
                Text("Filters coming soon...")
                    .foregroundColor(.secondary)
            }
            .navigationTitle("Filter Bookings")
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

struct MyBookingsView_Previews: PreviewProvider {
    static var previews: some View {
        MyBookingsView()
    }
}