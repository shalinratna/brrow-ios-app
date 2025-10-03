//
//  StripePaymentFlowView.swift
//  Brrow
//
//  Complete Stripe payment flow with escrow support
//

import SwiftUI
import StripePaymentSheet

struct StripePaymentFlowView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var paymentService = PaymentService.shared
    @EnvironmentObject var authManager: AuthManager

    // Listing information
    let listing: Listing
    let transactionType: PaymentTransactionType
    let rentalStartDate: Date?
    let rentalEndDate: Date?
    let deliveryMethod: String

    // UI State
    @State private var isProcessing = false
    @State private var paymentSheet: PaymentSheet?
    @State private var paymentResult: PaymentSheetResult?
    @State private var showSuccess = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var transactionId: String?
    @State private var clientSecret: String?
    @State private var buyerMessage = ""

    // Calculated properties
    private var totalDays: Int {
        guard let start = rentalStartDate, let end = rentalEndDate else { return 1 }
        return max(1, Calendar.current.dateComponents([.day], from: start, to: end).day ?? 1)
    }

    private var baseAmount: Double {
        if transactionType == .rental {
            let dailyRate = listing.dailyRate ?? listing.price
            return dailyRate * Double(totalDays)
        }
        return listing.price
    }

    private var costBreakdown: (total: Double, platformFee: Double, stripeFee: Double) {
        return paymentService.calculateTotalCost(amount: baseAmount)
    }

    var body: some View {
        NavigationView {
            ZStack {
                Theme.Colors.background.edgesIgnoringSafeArea(.all)

                ScrollView {
                    VStack(spacing: 24) {
                        // Header with listing info
                        listingHeaderView

                        // Transaction details
                        transactionDetailsView

                        // Cost breakdown
                        costBreakdownView

                        // Buyer message
                        buyerMessageView

                        // Payment button
                        paymentButton

                        // Security badges
                        securityBadgesView
                    }
                    .padding()
                }

                // Success overlay
                if showSuccess {
                    PaymentSuccessOverlay(
                        transactionType: transactionType,
                        amount: baseAmount,
                        onDismiss: {
                            presentationMode.wrappedValue.dismiss()
                        }
                    )
                }
            }
            .navigationTitle("Payment")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
            .alert("Payment Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }

    // MARK: - UI Components

    private var listingHeaderView: some View {
        HStack(spacing: 16) {
            // Listing image
            if let firstImage = listing.images.first, let urlString = firstImage.url, let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .failure, .empty:
                        Image(systemName: "photo")
                            .foregroundColor(.gray)
                    @unknown default:
                        ProgressView()
                    }
                }
                .frame(width: 80, height: 80)
                .cornerRadius(12)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(listing.title)
                    .font(.headline)
                    .foregroundColor(Theme.Colors.text)

                Text(listing.locationString)
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                if transactionType == .rental {
                    Text("Daily Rate: \(paymentService.formatCurrency(listing.dailyRate ?? listing.price))")
                        .font(.caption)
                        .foregroundColor(Theme.Colors.primary)
                }
            }

            Spacer()
        }
        .padding()
        .background(Theme.Colors.secondaryBackground)
        .cornerRadius(12)
    }

    private var transactionDetailsView: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Transaction Type")
                    .foregroundColor(.secondary)
                Spacer()
                Text(transactionType == PaymentTransactionType.rental ? "Rental" : "Purchase")
                    .fontWeight(.semibold)
                    .foregroundColor(Theme.Colors.text)
            }

            if transactionType == PaymentTransactionType.rental, let start = rentalStartDate, let end = rentalEndDate {
                Divider()

                HStack {
                    Text("Rental Period")
                        .foregroundColor(.secondary)
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(start, style: .date) - \(end, style: .date)")
                            .foregroundColor(Theme.Colors.text)
                        Text("\(totalDays) day\(totalDays == 1 ? "" : "s")")
                            .font(.caption)
                            .foregroundColor(Theme.Colors.primary)
                    }
                }
            }

            Divider()

            HStack {
                Text("Delivery Method")
                    .foregroundColor(.secondary)
                Spacer()
                Text(deliveryMethod)
                    .fontWeight(.semibold)
                    .foregroundColor(Theme.Colors.text)
            }
        }
        .padding()
        .background(Theme.Colors.secondaryBackground)
        .cornerRadius(12)
    }

    private var costBreakdownView: some View {
        VStack(spacing: 12) {
            Text("Cost Breakdown")
                .font(.headline)
                .foregroundColor(Theme.Colors.text)
                .frame(maxWidth: .infinity, alignment: .leading)

            VStack(spacing: 8) {
                PaymentCostRow(
                    label: transactionType == .rental ? "Rental Cost (\(totalDays) days)" : "Item Price",
                    amount: baseAmount
                )

                PaymentCostRow(
                    label: "Platform Fee (5%)",
                    amount: costBreakdown.platformFee,
                    isSecondary: true
                )

                PaymentCostRow(
                    label: "Payment Processing",
                    amount: costBreakdown.stripeFee,
                    isSecondary: true
                )

                Divider()
                    .padding(.vertical, 4)

                HStack {
                    Text("Total")
                        .font(.headline)
                        .foregroundColor(Theme.Colors.text)
                    Spacer()
                    Text(paymentService.formatCurrency(costBreakdown.total))
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(Theme.Colors.primary)
                }
            }
        }
        .padding()
        .background(Theme.Colors.secondaryBackground)
        .cornerRadius(12)
    }

    private var buyerMessageView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Message to Seller (Optional)")
                .font(.headline)
                .foregroundColor(Theme.Colors.text)

            TextEditor(text: $buyerMessage)
                .frame(height: 80)
                .padding(8)
                .background(Theme.Colors.background)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
        }
        .padding()
        .background(Theme.Colors.secondaryBackground)
        .cornerRadius(12)
    }

    private var paymentButton: some View {
        Button(action: initiatePayment) {
            HStack {
                if isProcessing {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    Text("Processing...")
                } else {
                    Image(systemName: "lock.shield.fill")
                    Text("Pay \(paymentService.formatCurrency(costBreakdown.total))")
                }
            }
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(isProcessing ? Color.gray : Theme.Colors.primary)
            .cornerRadius(12)
        }
        .disabled(isProcessing)
    }

    private var securityBadgesView: some View {
        VStack(spacing: 12) {
            Text("Your payment is secured by Stripe")
                .font(.caption)
                .foregroundColor(.secondary)

            HStack(spacing: 20) {
                SecurityBadge(icon: "lock.shield.fill", text: "Encrypted")
                SecurityBadge(icon: "checkmark.shield.fill", text: "PCI Compliant")
                SecurityBadge(icon: "building.columns.fill", text: "Escrow Protected")
            }
        }
        .padding()
    }

    // MARK: - Payment Logic

    private func initiatePayment() {
        isProcessing = true
        errorMessage = ""

        Task {
            do {
                // Step 1: Create payment intent on backend
                let paymentIntent = try await paymentService.createMarketplacePaymentIntent(
                    listingId: listing.id,
                    sellerId: listing.userId,
                    transactionType: transactionType == PaymentTransactionType.rental ? "RENTAL" : "PURCHASE",
                    rentalStartDate: rentalStartDate,
                    rentalEndDate: rentalEndDate,
                    deliveryMethod: deliveryMethod,
                    buyerMessage: buyerMessage.isEmpty ? nil : buyerMessage
                )

                // Step 2: Store transaction ID for later confirmation
                await MainActor.run {
                    self.transactionId = paymentIntent.transactionId
                    self.clientSecret = paymentIntent.clientSecret
                }

                // Step 3: Configure and present Stripe payment sheet
                var configuration = PaymentSheet.Configuration()
                configuration.merchantDisplayName = "Brrow"
                configuration.allowsDelayedPaymentMethods = false

                // Customer configuration
                if let customerId = authManager.currentUser?.stripeCustomerId {
                    configuration.customer = .init(
                        id: customerId,
                        ephemeralKeySecret: paymentIntent.clientSecret
                    )
                }

                let sheet = PaymentSheet(
                    paymentIntentClientSecret: paymentIntent.clientSecret,
                    configuration: configuration
                )

                await MainActor.run {
                    self.paymentSheet = sheet
                    presentPaymentSheet()
                }

            } catch PaymentError.sellerOnboardingRequired {
                await MainActor.run {
                    isProcessing = false
                    errorMessage = "The seller needs to complete their payment setup before accepting payments."
                    showError = true
                }
            } catch {
                await MainActor.run {
                    isProcessing = false
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }

    private func presentPaymentSheet() {
        guard let paymentSheet = paymentSheet else {
            isProcessing = false
            return
        }

        // Get the current view controller
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first,
              let rootViewController = window.rootViewController else {
            isProcessing = false
            errorMessage = "Unable to present payment sheet"
            showError = true
            return
        }

        var topController = rootViewController
        while let presentedController = topController.presentedViewController {
            topController = presentedController
        }

        paymentSheet.present(from: topController) { result in
            handlePaymentResult(result)
        }
    }

    private func handlePaymentResult(_ result: PaymentSheetResult) {
        switch result {
        case .completed:
            // Payment succeeded - confirm on backend
            confirmPayment()

        case .canceled:
            isProcessing = false
            // User canceled - do nothing

        case .failed(let error):
            isProcessing = false
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    private func confirmPayment() {
        guard let transactionId = transactionId else {
            isProcessing = false
            errorMessage = "Transaction ID missing"
            showError = true
            return
        }

        Task {
            do {
                try await paymentService.confirmPayment(transactionId: transactionId)

                await MainActor.run {
                    isProcessing = false
                    showSuccess = true

                    // Show success toast
                    ToastManager.shared.showSuccess(
                        title: "Payment Successful",
                        message: transactionType == .rental ? "Rental confirmed! Check your messages." : "Purchase confirmed! Check your messages."
                    )

                    // Haptic feedback
                    HapticManager.notification(type: .success)
                }
            } catch {
                await MainActor.run {
                    isProcessing = false
                    errorMessage = "Payment processed but confirmation failed. Please contact support."
                    showError = true
                }
            }
        }
    }
}

// MARK: - Supporting Views

struct PaymentCostRow: View {
    let label: String
    let amount: Double
    var isSecondary: Bool = false

    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(isSecondary ? .secondary : Theme.Colors.text)
            Spacer()
            Text(PaymentService.shared.formatCurrency(amount))
                .foregroundColor(isSecondary ? .secondary : Theme.Colors.text)
        }
        .font(isSecondary ? .subheadline : .body)
    }
}

struct PaymentSuccessOverlay: View {
    let transactionType: PaymentTransactionType
    let amount: Double
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .edgesIgnoringSafeArea(.all)

            VStack(spacing: 24) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 70))
                    .foregroundColor(Theme.Colors.success)

                VStack(spacing: 8) {
                    Text("Payment Successful!")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text(PaymentService.shared.formatCurrency(amount))
                        .font(.title)
                        .foregroundColor(Theme.Colors.primary)

                    Text(transactionType == PaymentTransactionType.rental ? "Your rental is confirmed" : "Your purchase is confirmed")
                        .font(.body)
                        .foregroundColor(.secondary)
                }

                VStack(spacing: 12) {
                    Button(action: onDismiss) {
                        Text("View Transaction")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Theme.Colors.primary)
                            .cornerRadius(12)
                    }

                    Button(action: onDismiss) {
                        Text("Done")
                            .font(.headline)
                            .foregroundColor(Theme.Colors.primary)
                    }
                }
            }
            .padding(32)
            .background(Theme.Colors.secondaryBackground)
            .cornerRadius(20)
            .padding(40)
        }
    }
}

// MARK: - Transaction Type Enum

enum PaymentTransactionType {
    case purchase
    case rental
}

// MARK: - Preview Provider

struct StripePaymentFlowView_Previews: PreviewProvider {
    static var previews: some View {
        StripePaymentFlowView(
            listing: Listing.example,
            transactionType: PaymentTransactionType.rental,
            rentalStartDate: Date(),
            rentalEndDate: Calendar.current.date(byAdding: .day, value: 3, to: Date()),
            deliveryMethod: "PICKUP"
        )
        .environmentObject(AuthManager.shared)
    }
}
