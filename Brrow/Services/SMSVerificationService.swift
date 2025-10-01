//
//  SMSVerificationService.swift
//  Brrow
//
//  SMS Verification Service using Twilio Verify API
//

import Foundation
import Combine

@MainActor
class SMSVerificationService: ObservableObject {
    static let shared = SMSVerificationService()

    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    @Published var verificationSent = false
    @Published var verificationSuccessful = false

    private let apiClient = APIClient.shared

    private init() {}

    // MARK: - Send SMS Verification Code

    func sendVerificationCode(to phoneNumber: String) async throws {
        isLoading = true
        errorMessage = nil
        successMessage = nil
        verificationSent = false

        do {
            let response = try await apiClient.sendSMSVerificationCode(phoneNumber: phoneNumber)

            if response.success {
                verificationSent = true
                successMessage = response.message ?? "Verification code sent successfully"
            } else {
                throw SMSVerificationError.sendFailed(response.message ?? "Failed to send verification code")
            }
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }

        isLoading = false
    }

    // MARK: - Verify SMS Code

    func verifyCode(_ code: String, for phoneNumber: String) async throws {
        isLoading = true
        errorMessage = nil
        successMessage = nil
        verificationSuccessful = false

        do {
            let response = try await apiClient.verifySMSCode(code: code, phoneNumber: phoneNumber)

            if response.success {
                verificationSuccessful = true
                successMessage = response.message ?? "Phone number verified successfully"

                // Update user data if provided
                if let userData = response.user {
                    AuthManager.shared.updateUser(userData)
                }
            } else {
                throw SMSVerificationError.verificationFailed(response.message ?? "Invalid verification code")
            }
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }

        isLoading = false
    }

    // MARK: - Reset State

    func resetState() {
        isLoading = false
        errorMessage = nil
        successMessage = nil
        verificationSent = false
        verificationSuccessful = false
    }

    // MARK: - Helper Methods

    func formatPhoneNumber(_ phoneNumber: String) -> String {
        // Remove all non-digits
        let digits = phoneNumber.filter { $0.isNumber }

        // Add +1 prefix for US numbers if not present
        if digits.count == 10 {
            return "+1" + digits
        } else if digits.count == 11 && digits.hasPrefix("1") {
            return "+" + digits
        } else if !phoneNumber.hasPrefix("+") {
            return "+" + digits
        }

        return phoneNumber
    }

    func isValidPhoneNumber(_ phoneNumber: String) -> Bool {
        let formatted = formatPhoneNumber(phoneNumber)

        // Basic E.164 format validation
        let phoneRegex = "^\\+[1-9]\\d{1,14}$"
        let phonePredicate = NSPredicate(format: "SELF MATCHES %@", phoneRegex)
        return phonePredicate.evaluate(with: formatted)
    }
}

// MARK: - API Extension removed - using APIClient's built-in SMS verification methods

// MARK: - Response Models

struct SMSVerificationResponse: Codable {
    let success: Bool
    let message: String?
    let error: String?
    let user: User?
    let status: String?
    let testMode: Bool?
}

// MARK: - Error Types

enum SMSVerificationError: LocalizedError {
    case invalidPhoneNumber
    case sendFailed(String)
    case verificationFailed(String)
    case networkError

    var errorDescription: String? {
        switch self {
        case .invalidPhoneNumber:
            return "Please enter a valid phone number"
        case .sendFailed(let message):
            return message
        case .verificationFailed(let message):
            return message
        case .networkError:
            return "Network error. Please check your connection and try again."
        }
    }
}