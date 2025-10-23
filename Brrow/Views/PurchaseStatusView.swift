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
    @State private var meetupIsInvalid = false  // Track if meetup ID is stale/deleted

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
            // Proactively check if meetup exists
            if let meetupId = viewModel.purchase.meetupId {
                validateMeetupExists(meetupId: meetupId)
            }
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
            if let meetupId = viewModel.purchase.meetupId, !meetupIsInvalid {
                // Meetup already exists and is valid, navigate to tracking
                NavigationView {
                    MeetupTrackingView(
                        meetupId: meetupId,
                        onVerificationReady: { _ in
                            showingMeetupCreation = false
                        },
                        onMeetupNotFound: {
                            // Meetup was deleted - mark as invalid and show schedule view instead
                            meetupIsInvalid = true
                            showingMeetupCreation = false
                        }
                    )
                }
            } else {
                // Schedule new meetup (either no meetupId or meetup is invalid)
                MeetupSchedulingView(
                    transactionId: viewModel.purchase.id,
                    onMeetupScheduled: { meetup in
                        meetupIsInvalid = false  // Reset flag when new meetup is scheduled
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
                // Schedule/Track Meetup Button
                Button(action: {
                    showingMeetupCreation = true
                }) {
                    HStack {
                        Image(systemName: "location.fill")
                        Text((viewModel.purchase.meetupId != nil && !meetupIsInvalid) ? "Track Meetup" : "Schedule Meetup")
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

    // MARK: - Helper Functions

    /// Proactively validate that a meetup exists before showing "Track Meetup" button
    private func validateMeetupExists(meetupId: String) {
        print("🔍 [PURCHASE STATUS] Proactively validating meetup exists: \(meetupId)")

        Task {
            do {
                let response: MeetupResponse = try await APIClient.shared.request(
                    "/api/meetups/\(meetupId)",
                    method: .GET
                )

                if response.success, response.data != nil {
                    print("✅ [PURCHASE STATUS] Meetup exists and is valid")
                    // Meetup exists - keep button as "Track Meetup"
                } else {
                    print("⚠️ [PURCHASE STATUS] Meetup response invalid - marking as stale")
                    await MainActor.run {
                        meetupIsInvalid = true
                    }
                }
            } catch {
                // 404/410 or any error means meetup doesn't exist or is invalid
                print("❌ [PURCHASE STATUS] Meetup validation failed: \(error.localizedDescription)")

                // Check error type and handle all meetup error scenarios
                if let apiError = error as? BrrowAPIError {
                    switch apiError {
                    case .validationError(let message):
                        // Handle all meetup error scenarios
                        if message.lowercased().contains("not found") ||
                           message.lowercased().contains("meetup_not_found") ||
                           message.lowercased().contains("expired") ||
                           message.lowercased().contains("meetup_expired") ||
                           message.lowercased().contains("cancelled") ||
                           message.lowercased().contains("meetup_cancelled") {

                            // Log specific error type
                            if message.lowercased().contains("expired") {
                                print("⏰ [PURCHASE STATUS] Meetup expired - button will show 'Schedule Meetup'")
                            } else if message.lowercased().contains("cancelled") {
                                print("🚫 [PURCHASE STATUS] Meetup cancelled - button will show 'Schedule Meetup'")
                            } else {
                                print("🔍 [PURCHASE STATUS] Meetup not found - button will show 'Schedule Meetup'")
                            }

                            await MainActor.run {
                                meetupIsInvalid = true
                            }
                        }
                    case .serverError(let message):
                        // Handle server errors (410 Gone for expired/cancelled)
                        if message.lowercased().contains("not found") ||
                           message.lowercased().contains("expired") ||
                           message.lowercased().contains("cancelled") {

                            // Log specific error type
                            if message.lowercased().contains("expired") {
                                print("⏰ [PURCHASE STATUS] Meetup expired (410) - button will show 'Schedule Meetup'")
                            } else if message.lowercased().contains("cancelled") {
                                print("🚫 [PURCHASE STATUS] Meetup cancelled (410) - button will show 'Schedule Meetup'")
                            } else {
                                print("🔍 [PURCHASE STATUS] Meetup not found (410) - button will show 'Schedule Meetup'")
                            }

                            await MainActor.run {
                                meetupIsInvalid = true
                            }
                        }
                    case .httpError(let statusCode, _):
                        // Handle HTTP error codes directly
                        if statusCode == 404 || statusCode == 410 {
                            print("🔍 [PURCHASE STATUS] Meetup not available (HTTP \(statusCode)) - button will show 'Schedule Meetup'")
                            await MainActor.run {
                                meetupIsInvalid = true
                            }
                        }
                    default:
                        break
                    }
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
