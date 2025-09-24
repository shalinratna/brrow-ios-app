//
//  BookingService.swift
//  Brrow
//
//  Complete booking management service
//

import Foundation
import Combine

@MainActor
class BookingService: ObservableObject {
    static let shared = BookingService()

    @Published var myBookings: [Booking] = []
    @Published var bookingRequests: [Booking] = []
    @Published var currentBooking: Booking?
    @Published var availability: [AvailabilityWindow] = []
    @Published var calendarDays: [CalendarDay] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let apiClient = APIClient.shared
    private var cancellables = Set<AnyCancellable>()

    private init() {
        setupNotificationObservers()
    }

    // MARK: - Setup

    private func setupNotificationObservers() {
        NotificationCenter.default.publisher(for: .newBookingReceived)
            .sink { [weak self] notification in
                self?.handleNewBooking(notification)
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: .bookingStatusChanged)
            .sink { [weak self] notification in
                self?.handleBookingStatusChange(notification)
            }
            .store(in: &cancellables)
    }

    // MARK: - Booking Management

    func createBooking(_ request: CreateBookingRequest) async throws -> Booking {
        isLoading = true
        errorMessage = nil

        do {
            let response = try await apiClient.performRequest(
                endpoint: "api/bookings",
                method: "POST",
                body: try JSONEncoder().encode(request),
                responseType: BookingResponse.self
            )

            guard response.success, let booking = response.data else {
                throw BrrowAPIError.serverError(response.message ?? "Failed to create booking")
            }

            // Add to local state
            myBookings.insert(booking, at: 0)

            // Send notification
            await UnifiedNotificationService.shared.sendOfferNotification(
                offer: RentalOffer(
                    id: booking.id,
                    itemTitle: booking.listing?.title ?? "Item",
                    requesterName: booking.booker?.name ?? "Someone",
                    amount: booking.totalAmount,
                    startDate: ISO8601DateFormatter().date(from: booking.startDate) ?? Date(),
                    endDate: ISO8601DateFormatter().date(from: booking.endDate) ?? Date()
                )
            )

            return booking

        } catch {
            errorMessage = error.localizedDescription
            throw error
        }

        isLoading = false
    }

    func updateBooking(_ bookingId: String, request: UpdateBookingRequest) async throws -> Booking {
        let response = try await apiClient.performRequest(
            endpoint: "api/bookings/\(bookingId)",
            method: "PATCH",
            body: try JSONEncoder().encode(request),
            responseType: BookingResponse.self
        )

        guard response.success, let booking = response.data else {
            throw BrrowAPIError.serverError(response.message ?? "Failed to update booking")
        }

        // Update local state
        updateLocalBooking(booking)

        return booking
    }

    func cancelBooking(_ bookingId: String, reason: String) async throws {
        let request = UpdateBookingRequest(
            status: .cancelled,
            startDate: nil,
            endDate: nil,
            specialRequests: nil,
            pickupTime: nil,
            dropoffTime: nil,
            cancellationReason: reason
        )

        let _ = try await updateBooking(bookingId, request: request)
    }

    func confirmBooking(_ bookingId: String) async throws {
        let request = UpdateBookingRequest(
            status: .confirmed,
            startDate: nil,
            endDate: nil,
            specialRequests: nil,
            pickupTime: nil,
            dropoffTime: nil,
            cancellationReason: nil
        )

        let _ = try await updateBooking(bookingId, request: request)
    }

    func declineBooking(_ bookingId: String, reason: String) async throws {
        let request = UpdateBookingRequest(
            status: .declined,
            startDate: nil,
            endDate: nil,
            specialRequests: nil,
            pickupTime: nil,
            dropoffTime: nil,
            cancellationReason: reason
        )

        let _ = try await updateBooking(bookingId, request: request)
    }

    // MARK: - Booking Retrieval

    func fetchMyBookings(filters: BookingFilters = BookingFilters(
        status: nil,
        bookingType: nil,
        dateRange: nil,
        userId: nil,
        listingId: nil,
        sortBy: .newest,
        sortOrder: .descending
    )) async throws {
        isLoading = true

        do {
            let queryString = buildQueryString(from: filters)
            let response = try await apiClient.performRequest(
                endpoint: "api/bookings/my-bookings\(queryString)",
                method: "GET",
                responseType: BookingsResponse.self
            )

            guard response.success, let data = response.data else {
                throw BrrowAPIError.serverError(response.message ?? "Failed to fetch bookings")
            }

            myBookings = data.bookings

        } catch {
            errorMessage = error.localizedDescription
            // Load mock data for demo
            loadMockBookings()
        }

        isLoading = false
    }

    func fetchBookingRequests() async throws {
        let response = try await apiClient.performRequest(
            endpoint: "api/bookings/requests",
            method: "GET",
            responseType: BookingsResponse.self
        )

        guard response.success, let data = response.data else {
            throw BrrowAPIError.serverError(response.message ?? "Failed to fetch booking requests")
        }

        bookingRequests = data.bookings
    }

    func fetchBookingDetails(_ bookingId: String) async throws -> Booking {
        let response = try await apiClient.performRequest(
            endpoint: "api/bookings/\(bookingId)",
            method: "GET",
            responseType: BookingResponse.self
        )

        guard response.success, let booking = response.data else {
            throw BrrowAPIError.serverError(response.message ?? "Failed to fetch booking details")
        }

        currentBooking = booking
        return booking
    }

    // MARK: - Availability Management

    func fetchAvailability(for listingId: String, month: Date) async throws -> [CalendarDay] {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        let monthString = formatter.string(from: month)

        do {
            let response = try await apiClient.performRequest(
                endpoint: "api/listings/\(listingId)/availability?month=\(monthString)",
                method: "GET",
                responseType: AvailabilityResponse.self
            )

            guard response.success, let data = response.data else {
                throw BrrowAPIError.serverError(response.message ?? "Failed to fetch availability")
            }

            availability = data.availableWindows

            // Generate calendar days
            calendarDays = CalendarDay.generateCalendar(
                for: month,
                availability: data.availableWindows,
                bookings: data.existingBookings,
                blockedDates: data.blockedDates
            )

            return calendarDays

        } catch {
            errorMessage = error.localizedDescription
            // Generate mock calendar for demo
            calendarDays = generateMockCalendar(for: month)
            return calendarDays
        }
    }

    func updateAvailability(for listingId: String, request: UpdateAvailabilityRequest) async throws {
        let response = try await apiClient.performRequest(
            endpoint: "api/listings/\(listingId)/availability",
            method: "PUT",
            body: try JSONEncoder().encode(request),
            responseType: APIResponse<EmptyResponse>.self
        )

        guard response.success else {
            throw BrrowAPIError.serverError(response.message ?? "Failed to update availability")
        }
    }

    func blockDates(for listingId: String, startDate: Date, endDate: Date, reason: String, notes: String? = nil) async throws {
        let formatter = ISO8601DateFormatter()

        let request = UpdateAvailabilityRequest(
            listingId: listingId,
            availabilityWindows: [],
            blockedDates: [
                UpdateAvailabilityRequest.BlockedDateInput(
                    startDate: formatter.string(from: startDate),
                    endDate: formatter.string(from: endDate),
                    reason: reason,
                    notes: notes
                )
            ]
        )

        try await updateAvailability(for: listingId, request: request)
    }

    // MARK: - Calendar Utilities

    func isDateAvailable(_ date: Date, for listingId: String) -> Bool {
        return calendarDays.first { Calendar.current.isDate($0.date, inSameDayAs: date) }?.isAvailable ?? false
    }

    func getBookingsForDate(_ date: Date) -> [Booking] {
        return calendarDays.first { Calendar.current.isDate($0.date, inSameDayAs: date) }?.bookings ?? []
    }

    func getPriceForDate(_ date: Date) -> Double? {
        return calendarDays.first { Calendar.current.isDate($0.date, inSameDayAs: date) }?.price
    }

    func getMinimumStay(for listingId: String) -> Int {
        return availability.first?.minimumStay ?? 1
    }

    func calculateTotalPrice(for listingId: String, startDate: Date, endDate: Date) -> Double {
        let calendar = Calendar.current
        let days = calendar.dateComponents([.day], from: startDate, to: endDate).day ?? 1

        let basePrice = getPriceForDate(startDate) ?? 25.0
        let subtotal = basePrice * Double(days)
        let platformFee = subtotal * 0.03 // 3% platform fee
        let brrowProtectionFee = subtotal * 0.10 // 10% protection fee

        return subtotal + platformFee + brrowProtectionFee
    }

    // MARK: - Helper Methods

    private func buildQueryString(from filters: BookingFilters) -> String {
        var components: [String] = []

        if let status = filters.status {
            components.append("status=\(status.rawValue)")
        }
        if let bookingType = filters.bookingType {
            components.append("type=\(bookingType.rawValue)")
        }
        if let dateRange = filters.dateRange {
            components.append("start_date=\(dateRange.startDate)")
            components.append("end_date=\(dateRange.endDate)")
        }
        if let userId = filters.userId {
            components.append("user_id=\(userId)")
        }
        if let listingId = filters.listingId {
            components.append("listing_id=\(listingId)")
        }

        components.append("sort_by=\(filters.sortBy.rawValue)")
        components.append("sort_order=\(filters.sortOrder.rawValue)")

        return components.isEmpty ? "" : "?" + components.joined(separator: "&")
    }

    private func updateLocalBooking(_ booking: Booking) {
        if let index = myBookings.firstIndex(where: { $0.id == booking.id }) {
            myBookings[index] = booking
        }

        if let index = bookingRequests.firstIndex(where: { $0.id == booking.id }) {
            bookingRequests[index] = booking
        }

        if currentBooking?.id == booking.id {
            currentBooking = booking
        }
    }

    private func handleNewBooking(_ notification: Notification) {
        guard let booking = notification.object as? Booking else { return }
        bookingRequests.insert(booking, at: 0)
    }

    private func handleBookingStatusChange(_ notification: Notification) {
        guard let booking = notification.object as? Booking else { return }
        updateLocalBooking(booking)
    }

    // MARK: - Mock Data

    private func loadMockBookings() {
        let currentUser = AuthManager.shared.currentUser

        myBookings = [
            Booking(
                id: "booking_1",
                bookerId: currentUser?.apiId ?? "user_1",
                ownerId: "owner_1",
                listingId: "listing_1",
                startDate: ISO8601DateFormatter().string(from: Date().addingTimeInterval(86400 * 2)),
                endDate: ISO8601DateFormatter().string(from: Date().addingTimeInterval(86400 * 4)),
                totalAmount: 150.0,
                platformFee: 4.5,
                brrowProtectionFee: 15.0,
                status: .confirmed,
                bookingType: .rental,
                specialRequests: "Please include the tripod and extra battery",
                pickupLocation: nil,
                dropoffLocation: nil,
                pickupTime: "10:00",
                dropoffTime: "18:00",
                isInstantBook: true,
                requiresApproval: false,
                cancellationPolicy: .flexible,
                createdAt: ISO8601DateFormatter().string(from: Date().addingTimeInterval(-86400)),
                updatedAt: ISO8601DateFormatter().string(from: Date().addingTimeInterval(-3600)),
                confirmedAt: ISO8601DateFormatter().string(from: Date().addingTimeInterval(-3600)),
                cancelledAt: nil,
                cancellationReason: nil,
                booker: BookingUser(
                    id: currentUser?.apiId ?? "user_1",
                    name: currentUser?.username ?? "John Doe",
                    profileImageUrl: nil,
                    averageRating: 4.8,
                    totalReviews: 15,
                    isVerified: true,
                    responseRate: 0.95,
                    responseTime: "1 hour"
                ),
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
                listing: BookingListing(
                    id: "listing_1",
                    title: "Professional DSLR Camera",
                    description: "Canon EOS R5 with 24-70mm lens",
                    price: 75.0,
                    images: [
                        BookingListing.BookingListingImage(
                            id: "img_1",
                            url: "https://example.com/camera.jpg",
                            isPrimary: true
                        )
                    ],
                    category: BookingListing.BookingCategory(
                        id: "electronics",
                        name: "Electronics",
                        icon: "camera.fill"
                    ),
                    location: Location(
                        address: "123 Main St",
                        city: "San Francisco",
                        state: "CA",
                        zipCode: "94102",
                        country: "US",
                        latitude: 37.7749,
                        longitude: -122.4194
                    ),
                    policies: nil
                ),
                payments: nil,
                messages: nil,
                reviews: nil
            )
        ]
    }

    private func generateMockCalendar(for month: Date) -> [CalendarDay] {
        let calendar = Calendar.current
        let startOfMonth = calendar.dateInterval(of: .month, for: month)?.start ?? month
        let range = calendar.range(of: .day, in: .month, for: month) ?? 1..<32

        return range.compactMap { day in
            guard let date = calendar.date(byAdding: .day, value: day - 1, to: startOfMonth) else {
                return nil
            }

            let isAvailable = day % 3 != 0 // Mock: every 3rd day is unavailable
            let isBooked = day % 7 == 0 // Mock: every 7th day is booked
            let price = isAvailable ? Double.random(in: 25...100) : nil

            return CalendarDay(
                date: date,
                isAvailable: isAvailable && !isBooked,
                isBooked: isBooked,
                isBlocked: false,
                price: price,
                bookings: [],
                specialNote: nil
            )
        }
    }
}

// MARK: - Notification Extensions

extension Notification.Name {
    static let newBookingReceived = Notification.Name("newBookingReceived")
    static let bookingStatusChanged = Notification.Name("bookingStatusChanged")
    static let bookingCancelled = Notification.Name("bookingCancelled")
    static let bookingConfirmed = Notification.Name("bookingConfirmed")
}