//
//  PurchaseReceiptView.swift
//  Brrow
//
//  Post-purchase success screen with receipt and celebration animation
//

import SwiftUI
import SafariServices
import Combine

struct PurchaseReceiptView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: PurchaseReceiptViewModel
    @State private var showingMessageComposer = false

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

                        // Next Steps - Meetup tracking
                        nextStepsCard

                        // Other party info (seller if buyer, buyer if seller)
                        otherPartyInfoCard

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
            viewModel.loadMeetup()
        }
        .sheet(isPresented: $viewModel.showPurchaseStatus) {
            PurchaseStatusView(purchase: purchase)
        }
        .fullScreenCover(item: $viewModel.selectedMeetup) { meetup in
            NavigationView {
                MeetupTrackingView(
                    meetupId: meetup.id,
                    onVerificationReady: { meetup in
                        viewModel.selectedMeetup = nil
                        viewModel.meetupToVerify = meetup
                    }
                )
            }
        }
        .fullScreenCover(item: $viewModel.meetupToVerify) { meetup in
            VerificationView(
                meetup: meetup,
                onVerificationComplete: { result in
                    viewModel.meetupToVerify = nil
                    // Refresh purchase to show completed status
                    viewModel.loadMeetup()
                }
            )
        }
        .sheet(isPresented: $showingMessageComposer) {
            if let otherParty = otherParty {
                DirectMessageComposerView(recipient: otherParty.toUser())
            }
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

    // MARK: - Next Steps Card
    private var nextStepsCard: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            HStack {
                Image(systemName: "mappin.and.ellipse")
                    .font(.system(size: 24))
                    .foregroundColor(Theme.Colors.primary)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Next Step: Meet & Verify")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(Theme.Colors.text)

                    if viewModel.isLoadingMeetup {
                        Text("Loading meetup info...")
                            .font(.system(size: 14))
                            .foregroundColor(Theme.Colors.secondaryText)
                    } else if let meetup = viewModel.meetup {
                        Text(meetupStatusText(for: meetup))
                            .font(.system(size: 14))
                            .foregroundColor(Theme.Colors.secondaryText)
                    } else {
                        Text("No meeting arranged yet - coordinate with \(otherPartyRole.lowercased())")
                            .font(.system(size: 14))
                            .foregroundColor(Theme.Colors.secondaryText)
                    }
                }
                Spacer()
            }

            Divider()

            // Instructions
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                instructionRow(
                    number: "1",
                    text: "Coordinate with \(otherPartyRole.lowercased()) on meeting location and time"
                )
                instructionRow(
                    number: "2",
                    text: "Both parties arrive at the meetup location (within 100m)"
                )
                instructionRow(
                    number: "3",
                    text: "Verify the item and complete with PIN or QR code"
                )
            }

            // Track Meetup Button
            if let meetup = viewModel.meetup {
                Button(action: {
                    viewModel.selectedMeetup = meetup
                }) {
                    HStack {
                        Image(systemName: "location.fill")
                        Text("Track Meetup")
                            .font(.system(size: 16, weight: .semibold))
                        Spacer()
                        Image(systemName: "arrow.right")
                    }
                    .foregroundColor(.white)
                    .padding(Theme.Spacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: Theme.CornerRadius.card)
                            .fill(Theme.Colors.primary)
                    )
                }
            } else if !viewModel.isLoadingMeetup {
                // No meetup yet - show message to coordinate
                VStack(spacing: Theme.Spacing.sm) {
                    Image(systemName: "bubble.left.and.bubble.right.fill")
                        .font(.system(size: 24))
                        .foregroundColor(Theme.Colors.primary.opacity(0.6))

                    Text("Contact seller to arrange meetup")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Theme.Colors.text)

                    Text("Use the message button above to coordinate")
                        .font(.system(size: 12))
                        .foregroundColor(Theme.Colors.secondaryText)
                }
                .padding(Theme.Spacing.md)
                .frame(maxWidth: .infinity)
                .background(Theme.Colors.secondaryBackground)
                .cornerRadius(Theme.CornerRadius.card)
            }
        }
        .padding(Theme.Spacing.md)
        .background(Theme.Colors.cardBackground)
        .cornerRadius(Theme.CornerRadius.card)
        .shadow(color: Theme.Shadows.card, radius: Theme.Shadows.cardRadius)
    }

    private func instructionRow(number: String, text: String) -> some View {
        HStack(alignment: .top, spacing: Theme.Spacing.sm) {
            Text(number)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 24, height: 24)
                .background(Circle().fill(Theme.Colors.primary))

            Text(text)
                .font(.system(size: 14))
                .foregroundColor(Theme.Colors.text)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func meetupStatusText(for meetup: Meetup) -> String {
        switch meetup.status {
        case .scheduled:
            return "Ready to track - coordinate with seller"
        case .buyerArrived:
            return "You've arrived - waiting for seller"
        case .sellerArrived:
            return "Seller arrived - head to location"
        case .bothArrived:
            return "Both arrived - ready to verify!"
        case .verified, .completed:
            return "Verification complete!"
        case .cancelled:
            return "Meetup cancelled"
        case .expired:
            return "Meetup expired"
        }
    }

    // MARK: - Other Party Info Card
    private var otherPartyInfoCard: some View {
        Group {
            if let otherUser = otherParty {
                VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                    Text("\(otherPartyRole) Information")
                        .font(Theme.Typography.headline)
                        .foregroundColor(Theme.Colors.text)

                    HStack(spacing: Theme.Spacing.md) {
                        // Profile image
                        if let profilePictureUrl = otherUser.profilePictureUrl, let url = URL(string: profilePictureUrl) {
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
                                    Text(otherUser.username.prefix(1).uppercased())
                                        .font(.system(size: 20, weight: .bold))
                                        .foregroundColor(Theme.Colors.primary)
                                )
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text(otherUser.username)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(Theme.Colors.text)

                            Text(otherPartyRole)
                                .font(.system(size: 13))
                                .foregroundColor(Theme.Colors.secondaryText)
                        }

                        Spacer()

                        Button(action: {
                            showingMessageComposer = true
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
        }
    }

    // MARK: - Computed Properties
    private var isBuyer: Bool {
        guard let currentUserId = AuthManager.shared.currentUser?.apiId else { return false }
        return purchase.buyerId == currentUserId
    }

    private var otherParty: PurchaseUser? {
        return isBuyer ? purchase.seller : purchase.buyer
    }

    private var otherPartyRole: String {
        return isBuyer ? "Seller" : "Buyer"
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
        return purchase.deadline.toUserFriendlyString()
    }

    private func formattedAmount(_ amount: Double) -> String {
        return String(format: "%.2f", amount)
    }

    private func formattedDate(_ date: Date) -> String {
        return date.toUserFriendlyString()
    }
}

// MARK: - ViewModel
class PurchaseReceiptViewModel: ObservableObject {
    @Published var checkmarkScale: CGFloat = 0
    @Published var checkmarkRotation: Double = -90
    @Published var pulseAnimation = false
    @Published var textOpacity: Double = 0
    @Published var showPurchaseStatus = false

    // Countdown timer
    @Published var daysRemaining: Int = 0
    @Published var hoursRemaining: Int = 0
    @Published var minutesRemaining: Int = 0

    // Meetup state
    @Published var meetup: Meetup?
    @Published var isLoadingMeetup = false
    @Published var selectedMeetup: Meetup?
    @Published var meetupToVerify: Meetup?

    let purchase: Purchase
    private var timer: Timer?
    private let meetupService = MeetupService.shared

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

    func loadMeetup() {
        isLoadingMeetup = true

        guard let meetupId = purchase.meetupId else {
            print("⚠️ No meetup ID found for purchase: \(purchase.id)")
            isLoadingMeetup = false
            return
        }

        meetupService.getMeetup(meetupId: meetupId)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoadingMeetup = false
                    if case .failure(let error) = completion {
                        print("❌ Failed to load meetup: \(error.localizedDescription)")
                    }
                },
                receiveValue: { [weak self] meetup in
                    print("✅ Loaded meetup: \(meetup.id)")
                    self?.meetup = meetup
                }
            )
            .store(in: &cancellables)
    }

    private var cancellables = Set<AnyCancellable>()
}
