//
//  PurchaseReceiptView.swift
//  Brrow
//
//  Post-purchase success screen with receipt and celebration animation
//

import SwiftUI
import SafariServices

struct PurchaseReceiptView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: PurchaseReceiptViewModel

    let purchase: Purchase
    let onDismiss: (() -> Void)?

    init(purchase: Purchase, onDismiss: (() -> Void)? = nil) {
        self.purchase = purchase
        self.onDismiss = onDismiss
        self._viewModel = StateObject(wrappedValue: PurchaseReceiptViewModel(purchase: purchase))
    }

    var body: some View {
        ZStack {
            Theme.Colors.background
                .ignoresSafeArea()

            // Confetti animation overlay
            if viewModel.showConfetti {
                ConfettiView()
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }

            VStack(spacing: 0) {
                // Header
                header

                ScrollView {
                    VStack(spacing: Theme.Spacing.lg) {
                        // Success checkmark with animation
                        successAnimation

                        // Purchase summary card
                        purchaseSummaryCard

                        // Escrow status
                        escrowStatusCard

                        // Deadline countdown
                        deadlineCard

                        // Seller/Buyer info
                        if let seller = purchase.seller {
                            sellerInfoCard(seller)
                        }

                        // Transaction details
                        transactionDetailsCard

                        // Action buttons
                        actionButtons
                    }
                    .padding(Theme.Spacing.md)
                    .padding(.bottom, 80)
                }
            }
        }
        .onAppear {
            viewModel.triggerSuccessAnimation()
        }
        .sheet(isPresented: $viewModel.showPurchaseStatus) {
            PurchaseStatusView(purchase: purchase)
        }
    }

    // MARK: - Header
    private var header: some View {
        HStack {
            Button(action: {
                onDismiss?()
                dismiss()
            }) {
                Image(systemName: "xmark")
                    .font(.title3)
                    .foregroundColor(Theme.Colors.text)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(Theme.Colors.cardBackground))
            }

            Spacer()

            Text("Receipt")
                .font(Theme.Typography.largeTitle)
                .foregroundColor(Theme.Colors.text)

            Spacer()

            Color.clear.frame(width: 44, height: 44)
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.top, 60)
        .padding(.bottom, Theme.Spacing.md)
    }

    // MARK: - Success Animation
    private var successAnimation: some View {
        VStack(spacing: Theme.Spacing.md) {
            ZStack {
                // Pulsing background circle
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Theme.Colors.success, Theme.Colors.success.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                    .scaleEffect(viewModel.pulseAnimation ? 1.1 : 1.0)
                    .opacity(viewModel.pulseAnimation ? 0.6 : 0.8)

                // Checkmark icon
                Image(systemName: "checkmark")
                    .font(.system(size: 60, weight: .bold))
                    .foregroundColor(.white)
                    .scaleEffect(viewModel.checkmarkScale)
                    .rotationEffect(.degrees(viewModel.checkmarkRotation))
            }

            Text("Purchase Confirmed!")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(Theme.Colors.text)
                .opacity(viewModel.textOpacity)

            Text("Your payment is secured in escrow")
                .font(.system(size: 16))
                .foregroundColor(Theme.Colors.secondaryText)
                .multilineTextAlignment(.center)
                .opacity(viewModel.textOpacity)
        }
        .padding(.vertical, Theme.Spacing.lg)
    }

    // MARK: - Purchase Summary Card
    private var purchaseSummaryCard: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("Purchase Summary")
                .font(Theme.Typography.headline)
                .foregroundColor(Theme.Colors.text)

            // Listing preview
            if let listing = purchase.listing {
                HStack(spacing: Theme.Spacing.md) {
                    if let imageUrl = listing.imageUrl, let url = URL(string: imageUrl) {
                        AsyncImage(url: url) { image in
                            image.resizable().aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Rectangle().fill(Theme.Colors.secondaryBackground)
                        }
                        .frame(width: 80, height: 80)
                        .cornerRadius(Theme.CornerRadius.card)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text(listing.title)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Theme.Colors.text)
                            .lineLimit(2)

                        Text("$\(Int(listing.price))")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(Theme.Colors.primary)
                    }
                    Spacer()
                }
            }

            Divider()

            // Price breakdown
            VStack(spacing: Theme.Spacing.sm) {
                HStack {
                    Text("Item Price")
                        .foregroundColor(Theme.Colors.secondaryText)
                    Spacer()
                    Text("$\(formattedAmount(purchase.amount))")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Theme.Colors.text)
                }

                HStack {
                    Text("Service Fee")
                        .foregroundColor(Theme.Colors.secondaryText)
                    Spacer()
                    Text("$0.00")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Theme.Colors.text)
                }

                Divider()

                HStack {
                    Text("Total Paid")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(Theme.Colors.text)
                    Spacer()
                    Text("$\(formattedAmount(purchase.amount))")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(Theme.Colors.primary)
                }
            }
            .padding(Theme.Spacing.md)
            .background(Theme.Colors.inputBackground)
            .cornerRadius(Theme.CornerRadius.md)
        }
        .padding(Theme.Spacing.md)
        .background(Theme.Colors.cardBackground)
        .cornerRadius(Theme.CornerRadius.card)
        .shadow(color: Theme.Shadows.card, radius: Theme.Shadows.cardRadius)
    }

    // MARK: - Escrow Status Card
    private var escrowStatusCard: some View {
        HStack(alignment: .top, spacing: Theme.Spacing.md) {
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 28))
                .foregroundColor(Theme.Colors.success)

            VStack(alignment: .leading, spacing: 8) {
                Text("Funds Held in Escrow")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Theme.Colors.text)

                Text("Your payment of $\(formattedAmount(purchase.amount)) is securely held until you verify receipt of the item. The seller cannot access these funds until both parties confirm the transaction.")
                    .font(.system(size: 14))
                    .foregroundColor(Theme.Colors.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 6) {
                    Circle()
                        .fill(Theme.Colors.success)
                        .frame(width: 8, height: 8)
                    Text("Payment Status: \(paymentStatusText)")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Theme.Colors.success)
                }
                .padding(.top, 4)
            }
        }
        .padding(Theme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.card)
                .fill(Theme.Colors.success.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.CornerRadius.card)
                        .strokeBorder(Theme.Colors.success.opacity(0.3), lineWidth: 1)
                )
        )
    }

    // MARK: - Deadline Card
    private var deadlineCard: some View {
        VStack(spacing: Theme.Spacing.md) {
            HStack {
                Image(systemName: "clock.fill")
                    .font(.system(size: 24))
                    .foregroundColor(Theme.Colors.warning)

                VStack(alignment: .leading, spacing: 4) {
                    Text("3-Day Verification Deadline")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(Theme.Colors.text)

                    Text("Meet seller by \(formattedDeadline)")
                        .font(.system(size: 14))
                        .foregroundColor(Theme.Colors.secondaryText)
                }
                Spacer()
            }

            // Countdown timer
            HStack(spacing: Theme.Spacing.sm) {
                timeBlock(value: viewModel.daysRemaining, label: "Days")
                Text(":")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(Theme.Colors.text)
                timeBlock(value: viewModel.hoursRemaining, label: "Hours")
                Text(":")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(Theme.Colors.text)
                timeBlock(value: viewModel.minutesRemaining, label: "Mins")
            }

            Text("If not completed, your payment will be automatically refunded")
                .font(.system(size: 12))
                .foregroundColor(Theme.Colors.secondaryText)
                .multilineTextAlignment(.center)
        }
        .padding(Theme.Spacing.md)
        .background(Theme.Colors.cardBackground)
        .cornerRadius(Theme.CornerRadius.card)
        .shadow(color: Theme.Shadows.card, radius: Theme.Shadows.cardRadius)
    }

    private func timeBlock(value: Int, label: String) -> some View {
        VStack(spacing: 4) {
            Text(String(format: "%02d", value))
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(Theme.Colors.warning)
                .frame(width: 60, height: 50)
                .background(Theme.Colors.warning.opacity(0.1))
                .cornerRadius(Theme.CornerRadius.sm)

            Text(label)
                .font(.system(size: 11))
                .foregroundColor(Theme.Colors.secondaryText)
        }
    }

    // MARK: - Seller Info Card
    private func sellerInfoCard(_ seller: PurchaseUser) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("Seller Information")
                .font(Theme.Typography.headline)
                .foregroundColor(Theme.Colors.text)

            HStack(spacing: Theme.Spacing.md) {
                // Profile image
                if let profileImage = seller.profileImage, let url = URL(string: profileImage) {
                    AsyncImage(url: url) { image in
                        image.resizable().aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Circle().fill(Theme.Colors.secondaryBackground)
                            .overlay(
                                Image(systemName: "person.fill")
                                    .foregroundColor(Theme.Colors.secondaryText)
                            )
                    }
                    .frame(width: 50, height: 50)
                    .clipShape(Circle())
                } else {
                    Circle()
                        .fill(Theme.Colors.primary.opacity(0.2))
                        .frame(width: 50, height: 50)
                        .overlay(
                            Text(seller.username.prefix(1).uppercased())
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(Theme.Colors.primary)
                        )
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(seller.username)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Theme.Colors.text)

                    Text("Seller")
                        .font(.system(size: 13))
                        .foregroundColor(Theme.Colors.secondaryText)
                }

                Spacer()

                Button(action: {
                    // Message seller action
                }) {
                    Image(systemName: "message.fill")
                        .font(.system(size: 16))
                        .foregroundColor(Theme.Colors.primary)
                        .frame(width: 40, height: 40)
                        .background(Circle().fill(Theme.Colors.primary.opacity(0.1)))
                }
            }
        }
        .padding(Theme.Spacing.md)
        .background(Theme.Colors.cardBackground)
        .cornerRadius(Theme.CornerRadius.card)
        .shadow(color: Theme.Shadows.card, radius: Theme.Shadows.cardRadius)
    }

    // MARK: - Transaction Details Card
    private var transactionDetailsCard: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("Transaction Details")
                .font(Theme.Typography.headline)
                .foregroundColor(Theme.Colors.text)

            VStack(spacing: Theme.Spacing.sm) {
                detailRow(label: "Transaction ID", value: purchase.id.prefix(8).uppercased())
                detailRow(label: "Purchase Type", value: purchase.purchaseType == .buyNow ? "Buy Now" : "Accepted Offer")
                detailRow(label: "Payment Method", value: "Stripe")
                detailRow(label: "Purchase Date", value: formattedDate(purchase.createdAt))
                if let paymentIntentId = purchase.paymentIntentId {
                    detailRow(label: "Payment ID", value: paymentIntentId.prefix(12).uppercased())
                }
            }
        }
        .padding(Theme.Spacing.md)
        .background(Theme.Colors.cardBackground)
        .cornerRadius(Theme.CornerRadius.card)
        .shadow(color: Theme.Shadows.card, radius: Theme.Shadows.cardRadius)
    }

    private func detailRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 14))
                .foregroundColor(Theme.Colors.secondaryText)
            Spacer()
            Text(value)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Theme.Colors.text)
        }
    }

    // MARK: - Action Buttons
    private var actionButtons: some View {
        VStack(spacing: Theme.Spacing.sm) {
            // Download Receipt Button
            Button(action: {
                viewModel.generatePDFReceipt()
            }) {
                HStack {
                    Image(systemName: "arrow.down.doc.fill")
                    Text("Download Receipt")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(
                    RoundedRectangle(cornerRadius: Theme.CornerRadius.card)
                        .fill(Theme.Colors.primary)
                )
            }

            // View Purchase Status Button
            Button(action: {
                viewModel.showPurchaseStatus = true
            }) {
                HStack {
                    Image(systemName: "list.bullet.clipboard")
                    Text("View Purchase Status")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(Theme.Colors.primary)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(
                    RoundedRectangle(cornerRadius: Theme.CornerRadius.card)
                        .strokeBorder(Theme.Colors.primary, lineWidth: 2)
                )
            }
        }
    }

    // MARK: - Helpers
    private var paymentStatusText: String {
        switch purchase.paymentStatus {
        case .held: return "Held in Escrow"
        case .captured: return "Completed"
        case .refunded: return "Refunded"
        case .cancelled: return "Cancelled"
        case .failed: return "Failed"
        default: return "Processing"
        }
    }

    private var formattedDeadline: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: purchase.deadline)
    }

    private func formattedAmount(_ amount: Double) -> String {
        return String(format: "%.2f", amount)
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - ViewModel
class PurchaseReceiptViewModel: ObservableObject {
    @Published var showConfetti = false
    @Published var checkmarkScale: CGFloat = 0
    @Published var checkmarkRotation: Double = -90
    @Published var pulseAnimation = false
    @Published var textOpacity: Double = 0
    @Published var showPurchaseStatus = false

    // Countdown timer
    @Published var daysRemaining: Int = 0
    @Published var hoursRemaining: Int = 0
    @Published var minutesRemaining: Int = 0

    let purchase: Purchase
    private var timer: Timer?

    init(purchase: Purchase) {
        self.purchase = purchase
        updateTimeRemaining()
        startTimer()
    }

    deinit {
        stopTimer()
    }

    func triggerSuccessAnimation() {
        // Trigger haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)

        // Show confetti
        withAnimation {
            showConfetti = true
        }

        // Animate checkmark
        withAnimation(.spring(response: 0.6, dampingFraction: 0.6, blendDuration: 0).delay(0.1)) {
            checkmarkScale = 1.0
            checkmarkRotation = 0
        }

        // Pulse animation
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true).delay(0.4)) {
            pulseAnimation = true
        }

        // Fade in text
        withAnimation(.easeIn(duration: 0.5).delay(0.5)) {
            textOpacity = 1.0
        }

        // Hide confetti after 3 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            withAnimation {
                self.showConfetti = false
            }
        }
    }

    func generatePDFReceipt() {
        print("📄 Generating PDF receipt for purchase: \(purchase.id)")

        guard let pdfURL = PDFReceiptGenerator.generateReceipt(for: purchase) else {
            print("❌ Failed to generate PDF receipt")
            return
        }

        print("✅ PDF receipt generated at: \(pdfURL.path)")

        // Share the PDF using UIActivityViewController
        DispatchQueue.main.async {
            let activityVC = UIActivityViewController(activityItems: [pdfURL], applicationActivities: nil)

            // Get the key window scene
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootViewController = windowScene.windows.first?.rootViewController {

                // Find the topmost view controller
                var topController = rootViewController
                while let presentedViewController = topController.presentedViewController {
                    topController = presentedViewController
                }

                // Present the activity view controller
                if let popoverController = activityVC.popoverPresentationController {
                    popoverController.sourceView = topController.view
                    popoverController.sourceRect = CGRect(x: topController.view.bounds.midX, y: topController.view.bounds.midY, width: 0, height: 0)
                    popoverController.permittedArrowDirections = []
                }

                topController.present(activityVC, animated: true) {
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.success)
                }
            }
        }
    }

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateTimeRemaining()
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func updateTimeRemaining() {
        let timeInterval = purchase.timeRemaining
        guard timeInterval > 0 else {
            daysRemaining = 0
            hoursRemaining = 0
            minutesRemaining = 0
            return
        }

        let days = Int(timeInterval / 86400)
        let hours = Int((timeInterval.truncatingRemainder(dividingBy: 86400)) / 3600)
        let minutes = Int((timeInterval.truncatingRemainder(dividingBy: 3600)) / 60)

        daysRemaining = days
        hoursRemaining = hours
        minutesRemaining = minutes
    }
}
