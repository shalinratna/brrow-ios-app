//
//  RentalBooking.swift
//  Brrow
//
//  Created by Claude on 1/14/25.
//

import Foundation

// MARK: - Booking Status
enum BookingStatus: String, Codable {
    case pending = "PENDING"
    case confirmed = "CONFIRMED"
    case readyForPickup = "READY_FOR_PICKUP"
    case inProgress = "IN_PROGRESS"
    case active = "ACTIVE"
    case readyForReturn = "READY_FOR_RETURN"
    case returned = "RETURNED"
    case pendingDamageReview = "PENDING_DAMAGE_REVIEW"
    case completed = "COMPLETED"
    case cancelled = "CANCELLED"
    case declined = "DECLINED"
    case expired = "EXPIRED"

    var displayName: String {
        switch self {
        case .pending: return "Pending"
        case .confirmed: return "Confirmed"
        case .readyForPickup: return "Ready for Pickup"
        case .inProgress: return "In Progress"
        case .active: return "Active"
        case .readyForReturn: return "Ready for Return"
        case .returned: return "Returned"
        case .pendingDamageReview: return "Pending Damage Review"
        case .completed: return "Completed"
        case .cancelled: return "Cancelled"
        case .declined: return "Declined"
        case .expired: return "Expired"
        }
    }

    var icon: String {
        switch self {
        case .pending: return "clock"
        case .confirmed: return "checkmark.circle"
        case .readyForPickup: return "shippingbox"
        case .inProgress, .active: return "hourglass"
        case .readyForReturn: return "arrow.uturn.backward"
        case .returned: return "checkmark.circle.fill"
        case .pendingDamageReview: return "exclamationmark.triangle"
        case .completed: return "checkmark.seal.fill"
        case .cancelled: return "xmark.circle"
        case .declined: return "hand.raised"
        case .expired: return "clock.badge.exclamationmark"
        }
    }

    var color: String {
        switch self {
        case .pending: return "orange"
        case .confirmed: return "blue"
        case .readyForPickup, .readyForReturn: return "purple"
        case .inProgress, .active: return "green"
        case .returned, .completed: return "green"
        case .pendingDamageReview: return "red"
        case .cancelled, .declined, .expired: return "gray"
        }
    }
}

// MARK: - Rental Booking Model
struct RentalBooking: Codable, Identifiable {
    let id: String
    let transactionId: String
    let listingId: String
    let renterId: String
    let ownerId: String
    let startDate: Date
    let endDate: Date
    let totalDays: Int
    let dailyRate: Double
    let subtotal: Double
    let platformFee: Double
    let brrowProtectionFee: Double
    let ownerInsuranceFee: Double
    let ownerOptedInsurance: Bool
    let totalAmount: Double
    let status: BookingStatus
    let bookingType: String
    let specialRequests: String?

    // Location details
    let pickupLocation: MeetupLocation?
    let dropoffLocation: MeetupLocation?
    let pickupTime: String?
    let dropoffTime: String?

    // Instant book settings
    let isInstantBook: Bool
    let requiresApproval: Bool
    let cancellationPolicy: String

    // Timestamps
    let confirmedAt: Date?
    let cancelledAt: Date?
    let cancellationReason: String?
    let completedAt: Date?
    let inspectionWindowEnd: Date?

    // Condition verification
    let preRentalConditionVerified: Bool
    let postRentalConditionVerified: Bool
    let preRentalPhotos: [String]?
    let postRentalPhotos: [String]?
    let actualPickupTime: Date?
    let actualReturnTime: Date?

    // Late return tracking
    let isLateReturn: Bool
    let lateFees: Double?
    let lateFeeCalculatedAt: Date?

    // Dates
    let createdAt: Date
    let updatedAt: Date

    // Relations
    let listing: Listing?
    let renter: User?
    let owner: User?
    let pickupMeetup: Meetup?
    let returnMeetup: Meetup?

    enum CodingKeys: String, CodingKey {
        case id
        case transactionId = "transaction_id"
        case listingId = "listing_id"
        case renterId = "renter_id"
        case ownerId = "owner_id"
        case startDate = "start_date"
        case endDate = "end_date"
        case totalDays = "total_days"
        case dailyRate = "daily_rate"
        case subtotal
        case platformFee = "platform_fee"
        case brrowProtectionFee = "brrow_protection_fee"
        case ownerInsuranceFee = "owner_insurance_fee"
        case ownerOptedInsurance = "owner_opted_insurance"
        case totalAmount = "total_amount"
        case status
        case bookingType = "booking_type"
        case specialRequests = "special_requests"
        case pickupLocation = "pickup_location"
        case dropoffLocation = "dropoff_location"
        case pickupTime = "pickup_time"
        case dropoffTime = "dropoff_time"
        case isInstantBook = "is_instant_book"
        case requiresApproval = "requires_approval"
        case cancellationPolicy = "cancellation_policy"
        case confirmedAt = "confirmed_at"
        case cancelledAt = "cancelled_at"
        case cancellationReason = "cancellation_reason"
        case completedAt = "completed_at"
        case inspectionWindowEnd = "inspection_window_end"
        case preRentalConditionVerified = "pre_rental_condition_verified"
        case postRentalConditionVerified = "post_rental_condition_verified"
        case preRentalPhotos = "pre_rental_photos"
        case postRentalPhotos = "post_rental_photos"
        case actualPickupTime = "actual_pickup_time"
        case actualReturnTime = "actual_return_time"
        case isLateReturn = "is_late_return"
        case lateFees = "late_fees"
        case lateFeeCalculatedAt = "late_fee_calculated_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case listing = "listings"
        case renter = "renters"
        case owner = "owners"
        case pickupMeetup, returnMeetup
    }

    // Custom decoding for dates and photos
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(String.self, forKey: .id)
        transactionId = try container.decode(String.self, forKey: .transactionId)
        listingId = try container.decode(String.self, forKey: .listingId)
        renterId = try container.decode(String.self, forKey: .renterId)
        ownerId = try container.decode(String.self, forKey: .ownerId)
        totalDays = try container.decode(Int.self, forKey: .totalDays)
        dailyRate = try container.decode(Double.self, forKey: .dailyRate)
        subtotal = try container.decode(Double.self, forKey: .subtotal)
        platformFee = try container.decode(Double.self, forKey: .platformFee)
        brrowProtectionFee = try container.decode(Double.self, forKey: .brrowProtectionFee)
        ownerInsuranceFee = try container.decode(Double.self, forKey: .ownerInsuranceFee)
        ownerOptedInsurance = try container.decode(Bool.self, forKey: .ownerOptedInsurance)
        totalAmount = try container.decode(Double.self, forKey: .totalAmount)
        status = try container.decode(BookingStatus.self, forKey: .status)
        bookingType = try container.decode(String.self, forKey: .bookingType)
        specialRequests = try container.decodeIfPresent(String.self, forKey: .specialRequests)
        pickupLocation = try container.decodeIfPresent(MeetupLocation.self, forKey: .pickupLocation)
        dropoffLocation = try container.decodeIfPresent(MeetupLocation.self, forKey: .dropoffLocation)
        pickupTime = try container.decodeIfPresent(String.self, forKey: .pickupTime)
        dropoffTime = try container.decodeIfPresent(String.self, forKey: .dropoffTime)
        isInstantBook = try container.decode(Bool.self, forKey: .isInstantBook)
        requiresApproval = try container.decode(Bool.self, forKey: .requiresApproval)
        cancellationPolicy = try container.decode(String.self, forKey: .cancellationPolicy)
        cancellationReason = try container.decodeIfPresent(String.self, forKey: .cancellationReason)
        preRentalConditionVerified = try container.decode(Bool.self, forKey: .preRentalConditionVerified)
        postRentalConditionVerified = try container.decode(Bool.self, forKey: .postRentalConditionVerified)
        isLateReturn = try container.decode(Bool.self, forKey: .isLateReturn)
        lateFees = try container.decodeIfPresent(Double.self, forKey: .lateFees)

        // Decode photo arrays (stored as JSON in database)
        if let prePhotosJson = try container.decodeIfPresent([String].self, forKey: .preRentalPhotos) {
            preRentalPhotos = prePhotosJson
        } else {
            preRentalPhotos = nil
        }

        if let postPhotosJson = try container.decodeIfPresent([String].self, forKey: .postRentalPhotos) {
            postRentalPhotos = postPhotosJson
        } else {
            postRentalPhotos = nil
        }

        // Relations
        listing = try container.decodeIfPresent(Listing.self, forKey: .listing)
        renter = try container.decodeIfPresent(User.self, forKey: .renter)
        owner = try container.decodeIfPresent(User.self, forKey: .owner)
        pickupMeetup = try container.decodeIfPresent(Meetup.self, forKey: .pickupMeetup)
        returnMeetup = try container.decodeIfPresent(Meetup.self, forKey: .returnMeetup)

        // Decode dates
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        // Date-only fields (no time component)
        let dateOnlyFormatter = DateFormatter()
        dateOnlyFormatter.dateFormat = "yyyy-MM-dd"

        if let startDateString = try container.decodeIfPresent(String.self, forKey: .startDate) {
            startDate = dateOnlyFormatter.date(from: startDateString) ?? Date()
        } else {
            startDate = Date()
        }

        if let endDateString = try container.decodeIfPresent(String.self, forKey: .endDate) {
            endDate = dateOnlyFormatter.date(from: endDateString) ?? Date()
        } else {
            endDate = Date()
        }

        // DateTime fields
        if let confirmedAtString = try container.decodeIfPresent(String.self, forKey: .confirmedAt) {
            confirmedAt = dateFormatter.date(from: confirmedAtString)
        } else {
            confirmedAt = nil
        }

        if let cancelledAtString = try container.decodeIfPresent(String.self, forKey: .cancelledAt) {
            cancelledAt = dateFormatter.date(from: cancelledAtString)
        } else {
            cancelledAt = nil
        }

        if let completedAtString = try container.decodeIfPresent(String.self, forKey: .completedAt) {
            completedAt = dateFormatter.date(from: completedAtString)
        } else {
            completedAt = nil
        }

        if let inspectionEndString = try container.decodeIfPresent(String.self, forKey: .inspectionWindowEnd) {
            inspectionWindowEnd = dateFormatter.date(from: inspectionEndString)
        } else {
            inspectionWindowEnd = nil
        }

        if let actualPickupString = try container.decodeIfPresent(String.self, forKey: .actualPickupTime) {
            actualPickupTime = dateFormatter.date(from: actualPickupString)
        } else {
            actualPickupTime = nil
        }

        if let actualReturnString = try container.decodeIfPresent(String.self, forKey: .actualReturnTime) {
            actualReturnTime = dateFormatter.date(from: actualReturnString)
        } else {
            actualReturnTime = nil
        }

        if let lateFeeCalcString = try container.decodeIfPresent(String.self, forKey: .lateFeeCalculatedAt) {
            lateFeeCalculatedAt = dateFormatter.date(from: lateFeeCalcString)
        } else {
            lateFeeCalculatedAt = nil
        }

        let createdAtString = try container.decode(String.self, forKey: .createdAt)
        createdAt = dateFormatter.date(from: createdAtString) ?? Date()

        let updatedAtString = try container.decode(String.self, forKey: .updatedAt)
        updatedAt = dateFormatter.date(from: updatedAtString) ?? Date()
    }

    // Helper computed properties
    var currentUserRole: String {
        guard let currentUserId = AuthManager.shared.currentUser?.id else { return "Unknown" }
        return currentUserId == renterId ? "Renter" : "Owner"
    }

    var isRenter: Bool {
        guard let currentUserId = AuthManager.shared.currentUser?.id else { return false }
        return currentUserId == renterId
    }

    var isOwner: Bool {
        guard let currentUserId = AuthManager.shared.currentUser?.id else { return false }
        return currentUserId == ownerId
    }

    var otherUser: User? {
        guard let currentUserId = AuthManager.shared.currentUser?.id else { return nil }
        if currentUserId == renterId {
            return owner
        } else {
            return renter
        }
    }

    var canSchedulePickup: Bool {
        status == .confirmed && pickupMeetup == nil
    }

    var canScheduleReturn: Bool {
        [.inProgress, .active, .readyForReturn].contains(status) && returnMeetup == nil
    }

    var rentalDuration: String {
        return "\(totalDays) day\(totalDays == 1 ? "" : "s")"
    }

    var totalCost: String {
        return String(format: "$%.2f", totalAmount)
    }

    var dailyRateDisplay: String {
        return String(format: "$%.2f/day", dailyRate)
    }
}

// MARK: - API Responses
struct RentalBookingResponse: Codable {
    let success: Bool
    let data: RentalBooking?
    let message: String?
}

struct RentalBookingsListResponse: Codable {
    let success: Bool
    let data: [RentalBooking]?
    let message: String?
}

struct BookingMeetupsResponse: Codable {
    let success: Bool
    let data: BookingMeetupsData?
    let message: String?
}

struct BookingMeetupsData: Codable {
    let pickupMeetup: Meetup?
    let returnMeetup: Meetup?
    let canSchedulePickup: Bool
    let canScheduleReturn: Bool

    enum CodingKeys: String, CodingKey {
        case pickupMeetup, returnMeetup, canSchedulePickup, canScheduleReturn
    }
}
