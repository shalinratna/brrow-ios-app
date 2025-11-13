//
//  ModernMakeOfferView.swift
//  Brrow
//
//  Modern Make Offer UI with Stripe Payment Holds
//

import SwiftUI
import Combine
@_spi(CustomerSessionBetaAccess) import StripePaymentSheet

struct ModernMakeOfferView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: MakeOfferViewModel

    let listing: Listing
    let originalPrice: Double

    init(listing: Listing) {
        self.listing = listing
        self.originalPrice = listing.price
        self._viewModel = StateObject(wrappedValue: MakeOfferViewModel(listing: listing))
    }

    var body: some View {
        ZStack {
            Theme.Colors.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Custom Header
                header

                ScrollView {
                    VStack(spacing: Theme.Spacing.lg) {
                        // Listing Preview
                        listingPreview

                        // Offer Amount Section
                        offerAmountSection

                        // Quick Adjustment Buttons
                        quickAdjustmentButtons

                        // Message Section
                        messageSection

                        // Payment Hold Disclaimer
                        paymentHoldDisclaimer
                    }
                    .padding(.horizontal, Theme.Spacing.md)
                    .padding(.top, Theme.Spacing.md)
                }

                // Send Offer Button
                sendOfferButton
            }
        }
        .alert("Offer Sent!", isPresented: $viewModel.showSuccessAlert) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("Your offer of $\(Int(viewModel.offerAmount)) has been sent! Funds are held on your card pending seller response.")
        }
        .alert("Error", isPresented: $viewModel.showErrorAlert) {
            Button("Try Again", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage)
        }
        .onChange(of: viewModel.shouldPresentPaymentSheet) { shouldPresent in
            if shouldPresent {
                viewModel.presentPaymentSheet()
            }
        }
    }

    // MARK: - Header
    private var header: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(.title3)
                    .foregroundColor(Theme.Colors.text)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(Theme.Colors.cardBackground)
                    )
            }

            Spacer()

            Text("Make an Offer")
                .font(Theme.Typography.largeTitle)
                .foregroundColor(Theme.Colors.text)

            Spacer()

            Color.clear
                .frame(width: 44, height: 44)
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.top, 60)
        .padding(.bottom, Theme.Spacing.md)
        .background(Theme.Colors.background)
    }

    // MARK: - Listing Preview
    private var listingPreview: some View {
        HStack(spacing: Theme.Spacing.md) {
            // Image
            if let imageUrl = listing.images.first?.imageUrl, let url = URL(string: imageUrl) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Theme.Colors.secondaryBackground)
                        .overlay(
                            ProgressView()
                        )
                }
                .frame(width: 80, height: 80)
                .cornerRadius(Theme.CornerRadius.card)
            } else {
                Rectangle()
                    .fill(Theme.Colors.secondaryBackground)
                    .frame(width: 80, height: 80)
                    .cornerRadius(Theme.CornerRadius.card)
                    .overlay(
                        Image(systemName: "photo")
                            .foregroundColor(Theme.Colors.secondaryText)
                    )
            }

            // Info
            VStack(alignment: .leading, spacing: 6) {
                Text(listing.title)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Theme.Colors.text)
                    .lineLimit(2)

                HStack(spacing: 8) {
                    Text("Original Price:")
                        .font(.system(size: 14))
                        .foregroundColor(Theme.Colors.secondaryText)

                    Text("$\(Int(originalPrice))")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(Theme.Colors.secondaryText)
                        .strikethrough()
                }
            }

            Spacer()
        }
        .padding(Theme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.card)
                .fill(Theme.Colors.cardBackground)
                .shadow(color: Theme.Shadows.card, radius: Theme.Shadows.cardRadius)
        )
    }

    // MARK: - Offer Amount Section
    private var offerAmountSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Your Offer")
                .font(Theme.Typography.headline)
                .foregroundColor(Theme.Colors.text)

            HStack {
                Text("$")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(Theme.Colors.primary)

                TextField("0", text: $viewModel.offerAmountText)
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(Theme.Colors.primary)
                    .keyboardType(.decimalPad)
                    .onChange(of: viewModel.offerAmountText) { newValue in
                        viewModel.validateOfferAmount(newValue)
                    }
            }
            .padding(Theme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                    .fill(Theme.Colors.inputBackground)
            )

            // Savings Display
            if viewModel.offerAmount > 0 && viewModel.offerAmount < originalPrice {
                HStack {
                    Image(systemName: "arrow.down.circle.fill")
                        .foregroundColor(Theme.Colors.success)
                    Text("You'll save $\(Int(originalPrice - viewModel.offerAmount))")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Theme.Colors.success)
                }
                .padding(.top, 4)
            }
        }
    }

    // MARK: - Quick Adjustment Buttons
    private var quickAdjustmentButtons: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Quick Adjust")
                .font(Theme.Typography.body)
                .foregroundColor(Theme.Colors.secondaryText)

            HStack(spacing: Theme.Spacing.sm) {
                ForEach([-25, -10, -5, 5, 10, 25], id: \.self) { adjustment in
                    Button(action: {
                        viewModel.adjustOffer(by: Double(adjustment))
                    }) {
                        Text("\(adjustment > 0 ? "+" : "")\(adjustment)")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(adjustment < 0 ? Theme.Colors.primary : Theme.Colors.accent)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Theme.Spacing.sm)
                            .background(
                                RoundedRectangle(cornerRadius: Theme.CornerRadius.card)
                                    .fill(adjustment < 0 ? Theme.Colors.primary.opacity(0.1) : Theme.Colors.accent.opacity(0.1))
                            )
                    }
                }
            }
        }
    }

    // MARK: - Message Section
    private var messageSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Add a Message (Optional)")
                .font(Theme.Typography.headline)
                .foregroundColor(Theme.Colors.text)

            TextEditor(text: $viewModel.message)
                .font(Theme.Typography.body)
                .foregroundColor(Theme.Colors.text)
                .frame(height: 100)
                .padding(Theme.Spacing.sm)
                .background(Theme.Colors.inputBackground)
                .cornerRadius(Theme.CornerRadius.md)
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                        .stroke(Theme.Colors.border, lineWidth: 1)
                )
        }
    }

    // MARK: - Payment Hold Disclaimer
    private var paymentHoldDisclaimer: some View {
        HStack(alignment: .top, spacing: Theme.Spacing.sm) {
            Image(systemName: "info.circle.fill")
                .foregroundColor(Theme.Colors.info)
                .font(.system(size: 20))

            VStack(alignment: .leading, spacing: 4) {
                Text("Payment Authorization")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Theme.Colors.text)

                Text("Your card will be authorized for $\(Int(viewModel.offerAmount)) but not charged until the seller accepts your offer. The hold will be released if declined or if there's no response within 7 days.")
                    .font(.system(size: 13))
                    .foregroundColor(Theme.Colors.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(Theme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                .fill(Theme.Colors.info.opacity(0.1))
        )
    }

    // MARK: - Send Offer Button
    private var sendOfferButton: some View {
        VStack(spacing: 0) {
            Divider()

            Button(action: {
                viewModel.sendOffer()
            }) {
                HStack {
                    if viewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Send Offer")
                            .font(.system(size: 18, weight: .bold))
                    }
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    RoundedRectangle(cornerRadius: Theme.CornerRadius.card)
                        .fill(viewModel.canSendOffer ? Theme.Colors.primary : Theme.Colors.secondaryText)
                )
            }
            .disabled(!viewModel.canSendOffer || viewModel.isLoading)
            .padding(Theme.Spacing.md)
        }
        .background(Theme.Colors.background)
    }
}

// MARK: - ViewModel
class MakeOfferViewModel: ObservableObject {
    @Published var offerAmountText: String = ""
    @Published var offerAmount: Double = 0
    @Published var message: String = ""
    @Published var isLoading: Bool = false
    @Published var showSuccessAlert: Bool = false
    @Published var showErrorAlert: Bool = false
    @Published var errorMessage: String = ""
    @Published var paymentSheet: PaymentSheet?
    @Published var shouldPresentPaymentSheet: Bool = false

    let listing: Listing
    let originalPrice: Double
    private var currentTask: URLSessionDataTask?
    private var cancellables = Set<AnyCancellable>()
    private var currentOfferId: Int?
    private var currentClientSecret: String?

    init(listing: Listing) {
        self.listing = listing
        self.originalPrice = listing.price

        // Set initial offer to 80% of listing price
        let initialOffer = listing.price * 0.8
        self.offerAmount = initialOffer
        self.offerAmountText = String(Int(initialOffer))
    }

    deinit {
        // Cancel any in-flight network requests
        currentTask?.cancel()
        cancellables.removeAll()
    }

    var canSendOffer: Bool {
        return offerAmount > 0 && offerAmount <= originalPrice && !isLoading
    }

    func validateOfferAmount(_ text: String) {
        // Remove non-numeric characters
        let filtered = text.filter { $0.isNumber }

        if let amount = Double(filtered) {
            offerAmount = amount
            offerAmountText = filtered
        } else {
            offerAmount = 0
            offerAmountText = ""
        }
    }

    func adjustOffer(by amount: Double) {
        let newAmount = offerAmount + amount
        if newAmount > 0 && newAmount <= originalPrice {
            offerAmount = newAmount
            offerAmountText = String(Int(newAmount))
        }
    }

    func sendOffer() {
        guard canSendOffer else { return }

        // Cancel any existing request
        currentTask?.cancel()

        isLoading = true

        // Get auth token
        guard let token = KeychainHelper().loadString(forKey: "brrow_auth_token") else {
            errorMessage = "Not authenticated. Please log in again."
            showErrorAlert = true
            isLoading = false
            return
        }

        // Prepare request
        let requestBody: [String: Any] = [
            "listingId": listing.id,
            "amount": offerAmount,
            "message": message.isEmpty ? nil : message,
            "duration": 1 // Default 1 day
        ]

        guard let url = URL(string: "https://brrow-backend-nodejs-production.up.railway.app/api/offers") else {
            errorMessage = "Invalid URL"
            showErrorAlert = true
            isLoading = false
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            errorMessage = "Failed to encode request: \(error.localizedDescription)"
            showErrorAlert = true
            isLoading = false
            return
        }

        // Send request and store task for cancellation
        currentTask = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }

            DispatchQueue.main.async {
                // Clear current task reference
                self.currentTask = nil
                self.isLoading = false

                // Handle cancellation
                if let error = error as NSError?, error.code == NSURLErrorCancelled {
                    return // Silently ignore cancelled requests
                }

                if let error = error {
                    self.errorMessage = "Network error: \(error.localizedDescription)"
                    self.showErrorAlert = true
                    return
                }

                guard let httpResponse = response as? HTTPURLResponse else {
                    self.errorMessage = "Invalid response"
                    self.showErrorAlert = true
                    return
                }

                if httpResponse.statusCode == 201 {
                    // Success - parse response and setup payment
                    guard let data = data,
                          let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                          let responseData = json["data"] as? [String: Any],
                          let clientSecret = responseData["clientSecret"] as? String,
                          let customerSessionClientSecret = responseData["customerSessionClientSecret"] as? String,
                          let customerId = responseData["customerId"] as? String,
                          let offerId = responseData["id"] as? Int else {
                        self.errorMessage = "Invalid response from server"
                        self.showErrorAlert = true
                        return
                    }

                    // Store offer ID and client secret
                    self.currentOfferId = offerId
                    self.currentClientSecret = clientSecret

                    print("💳 Received offer response:")
                    print("   Offer ID: \(offerId)")
                    print("   Client Secret: \(clientSecret.prefix(30))...")
                    print("   Customer ID: \(customerId)")
                    print("   Customer Session: \(customerSessionClientSecret.prefix(30))...")

                    // Setup and present payment sheet with Customer Session auth
                    self.setupPaymentSheet(
                        clientSecret: clientSecret,
                        customerId: customerId,
                        customerSessionClientSecret: customerSessionClientSecret
                    )
                } else if httpResponse.statusCode == 402 {
                    self.errorMessage = "Payment method declined. Please add a valid payment method."
                    self.showErrorAlert = true
                } else {
                    // Parse error message
                    if let data = data,
                       let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let error = json["error"] as? String {
                        self.errorMessage = error
                    } else {
                        self.errorMessage = "Failed to send offer. Please try again."
                    }
                    self.showErrorAlert = true
                }
            }
        }

        currentTask?.resume()
    }

    // MARK: - Stripe Payment Sheet

    private func setupPaymentSheet(
        clientSecret: String,
        customerId: String,
        customerSessionClientSecret: String
    ) {
        var configuration = PaymentSheet.Configuration()
        configuration.merchantDisplayName = "Brrow"
        configuration.allowsDelayedPaymentMethods = false
        configuration.returnURL = "brrowapp://stripe-redirect"

        // Stripe SDK 25.0+ — Customer Session auth with customer ID and ephemeral key
        configuration.customer = PaymentSheet.CustomerConfiguration(id: customerId, ephemeralKeySecret: customerSessionClientSecret)

        paymentSheet = PaymentSheet(
            paymentIntentClientSecret: clientSecret,
            configuration: configuration
        )

        // Trigger payment sheet presentation
        shouldPresentPaymentSheet = true
    }

    func presentPaymentSheet() {
        guard let paymentSheet = paymentSheet else { return }

        // CRITICAL FIX: Get the topmost presented view controller, not just root
        // This prevents "already presenting" crash when ModernMakeOfferView is shown as sheet
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first,
              let rootViewController = window.rootViewController else {
            print("❌ Failed to get root view controller for PaymentSheet")
            errorMessage = "Unable to present payment sheet"
            showErrorAlert = true
            return
        }

        // Find the topmost presented view controller
        var topController = rootViewController
        while let presented = topController.presentedViewController {
            topController = presented
        }

        // Ensure we're not already presenting something
        guard topController.presentedViewController == nil else {
            print("⚠️ View controller is already presenting, waiting...")
            // Retry after a short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.presentPaymentSheet()
            }
            return
        }

        print("✅ Presenting PaymentSheet from: \(type(of: topController))")
        paymentSheet.present(from: topController) { [weak self] result in
            self?.handlePaymentResult(result)
        }
    }

    private func handlePaymentResult(_ result: PaymentSheetResult) {
        switch result {
        case .completed:
            // Payment confirmed successfully
            print("✅ Payment completed for offer \(currentOfferId ?? 0)")
            showSuccessAlert = true

        case .canceled:
            // User cancelled payment
            print("❌ Payment cancelled by user")
            errorMessage = "Payment cancelled. Your offer was not sent."
            showErrorAlert = true

        case .failed(let error):
            // Payment failed
            print("❌ Payment failed: \(error.localizedDescription)")
            errorMessage = "Payment failed: \(error.localizedDescription)"
            showErrorAlert = true
        }

        // Clean up
        paymentSheet = nil
        shouldPresentPaymentSheet = false
    }
}
