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

class PaymentService: NSObject {
    
    static let shared = PaymentService()
    private var cancellables = Set<AnyCancellable>()
    private let apiClient = APIClient.shared
    
    private override init() {
        super.init()
        STPAPIClient.shared.publishableKey = Bundle.main.object(forInfoDictionaryKey: "StripePublishableKey") as? String ?? ""
    }
    
    // MARK: - Payment Intent Creation
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
        let response: PaymentIntentResponse = try await apiClient.request(endpoint, method: .POST, parameters: params)
        
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
}

// MARK: - Payment Intent Response
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
