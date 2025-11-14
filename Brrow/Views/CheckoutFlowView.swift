//
//  CheckoutFlowView.swift
//  Brrow
//
//  Created by Shalin Ratna on 7/16/25.
//

import SwiftUI
import SafariServices

/// Reusable component for presenting Stripe Checkout Sessions in a full-page browser experience
struct CheckoutFlowView: UIViewControllerRepresentable {
    let checkoutURL: String
    let onSuccess: (String) -> Void  // Returns session ID
    let onCancel: () -> Void
    let onError: (Error) -> Void

    func makeUIViewController(context: Context) -> SFSafariViewController {
        guard let url = URL(string: checkoutURL) else {
            // If URL is invalid, call error handler immediately
            DispatchQueue.main.async {
                onError(CheckoutError.invalidURL)
            }
            // Return dummy Safari VC (will be dismissed immediately via coordinator)
            return SFSafariViewController(url: URL(string: "about:blank")!)
        }

        let config = SFSafariViewController.Configuration()
        config.entersReaderIfAvailable = false
        config.barCollapsingEnabled = true

        let safariVC = SFSafariViewController(url: url, configuration: config)
        safariVC.preferredControlTintColor = .systemBlue
        safariVC.preferredBarTintColor = .systemBackground
        safariVC.dismissButtonStyle = .cancel
        safariVC.delegate = context.coordinator

        return safariVC
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {
        // No updates needed
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(
            onSuccess: onSuccess,
            onCancel: onCancel,
            onError: onError
        )
    }

    class Coordinator: NSObject, SFSafariViewControllerDelegate {
        let onSuccess: (String) -> Void
        let onCancel: () -> Void
        let onError: (Error) -> Void

        init(onSuccess: @escaping (String) -> Void,
             onCancel: @escaping () -> Void,
             onError: @escaping (Error) -> Void) {
            self.onSuccess = onSuccess
            self.onCancel = onCancel
            self.onError = onError
        }

        func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
            // User manually dismissed the Safari view (tapped Cancel/Done)
            // This means they canceled the checkout without completing
            print("🚫 Checkout Session: User dismissed Safari view")
            onCancel()
        }

        // This delegate method is called when Safari redirects to our deep link
        func safariViewController(_ controller: SFSafariViewController,
                                initialLoadDidRedirectTo URL: URL) {
            print("🔗 Checkout Session: Redirect detected to \(URL.absoluteString)")
            handleDeepLink(url: URL)
        }

        private func handleDeepLink(url: URL) {
            // Parse the deep link URL
            // Expected formats:
            // - brrowapp://payment/success?session_id=cs_xxx&listing_id=xxx
            // - brrowapp://payment/cancel?listing_id=xxx

            guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
                onError(CheckoutError.invalidDeepLink)
                return
            }

            let path = components.path

            if path.contains("/success") {
                // Extract session ID from query parameters
                if let sessionId = components.queryItems?.first(where: { $0.name == "session_id" })?.value {
                    print("✅ Checkout Session: Success with session ID \(sessionId)")
                    onSuccess(sessionId)
                } else {
                    onError(CheckoutError.missingSessionId)
                }
            } else if path.contains("/cancel") {
                print("🚫 Checkout Session: User canceled payment")
                onCancel()
            } else {
                onError(CheckoutError.unknownDeepLink)
            }
        }
    }
}

// MARK: - Checkout Error Types
enum CheckoutError: LocalizedError, Equatable {
    case invalidURL
    case invalidDeepLink
    case missingSessionId
    case unknownDeepLink
    case sessionExpired
    case paymentFailed(String)
    case userCanceled

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid checkout URL"
        case .invalidDeepLink:
            return "Invalid payment callback"
        case .missingSessionId:
            return "Missing session ID in payment callback"
        case .unknownDeepLink:
            return "Unknown payment callback"
        case .sessionExpired:
            return "Checkout session expired"
        case .paymentFailed(let reason):
            return "Payment failed: \(reason)"
        case .userCanceled:
            return "Payment canceled"
        }
    }
}

// MARK: - Checkout Flow Container View
/// SwiftUI view that orchestrates the entire checkout flow
struct CheckoutFlowContainer: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var paymentService = PaymentService.shared

    let listingId: String
    let sellerId: String
    let transactionType: String
    let rentalStartDate: Date?
    let rentalEndDate: Date?
    let deliveryMethod: String
    let includeInsurance: Bool?
    let onCompletion: (Result<String, Error>) -> Void

    @State private var showCheckout = false
    @State private var checkoutURL: String?
    @State private var sessionId: String?
    @State private var isPolling = false
    @State private var errorMessage: String?
    @State private var isCreatingSession = false  // Prevent double-tap duplicates

    var body: some View {
        ZStack {
            if let url = checkoutURL, showCheckout {
                // Present the checkout browser
                CheckoutFlowView(
                    checkoutURL: url,
                    onSuccess: { sessionId in
                        guard !sessionId.isEmpty else {
                            print("⚠️ [CheckoutFlow] onSuccess called with empty sessionId")
                            return
                        }
                        self.sessionId = sessionId
                        showCheckout = false
                        pollCheckoutStatus(sessionId: sessionId)
                    },
                    onCancel: {
                        showCheckout = false
                        onCompletion(.failure(CheckoutError.userCanceled))

                        // Delay dismiss to let parent view handle completion callback
                        Task { @MainActor in
                            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 second
                            dismiss()
                        }
                    },
                    onError: { error in
                        showCheckout = false
                        errorMessage = error.localizedDescription
                        onCompletion(.failure(error))

                        // Delay dismiss to let parent view handle completion callback
                        Task { @MainActor in
                            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 second
                            dismiss()
                        }
                    }
                )
                .ignoresSafeArea()
            } else if isPolling {
                // Show polling indicator with improved UI
                VStack(spacing: 24) {
                    // Animated checkmark circle
                    ZStack {
                        Circle()
                            .stroke(Color.blue.opacity(0.3), lineWidth: 4)
                            .frame(width: 80, height: 80)

                        Circle()
                            .trim(from: 0, to: 0.7)
                            .stroke(Color.blue, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                            .frame(width: 80, height: 80)
                            .rotationEffect(.degrees(-90))
                            .animation(.linear(duration: 1).repeatForever(autoreverses: false), value: isPolling)

                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.blue)
                            .opacity(0.3)
                    }

                    VStack(spacing: 8) {
                        Text("Verifying Payment")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)

                        Text("This usually takes a few seconds")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(40)
                .frame(maxWidth: 320)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color(.systemBackground))
                        .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 10)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color(.separator), lineWidth: 1)
                )
            }
        }
        .task {
            await createCheckoutSession()
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("ShowPaymentSuccess"))) { notification in
            // Handle payment success notification from BrrowApp deep link handler
            // This is triggered when iOS intercepts the brrowapp:// deep link
            guard let userInfo = notification.userInfo,
                  let sessionId = userInfo["sessionId"] as? String,
                  !sessionId.isEmpty else {
                print("⚠️ [CheckoutFlow] Received ShowPaymentSuccess but missing sessionId")
                return
            }

            // Only handle if this notification is for our listing
            if let notificationListingId = userInfo["listingId"] as? String,
               notificationListingId == listingId {
                print("✅ [CheckoutFlow] Payment success notification received for session: \(sessionId)")

                // Close the Safari view and start polling
                self.sessionId = sessionId
                showCheckout = false
                pollCheckoutStatus(sessionId: sessionId)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("ShowPaymentCanceled"))) { notification in
            // Handle payment cancellation notification from BrrowApp deep link handler
            guard let userInfo = notification.userInfo else { return }

            // Only handle if this notification is for our listing
            if let notificationListingId = userInfo["listingId"] as? String,
               notificationListingId == listingId {
                print("❌ [CheckoutFlow] Payment canceled notification received")

                // Close the Safari view and report error
                showCheckout = false
                onCompletion(.failure(CheckoutError.userCanceled))

                // Delay dismiss to let parent view handle completion callback
                Task { @MainActor in
                    try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 second
                    dismiss()
                }
            }
        }
        .alert("Payment Error", isPresented: .constant(errorMessage != nil)) {
            Button("OK") {
                errorMessage = nil
                dismiss()
            }
        } message: {
            if let error = errorMessage {
                Text(error)
            }
        }
    }

    private func createCheckoutSession() async {
        // Prevent double-tap duplicates - only create one session at a time
        guard !isCreatingSession else {
            print("⚠️ [CHECKOUT] Session creation already in progress, ignoring duplicate request")
            return
        }

        isCreatingSession = true
        defer { isCreatingSession = false }

        do {
            let session = try await paymentService.createCheckoutSession(
                listingId: listingId,
                sellerId: sellerId,
                transactionType: transactionType,
                rentalStartDate: rentalStartDate,
                rentalEndDate: rentalEndDate,
                deliveryMethod: deliveryMethod,
                includeInsurance: includeInsurance
            )

            await MainActor.run {
                checkoutURL = session.url
                sessionId = session.sessionId
            }

            // Small delay to ensure URL is ready before presenting Safari
            try? await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds

            await MainActor.run {
                showCheckout = true
            }

        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                onCompletion(.failure(error))
                dismiss()
            }
        }
    }

    private func pollCheckoutStatus(sessionId: String) {
        // Guard against empty session ID
        guard !sessionId.isEmpty else {
            print("⚠️ [CheckoutFlow] Cannot poll with empty session ID")
            return
        }

        isPolling = true

        Task {
            do {
                // Poll for status (backend will have the latest info from webhooks)
                try await Task.sleep(nanoseconds: 2_000_000_000) // 2 second delay

                let status = try await paymentService.checkCheckoutStatus(sessionId: sessionId)

                await MainActor.run {
                    isPolling = false

                    if status.sessionStatus == "complete" {
                        // Payment successful
                        if let transactionId = status.transactionId {
                            onCompletion(.success(transactionId))
                        } else {
                            onCompletion(.failure(CheckoutError.missingSessionId))
                        }

                        // Delay dismiss to let parent view handle completion callback
                        Task { @MainActor in
                            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 second
                            dismiss()
                        }
                    } else {
                        // Payment not yet complete, poll again
                        pollCheckoutStatus(sessionId: sessionId)
                    }
                }

            } catch {
                await MainActor.run {
                    isPolling = false
                    errorMessage = error.localizedDescription
                    onCompletion(.failure(error))

                    // Delay dismiss to let parent view handle completion callback
                    Task { @MainActor in
                        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 second
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Preview
#Preview {
    CheckoutFlowContainer(
        listingId: "test-listing-id",
        sellerId: "test-seller-id",
        transactionType: "SALE",
        rentalStartDate: nil,
        rentalEndDate: nil,
        deliveryMethod: "PICKUP",
        includeInsurance: nil,
        onCompletion: { result in
            switch result {
            case .success(let transactionId):
                print("Payment completed: \(transactionId)")
            case .failure(let error):
                print("Payment failed: \(error)")
            }
        }
    )
}
