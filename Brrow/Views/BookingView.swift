//
//  BookingView.swift
//  Brrow
//
//  Complete booking interface with calendar and availability
//

import SwiftUI

struct BookingView: View {
    let listing: Listing

    @StateObject private var bookingService = BookingService.shared
    @State private var selectedStartDate: Date?
    @State private var selectedEndDate: Date?
    @State private var currentMonth = Date()
    @State private var showingBookingConfirmation = false
    @State private var showingSpecialRequests = false
    @State private var specialRequests = ""
    @State private var pickupTime = Date()
    @State private var dropoffTime = Date()
    @State private var isLoading = false
    @State private var errorMessage: String?

    private var isBookingValid: Bool {
        selectedStartDate != nil && selectedEndDate != nil &&
        selectedStartDate! < selectedEndDate! &&
        daysBetween >= minimumStay
    }

    private var daysBetween: Int {
        guard let start = selectedStartDate, let end = selectedEndDate else { return 0 }
        return Calendar.current.dateComponents([.day], from: start, to: end).day ?? 0
    }

    private var minimumStay: Int {
        bookingService.getMinimumStay(for: listing.id)
    }

    private var totalPrice: Double {
        guard let start = selectedStartDate, let end = selectedEndDate else { return 0 }
        return bookingService.calculateTotalPrice(for: listing.id, startDate: start, endDate: end)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                bookingHeaderView

                // Calendar
                calendarView

                // Date Selection Summary
                if selectedStartDate != nil || selectedEndDate != nil {
                    dateSelectionView
                }

                // Pricing Breakdown
                if isBookingValid {
                    pricingBreakdownView
                }

                // Special Requests
                specialRequestsView

                // Pickup/Dropoff Times
                timeSelectionView

                // Book Button
                bookButtonView
            }
            .padding()
        }
        .navigationTitle("Book \(listing.title)")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadCalendar()
        }
        .sheet(isPresented: $showingBookingConfirmation) {
            BookingConfirmationView(
                listing: listing,
                startDate: selectedStartDate ?? Date(),
                endDate: selectedEndDate ?? Date(),
                totalPrice: totalPrice,
                specialRequests: specialRequests,
                pickupTime: pickupTime,
                dropoffTime: dropoffTime
            )
        }
        .alert("Error", isPresented: .constant(errorMessage != nil)) {
            Button("OK") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private var bookingHeaderView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                AsyncImage(url: URL(string: listing.images.first?.url ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Color(.systemGray5))
                }
                .frame(width: 80, height: 80)
                .cornerRadius(12)

                VStack(alignment: .leading, spacing: 4) {
                    Text(listing.title)
                        .font(.headline)
                        .fontWeight(.semibold)

                    Text(listing.location.city)
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    HStack {
                        Text("$\(Int(listing.dailyRate ?? listing.price))")
                            .font(.title3)
                            .fontWeight(.bold)
                        Text("per day")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()
            }

            Text("Select your rental dates")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    private var calendarView: some View {
        VStack(spacing: 16) {
            // Month Navigation
            HStack {
                Button {
                    currentMonth = Calendar.current.date(byAdding: .month, value: -1, to: currentMonth) ?? currentMonth
                    Task { await loadCalendar() }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.title2)
                        .foregroundColor(.blue)
                }

                Spacer()

                Text(currentMonth, formatter: monthYearFormatter)
                    .font(.title2)
                    .fontWeight(.semibold)

                Spacer()

                Button {
                    currentMonth = Calendar.current.date(byAdding: .month, value: 1, to: currentMonth) ?? currentMonth
                    Task { await loadCalendar() }
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal)

            // Days of Week Header
            HStack {
                ForEach(["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"], id: \.self) { day in
                    Text(day)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }

            // Calendar Grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                ForEach(bookingService.calendarDays) { day in
                    CalendarDayView(
                        day: day,
                        selectedStartDate: selectedStartDate,
                        selectedEndDate: selectedEndDate,
                        isInRange: isDateInRange(day.date)
                    ) {
                        handleDateSelection(day.date)
                    }
                }
            }
            .padding(.horizontal)

            // Legend
            calendarLegendView
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }

    private var calendarLegendView: some View {
        HStack(spacing: 16) {
            LegendItem(color: .green, text: "Available")
            LegendItem(color: .red, text: "Booked")
            LegendItem(color: .gray, text: "Blocked")
            LegendItem(color: .blue, text: "Selected")
        }
        .font(.caption)
    }

    private var dateSelectionView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Selected Dates")
                .font(.headline)

            HStack {
                DateSelectionCard(
                    title: "Check-in",
                    date: selectedStartDate,
                    action: { clearStartDate() }
                )

                Image(systemName: "arrow.right")
                    .foregroundColor(.secondary)

                DateSelectionCard(
                    title: "Check-out",
                    date: selectedEndDate,
                    action: { clearEndDate() }
                )
            }

            if daysBetween > 0 {
                Text("\(daysBetween) day\(daysBetween == 1 ? "" : "s")")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            if daysBetween < minimumStay && daysBetween > 0 {
                Text("Minimum stay: \(minimumStay) day\(minimumStay == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    private var pricingBreakdownView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Price Breakdown")
                .font(.headline)

            let dailyRate = listing.dailyRate ?? listing.price
            let subtotal = dailyRate * Double(daysBetween)
            let platformFee = subtotal * 0.03
            let protectionFee = subtotal * 0.10

            PriceRow(label: "$\(Int(dailyRate)) × \(daysBetween) day\(daysBetween == 1 ? "" : "s")", amount: subtotal)
            PriceRow(label: "Platform fee", amount: platformFee)
            PriceRow(label: "Brrow Protection", amount: protectionFee)

            Divider()

            HStack {
                Text("Total")
                    .font(.headline)
                    .fontWeight(.bold)
                Spacer()
                Text("$\(Int(totalPrice))")
                    .font(.headline)
                    .fontWeight(.bold)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }

    private var specialRequestsView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Special Requests")
                    .font(.headline)
                Spacer()
                Button("Add") {
                    showingSpecialRequests = true
                }
                .font(.subheadline)
                .foregroundColor(.blue)
            }

            if !specialRequests.isEmpty {
                Text(specialRequests)
                    .font(.subheadline)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
            } else {
                Text("No special requests")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .sheet(isPresented: $showingSpecialRequests) {
            SpecialRequestsView(requests: $specialRequests)
        }
    }

    private var timeSelectionView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Pickup & Dropoff Times")
                .font(.headline)

            HStack {
                VStack(alignment: .leading) {
                    Text("Pickup Time")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    DatePicker("", selection: $pickupTime, displayedComponents: .hourAndMinute)
                        .labelsHidden()
                }

                Spacer()

                VStack(alignment: .leading) {
                    Text("Dropoff Time")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    DatePicker("", selection: $dropoffTime, displayedComponents: .hourAndMinute)
                        .labelsHidden()
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }

    private var bookButtonView: some View {
        VStack(spacing: 12) {
            Button {
                if isBookingValid {
                    showingBookingConfirmation = true
                }
            } label: {
                Text(isBookingValid ? "Continue to Booking" : "Select dates to continue")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isBookingValid ? Color.blue : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .font(.headline)
            }
            .disabled(!isBookingValid)

            Text("You won't be charged until your request is accepted")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Helper Methods

    private func loadCalendar() async {
        do {
            let _ = try await bookingService.fetchAvailability(for: listing.id, month: currentMonth)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func handleDateSelection(_ date: Date) {
        if selectedStartDate == nil {
            selectedStartDate = date
        } else if selectedEndDate == nil && date > selectedStartDate! {
            selectedEndDate = date
        } else {
            // Reset selection
            selectedStartDate = date
            selectedEndDate = nil
        }
    }

    private func clearStartDate() {
        selectedStartDate = nil
        selectedEndDate = nil
    }

    private func clearEndDate() {
        selectedEndDate = nil
    }

    private func isDateInRange(_ date: Date) -> Bool {
        guard let start = selectedStartDate else { return false }
        if let end = selectedEndDate {
            return date >= start && date <= end
        }
        return date == start
    }

    private var monthYearFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }
}

// MARK: - Supporting Views

struct CalendarDayView: View {
    let day: CalendarDay
    let selectedStartDate: Date?
    let selectedEndDate: Date?
    let isInRange: Bool
    let action: () -> Void

    private var isSelected: Bool {
        if let start = selectedStartDate, Calendar.current.isDate(day.date, inSameDayAs: start) {
            return true
        }
        if let end = selectedEndDate, Calendar.current.isDate(day.date, inSameDayAs: end) {
            return true
        }
        return false
    }

    private var backgroundColor: Color {
        if isSelected { return .blue }
        if isInRange { return .blue.opacity(0.2) }

        switch day.status {
        case .available: return .clear
        case .booked: return .red.opacity(0.1)
        case .blocked: return .gray.opacity(0.1)
        case .unavailable: return .clear
        }
    }

    private var textColor: Color {
        if isSelected { return .white }

        switch day.status {
        case .available: return .primary
        case .booked: return .red
        case .blocked: return .gray
        case .unavailable: return .gray.opacity(0.5)
        }
    }

    var body: some View {
        Button(action: day.status == .available ? action : {}) {
            VStack(spacing: 2) {
                Text("\(Calendar.current.component(.day, from: day.date))")
                    .font(.subheadline)
                    .fontWeight(isSelected ? .bold : .regular)
                    .foregroundColor(textColor)

                if let price = day.price, day.status == .available {
                    Text("$\(Int(price))")
                        .font(.caption2)
                        .foregroundColor(isSelected ? .white : .secondary)
                }
            }
            .frame(height: 44)
            .frame(maxWidth: .infinity)
            .background(backgroundColor)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
        .disabled(day.status != .available)
    }
}

struct LegendItem: View {
    let color: Color
    let text: String

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(text)
        }
    }
}

struct DateSelectionCard: View {
    let title: String
    let date: Date?
    let action: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    if let date = date {
                        Text(date, format: .dateTime.month(.abbreviated).day())
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Text(date, format: .dateTime.weekday(.wide))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Text("Select date")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                if date != nil {
                    Button(action: action) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }
}

struct PriceRow: View {
    let label: String
    let amount: Double

    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
            Spacer()
            Text("$\(Int(amount))")
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }
}

// MARK: - Preview

struct BookingView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            BookingView(listing: Listing.example
)
        }
    }
}