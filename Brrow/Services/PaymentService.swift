//
//  PaymentService.swift
//  Brrow
//
//  Created by Shalin Ratna on 7/16/25.
//

import Foundation
import Combine
import UIKit
import StripePaymentSheet
import SwiftUI

@MainActor
class PaymentService: NSObject, ObservableObject {
    
    static let shared = PaymentService()
    private var cancellables = Set<AnyCancellable>()
    private let apiClient = APIClient.shared
    
    @Published var isLoading = false
    @Published var error: String?
    @Published var connectStatus: ConnectStatus?
    @Published var paymentMethods: [PaymentMethodInfo] = []
    
    private override init() {
        super.init()
        STPAPIClient.shared.publishableKey = Bundle.main.object(forInfoDictionaryKey: "StripePublishableKey") as? String ?? ""
    }
    
    // MARK: - Modern Payment Intent Creation (New Backend)
    
    /// Create payment intent for marketplace transaction with escrow
    func createMarketplacePaymentIntent(
        listingId: String,
        sellerId: String,
        transactionType: String = "PURCHASE",
        rentalStartDate: Date? = nil,
        rentalEndDate: Date? = nil,
        deliveryMethod: String = "PICKUP",
        buyerMessage: String? = nil
    ) async throws -> MarketplacePaymentIntent {
        
        isLoading = true
        defer { isLoading = false }
        
        let request = CreatePaymentIntentRequest(
            listingId: listingId,
            sellerId: sellerId,
            transactionType: transactionType,
            rentalStartDate: rentalStartDate,
            rentalEndDate: rentalEndDate,
            deliveryMethod: deliveryMethod,
            buyerMessage: buyerMessage
        )
        
        let response = try await apiClient.performRequest(
            endpoint: "api/payments/create-payment-intent",
            method: "POST",
            body: try JSONEncoder().encode(request),
            responseType: APIResponse<MarketplacePaymentIntent>.self
        )

        // DEBUG: Log response
        print("🌐 DEBUG - API Response:")
        print("   Success: \(response.success)")
        if let data = response.data {
            print("   Has payment intent data: true")
            print("   Client Secret exists: \(!data.clientSecret.isEmpty)")
            print("   Ephemeral Key exists: \(!data.ephemeralKey.isEmpty)")
            print("   Customer ID exists: \(!data.customerId.isEmpty)")
        } else {
            print("   Has payment intent data: false")
            print("   Message: \(response.message ?? "none")")
        }

        guard response.success, let paymentIntent = response.data else {
            let errorMessage = response.message ?? "Failed to create payment intent"
            if errorMessage.contains("Seller needs to set up payment account") {
                throw PaymentError.sellerOnboardingRequired
            }
            throw BrrowAPIError.serverError(errorMessage)
        }
        
        // Track analytics
        let event = AnalyticsEvent(
            eventName: "marketplace_payment_intent_created",
            eventType: "payment",
            metadata: [
                "amount": String(paymentIntent.amount),
                "transaction_type": transactionType,
                "listing_id": listingId
            ]
        )
        
        // Fire and forget analytics tracking
        Task {
            try? await apiClient.trackAnalytics(event: event)
        }
        
        return paymentIntent
    }
    
    /// Confirm payment after successful Stripe payment
    func confirmPayment(transactionId: String) async throws {
        let body = ["transactionId": transactionId]
        
        let response = try await apiClient.performRequest(
            endpoint: "api/payments/confirm-payment",
            method: "POST",
            body: try JSONSerialization.data(withJSONObject: body),
            responseType: APIResponse<TransactionConfirmation>.self
        )
        
        guard response.success else {
            throw BrrowAPIError.serverError(response.message ?? "Failed to confirm payment")
        }
    }
    
    /// Release escrow funds after successful delivery
    func releaseFunds(transactionId: String) async throws {
        let body = ["transactionId": transactionId]
        
        let response = try await apiClient.performRequest(
            endpoint: "api/payments/release-funds",
            method: "POST",
            body: try JSONSerialization.data(withJSONObject: body),
            responseType: APIResponse<EmptyResponse>.self
        )
        
        guard response.success else {
            throw BrrowAPIError.serverError(response.message ?? "Failed to release funds")
        }
    }
    
    // MARK: - Legacy Payment Intent Creation (Existing)
    func createPaymentIntent(amount: Int, currency: String = "usd", transactionType: String, listingId: String? = nil) async throws -> PaymentIntentResponse {
        // Convert amount to cents
        let amountInCents = amount * 100
        
        // Create payment intent request parameters
        let params: [String: String] = [
            "amount": String(amountInCents),
            "currency": currency,
            "transaction_type": transactionType,
            "listing_id": listingId ?? ""
        ]
        
        // Track analytics
        let event = AnalyticsEvent(
            eventName: "payment_intent_created",
            eventType: "payment",
            metadata: [
                "amount": String(amountInCents),
                "currency": currency,
                "transaction_type": transactionType
            ]
        )
        
        // Fire and forget analytics tracking
        Task {
            try? await apiClient.trackAnalytics(event: event)
        }
        
        // Call the actual API
        let endpoint = "stripe/create_payment_intent.php"
        let bodyData = try JSONEncoder().encode(params)
        let response: PaymentIntentResponse = try await apiClient.performRequest(
            endpoint: endpoint,
            method: "POST",
            body: bodyData,
            responseType: PaymentIntentResponse.self
        )
        
        return response
    }
    
    // MARK: - Payment Sheet Presentation
    func presentPaymentSheet(from viewController: UIViewController, with clientSecret: String, completion: @escaping (Bool, Error?) -> Void) {
        var configuration = PaymentSheet.Configuration()
        configuration.merchantDisplayName = "Brrow"
        configuration.allowsDelayedPaymentMethods = false
        
        let paymentSheet = PaymentSheet(
            paymentIntentClientSecret: clientSecret,
            configuration: configuration
        )
        
        // Track analytics
        let event = AnalyticsEvent(
            eventName: "payment_sheet_presented",
            eventType: "payment"
        )
        
        // Fire and forget analytics tracking
        Task {
            try? await apiClient.trackAnalytics(event: event)
        }
        
        paymentSheet.present(from: viewController) { paymentResult in
            switch paymentResult {
            case .completed:
                // Track successful payment
                let event = AnalyticsEvent(
                    eventName: "payment_completed",
                    eventType: "payment",
                    metadata: ["client_secret": clientSecret]
                )
                
                // Fire and forget analytics tracking
                Task {
                    try? await self.apiClient.trackAnalytics(event: event)
                }
                
                completion(true, nil)
                
            case .canceled:
                completion(false, nil)
                
            case .failed(let error):
                // Track payment failure
                let event = AnalyticsEvent(
                    eventName: "payment_failed",
                    eventType: "payment",
                    metadata: [
                        "error": error.localizedDescription,
                        "client_secret": clientSecret
                    ]
                )
                
                // Fire and forget analytics tracking
                Task {
                    try? await self.apiClient.trackAnalytics(event: event)
                }
                
                completion(false, error)
            }
        }
    }
}

// MARK: - STPAuthenticationContext
extension PaymentService: STPAuthenticationContext {
    func authenticationPresentingViewController() -> UIViewController {
        // Get the top-most view controller
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first,
              let rootViewController = window.rootViewController else {
            fatalError("No root view controller found")
        }
        
        var topController = rootViewController
        while let presentedController = topController.presentedViewController {
            topController = presentedController
        }
        
        return topController
    }
    
    // MARK: - Stripe Connect Operations
    
    /// Create Stripe Connect account for sellers
    func createConnectAccount(email: String, businessType: String = "individual") async throws -> ConnectAccount {
        let body: [String: Any] = [
            "email": email,
            "businessType": businessType
        ]
        
        let response = try await apiClient.performRequest(
            endpoint: "api/payments/create-connect-account",
            method: "POST",
            body: try JSONSerialization.data(withJSONObject: body),
            responseType: APIResponse<ConnectAccount>.self
        )
        
        guard response.success, let account = response.data else {
            throw BrrowAPIError.serverError(response.message ?? "Failed to create Connect account")
        }
        
        return account
    }
    
    /// Check Stripe Connect account status
    func checkConnectStatus() async throws -> ConnectStatus {
        let response = try await apiClient.performRequest(
            endpoint: "api/payments/connect-status",
            method: "GET",
            responseType: APIResponse<ConnectStatus>.self
        )
        
        guard response.success, let status = response.data else {
            throw BrrowAPIError.serverError(response.message ?? "Failed to check Connect status")
        }
        
        await MainActor.run {
            self.connectStatus = status
        }
        
        return status
    }
    
    /// Fetch user's payment methods
    func fetchPaymentMethods() async throws -> [PaymentMethodInfo] {
        let response = try await apiClient.performRequest(
            endpoint: "api/payments/payment-methods",
            method: "GET",
            responseType: APIResponse<PaymentMethodsResponse>.self
        )

        guard response.success, let data = response.data else {
            throw BrrowAPIError.serverError(response.message ?? "Failed to fetch payment methods")
        }

        await MainActor.run {
            self.paymentMethods = data.paymentMethods
        }

        return data.paymentMethods
    }

    /// Create SetupIntent for adding new payment method
    func createSetupIntent() async throws -> SetupIntentResponse {
        let response = try await apiClient.performRequest(
            endpoint: "api/payments/create-setup-intent",
            method: "POST",
            responseType: APIResponse<SetupIntentResponse>.self
        )

        guard response.success, let setupIntent = response.data else {
            throw BrrowAPIError.serverError(response.message ?? "Failed to create setup intent")
        }

        // Track analytics
        let event = AnalyticsEvent(
            eventName: "setup_intent_created",
            eventType: "payment"
        )

        Task {
            try? await apiClient.trackAnalytics(event: event)
        }

        return setupIntent
    }
    
    // MARK: - Helper Methods
    
    /// Calculate total cost including fees
    func calculateTotalCost(amount: Double) -> (total: Double, platformFee: Double, stripeFee: Double) {
        let stripeFee = amount * 0.029 + 0.30 // 2.9% + 30¢
        let platformFee = amount * 0.05 // 5% platform fee
        let total = amount + stripeFee + platformFee
        
        return (total: total, platformFee: platformFee, stripeFee: stripeFee)
    }
    
    /// Calculate rental cost for date range
    func calculateRentalCost(dailyRate: Double, startDate: Date, endDate: Date) -> (days: Int, totalCost: Double) {
        let days = max(1, Calendar.current.dateComponents([.day], from: startDate, to: endDate).day ?? 1)
        let totalCost = Double(days) * dailyRate
        
        return (days: days, totalCost: totalCost)
    }
    
    /// Format currency
    func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        return formatter.string(from: NSNumber(value: amount)) ?? "$\(String(format: "%.2f", amount))"
    }
}

// MARK: - Payment Error Types
enum PaymentError: LocalizedError {
    case sellerOnboardingRequired
    case paymentFailed(String)
    case insufficientFunds
    case invalidAmount
    case networkError
    
    var errorDescription: String? {
        switch self {
        case .sellerOnboardingRequired:
            return "Seller needs to complete payment setup"
        case .paymentFailed(let reason):
            return "Payment failed: \(reason)"
        case .insufficientFunds:
            return "Insufficient funds"
        case .invalidAmount:
            return "Invalid payment amount"
        case .networkError:
            return "Network connection error"
        }
    }
}

// MARK: - New Payment Models
struct MarketplacePaymentIntent: Codable {
    let clientSecret: String
    let customerSessionClientSecret: String  // Customer Session for Stripe iOS SDK 25.0+
    let customerId: String
    let transactionId: String
    let amount: Double
    let platformFee: Double
    let paymentIntentId: String
}

struct CreatePaymentIntentRequest: Codable {
    let listingId: String
    let sellerId: String
    let transactionType: String
    let rentalStartDate: Date?
    let rentalEndDate: Date?
    let deliveryMethod: String
    let buyerMessage: String?

    enum CodingKeys: String, CodingKey {
        case listingId, sellerId, transactionType, rentalStartDate, rentalEndDate, deliveryMethod, buyerMessage
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(listingId, forKey: .listingId)
        try container.encode(sellerId, forKey: .sellerId)
        try container.encode(transactionType, forKey: .transactionType)
        try container.encode(deliveryMethod, forKey: .deliveryMethod)

        // Encode dates as ISO 8601 strings if present
        if let rentalStartDate = rentalStartDate {
            let formatter = ISO8601DateFormatter()
            try container.encode(formatter.string(from: rentalStartDate), forKey: .rentalStartDate)
        }

        if let rentalEndDate = rentalEndDate {
            let formatter = ISO8601DateFormatter()
            try container.encode(formatter.string(from: rentalEndDate), forKey: .rentalEndDate)
        }

        if let buyerMessage = buyerMessage {
            try container.encode(buyerMessage, forKey: .buyerMessage)
        }
    }
}

struct ConnectAccount: Codable {
    let accountId: String
    let onboardingUrl: String
}

struct ConnectStatus: Codable {
    let hasAccount: Bool
    let canReceivePayments: Bool
    let detailsSubmitted: Bool?
    let requiresAction: Bool?
}

struct PaymentMethodInfo: Codable {
    let id: String
    let type: String
    let card: PaymentCard
    
    struct PaymentCard: Codable {
        let brand: String
        let last4: String
        let expMonth: Int
        let expYear: Int
    }
}

private struct TransactionConfirmation: Codable {
    let transactionId: String
    let status: String
    let paymentIntentId: String
}

private struct PaymentMethodsResponse: Codable {
    let paymentMethods: [PaymentMethodInfo]
}

struct SetupIntentResponse: Codable {
    let clientSecret: String
    let setupIntentId: String?
}

// MARK: - Legacy Payment Intent Response (Existing)
struct PaymentIntentResponse: Codable {
    let clientSecret: String
    let publishableKey: String
    let customerId: String?
    let ephemeralKeySecret: String?
    
    enum CodingKeys: String, CodingKey {
        case clientSecret = "client_secret"
        case publishableKey = "publishable_key"
        case customerId = "customer_id"
        case ephemeralKeySecret = "ephemeral_key_secret"
    }
}
