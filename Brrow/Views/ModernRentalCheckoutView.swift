//
//  ModernRentalCheckoutView.swift
//  Brrow
//
//  Modern, intuitive rental checkout screen matching the quality of Rental Details
//

import SwiftUI
import StripePaymentSheet

struct ModernRentalCheckoutView: View {
    let listing: Listing
    let startDate: Date
    let endDate: Date
    let onDismiss: () -> Void

    @StateObject private var paymentService = PaymentService.shared
    @State private var deliveryMethod: DeliveryMethod = .pickup
    @State private var buyerMessage = ""
    @State private var includeInsurance = true
    @State private var paymentSheet: PaymentSheet?
    @State private var paymentIntent: MarketplacePaymentIntent?
    @State private var isProcessing = false
    @State private var showingSuccess = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @Environment(\.presentationMode) var presentationMode

    private let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
    private let insuranceRate: Double = 0.15 // 15% of rental cost for insurance

    enum DeliveryMethod: String, CaseIterable {
        case pickup = "PICKUP"
        case delivery = "DELIVERY"
        case shipping = "SHIPPING"

        var title: String {
            switch self {
            case .pickup: return "Pickup"
            case .delivery: return "Delivery"
            case .shipping: return "Shipping"
            }
        }

        var icon: String {
            switch self {
            case .pickup: return "car.fill"
            case .delivery: return "truck.box.fill"
            case .shipping: return "shippingbox.fill"
            }
        }

        var description: String {
            switch self {
            case .pickup: return "Meet in person to pick up the item"
            case .delivery: return "Seller delivers to your location"
            case .shipping: return "Item shipped via mail/courier"
            }
        }
    }

    // Calculate rental days
    var rentalDays: Int {
        max(1, Calendar.current.dateComponents([.day], from: startDate, to: endDate).day ?? 1)
    }

    // Base rental cost
    var rentalCost: Double {
        listing.displayPrice * Double(rentalDays)
    }

    // Insurance cost (15% of rental cost)
    var insuranceCost: Double {
        includeInsurance ? rentalCost * insuranceRate : 0
    }

    // Total the user pays (rental + insurance if selected)
    var totalCost: Double {
        rentalCost + insuranceCost
    }

    var body: some View {
        NavigationView {
            ZStack {
                Theme.Colors.background
                    .ignoresSafeArea()

                if isProcessing {
                    processingView
                } else if showingSuccess {
                    successView
                } else {
                    checkoutContentView
                }
            }
            .navigationTitle("Complete Rental")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                        onDismiss()
                    }
                    .foregroundColor(Theme.Colors.primary)
                }
            }
        }
        .alert("Rental Failed", isPresented: $showingError) {
            Button("OK") {
                isProcessing = false
            }
        } message: {
            Text(errorMessage)
        }
    }

    // MARK: - Main Checkout Content
    private var checkoutContentView: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                // Item Summary Card
                itemSummaryCard

                // Rental Period Card
                rentalPeriodCard

                // Delivery Method Card
                deliveryMethodCard

                // Optional Message Card
                messageCard

                // Insurance Option Card
                insuranceCard

                // Price Breakdown Card
                priceBreakdownCard

                // Checkout Button
                checkoutButton

                // Trust badges
                trustBadges

                // Bottom padding
                Color.clear.frame(height: 20)
            }
            .padding(20)
        }
    }

    // MARK: - Item Summary Card
    private var itemSummaryCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 16) {
                // Item Image
                BrrowAsyncImage(url: listing.images.first?.imageUrl) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.2))
                }
                .frame(width: 80, height: 80)
                .clipShape(RoundedRectangle(cornerRadius: 12))

                // Item Info
                VStack(alignment: .leading, spacing: 8) {
                    Text(listing.title)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(Theme.Colors.text)
                        .lineLimit(2)

                    HStack(spacing: 4) {
                        Text("$\(listing.displayPrice, specifier: "%.2f")")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(Theme.Colors.primary)
                        Text("/day")
                            .font(.system(size: 14))
                            .foregroundColor(Theme.Colors.secondaryText)
                    }

                    // Rental badge
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.system(size: 11))
                        Text("Rental")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Theme.Colors.primary.opacity(0.9))
                    .cornerRadius(8)
                }

                Spacer()
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Theme.Colors.cardBackground)
                .shadow(color: Theme.Shadows.card, radius: Theme.Shadows.cardRadius, x: 0, y: 2)
        )
    }

    // MARK: - Rental Period Card
    private var rentalPeriodCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "calendar.circle.fill")
                    .foregroundColor(Theme.Colors.primary)
                    .font(.system(size: 20))
                Text("Rental Period")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Theme.Colors.text)
            }

            // Date display
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Start Date")
                        .font(.system(size: 13))
                        .foregroundColor(Theme.Colors.secondaryText)
                    Text(formatDate(startDate))
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(Theme.Colors.text)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Theme.Colors.secondaryBackground)
                )

                Image(systemName: "arrow.right")
                    .foregroundColor(Theme.Colors.primary)
                    .font(.system(size: 16, weight: .semibold))

                VStack(alignment: .leading, spacing: 6) {
                    Text("Return Date")
                        .font(.system(size: 13))
                        .foregroundColor(Theme.Colors.secondaryText)
                    Text(formatDate(endDate))
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(Theme.Colors.text)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Theme.Colors.secondaryBackground)
                )
            }

            // Duration highlight
            HStack {
                Image(systemName: "clock.fill")
                    .font(.system(size: 14))
                Text("\(rentalDays) \(rentalDays == 1 ? "day" : "days") rental")
                    .font(.system(size: 15, weight: .medium))
            }
            .foregroundColor(Theme.Colors.primary)
            .frame(maxWidth: .infinity)
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Theme.Colors.primary.opacity(0.1))
            )
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Theme.Colors.cardBackground)
                .shadow(color: Theme.Shadows.card, radius: Theme.Shadows.cardRadius, x: 0, y: 2)
        )
    }

    // MARK: - Delivery Method Card
    private var deliveryMethodCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "shippingbox.circle.fill")
                    .foregroundColor(Theme.Colors.primary)
                    .font(.system(size: 20))
                Text("Pickup & Return")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Theme.Colors.text)
            }

            Text("Choose how you'll receive and return this item")
                .font(.system(size: 14))
                .foregroundColor(Theme.Colors.secondaryText)

            VStack(spacing: 12) {
                ForEach(DeliveryMethod.allCases, id: \.self) { method in
                    DeliveryMethodRow(
                        method: method,
                        isSelected: deliveryMethod == method
                    ) {
                        impactFeedback.impactOccurred()
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            deliveryMethod = method
                        }
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Theme.Colors.cardBackground)
                .shadow(color: Theme.Shadows.card, radius: Theme.Shadows.cardRadius, x: 0, y: 2)
        )
    }

    // MARK: - Message Card
    private var messageCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "message.circle.fill")
                    .foregroundColor(Theme.Colors.primary)
                    .font(.system(size: 20))
                Text("Message to Owner")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Theme.Colors.text)
                Text("(Optional)")
                    .font(.system(size: 14))
                    .foregroundColor(Theme.Colors.secondaryText)
            }

            Text("Share any questions or special requests")
                .font(.system(size: 14))
                .foregroundColor(Theme.Colors.secondaryText)

            TextEditor(text: $buyerMessage)
                .frame(minHeight: 80)
                .padding(12)
                .background(Theme.Colors.secondaryBackground)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Theme.Colors.border.opacity(0.2), lineWidth: 1)
                )
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Theme.Colors.cardBackground)
                .shadow(color: Theme.Shadows.card, radius: Theme.Shadows.cardRadius, x: 0, y: 2)
        )
    }

    // MARK: - Insurance Card
    private var insuranceCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "shield.checkered")
                    .foregroundColor(Theme.Colors.primary)
                    .font(.system(size: 20))
                Text("Rental Protection")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Theme.Colors.text)
            }

            Text("Protect yourself against accidental damage, loss, or theft")
                .font(.system(size: 14))
                .foregroundColor(Theme.Colors.secondaryText)

            Toggle(isOn: $includeInsurance) {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Add Insurance Protection")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Theme.Colors.text)

                        Text("Coverage up to item value • 24/7 support")
                            .font(.system(size: 13))
                            .foregroundColor(Theme.Colors.secondaryText)
                    }

                    Spacer()

                    Text(String(format: "+$%.2f", rentalCost * insuranceRate))
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(Theme.Colors.primary)
                }
            }
            .toggleStyle(SwitchToggleStyle(tint: Theme.Colors.primary))
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(includeInsurance ? Theme.Colors.primary.opacity(0.08) : Theme.Colors.secondaryBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(includeInsurance ? Theme.Colors.primary : Color.clear, lineWidth: 2)
            )
            .onChange(of: includeInsurance) { _ in
                impactFeedback.impactOccurred()
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Theme.Colors.cardBackground)
                .shadow(color: Theme.Shadows.card, radius: Theme.Shadows.cardRadius, x: 0, y: 2)
        )
    }

    // MARK: - Price Breakdown Card
    private var priceBreakdownCard: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "dollarsign.circle.fill")
                    .foregroundColor(Theme.Colors.primary)
                    .font(.system(size: 20))
                Text("Price Summary")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Theme.Colors.text)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(spacing: 12) {
                PriceRow(
                    title: "Rental Cost",
                    value: String(format: "$%.2f × %d %@", listing.displayPrice, rentalDays, rentalDays == 1 ? "day" : "days"),
                    isBold: false
                )

                if includeInsurance {
                    PriceRow(
                        title: "Insurance Protection",
                        value: String(format: "$%.2f", insuranceCost),
                        isBold: false
                    )
                }

                Divider()
                    .background(Theme.Colors.secondary.opacity(0.3))
                    .padding(.vertical, 4)

                PriceRow(
                    title: "Total",
                    value: String(format: "$%.2f", totalCost),
                    isBold: true,
                    valueColor: Theme.Colors.primary
                )
            }

            // Security deposit note (if applicable)
            if let securityDeposit = listing.securityDeposit, securityDeposit > 0 {
                HStack(spacing: 8) {
                    Image(systemName: "shield.checkered")
                        .font(.system(size: 14))
                    Text("Security deposit of $\(securityDeposit, specifier: "%.2f") will be held and returned after item return")
                        .font(.system(size: 13))
                }
                .foregroundColor(Theme.Colors.secondaryText)
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Theme.Colors.warning.opacity(0.1))
                .cornerRadius(10)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Theme.Colors.cardBackground)
                .shadow(color: Theme.Shadows.card, radius: Theme.Shadows.cardRadius, x: 0, y: 2)
        )
    }

    // MARK: - Checkout Button
    private var checkoutButton: some View {
        Button(action: proceedToPayment) {
            HStack {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 16))
                Text("Proceed to Payment")
                    .font(.system(size: 17, weight: .semibold))
                Image(systemName: "arrow.right")
                    .font(.system(size: 15, weight: .semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                LinearGradient(
                    colors: [Theme.Colors.primary, Theme.Colors.primary.opacity(0.8)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(16)
            .shadow(color: Theme.Colors.primary.opacity(0.3), radius: 10, x: 0, y: 5)
        }
        .disabled(paymentService.isLoading)
    }

    // MARK: - Trust Badges
    private var trustBadges: some View {
        HStack(spacing: 20) {
            TrustBadge(icon: "checkmark.shield.fill", text: "Secure Payment")
            TrustBadge(icon: "lock.fill", text: "Encrypted")
            TrustBadge(icon: "star.fill", text: "Rated 4.8/5")
        }
        .padding(.top, 8)
    }

    // MARK: - Processing View
    private var processingView: some View {
        VStack(spacing: 24) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(Theme.Colors.primary)

            Text("Processing Your Rental...")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(Theme.Colors.text)

            Text("Please wait while we securely process your payment")
                .font(.system(size: 15))
                .foregroundColor(Theme.Colors.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Success View
    private var successView: some View {
        VStack(spacing: 24) {
            // Success checkmark animation
            ZStack {
                Circle()
                    .fill(Theme.Colors.primary.opacity(0.2))
                    .frame(width: 120, height: 120)

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(Theme.Colors.primary)
            }

            Text("Rental Confirmed!")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(Theme.Colors.text)

            Text("The owner has been notified and will confirm pickup details soon.")
                .font(.system(size: 16))
                .foregroundColor(Theme.Colors.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            VStack(spacing: 12) {
                SuccessDetailRow(icon: "calendar", text: "Rental: \(formatDate(startDate)) - \(formatDate(endDate))")
                SuccessDetailRow(icon: "location.fill", text: "Pickup: \(deliveryMethod.title)")
                if includeInsurance {
                    SuccessDetailRow(icon: "shield.checkered", text: "Insurance: Included")
                }
                SuccessDetailRow(icon: "dollarsign.circle", text: String(format: "Total: $%.2f", totalCost))
            }
            .padding(20)
            .background(Theme.Colors.secondaryBackground)
            .cornerRadius(16)
            .padding(.horizontal, 30)

            Button(action: {
                presentationMode.wrappedValue.dismiss()
                onDismiss()
            }) {
                Text("Done")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Theme.Colors.primary)
                    .cornerRadius(14)
            }
            .padding(.horizontal, 30)
            .padding(.top, 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    // MARK: - Helper Functions
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }

    private func proceedToPayment() {
        impactFeedback.impactOccurred()
        isProcessing = true

        Task {
            do {
                let intent = try await paymentService.createMarketplacePaymentIntent(
                    listingId: listing.listingId,
                    sellerId: listing.userId,
                    transactionType: "RENTAL",
                    rentalStartDate: startDate,
                    rentalEndDate: endDate,
                    deliveryMethod: deliveryMethod.rawValue,
                    buyerMessage: buyerMessage.isEmpty ? nil : buyerMessage
                )

                // DEBUG: Print payment intent details
                print("🔍 DEBUG - Payment Intent Received:")
                print("   Client Secret: \(intent.clientSecret.prefix(30))...")
                print("   Customer Session Client Secret: \(intent.customerSessionClientSecret.prefix(30))...")
                print("   Customer ID: \(intent.customerId)")
                print("   Amount: $\(intent.amount)")

                await MainActor.run {
                    self.paymentIntent = intent
                    setupPaymentSheet(
                        clientSecret: intent.clientSecret,
                        customerSessionClientSecret: intent.customerSessionClientSecret,
                        customerId: intent.customerId
                    )
                    presentPaymentSheet()
                }

            } catch PaymentError.sellerOnboardingRequired {
                await MainActor.run {
                    errorMessage = "The owner needs to complete their payment setup first. Please try again later."
                    showingError = true
                    isProcessing = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showingError = true
                    isProcessing = false
                }
            }
        }
    }

    private func setupPaymentSheet(clientSecret: String, customerSessionClientSecret: String, customerId: String) {
        print("🔧 DEBUG - Setting up PaymentSheet (SDK 25.0):")
        print("   Customer ID: \(customerId)")
        print("   Customer Session Client Secret length: \(customerSessionClientSecret.count)")
        print("   Customer Session Client Secret prefix: \(customerSessionClientSecret.prefix(5))")
        print("   Client Secret length: \(clientSecret.count)")

        var configuration = PaymentSheet.Configuration()
        configuration.merchantDisplayName = "Brrow"
        configuration.allowsDelayedPaymentMethods = false

        // Customer Session - modern approach for SDK 25.0+
        // This replaces the deprecated ephemeral keys method
        configuration.customer = PaymentSheet.CustomerConfiguration(
            id: customerId,
            customerSessionClientSecret: customerSessionClientSecret
        )

        print("   ✅ Configuration created")

        paymentSheet = PaymentSheet(
            paymentIntentClientSecret: clientSecret,
            configuration: configuration
        )

        print("   ✅ PaymentSheet initialized")
    }

    private func presentPaymentSheet() {
        guard let paymentSheet = paymentSheet else {
            isProcessing = false
            return
        }

        // Get the topmost view controller (this checkout view), not the root
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {

            var topController = window.rootViewController
            while let presentedViewController = topController?.presentedViewController {
                topController = presentedViewController
            }

            guard let topmostVC = topController else {
                isProcessing = false
                return
            }

            // Add a small delay to ensure this view is fully presented
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                paymentSheet.present(from: topmostVC) { result in
                    Task {
                        await self.handlePaymentResult(result)
                    }
                }
            }
        } else {
            isProcessing = false
        }
    }

    private func handlePaymentResult(_ result: PaymentSheetResult) async {
        switch result {
        case .completed:
            if let transactionId = paymentIntent?.transactionId {
                do {
                    try await paymentService.confirmPayment(transactionId: transactionId)
                    await MainActor.run {
                        impactFeedback.impactOccurred()
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                            showingSuccess = true
                        }
                    }
                } catch {
                    await MainActor.run {
                        errorMessage = "Payment succeeded but confirmation failed. Please contact support."
                        showingError = true
                        isProcessing = false
                    }
                }
            }

        case .canceled:
            await MainActor.run {
                isProcessing = false
            }

        case .failed(let error):
            await MainActor.run {
                errorMessage = error.localizedDescription
                showingError = true
                isProcessing = false
            }
        }
    }
}

// MARK: - Supporting Views

struct DeliveryMethodRow: View {
    let method: ModernRentalCheckoutView.DeliveryMethod
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                // Icon
                ZStack {
                    Circle()
                        .fill(isSelected ? Theme.Colors.primary : Theme.Colors.secondaryBackground)
                        .frame(width: 48, height: 48)

                    Image(systemName: method.icon)
                        .font(.system(size: 20))
                        .foregroundColor(isSelected ? .white : Theme.Colors.text)
                }

                // Text content
                VStack(alignment: .leading, spacing: 4) {
                    Text(method.title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Theme.Colors.text)

                    Text(method.description)
                        .font(.system(size: 13))
                        .foregroundColor(Theme.Colors.secondaryText)
                        .lineLimit(1)
                }

                Spacer()

                // Checkmark
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(Theme.Colors.primary)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Theme.Colors.primary.opacity(0.08) : Theme.Colors.secondaryBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Theme.Colors.primary : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct PriceRow: View {
    let title: String
    let value: String
    var isBold: Bool = false
    var valueColor: Color? = nil

    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: isBold ? 18 : 15, weight: isBold ? .semibold : .regular))
                .foregroundColor(Theme.Colors.text)

            Spacer()

            Text(value)
                .font(.system(size: isBold ? 20 : 15, weight: isBold ? .bold : .medium))
                .foregroundColor(valueColor ?? Theme.Colors.text)
        }
    }
}

struct TrustBadge: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12))
            Text(text)
                .font(.system(size: 12, weight: .medium))
        }
        .foregroundColor(Theme.Colors.secondaryText)
    }
}

struct SuccessDetailRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(Theme.Colors.primary)
                .frame(width: 24)

            Text(text)
                .font(.system(size: 15))
                .foregroundColor(Theme.Colors.text)

            Spacer()
        }
    }
}

#Preview {
    ModernRentalCheckoutView(
        listing: Listing.example,
        startDate: Date(),
        endDate: Calendar.current.date(byAdding: .day, value: 2, to: Date()) ?? Date(),
        onDismiss: {}
    )
}
