//
//  BuyNowConfirmationView.swift
//  Brrow
//
//  Buy Now confirmation with payment hold
//

import SwiftUI
import SafariServices

struct BuyNowConfirmationView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: BuyNowViewModel

    let listing: Listing

    init(listing: Listing) {
        self.listing = listing
        self._viewModel = StateObject(wrappedValue: BuyNowViewModel(listing: listing))
    }

    var body: some View {
        ZStack {
            Theme.Colors.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                header

                ScrollView {
                    VStack(spacing: Theme.Spacing.lg) {
                        // Listing preview
                        listingPreview

                        // Price breakdown
                        priceBreakdown

                        // Payment hold info
                        paymentHoldInfo

                        // 3-day deadline info
                        deadlineInfo

                        // Terms
                        termsSection
                    }
                    .padding(Theme.Spacing.md)
                }

                // Confirm button
                confirmButton
            }
        }
        .alert("Error", isPresented: $viewModel.showErrorAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage)
        }
        .fullScreenCover(isPresented: $viewModel.showReceipt) {
            if let purchase = viewModel.createdPurchase {
                PurchaseReceiptView(purchase: purchase) {
                    // Dismiss confirmation view and refresh marketplace
                    dismiss()
                    // Post notification to refresh marketplace
                    NotificationCenter.default.post(name: Notification.Name("RefreshMarketplace"), object: nil)
                }
            }
        }
        .fullScreenCover(isPresented: $viewModel.showPurchaseStatus) {
            if let purchase = viewModel.createdPurchase {
                PurchaseStatusView(purchase: purchase)
            }
        }
        .fullScreenCover(isPresented: $viewModel.showCheckout) {
            if let checkoutURL = viewModel.checkoutURL {
                SafariView(url: checkoutURL)
                    .ignoresSafeArea()
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
                    .background(Circle().fill(Theme.Colors.cardBackground))
            }

            Spacer()

            Text("Confirm Purchase")
                .font(Theme.Typography.largeTitle)
                .foregroundColor(Theme.Colors.text)

            Spacer()

            Color.clear.frame(width: 44, height: 44)
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.top, 60)
        .padding(.bottom, Theme.Spacing.md)
    }

    // MARK: - Listing Preview
    private var listingPreview: some View {
        HStack(spacing: Theme.Spacing.md) {
            if let imageUrl = listing.images.first?.imageUrl, !imageUrl.isEmpty, let url = URL(string: imageUrl) {
                AsyncImage(url: url) { image in
                    image.resizable().aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle().fill(Theme.Colors.secondaryBackground).overlay(ProgressView())
                }
                .frame(width: 100, height: 100)
                .cornerRadius(Theme.CornerRadius.card)
            } else {
                Rectangle()
                    .fill(Theme.Colors.secondaryBackground)
                    .frame(width: 100, height: 100)
                    .cornerRadius(Theme.CornerRadius.card)
                    .overlay(Image(systemName: "photo").foregroundColor(Theme.Colors.secondaryText))
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(listing.title)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Theme.Colors.text)
                    .lineLimit(2)

                if let seller = listing.user {
                    HStack(spacing: 4) {
                        Image(systemName: "person.circle.fill")
                            .foregroundColor(Theme.Colors.secondaryText)
                        Text(seller.username ?? "Seller")
                            .font(.system(size: 14))
                            .foregroundColor(Theme.Colors.secondaryText)
                    }
                }

                Text("$\(Int(listing.price))")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(Theme.Colors.primary)
            }
            Spacer()
        }
        .padding(Theme.Spacing.md)
        .background(RoundedRectangle(cornerRadius: Theme.CornerRadius.card).fill(Theme.Colors.cardBackground).shadow(color: Theme.Shadows.card, radius: Theme.Shadows.cardRadius))
    }

    // MARK: - Price Breakdown
    private var priceBreakdown: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("Price Breakdown")
                .font(Theme.Typography.headline)
                .foregroundColor(Theme.Colors.text)

            VStack(spacing: Theme.Spacing.sm) {
                HStack {
                    Text("Item Price")
                        .foregroundColor(Theme.Colors.secondaryText)
                    Spacer()
                    Text("$\(Int(listing.price))")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Theme.Colors.text)
                }

                Divider()

                HStack {
                    Text("Total")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(Theme.Colors.text)
                    Spacer()
                    Text("$\(Int(listing.price))")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(Theme.Colors.primary)
                }
            }
            .padding(Theme.Spacing.md)
            .background(Theme.Colors.inputBackground)
            .cornerRadius(Theme.CornerRadius.md)
        }
    }

    // MARK: - Payment Hold Info
    private var paymentHoldInfo: some View {
        HStack(alignment: .top, spacing: Theme.Spacing.sm) {
            Image(systemName: "lock.shield.fill")
                .foregroundColor(Theme.Colors.success)
                .font(.system(size: 24))

            VStack(alignment: .leading, spacing: 6) {
                Text("Secure Escrow Payment")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Theme.Colors.text)

                Text("Your payment is held securely until you verify receipt of the item. The seller won't receive funds until verification is complete.")
                    .font(.system(size: 14))
                    .foregroundColor(Theme.Colors.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(Theme.Spacing.md)
        .background(RoundedRectangle(cornerRadius: Theme.CornerRadius.md).fill(Theme.Colors.success.opacity(0.1)))
    }

    // MARK: - Deadline Info
    private var deadlineInfo: some View {
        HStack(alignment: .top, spacing: Theme.Spacing.sm) {
            Image(systemName: "clock.fill")
                .foregroundColor(Theme.Colors.warning)
                .font(.system(size: 24))

            VStack(alignment: .leading, spacing: 6) {
                Text("3-Day Verification Deadline")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Theme.Colors.text)

                Text("You must meet the seller and verify the item within 3 days. If not completed, your payment will be automatically refunded.")
                    .font(.system(size: 14))
                    .foregroundColor(Theme.Colors.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(Theme.Spacing.md)
        .background(RoundedRectangle(cornerRadius: Theme.CornerRadius.md).fill(Theme.Colors.warning.opacity(0.1)))
    }

    // MARK: - Terms
    private var termsSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("By purchasing, you agree to:")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Theme.Colors.text)

            VStack(alignment: .leading, spacing: 6) {
                bulletPoint("Meet the seller within 3 days")
                bulletPoint("Verify the item's condition in person")
                bulletPoint("Brrow's purchase protection terms")
            }
        }
        .padding(Theme.Spacing.md)
        .background(Theme.Colors.cardBackground)
        .cornerRadius(Theme.CornerRadius.md)
    }

    private func bulletPoint(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
                .foregroundColor(Theme.Colors.primary)
            Text(text)
                .font(.system(size: 13))
                .foregroundColor(Theme.Colors.secondaryText)
        }
    }

    // MARK: - Confirm Button
    private var confirmButton: some View {
        VStack(spacing: 0) {
            Divider()

            Button(action: {
                viewModel.confirmPurchase()
            }) {
                HStack {
                    if viewModel.isLoading {
                        ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Confirm & Pay $\(Int(listing.price))")
                            .font(.system(size: 18, weight: .bold))
                    }
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(RoundedRectangle(cornerRadius: Theme.CornerRadius.card).fill(viewModel.isLoading ? Theme.Colors.secondaryText : Theme.Colors.primary))
            }
            .disabled(viewModel.isLoading)
            .padding(Theme.Spacing.md)
        }
        .background(Theme.Colors.background)
    }
}

// MARK: - ViewModel
class BuyNowViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var showSuccessAlert = false
    @Published var showErrorAlert = false
    @Published var errorMessage = ""
    @Published var showPurchaseStatus = false
    @Published var showCheckout = false
    @Published var checkoutURL: URL?
    @Published var createdPurchase: Purchase?
    @Published var showReceipt = false

    let listing: Listing

    init(listing: Listing) {
        self.listing = listing
        setupNotificationObservers()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    private func setupNotificationObservers() {
        // Listen for payment success from deep link
        NotificationCenter.default.addObserver(
            forName: Notification.Name("ShowPaymentSuccess"),
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self = self else { return }

            if let purchaseId = notification.userInfo?["purchaseId"] as? String {
                print("✅ [BUY NOW] Payment success notification received for purchase: \(purchaseId)")

                // Close checkout view
                self.showCheckout = false

                // Refresh purchase status from backend
                self.refreshPurchaseStatus(purchaseId: purchaseId)
            }
        }

        // Listen for payment cancelation from deep link
        NotificationCenter.default.addObserver(
            forName: Notification.Name("ShowPaymentCanceled"),
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self = self else { return }

            print("❌ [BUY NOW] Payment canceled notification received")

            // Close checkout view
            self.showCheckout = false

            // Show error message
            self.errorMessage = "Payment was canceled. You can try again."
            self.showErrorAlert = true
        }
    }

    private func refreshPurchaseStatus(purchaseId: String) {
        print("🔄 [BUY NOW] Refreshing purchase status for: \(purchaseId)")

        guard let token = KeychainHelper().loadString(forKey: "brrow_auth_token") else {
            return
        }

        guard let url = URL(string: "https://brrow-backend-nodejs-production.up.railway.app/api/purchases/\(purchaseId)") else {
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                if let data = data,
                   let httpResponse = response as? HTTPURLResponse,
                   httpResponse.statusCode == 200 {

                    do {
                        let decoder = JSONDecoder()
                        let dateFormatter = DateFormatter()
                        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
                        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
                        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
                        decoder.dateDecodingStrategy = .formatted(dateFormatter)

                        let response = try decoder.decode(GetPurchaseResponse.self, from: data)
                        print("✅ [BUY NOW] Purchase refreshed - status: \(response.purchase.paymentStatus)")

                        self?.createdPurchase = response.purchase

                        // Show receipt if payment is held
                        if response.purchase.paymentStatus == .held {
                            self?.showReceipt = true
                        } else if response.purchase.paymentStatus == .failed {
                            self?.errorMessage = "Payment failed. Please try again."
                            self?.showErrorAlert = true
                        }
                    } catch {
                        print("❌ [BUY NOW] Failed to decode purchase: \(error)")
                    }
                }
            }
        }.resume()
    }

    func confirmPurchase() {
        print("🛒 [BUY NOW] Starting purchase confirmation")
        print("🛒 Listing ID: \(listing.id)")
        print("🛒 Amount: $\(listing.price)")

        isLoading = true

        guard let token = KeychainHelper().loadString(forKey: "brrow_auth_token") else {
            print("❌ [BUY NOW] No auth token found")
            errorMessage = "Not authenticated"
            showErrorAlert = true
            isLoading = false
            return
        }

        print("✅ [BUY NOW] Auth token retrieved")

        let requestBody: [String: Any] = [
            "listing_id": listing.id,
            "amount": listing.price,
            "purchase_type": "BUY_NOW"
        ]

        print("📦 [BUY NOW] Request body: \(requestBody)")

        guard let url = URL(string: "https://brrow-backend-nodejs-production.up.railway.app/api/purchases") else {
            print("❌ [BUY NOW] Invalid URL")
            errorMessage = "Invalid URL"
            showErrorAlert = true
            isLoading = false
            return
        }

        print("🌐 [BUY NOW] URL: \(url.absoluteString)")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
            print("✅ [BUY NOW] Request body encoded, sending request...")
        } catch {
            print("❌ [BUY NOW] Failed to encode request: \(error)")
            errorMessage = "Failed to encode request"
            showErrorAlert = true
            isLoading = false
            return
        }

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isLoading = false

                if let error = error {
                    print("❌ [BUY NOW] Network error: \(error.localizedDescription)")
                    self?.errorMessage = "Network error: \(error.localizedDescription)"
                    self?.showErrorAlert = true
                    return
                }

                guard let httpResponse = response as? HTTPURLResponse else {
                    print("❌ [BUY NOW] Invalid response")
                    self?.errorMessage = "Invalid response"
                    self?.showErrorAlert = true
                    return
                }

                print("📡 [BUY NOW] Response status code: \(httpResponse.statusCode)")

                if httpResponse.statusCode == 201, let data = data {
                    let responseString = String(data: data, encoding: .utf8) ?? "Unable to decode"
                    print("✅ [BUY NOW] Success response: \(responseString)")

                    do {
                        let decoder = JSONDecoder()
                        // Configure date decoding to handle backend's ISO8601 format with fractional seconds
                        let dateFormatter = DateFormatter()
                        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
                        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
                        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
                        decoder.dateDecodingStrategy = .formatted(dateFormatter)

                        let response = try decoder.decode(CreatePurchaseResponse.self, from: data)
                        print("✅ [BUY NOW] Purchase decoded successfully: \(response.purchase.id)")
                        print("✅ [BUY NOW] Needs payment method: \(response.needsPaymentMethod ?? false)")

                        self?.createdPurchase = response.purchase

                        // Check if user needs to add a payment method
                        if response.needsPaymentMethod == true {
                            // Check if we have a checkout URL (new Stripe Checkout flow)
                            if let checkoutUrlString = response.checkoutUrl,
                               let checkoutURL = URL(string: checkoutUrlString) {
                                print("💳 [BUY NOW] Opening Stripe Checkout - URL: \(checkoutUrlString)")
                                self?.checkoutURL = checkoutURL
                                self?.showCheckout = true
                            } else {
                                // Fallback to old payment method setup flow
                                print("⚠️ [BUY NOW] No checkout URL - showing error")
                                self?.errorMessage = "Unable to process payment. Please try again."
                                self?.showErrorAlert = true
                            }
                        } else {
                            print("✅ [BUY NOW] Payment method already set - showing receipt")
                            self?.showReceipt = true
                        }
                    } catch {
                        print("❌ [BUY NOW] Failed to decode response: \(error)")
                        self?.errorMessage = "Failed to decode response: \(error.localizedDescription)"
                        self?.showErrorAlert = true
                    }
                } else {
                    if let data = data {
                        let responseString = String(data: data, encoding: .utf8) ?? "Unable to decode"
                        print("❌ [BUY NOW] Error response: \(responseString)")

                        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                           let message = json["message"] as? String {
                            self?.errorMessage = message
                        } else {
                            self?.errorMessage = "Purchase failed"
                        }
                    } else {
                        print("❌ [BUY NOW] No response data")
                        self?.errorMessage = "Purchase failed - no response"
                    }
                    self?.showErrorAlert = true
                }
            }
        }.resume()

        print("🚀 [BUY NOW] Request sent, waiting for response...")
    }
}

// MARK: - Safari View for Stripe Checkout
