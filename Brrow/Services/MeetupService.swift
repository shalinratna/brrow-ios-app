//
//  MeetupService.swift
//  Brrow
//
//  Created by Claude on 1/6/25.
//

import Foundation
import Combine
import CoreLocation

class MeetupService: ObservableObject {
    static let shared = MeetupService()

    private let apiClient = APIClient.shared
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Schedule Meetup
    func scheduleMeetup(
        transactionId: String,
        location: CLLocationCoordinate2D,
        address: String,
        scheduledTime: Date,
        notes: String? = nil
    ) -> AnyPublisher<Meetup, Error> {
        let meetupLocation = [
            "latitude": location.latitude,
            "longitude": location.longitude,
            "address": address
        ] as [String: Any]

        let dateFormatter = ISO8601DateFormatter()
        let parameters: [String: Any] = [
            "transactionId": transactionId,
            "meetupLocation": meetupLocation,
            "scheduledTime": dateFormatter.string(from: scheduledTime),
            "notes": notes as Any
        ]

        return Future { promise in
            Task {
                do {
                    let response: MeetupResponse = try await self.apiClient.request(
                        "/api/meetups/schedule",
                        method: .POST,
                        parameters: parameters
                    )

                    if response.success, let meetup = response.data {
                        promise(.success(meetup))
                    } else {
                        promise(.failure(BrrowAPIError.serverError(response.message ?? "Failed to schedule meetup")))
                    }
                } catch {
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    // MARK: - Get Meetup Details
    func getMeetup(meetupId: String) -> AnyPublisher<Meetup, Error> {
        return Future { promise in
            Task {
                do {
                    let response: MeetupResponse = try await self.apiClient.request(
                        "/api/meetups/\(meetupId)",
                        method: .GET
                    )

                    if response.success, let meetup = response.data {
                        promise(.success(meetup))
                    } else {
                        promise(.failure(BrrowAPIError.serverError(response.message ?? "Failed to fetch meetup")))
                    }
                } catch {
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    // MARK: - Update User Location
    func updateLocation(
        meetupId: String,
        location: CLLocationCoordinate2D
    ) -> AnyPublisher<LocationUpdateData, Error> {
        let parameters: [String: Any] = [
            "latitude": location.latitude,
            "longitude": location.longitude
        ]

        return Future { promise in
            Task {
                do {
                    let response: LocationUpdateResponse = try await self.apiClient.request(
                        "/api/meetups/\(meetupId)/update-location",
                        method: .PUT,
                        parameters: parameters
                    )

                    if response.success, let data = response.data {
                        promise(.success(data))
                    } else {
                        promise(.failure(BrrowAPIError.serverError(response.message ?? "Failed to update location")))
                    }
                } catch {
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    // MARK: - Get Proximity Status
    func getProximityStatus(meetupId: String) -> AnyPublisher<ProximityStatus, Error> {
        return Future { promise in
            Task {
                do {
                    let response: ProximityStatusResponse = try await self.apiClient.request(
                        "/api/meetups/\(meetupId)/proximity-status",
                        method: .GET
                    )

                    if response.success, let data = response.data {
                        promise(.success(data))
                    } else {
                        promise(.failure(BrrowAPIError.serverError(response.message ?? "Failed to fetch proximity status")))
                    }
                } catch {
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    // MARK: - Manual Arrival Override
    func manualArrival(meetupId: String) -> AnyPublisher<Meetup, Error> {
        return Future { promise in
            Task {
                do {
                    let response: MeetupResponse = try await self.apiClient.request(
                        "/api/meetups/\(meetupId)/manual-arrival",
                        method: .POST,
                        parameters: nil
                    )

                    if response.success, let meetup = response.data {
                        promise(.success(meetup))
                    } else {
                        promise(.failure(BrrowAPIError.serverError(response.message ?? "Failed to mark manual arrival")))
                    }
                } catch {
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    // MARK: - Generate Verification Code
    func generateVerificationCode(
        meetupId: String,
        codeType: VerificationMethod
    ) -> AnyPublisher<VerificationCode, Error> {
        let parameters: [String: Any] = [
            "meetupId": meetupId,
            "codeType": codeType.rawValue
        ]

        return Future { promise in
            Task {
                do {
                    let response: VerificationCodeResponse = try await self.apiClient.request(
                        "api/meetups/verification-codes/generate",
                        method: .POST,
                        parameters: parameters
                    )

                    print("🔍 [VERIFICATION CODE] Response received:")
                    print("   Success: \(response.success)")
                    print("   Data: \(String(describing: response.data))")
                    print("   Message: \(String(describing: response.message))")

                    if response.success, let code = response.data {
                        print("✅ [VERIFICATION CODE] Successfully decoded code:")
                        print("   ID: \(code.id)")
                        print("   Type: \(code.codeType)")
                        print("   Value: \(code.codeValue)")
                        print("   Expires: \(code.expiresAt)")
                        promise(.success(code))
                    } else {
                        print("❌ [VERIFICATION CODE] Failed: No data in response")
                        promise(.failure(BrrowAPIError.serverError(response.message ?? "Failed to generate code")))
                    }
                } catch {
                    print("❌ [VERIFICATION CODE] Error: \(error)")
                    if let decodingError = error as? DecodingError {
                        print("   Decoding error details: \(decodingError)")
                    }
                    if let apiError = error as? BrrowAPIError {
                        print("   API Error: \(apiError)")
                    }
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    // MARK: - Verify Code
    func verifyCode(
        meetupId: String,
        codeValue: String
    ) -> AnyPublisher<VerificationResult, Error> {
        let parameters: [String: Any] = [
            "meetupId": meetupId,
            "codeValue": codeValue
        ]

        return Future { promise in
            Task {
                do {
                    let response: VerificationResultResponse = try await self.apiClient.request(
                        "api/meetups/verification-codes/verify",
                        method: .POST,
                        parameters: parameters
                    )

                    print("🔍 [VERIFY CODE] Response received:")
                    print("   Success: \(response.success)")
                    print("   Data: \(String(describing: response.data))")
                    print("   Message: \(String(describing: response.message))")

                    if response.success, let result = response.data {
                        print("✅ [VERIFY CODE] Verification successful")
                        promise(.success(result))
                    } else {
                        print("❌ [VERIFY CODE] Verification failed: \(response.message ?? "Unknown error")")
                        promise(.failure(BrrowAPIError.serverError(response.message ?? "Failed to verify code")))
                    }
                } catch {
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    // MARK: - Get User's Meetups
    func getUserMeetups(status: MeetupStatus? = nil) -> AnyPublisher<[Meetup], Error> {
        var endpoint = "/api/meetups/user/my-meetups"
        if let status = status {
            endpoint += "?status=\(status.rawValue)"
        }

        return Future { promise in
            Task {
                do {
                    let response: MeetupsListResponse = try await self.apiClient.request(
                        endpoint,
                        method: .GET
                    )

                    if response.success, let meetups = response.data {
                        promise(.success(meetups))
                    } else {
                        promise(.failure(BrrowAPIError.serverError(response.message ?? "Failed to fetch meetups")))
                    }
                } catch {
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    // MARK: - Cancel Meetup
    func cancelMeetup(meetupId: String, reason: String? = nil) -> AnyPublisher<Bool, Error> {
        var parameters: [String: Any] = [:]
        if let reason = reason {
            parameters["reason"] = reason
        }

        return Future { promise in
            Task {
                do {
                    let response: MeetupResponse = try await self.apiClient.request(
                        "/api/meetups/\(meetupId)",
                        method: .DELETE,
                        parameters: parameters.isEmpty ? nil : parameters
                    )

                    if response.success {
                        promise(.success(true))
                    } else {
                        promise(.failure(BrrowAPIError.serverError(response.message ?? "Failed to cancel meetup")))
                    }
                } catch {
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    // MARK: - Complete Purchase (Alternative method)
    func completePurchase(purchaseId: String) -> AnyPublisher<Bool, Error> {
        return Future { promise in
            Task {
                do {
                    let response: MeetupResponse = try await self.apiClient.request(
                        "/api/meetups/purchases/\(purchaseId)/complete",
                        method: .PUT
                    )

                    if response.success {
                        promise(.success(true))
                    } else {
                        promise(.failure(BrrowAPIError.serverError(response.message ?? "Failed to complete purchase")))
                    }
                } catch {
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    // MARK: - Rental Meetup Scheduling (Two-Meetup System)

    /// Schedule a meetup for a rental booking (supports PICKUP and RETURN types)
    func scheduleRentalMeetup(
        bookingId: String,
        meetupType: MeetupType,
        location: CLLocationCoordinate2D,
        address: String,
        scheduledTime: Date,
        notes: String? = nil
    ) -> AnyPublisher<Meetup, Error> {
        let meetupLocation = [
            "latitude": location.latitude,
            "longitude": location.longitude,
            "address": address
        ] as [String: Any]

        let dateFormatter = ISO8601DateFormatter()
        let parameters: [String: Any] = [
            "bookingId": bookingId,
            "meetupType": meetupType.rawValue,
            "meetupLocation": meetupLocation,
            "scheduledTime": dateFormatter.string(from: scheduledTime),
            "notes": notes as Any
        ]

        return Future { promise in
            Task {
                do {
                    let response: MeetupResponse = try await self.apiClient.request(
                        "api/meetups",
                        method: .POST,
                        parameters: parameters
                    )

                    if response.success, let meetup = response.data {
                        promise(.success(meetup))
                    } else {
                        promise(.failure(BrrowAPIError.serverError(response.message ?? "Failed to schedule \(meetupType.displayName.lowercased()) meetup")))
                    }
                } catch {
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    /// Get both pickup and return meetups for a rental booking
    func getRentalMeetups(bookingId: String) -> AnyPublisher<(pickup: Meetup?, return: Meetup?), Error> {
        return Future { promise in
            Task {
                do {
                    struct BookingMeetupsResponse: Codable {
                        let success: Bool
                        let data: BookingMeetupsData?
                        let message: String?
                    }

                    struct BookingMeetupsData: Codable {
                        let pickupMeetup: Meetup?
                        let returnMeetup: Meetup?
                    }

                    let response: BookingMeetupsResponse = try await self.apiClient.request(
                        "api/bookings/\(bookingId)/meetups",
                        method: .GET
                    )

                    if response.success, let data = response.data {
                        promise(.success((pickup: data.pickupMeetup, return: data.returnMeetup)))
                    } else {
                        promise(.failure(BrrowAPIError.serverError(response.message ?? "Failed to fetch rental meetups")))
                    }
                } catch {
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }
}
