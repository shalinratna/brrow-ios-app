//
//  BookingModels.swift
//  Brrow
//
//  Complete booking and calendar system models
//

import Foundation

// MARK: - Booking Models

struct Booking: Codable, Identifiable {
    let id: String
    let bookerId: String
    let ownerId: String
    let listingId: String
    let startDate: String
    let endDate: String
    let totalAmount: Double
    let platformFee: Double
    let brrowProtectionFee: Double
    let status: GeneralBookingStatus
    let bookingType: BookingType
    let specialRequests: String?
    let pickupLocation: Location?
    let dropoffLocation: Location?
    let pickupTime: String?
    let dropoffTime: String?
    let isInstantBook: Bool
    let requiresApproval: Bool
    let cancellationPolicy: CancellationPolicy
    let createdAt: String
    let updatedAt: String
    let confirmedAt: String?
    let cancelledAt: String?
    let cancellationReason: String?

    // Populated relations
    let booker: BookingUser?
    let owner: BookingUser?
    let listing: BookingListing?
    let payments: [BookingPayment]?
    let messages: [BookingMessage]?
    let reviews: [BookingReview]?

    enum CodingKeys: String, CodingKey {
        case id, bookerId, ownerId, listingId
        case startDate, endDate, totalAmount, platformFee, brrowProtectionFee
        case status, bookingType, specialRequests
        case pickupLocation, dropoffLocation, pickupTime, dropoffTime
        case isInstantBook, requiresApproval, cancellationPolicy
        case createdAt, updatedAt, confirmedAt, cancelledAt, cancellationReason
        case booker, owner, listing, payments, messages, reviews
    }
}

enum GeneralBookingStatus: String, Codable, CaseIterable {
    case pending = "PENDING"
    case confirmed = "CONFIRMED"
    case active = "ACTIVE"
    case completed = "COMPLETED"
    case cancelled = "CANCELLED"
    case declined = "DECLINED"
    case expired = "EXPIRED"

    var displayName: String {
        switch self {
        case .pending: return "Pending Approval"
        case .confirmed: return "Confirmed"
        case .active: return "Active"
        case .completed: return "Completed"
        case .cancelled: return "Cancelled"
        case .declined: return "Declined"
        case .expired: return "Expired"
        }
    }

    var color: String {
        switch self {
        case .pending: return "orange"
        case .confirmed: return "blue"
        case .active: return "green"
        case .completed: return "gray"
        case .cancelled, .declined, .expired: return "red"
        }
    }

    var icon: String {
        switch self {
        case .pending: return "clock.fill"
        case .confirmed: return "checkmark.circle.fill"
        case .active: return "play.circle.fill"
        case .completed: return "flag.checkered"
        case .cancelled: return "xmark.circle.fill"
        case .declined: return "hand.raised.fill"
        case .expired: return "timer"
        }
    }
}

enum BookingType: String, Codable {
    case rental = "RENTAL"
    case purchase = "PURCHASE"
    case service = "SERVICE"

    var displayName: String {
        switch self {
        case .rental: return "Rental"
        case .purchase: return "Purchase"
        case .service: return "Service"
        }
    }
}

enum CancellationPolicy: String, Codable {
    case flexible = "FLEXIBLE"
    case moderate = "MODERATE"
    case strict = "STRICT"

    var displayName: String {
        switch self {
        case .flexible: return "Flexible"
        case .moderate: return "Moderate"
        case .strict: return "Strict"
        }
    }

    var description: String {
        switch self {
        case .flexible:
            return "Free cancellation up to 24 hours before pickup"
        case .moderate:
            return "Free cancellation up to 48 hours before pickup"
        case .strict:
            return "Free cancellation up to 7 days before pickup"
        }
    }

    var refundPercentage: Double {
        switch self {
        case .flexible: return 1.0
        case .moderate: return 0.5
        case .strict: return 0.0
        }
    }
}

// MARK: - Calendar & Availability

struct CalendarDay: Identifiable {
    let id = UUID()
    let date: Date
    var isAvailable: Bool
    var isBooked: Bool
    var isBlocked: Bool
    var price: Double?
    var bookings: [Booking]
    var specialNote: String?

    var status: DayStatus {
        if isBlocked { return .blocked }
        if isBooked { return .booked }
        if isAvailable { return .available }
        return .unavailable
    }

    enum DayStatus {
        case available
        case booked
        case blocked
        case unavailable

        var color: String {
            switch self {
            case .available: return "green"
            case .booked: return "red"
            case .blocked: return "gray"
            case .unavailable: return "lightgray"
            }
        }
    }
}

struct AvailabilityWindow: Codable, Identifiable {
    let id: String
    let listingId: String
    let startDate: String
    let endDate: String
    let isAvailable: Bool
    let price: Double?
    let minimumStay: Int
    let maximumStay: Int?
    let notes: String?
    let createdAt: String
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case id, listingId, startDate, endDate
        case isAvailable, price, minimumStay, maximumStay
        case notes, createdAt, updatedAt
    }
}

struct BlockedDate: Codable, Identifiable {
    let id: String
    let listingId: String
    let startDate: String
    let endDate: String
    let reason: String
    let notes: String?
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case id, listingId, startDate, endDate
        case reason, notes, createdAt
    }
}

// MARK: - Booking Components

struct BookingUser: Codable {
    let id: String
    let name: String
    let profileImageUrl: String?
    let averageRating: Double?
    let totalReviews: Int?
    let isVerified: Bool
    let responseRate: Double?
    let responseTime: String?

    enum CodingKeys: String, CodingKey {
        case id, name, profileImageUrl
        case averageRating, totalReviews, isVerified
        case responseRate, responseTime
    }
}

struct BookingListing: Codable {
    let id: String
    let title: String
    let description: String?
    let price: Double
    let images: [BookingListingImage]
    let category: BookingCategory?
    let location: Location
    let policies: ListingPolicies?

    struct BookingListingImage: Codable {
        let id: String
        let url: String
        let isPrimary: Bool
    }

    struct BookingCategory: Codable {
        let id: String
        let name: String
        let icon: String?
    }

    struct ListingPolicies: Codable {
        let cancellationPolicy: CancellationPolicy
        let housePules: [String]?
        let checkInInstructions: String?
        let additionalInfo: String?
    }
}

struct BookingPayment: Codable, Identifiable {
    let id: String
    let bookingId: String
    let amount: Double
    let paymentType: PaymentType
    let status: PaymentStatus
    let processedAt: String?
    let refundedAt: String?
    let failureReason: String?

    enum PaymentType: String, Codable {
        case deposit = "DEPOSIT"
        case full = "FULL"
        case refund = "REFUND"
        case fee = "FEE"
    }

    enum PaymentStatus: String, Codable {
        case pending = "PENDING"
        case completed = "COMPLETED"
        case failed = "FAILED"
        case refunded = "REFUNDED"
    }
}

struct BookingMessage: Codable, Identifiable {
    let id: String
    let bookingId: String
    let senderId: String
    let content: String
    let messageType: MessageType
    let createdAt: String

    enum MessageType: String, Codable {
        case text = "TEXT"
        case system = "SYSTEM"
        case automated = "AUTOMATED"
    }
}

struct BookingReview: Codable, Identifiable {
    let id: String
    let bookingId: String
    let reviewerId: String
    let revieweeId: String
    let rating: Int
    let comment: String?
    let reviewType: String
    let createdAt: String
}

// MARK: - API Request/Response Models

struct CreateBookingRequest: Codable {
    let listingId: String
    let startDate: String
    let endDate: String
    let specialRequests: String?
    let pickupLocation: Location?
    let dropoffLocation: Location?
    let pickupTime: String?
    let dropoffTime: String?
    let totalGuests: Int?
    let agreedToTerms: Bool

    enum CodingKeys: String, CodingKey {
        case listingId, startDate, endDate, specialRequests
        case pickupLocation, dropoffLocation, pickupTime, dropoffTime
        case totalGuests, agreedToTerms
    }
}

struct UpdateBookingRequest: Codable {
    let status: GeneralBookingStatus?
    let startDate: String?
    let endDate: String?
    let specialRequests: String?
    let pickupTime: String?
    let dropoffTime: String?
    let cancellationReason: String?

    enum CodingKeys: String, CodingKey {
        case status, startDate, endDate, specialRequests
        case pickupTime, dropoffTime, cancellationReason
    }
}

struct BookingResponse: Codable {
    let success: Bool
    let data: Booking?
    let message: String?
}

struct BookingsResponse: Codable {
    let success: Bool
    let data: BookingsData?
    let message: String?

    struct BookingsData: Codable {
        let bookings: [Booking]
        let pagination: PaginationInfo?
        let summary: BookingSummary?
    }
}

struct BookingSummary: Codable {
    let totalBookings: Int
    let activeBookings: Int
    let completedBookings: Int
    let totalEarnings: Double
    let averageRating: Double?
    let responseRate: Double?

    enum CodingKeys: String, CodingKey {
        case totalBookings, activeBookings, completedBookings
        case totalEarnings, averageRating, responseRate
    }
}

struct AvailabilityResponse: Codable {
    let success: Bool
    let data: AvailabilityData?
    let message: String?

    struct AvailabilityData: Codable {
        let listingId: String
        let availableWindows: [AvailabilityWindow]
        let blockedDates: [BlockedDate]
        let existingBookings: [Booking]
        let calendar: [CalendarEntry]

        struct CalendarEntry: Codable {
            let date: String
            let isAvailable: Bool
            let price: Double?
            let minimumStay: Int?
        }
    }
}

struct UpdateAvailabilityRequest: Codable {
    let listingId: String
    let availabilityWindows: [AvailabilityWindowInput]
    let blockedDates: [BlockedDateInput]

    struct AvailabilityWindowInput: Codable {
        let startDate: String
        let endDate: String
        let isAvailable: Bool
        let price: Double?
        let minimumStay: Int
        let maximumStay: Int?
    }

    struct BlockedDateInput: Codable {
        let startDate: String
        let endDate: String
        let reason: String
        let notes: String?
    }
}

// MARK: - Booking Filters & Search

struct BookingFilters: Codable {
    var status: GeneralBookingStatus?
    var bookingType: BookingType?
    var dateRange: DateRange?
    var userId: String?
    var listingId: String?
    var sortBy: BookingSortOption
    var sortOrder: SortOrder

    struct DateRange: Codable {
        let startDate: String
        let endDate: String
    }
}

enum BookingSortOption: String, Codable, CaseIterable {
    case newest = "NEWEST"
    case oldest = "OLDEST"
    case startDate = "START_DATE"
    case endDate = "END_DATE"
    case amount = "AMOUNT"
    case status = "STATUS"

    var displayName: String {
        switch self {
        case .newest: return "Newest First"
        case .oldest: return "Oldest First"
        case .startDate: return "Start Date"
        case .endDate: return "End Date"
        case .amount: return "Amount"
        case .status: return "Status"
        }
    }
}

// MARK: - Calendar Utilities

extension CalendarDay {
    static func generateCalendar(for month: Date,
                                 availability: [AvailabilityWindow] = [],
                                 bookings: [Booking] = [],
                                 blockedDates: [BlockedDate] = []) -> [CalendarDay] {
        let calendar = Calendar.current
        let startOfMonth = calendar.dateInterval(of: .month, for: month)?.start ?? month
        let range = calendar.range(of: .day, in: .month, for: month) ?? 1..<32

        return range.compactMap { day in
            guard let date = calendar.date(byAdding: .day, value: day - 1, to: startOfMonth) else {
                return nil
            }

            let dayBookings = bookings.filter { booking in
                // Check if date falls within booking period
                let formatter = ISO8601DateFormatter()
                guard let startDate = formatter.date(from: booking.startDate),
                      let endDate = formatter.date(from: booking.endDate) else {
                    return false
                }
                return date >= startDate && date <= endDate
            }

            let isBlocked = blockedDates.contains { blockedDate in
                let formatter = ISO8601DateFormatter()
                guard let startDate = formatter.date(from: blockedDate.startDate),
                      let endDate = formatter.date(from: blockedDate.endDate) else {
                    return false
                }
                return date >= startDate && date <= endDate
            }

            let isBooked = !dayBookings.isEmpty
            let isAvailable = availability.contains { window in
                let formatter = ISO8601DateFormatter()
                guard let startDate = formatter.date(from: window.startDate),
                      let endDate = formatter.date(from: window.endDate) else {
                    return false
                }
                return window.isAvailable && date >= startDate && date <= endDate
            }

            return CalendarDay(
                date: date,
                isAvailable: isAvailable && !isBlocked,
                isBooked: isBooked,
                isBlocked: isBlocked,
                price: availability.first?.price,
                bookings: dayBookings,
                specialNote: nil
            )
        }
    }
}