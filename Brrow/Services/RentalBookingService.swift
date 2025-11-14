//
//  RentalBookingService.swift
//  Brrow
//
//  Created by Claude on 1/14/25.
//

import Foundation
import Combine

class RentalBookingService: ObservableObject {
    static let shared = RentalBookingService()

    private let apiClient = APIClient.shared

    private init() {}

    // MARK: - Get Rental Booking
    func getRentalBooking(bookingId: String) -> AnyPublisher<RentalBooking, Error> {
        return Future { promise in
            Task {
                do {
                    let response: RentalBookingResponse = try await self.apiClient.request(
                        "api/mobile/rentals/\(bookingId)/details",
                        method: .GET
                    )

                    if response.success, let booking = response.data {
                        promise(.success(booking))
                    } else {
                        promise(.failure(BrrowAPIError.serverError(response.message ?? "Failed to get rental booking")))
                    }
                } catch {
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    // MARK: - Get My Rental Bookings
    func getMyRentalBookings(status: BookingStatus? = nil) -> AnyPublisher<[RentalBooking], Error> {
        var endpoint = "api/mobile/rentals/dashboard"
        if let status = status {
            endpoint += "?status=\(status.rawValue)"
        }

        return Future { promise in
            Task {
                do {
                    let response: RentalBookingsListResponse = try await self.apiClient.request(
                        endpoint,
                        method: .GET
                    )

                    if response.success, let bookings = response.data {
                        promise(.success(bookings))
                    } else {
                        promise(.failure(BrrowAPIError.serverError(response.message ?? "Failed to get rental bookings")))
                    }
                } catch {
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    // MARK: - Get Booking Meetups
    func getBookingMeetups(bookingId: String) -> AnyPublisher<BookingMeetupsData, Error> {
        return Future { promise in
            Task {
                do {
                    let response: BookingMeetupsResponse = try await self.apiClient.request(
                        "api/bookings/\(bookingId)/meetups",
                        method: .GET
                    )

                    if response.success, let data = response.data {
                        promise(.success(data))
                    } else {
                        promise(.failure(BrrowAPIError.serverError(response.message ?? "Failed to get booking meetups")))
                    }
                } catch {
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    // MARK: - Schedule Pickup Meetup
    func schedulePickupMeetup(
        bookingId: String,
        location: MeetupLocation,
        scheduledTime: Date,
        notes: String? = nil
    ) -> AnyPublisher<Meetup, Error> {
        let parameters: [String: Any] = [
            "meetupLocation": [
                "latitude": location.latitude,
                "longitude": location.longitude,
                "address": location.address ?? ""
            ],
            "scheduledTime": ISO8601DateFormatter().string(from: scheduledTime),
            "notes": notes ?? ""
        ]

        return Future { promise in
            Task {
                do {
                    let response: MeetupResponse = try await self.apiClient.request(
                        "api/bookings/\(bookingId)/schedule-pickup-meetup",
                        method: .POST,
                        parameters: parameters
                    )

                    if response.success, let meetup = response.data {
                        promise(.success(meetup))
                    } else {
                        promise(.failure(BrrowAPIError.serverError(response.message ?? "Failed to schedule pickup meetup")))
                    }
                } catch {
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    // MARK: - Schedule Return Meetup
    func scheduleReturnMeetup(
        bookingId: String,
        location: MeetupLocation,
        scheduledTime: Date,
        notes: String? = nil
    ) -> AnyPublisher<Meetup, Error> {
        let parameters: [String: Any] = [
            "meetupLocation": [
                "latitude": location.latitude,
                "longitude": location.longitude,
                "address": location.address ?? ""
            ],
            "scheduledTime": ISO8601DateFormatter().string(from: scheduledTime),
            "notes": notes ?? ""
        ]

        return Future { promise in
            Task {
                do {
                    let response: MeetupResponse = try await self.apiClient.request(
                        "api/bookings/\(bookingId)/schedule-return-meetup",
                        method: .POST,
                        parameters: parameters
                    )

                    if response.success, let meetup = response.data {
                        promise(.success(meetup))
                    } else {
                        promise(.failure(BrrowAPIError.serverError(response.message ?? "Failed to schedule return meetup")))
                    }
                } catch {
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    // MARK: - Calculate Late Fees (for display purposes)
    func calculateLateFees(bookingId: String) -> AnyPublisher<Double, Error> {
        return Future { promise in
            Task {
                do {
                    struct LateFeeResponse: Codable {
                        let success: Bool
                        let lateFees: Double?
                        let message: String?
                    }

                    let response: LateFeeResponse = try await self.apiClient.request(
                        "api/bookings/\(bookingId)/calculate-late-fees",
                        method: .POST
                    )

                    if response.success, let fees = response.lateFees {
                        promise(.success(fees))
                    } else {
                        promise(.failure(BrrowAPIError.serverError(response.message ?? "Failed to calculate late fees")))
                    }
                } catch {
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }
}
