//
//  PurchaseStatusView.swift
//  Brrow
//
//  Real-time purchase tracking with deadline and verification
//

import SwiftUI

struct PurchaseStatusView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: PurchaseStatusViewModel
    @State private var showingMessageComposer = false
    @State private var showingMeetupCreation = false

    init(purchase: Purchase) {
        self._viewModel = StateObject(wrappedValue: PurchaseStatusViewModel(purchase: purchase))
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
                        // Status card
                        statusCard

                        // Deadline countdown
                        if !viewModel.purchase.isCompleted {
                            deadlineCountdown
                        }

                        // Timeline
                        timeline

                        // Listing info
                        if let listing = viewModel.purchase.listing {
                            listingInfo(listing)
                        }

                        // Action buttons
                        actionButtons
                    }
                    .padding(Theme.Spacing.md)
                }
            }
        }
        .onAppear {
            viewModel.startTimer()
        }
        .onDisappear {
            viewModel.stopTimer()
        }
        .sheet(isPresented: $showingMessageComposer) {
            if let otherParty = otherPartyUser {
                DirectMessageComposerView(recipient: otherParty)
            }
        }
        .sheet(isPresented: $showingMeetupCreation) {
            if let meetupId = viewModel.purchase.meetupId {
                // Meetup already exists, navigate to tracking
                NavigationView {
                    MeetupTrackingView(
                        meetupId: meetupId,
                        onVerificationReady: { _ in
                            showingMeetupCreation = false
                        }
                    )
                }
            } else {
                // Create new meetup
                MeetupCreationView(
                    purchaseId: viewModel.purchase.id,
                    onMeetupCreated: { meetup in
                        viewModel.purchase = Purchase(
                            id: viewModel.purchase.id,
                            listingId: viewModel.purchase.listingId,
                            buyerId: viewModel.purchase.buyerId,
                            sellerId: viewModel.purchase.sellerId,
                            purchaseType: viewModel.purchase.purchaseType,
                            amount: viewModel.purchase.amount,
                            paymentIntentId: viewModel.purchase.paymentIntentId,
                            paymentStatus: viewModel.purchase.paymentStatus,
                            verificationStatus: viewModel.purchase.verificationStatus,
                            deadline: viewModel.purchase.deadline,
                            createdAt: viewModel.purchase.createdAt,
                            updatedAt: viewModel.purchase.updatedAt,
                            sellerConfirmedAt: viewModel.purchase.sellerConfirmedAt,
                            buyerConfirmedAt: viewModel.purchase.buyerConfirmedAt,
                            verificationCompletedAt: viewModel.purchase.verificationCompletedAt,
                            refundedAt: viewModel.purchase.refundedAt,
                            meetupId: meetup.id,
                            sellerConfirmed: viewModel.purchase.sellerConfirmed,
                            buyerConfirmed: viewModel.purchase.buyerConfirmed,
                            transactionDisplayId: viewModel.purchase.transactionDisplayId,
                            isActive: viewModel.purchase.isActive,
                            isPast: viewModel.purchase.isPast,
                            receiptId: viewModel.purchase.receiptId,
                            receiptGeneratedAt: viewModel.purchase.receiptGeneratedAt,
                            receiptUrl: viewModel.purchase.receiptUrl,
                            listing: viewModel.purchase.listing,
                            buyer: viewModel.purchase.buyer,
                            seller: viewModel.purchase.seller
                        )
                        showingMeetupCreation = false
                    }
                )
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

            Text("Purchase Status")
                .font(Theme.Typography.largeTitle)
                .foregroundColor(Theme.Colors.text)

            Spacer()

            Color.clear.frame(width: 44, height: 44)
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.top, 60)
        .padding(.bottom, Theme.Spacing.md)
    }

    // MARK: - Status Card
    private var statusCard: some View {
        VStack(spacing: Theme.Spacing.md) {
            // Status icon
            ZStack {
                Circle()
                    .fill(statusColor.opacity(0.2))
                    .frame(width: 80, height: 80)

                Image(systemName: statusIcon)
                    .font(.system(size: 36))
                    .foregroundColor(statusColor)
            }

            // Status text
            Text(statusText)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(Theme.Colors.text)
                .multilineTextAlignment(.center)

            Text(statusSubtext)
                .font(.system(size: 14))
                .foregroundColor(Theme.Colors.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Theme.Spacing.md)
        }
        .padding(Theme.Spacing.lg)
        .frame(maxWidth: .infinity)
        .background(RoundedRectangle(cornerRadius: Theme.CornerRadius.md).fill(Theme.Colors.cardBackground).shadow(color: Theme.Shadows.card, radius: Theme.Shadows.cardRadius))
    }

    private var statusIcon: String {
        switch viewModel.purchase.verificationStatus {
        case .pending: return "clock.fill"
        case .sellerConfirmed: return "checkmark.circle.fill"
        case .buyerConfirmed: return "checkmark.circle.fill"
        case .bothConfirmed: return "checkmark.seal.fill"
        case .failed: return "xmark.circle.fill"
        }
    }

    private var statusColor: Color {
        switch viewModel.purchase.verificationStatus {
        case .pending: return Theme.Colors.warning
        case .sellerConfirmed, .buyerConfirmed: return Theme.Colors.info
        case .bothConfirmed: return Theme.Colors.success
        case .failed: return Theme.Colors.error
        }
    }

    private var statusText: String {
        if viewModel.purchase.isCompleted {
            return "Purchase Complete!"
        } else if viewModel.purchase.isExpired {
            return "Deadline Expired"
        } else {
            return "Awaiting Verification"
        }
    }

    private var statusSubtext: String {
        if viewModel.purchase.isCompleted {
            return "Thank you for using Brrow!"
        } else if viewModel.purchase.isExpired {
            return "Your payment has been refunded"
        } else {
            return "Meet the \(otherPartyRole.lowercased()) to complete verification"
        }
    }

    // MARK: - Computed Properties
    private var isBuyer: Bool {
        guard let currentUserId = AuthManager.shared.currentUser?.apiId else { return false }
        return viewModel.purchase.buyerId == currentUserId
    }

    private var otherPartyRole: String {
        return isBuyer ? "seller" : "buyer"
    }

    private var otherPartyUser: User? {
        let otherPartyPurchaseUser = isBuyer ? viewModel.purchase.seller : viewModel.purchase.buyer
        return otherPartyPurchaseUser?.toUser()
    }

    // MARK: - Deadline Countdown
    private var deadlineCountdown: some View {
        VStack(spacing: Theme.Spacing.sm) {
            Text("Time Remaining")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Theme.Colors.secondaryText)

            HStack(spacing: Theme.Spacing.md) {
                // Days
                timeBlock(value: viewModel.daysRemaining, label: "Days")

                Text(":")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(Theme.Colors.text)

                // Hours
                timeBlock(value: viewModel.hoursRemaining, label: "Hours")

                Text(":")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(Theme.Colors.text)

                // Minutes
                timeBlock(value: viewModel.minutesRemaining, label: "Minutes")
            }

            Text("Deadline: \(viewModel.purchase.formattedDeadline)")
                .font(.system(size: 12))
                .foregroundColor(Theme.Colors.secondaryText)
        }
        .padding(Theme.Spacing.md)
        .background(RoundedRectangle(cornerRadius: Theme.CornerRadius.md).fill(Theme.Colors.warning.opacity(0.1)))
    }

    private func timeBlock(value: Int, label: String) -> some View {
        VStack(spacing: 4) {
            Text(String(format: "%02d", value))
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(Theme.Colors.primary)

            Text(label)
                .font(.system(size: 11))
                .foregroundColor(Theme.Colors.secondaryText)
        }
        .frame(width: 70)
        .padding(.vertical, Theme.Spacing.sm)
        .background(Theme.Colors.cardBackground)
        .cornerRadius(Theme.CornerRadius.card)
    }

    // MARK: - Timeline
    private var timeline: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("Timeline")
                .font(Theme.Typography.headline)
                .foregroundColor(Theme.Colors.text)

            VStack(spacing: 0) {
                timelineItem(
                    icon: "cart.fill",
                    title: "Purchase Created",
                    time: viewModel.purchase.createdAt,
                    isCompleted: true
                )

                if let sellerConfirmedAt = viewModel.purchase.sellerConfirmedAt {
                    timelineItem(
                        icon: "person.fill.checkmark",
                        title: "Seller Confirmed",
                        time: sellerConfirmedAt,
                        isCompleted: true
                    )
                }

                if let buyerConfirmedAt = viewModel.purchase.buyerConfirmedAt {
                    timelineItem(
                        icon: "person.fill.checkmark",
                        title: "Buyer Confirmed",
                        time: buyerConfirmedAt,
                        isCompleted: true
                    )
                }

                if let completedAt = viewModel.purchase.verificationCompletedAt {
                    timelineItem(
                        icon: "checkmark.seal.fill",
                        title: "Verification Complete",
                        time: completedAt,
                        isCompleted: true,
                        isLast: true
                    )
                }
            }
        }
    }

    private func timelineItem(icon: String, title: String, time: Date, isCompleted: Bool, isLast: Bool = false) -> some View {
        HStack(alignment: .top, spacing: Theme.Spacing.md) {
            VStack(spacing: 0) {
                ZStack {
                    Circle()
                        .fill(isCompleted ? Theme.Colors.success : Theme.Colors.secondaryBackground)
                        .frame(width: 32, height: 32)

                    Image(systemName: icon)
                        .font(.system(size: 14))
                        .foregroundColor(isCompleted ? .white : Theme.Colors.secondaryText)
                }

                if !isLast {
                    Rectangle()
                        .fill(Theme.Colors.border)
                        .frame(width: 2, height: 40)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Theme.Colors.text)

                Text(timeString(from: time))
                    .font(.system(size: 13))
                    .foregroundColor(Theme.Colors.secondaryText)
            }
            .padding(.top, 4)

            Spacer()
        }
    }

    private func timeString(from date: Date) -> String {
        return date.toUserFriendlyString()
    }

    // MARK: - Listing Info
    private func listingInfo(_ listing: PurchaseListing) -> some View {
        HStack(spacing: Theme.Spacing.md) {
            if let imageUrl = listing.imageUrl, let url = URL(string: imageUrl) {
                AsyncImage(url: url) { image in
                    image.resizable().aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle().fill(Theme.Colors.secondaryBackground).overlay(ProgressView())
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
        .padding(Theme.Spacing.md)
        .background(RoundedRectangle(cornerRadius: Theme.CornerRadius.card).fill(Theme.Colors.cardBackground))
    }

    // MARK: - Action Buttons
    private var actionButtons: some View {
        VStack(spacing: Theme.Spacing.sm) {
            if !viewModel.purchase.isCompleted && !viewModel.purchase.isExpired {
                // Schedule Meetup Button
                Button(action: {
                    showingMeetupCreation = true
                }) {
                    HStack {
                        Image(systemName: "location.fill")
                        Text(viewModel.purchase.meetupId != nil ? "Track Meetup" : "Schedule Meetup")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(RoundedRectangle(cornerRadius: Theme.CornerRadius.card).fill(Theme.Colors.primary))
                }

                // Message Other Party Button
                Button(action: {
                    showingMessageComposer = true
                }) {
                    HStack {
                        Image(systemName: "message.fill")
                        Text("Message \(otherPartyRole.capitalized)")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundColor(Theme.Colors.primary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(RoundedRectangle(cornerRadius: Theme.CornerRadius.card).stroke(Theme.Colors.primary, lineWidth: 2))
                }
            }
        }
    }
}

// MARK: - ViewModel
class PurchaseStatusViewModel: ObservableObject {
    @Published var purchase: Purchase
    @Published var daysRemaining: Int = 0
    @Published var hoursRemaining: Int = 0
    @Published var minutesRemaining: Int = 0

    private var timer: Timer?

    init(purchase: Purchase) {
        self.purchase = purchase
        updateTimeRemaining()
    }

    func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateTimeRemaining()
        }
    }

    func stopTimer() {
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
