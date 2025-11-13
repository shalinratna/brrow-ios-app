//
//  TransactionDetailView.swift
//  Brrow
//
//  Detailed transaction view with 3-step timeline
//

import SwiftUI
import Combine

struct TransactionDetailView: View {
    let purchaseId: String
    @StateObject private var viewModel = TransactionDetailViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var showingMeetupScheduling = false
    @State private var meetupIsInvalid = false  // Track if meetup ID is stale/deleted
    @State private var showingCancelPurchaseConfirmation = false
    @State private var isCancelingPurchase = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                if viewModel.isLoading {
                    ProgressView()
                        .padding(.top, 100)
                } else if let purchase = viewModel.purchase {
                    // Header with transaction ID
                    VStack(spacing: 8) {
                        Text("Transaction")
                            .font(.title2)
                            .fontWeight(.bold)

                        if let displayId = purchase.transactionDisplayId {
                            Text(displayId)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.blue)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 6)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(8)
                        }
                    }
                    .padding(.top)

                    // Listing info
                    ListingInfoSection(purchase: purchase)

                    // Only show timeline and receipt for active transactions
                    if purchase.paymentStatus != "CANCELLED" {
                        // Timeline
                        TimelineSection(steps: purchase.timeline)

                        // Receipt
                        ReceiptSection(receipt: purchase.receipt, amount: purchase.amount)
                    }

                    // Check if purchase is cancelled (expired)
                    if purchase.paymentStatus == "CANCELLED" {
                        // Transaction cancelled/expired - show expired message
                        TransactionExpiredSection(cancellationReason: purchase.cancellationReason, cancelledAt: purchase.cancelledAt)
                    } else if let meetup = purchase.meetup,
                       !meetupIsInvalid,
                       meetup.status != "EXPIRED",
                       meetup.status != "CANCELLED",
                       meetup.meetupLocation != nil || meetup.scheduledTime != nil {
                        // Meetup exists, is valid, NOT expired/cancelled, AND has data - show tracking
                        MeetupTrackingSection(meetupId: meetup.id, viewModel: viewModel)
                    } else if let meetup = purchase.meetup, (meetup.status == "EXPIRED") {
                        // Meetup expired - show expired message
                        MeetupExpiredSection()
                    } else {
                        // No meetup OR meetup is incomplete OR meetup is invalid - show scheduling
                        MeetupSchedulingSection(
                            showingMeetupScheduling: $showingMeetupScheduling
                        )
                    }

                    // Action buttons (if applicable)
                    if purchase.sellerConfirmed == false && !purchase.isBuyer {
                        SellerActionsSection(viewModel: viewModel, purchaseId: purchase.id)
                    }

                    // Buyer cancel purchase button
                    if purchase.isBuyer &&
                       purchase.paymentStatus != "CANCELLED" &&
                       purchase.paymentStatus != "CAPTURED" &&
                       purchase.paymentStatus != "REFUNDED" {
                        BuyerActionsSection(
                            showingCancelConfirmation: $showingCancelPurchaseConfirmation,
                            isCanceling: $isCancelingPurchase
                        )
                    }
                }
            }
            .padding()
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.fetchPurchaseDetails(purchaseId: purchaseId)
        }
        .onChange(of: viewModel.isLoading) { isLoading in
            // Proactively validate meetup exists AFTER purchase details finish loading
            if !isLoading, let meetupId = viewModel.purchase?.meetup?.id {
                print("🔍 [TRANSACTION DETAIL] Purchase loaded, validating meetup: \(meetupId)")
                validateMeetupExists(meetupId: meetupId)
            }
        }
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .alert("Success", isPresented: .constant(viewModel.successMessage != nil)) {
            Button("OK") {
                viewModel.successMessage = nil
                dismiss()
            }
        } message: {
            Text(viewModel.successMessage ?? "")
        }
        .fullScreenCover(isPresented: $viewModel.showMeetupTracking) {
            if let meetupId = viewModel.purchase?.meetup?.id {
                NavigationView {
                    MeetupTrackingView(
                        meetupId: meetupId,
                        onVerificationReady: { meetup in
                            viewModel.showMeetupTracking = false
                            viewModel.meetupToVerify = meetup
                        },
                        onMeetupNotFound: {
                            // Meetup was deleted - mark as invalid and dismiss
                            meetupIsInvalid = true
                            viewModel.showMeetupTracking = false
                        }
                    )
                }
            }
        }
        .fullScreenCover(item: $viewModel.meetupToVerify) { meetup in
            VerificationView(
                meetup: meetup,
                onVerificationComplete: { result in
                    viewModel.meetupToVerify = nil
                    // Refresh purchase details
                    viewModel.fetchPurchaseDetails(purchaseId: purchaseId)
                }
            )
        }
        .sheet(isPresented: $showingMeetupScheduling) {
            if let purchase = viewModel.purchase {
                MeetupSchedulingView(
                    transactionId: purchase.id,
                    onMeetupScheduled: { meetup in
                        showingMeetupScheduling = false
                        // Refresh purchase details to show updated meetup
                        viewModel.fetchPurchaseDetails(purchaseId: purchaseId)
                    }
                )
            }
        }
        .alert("Cancel Purchase?", isPresented: $showingCancelPurchaseConfirmation) {
            Button("Keep Purchase", role: .cancel) {}
            Button("Cancel Purchase", role: .destructive) {
                cancelPurchase()
            }
        } message: {
            Text("Are you sure you want to cancel this purchase? Your payment will be refunded to your original payment method.")
        }
    }

    // MARK: - Helper Functions

    /// Proactively validate that a meetup exists before showing "Track Meetup" button
    private func validateMeetupExists(meetupId: String) {
        print("🔍 [TRANSACTION DETAIL] Proactively validating meetup exists: \(meetupId)")

        Task {
            do {
                let response: MeetupResponse = try await APIClient.shared.request(
                    "/api/meetups/\(meetupId)",
                    method: .GET
                )

                if response.success, response.data != nil {
                    print("✅ [TRANSACTION DETAIL] Meetup exists and is valid")
                    // Meetup exists - keep button as "Track Meetup Location"
                } else {
                    print("⚠️ [TRANSACTION DETAIL] Meetup response invalid - marking as stale")
                    await MainActor.run {
                        meetupIsInvalid = true
                    }
                }
            } catch {
                // 404 or any error means meetup doesn't exist
                print("❌ [TRANSACTION DETAIL] Meetup validation failed: \(error.localizedDescription)")

                // Check if it's a 404 error
                if let apiError = error as? BrrowAPIError {
                    switch apiError {
                    case .validationError(let message):
                        if message.lowercased().contains("not found") || message.lowercased().contains("meetup") {
                            print("🔍 [TRANSACTION DETAIL] Confirmed meetup deleted (404) - button will show 'Schedule Meetup'")
                            await MainActor.run {
                                meetupIsInvalid = true
                            }
                        }
                    case .serverError(let message):
                        if message.lowercased().contains("not found") {
                            print("🔍 [TRANSACTION DETAIL] Confirmed meetup deleted (404) - button will show 'Schedule Meetup'")
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

    /// Cancel the purchase and refund the payment
    private func cancelPurchase() {
        isCancelingPurchase = true

        Task {
            do {
                let response: CancelPurchaseResponse = try await APIClient.shared.request(
                    "/api/purchases/\(purchaseId)/cancel",
                    method: .POST,
                    parameters: ["reason": "Canceled by buyer"]
                )

                await MainActor.run {
                    isCancelingPurchase = false

                    if response.success {
                        print("✅ [TRANSACTION DETAIL] Purchase canceled successfully")
                        viewModel.successMessage = "Purchase cancelled successfully. Your payment will be refunded."
                        // Refresh to show updated status
                        viewModel.fetchPurchaseDetails(purchaseId: purchaseId)
                    } else {
                        print("❌ [TRANSACTION DETAIL] Failed to cancel purchase: \(response.message ?? "Unknown error")")
                        viewModel.errorMessage = response.message ?? "Failed to cancel purchase"
                    }
                }
            } catch {
                await MainActor.run {
                    isCancelingPurchase = false
                    print("❌ [TRANSACTION DETAIL] Error canceling purchase: \(error.localizedDescription)")
                    viewModel.errorMessage = "Failed to cancel purchase: \(error.localizedDescription)"
                }
            }
        }
    }
}

struct ListingInfoSection: View {
    let purchase: PurchaseDetail

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let listing = purchase.listing {
                HStack(spacing: 12) {
                    if let imageUrl = listing.listingImages?.first?.imageUrl {
                        AsyncImage(url: URL(string: imageUrl)) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Color.gray.opacity(0.2)
                        }
                        .frame(width: 80, height: 80)
                        .cornerRadius(12)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(listing.title)
                            .font(.headline)
                            .lineLimit(2)

                        Text(listing.description)
                            .font(.caption)
                            .foregroundColor(.gray)
                            .lineLimit(3)

                        Text("$\(String(format: "%.2f", listing.price))")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                    }

                    Spacer()
                }
            } else {
                // FIXED: Show message when listing is deleted/unavailable
                HStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.orange)
                        .frame(width: 80, height: 80)
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(12)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Listing No Longer Available")
                            .font(.headline)
                            .foregroundColor(.orange)

                        Text("This listing has been removed or deleted by the owner")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .lineLimit(3)
                    }

                    Spacer()
                }
            }

            Divider()

            // Other party info
            if let otherParty = purchase.otherParty {
                HStack {
                    Text(purchase.isBuyer ? "Seller:" : "Buyer:")
                        .font(.subheadline)
                        .foregroundColor(.gray)

                    Spacer()

                    HStack(spacing: 8) {
                        if let profilePicUrl = otherParty.profilePictureUrl {
                            AsyncImage(url: URL(string: profilePicUrl)) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            } placeholder: {
                                Color.gray.opacity(0.3)
                            }
                            .frame(width: 30, height: 30)
                            .clipShape(Circle())
                        }

                        Text("@\(otherParty.username)")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct TimelineSection: View {
    let steps: [TimelineStep]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Transaction Progress")
                .font(.headline)
                .padding(.bottom, 16)

            ForEach(steps) { step in
                TimelineStepView(step: step, isLast: step.step == steps.count)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct TimelineStepView: View {
    let step: TimelineStep
    let isLast: Bool

    var statusColor: Color {
        switch step.status {
        case "completed": return .green
        case "in_progress": return .blue
        default: return .gray.opacity(0.3)
        }
    }

    var statusIcon: String {
        switch step.status {
        case "completed": return "checkmark.circle.fill"
        case "in_progress": return "circle.circle.fill"
        default: return "circle"
        }
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Icon column
            VStack(spacing: 0) {
                Image(systemName: statusIcon)
                    .font(.title3)
                    .foregroundColor(statusColor)
                    .frame(width: 30, height: 30)

                if !isLast {
                    Rectangle()
                        .fill(step.status == "completed" ? Color.green.opacity(0.3) : Color.gray.opacity(0.2))
                        .frame(width: 2)
                        .padding(.vertical, 4)
                }
            }

            // Content column
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(step.title)
                        .font(.headline)
                        .fontWeight(step.status == "in_progress" ? .bold : .semibold)

                    if step.status == "completed" {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.caption)
                    }
                }

                Text(step.description)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .fixedSize(horizontal: false, vertical: true)

                if let completedAt = step.completedAt {
                    Text(formatDate(completedAt))
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            .padding(.bottom, isLast ? 0 : 20)

            Spacer()
        }
    }

    func formatDate(_ dateString: String) -> String {
        return dateString.toUserFriendlyDate()
    }
}

struct ReceiptSection: View {
    let receipt: Receipt
    let amount: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Receipt")
                .font(.headline)

            VStack(spacing: 10) {
                ReceiptRow(label: "Subtotal", value: formatCurrency(receipt.subtotal))
                // Show promotions/discounts if any (placeholder for future implementation)
                // Note: Stripe fees are NOT shown to buyers - they never pay more than subtotal
                Divider()
                ReceiptRow(label: "Total", value: formatCurrency(receipt.subtotal), isBold: true)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    func formatCurrency(_ amount: Double) -> String {
        return "$\(String(format: "%.2f", amount))"
    }
}

struct ReceiptRow: View {
    let label: String
    let value: String
    var note: String? = nil
    var isBold: Bool = false

    var body: some View {
        VStack(spacing: 4) {
            HStack {
                Text(label)
                    .font(isBold ? .headline : .subheadline)
                Spacer()
                Text(value)
                    .font(isBold ? .headline : .subheadline)
                    .fontWeight(isBold ? .bold : .regular)
            }

            if let note = note {
                Text(note)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}

struct MeetupTrackingSection: View {
    let meetupId: String
    @ObservedObject var viewModel: TransactionDetailViewModel

    @State private var showCancelConfirmation = false
    @State private var isCancelling = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Meetup & Verification")
                .font(.headline)

            Button(action: {
                viewModel.showMeetupTracking = true
            }) {
                HStack {
                    Image(systemName: "location.fill")
                    Text("Track Meetup Location")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Spacer()
                    Image(systemName: "arrow.right")
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .cornerRadius(12)
            }

            // Cancel Meetup Button
            Button(action: {
                showCancelConfirmation = true
            }) {
                HStack {
                    Image(systemName: "xmark.circle")
                    Text("Cancel Meetup")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Spacer()
                }
                .foregroundColor(.red)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.red.opacity(0.1))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.red.opacity(0.3), lineWidth: 1)
                )
            }
            .disabled(isCancelling)

            Text("Once both parties arrive at the meetup location, you can verify the transaction using a PIN or QR code.")
                .font(.caption)
                .foregroundColor(.gray)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .alert("Cancel Meetup?", isPresented: $showCancelConfirmation) {
            Button("No, Keep It", role: .cancel) {}
            Button("Yes, Cancel", role: .destructive) {
                cancelMeetup()
            }
        } message: {
            Text("Are you sure you want to cancel this meetup? You can schedule a new one later.")
        }
    }

    private func cancelMeetup() {
        isCancelling = true

        MeetupService.shared.cancelMeetup(meetupId: meetupId)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    isCancelling = false
                    if case .failure(let error) = completion {
                        viewModel.errorMessage = error.localizedDescription
                    }
                },
                receiveValue: { success in
                    if success {
                        viewModel.successMessage = "Meetup cancelled successfully"
                        // Refresh purchase details to update UI
                        if let purchaseId = viewModel.purchase?.id {
                            viewModel.fetchPurchaseDetails(purchaseId: purchaseId)
                        }
                    }
                }
            )
            .store(in: &viewModel.cancellables)
    }
}

struct TransactionExpiredSection: View {
    let cancellationReason: String?
    let cancelledAt: String?

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            HStack(spacing: Theme.Spacing.sm) {
                Image(systemName: "clock.badge.exclamationmark")
                    .foregroundColor(Theme.Colors.error)
                    .font(.system(size: 36))
                Text("Transaction Expired")
                    .font(Theme.Typography.title)
                    .foregroundColor(Theme.Colors.error)
            }

            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                if let cancelledAt = cancelledAt {
                    Text("Expired on \(formatDate(cancelledAt))")
                        .font(Theme.Typography.subheadline)
                        .foregroundColor(Theme.Colors.secondaryText)
                }

                Text(cancellationReason ?? "This transaction has expired and been automatically cancelled.")
                    .font(Theme.Typography.body)
                    .foregroundColor(Theme.Colors.text)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(Theme.Colors.success)
                        .font(.system(size: 16))
                    Text("The payment hold has been released and your funds are available. No charges were made.")
                        .font(Theme.Typography.body)
                        .fontWeight(.medium)
                        .foregroundColor(Theme.Colors.success)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.top, Theme.Spacing.xs)
            }
        }
        .padding(Theme.Spacing.lg)
        .background(Theme.Colors.error.opacity(0.08))
        .cornerRadius(Theme.CornerRadius.card)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.card)
                .stroke(Theme.Colors.error.opacity(0.3), lineWidth: 1.5)
        )
        .padding(.horizontal, Theme.Spacing.md)
    }

    private func formatDate(_ dateString: String) -> String {
        return dateString.toUserFriendlyDate()
    }
}

struct MeetupExpiredSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.red)
                    .font(.title2)
                Text("Meetup Expired")
                    .font(.headline)
                    .foregroundColor(.red)
            }

            Text("This meetup has expired. The transaction has been cancelled and any payment holds have been released. You can schedule a new meetup if both parties are still interested.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Text("To continue with this transaction, please schedule a new meetup with the other party.")
                .font(.caption)
                .foregroundColor(.gray)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .background(Color.red.opacity(0.1))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.red.opacity(0.3), lineWidth: 1)
        )
    }
}

struct SellerActionsSection: View {
    @ObservedObject var viewModel: TransactionDetailViewModel
    let purchaseId: String

    var body: some View {
        VStack(spacing: 12) {
            Button(action: {
                viewModel.acceptPurchase(purchaseId: purchaseId)
            }) {
                Text("Accept Purchase")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .cornerRadius(12)
            }

            Button(action: {
                viewModel.declinePurchase(purchaseId: purchaseId)
            }) {
                Text("Decline Purchase")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red)
                    .cornerRadius(12)
            }
        }
        .padding(.vertical)
    }
}

struct BuyerActionsSection: View {
    @Binding var showingCancelConfirmation: Bool
    @Binding var isCanceling: Bool

    var body: some View {
        VStack(spacing: 12) {
            Button(action: {
                showingCancelConfirmation = true
            }) {
                HStack {
                    if isCanceling {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        Text("Canceling...")
                            .font(.headline)
                            .foregroundColor(.white)
                    } else {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.white)
                        Text("Cancel Purchase")
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.red)
                .cornerRadius(12)
            }
            .disabled(isCanceling)

            Text("Cancel this purchase and receive a full refund to your original payment method.")
                .font(.caption)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical)
    }
}

struct MeetupSchedulingSection: View {
    @Binding var showingMeetupScheduling: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Coordinate Meetup")
                .font(.headline)

            Text("Schedule a meetup location and time with the other party to complete this transaction safely.")
                .font(.caption)
                .foregroundColor(.gray)
                .fixedSize(horizontal: false, vertical: true)

            Button(action: {
                showingMeetupScheduling = true
            }) {
                HStack {
                    Image(systemName: "location")
                    Text("Schedule Meetup")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Spacer()
                    Image(systemName: "arrow.right")
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .cornerRadius(12)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - ViewModel
@MainActor
class TransactionDetailViewModel: ObservableObject {
    @Published var purchase: PurchaseDetail?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    @Published var showMeetupTracking = false
    @Published var meetupToVerify: Meetup?

    var cancellables = Set<AnyCancellable>()

    func fetchPurchaseDetails(purchaseId: String) {
        isLoading = true
        errorMessage = nil

        Task {
            do {
                guard let url = URL(string: "\(AppConfig.baseURL)/api/purchases/\(purchaseId)/details") else {
                    throw URLError(.badURL)
                }

                var request = URLRequest(url: url)
                request.httpMethod = "GET"

                if let token = TokenStorage.shared.getToken() {
                    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                }

                let (data, _) = try await URLSession.shared.data(for: request)
                let response = try JSONDecoder().decode(PurchaseDetailResponse.self, from: data)

                self.purchase = response.purchase
                self.isLoading = false
            } catch {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }

    func acceptPurchase(purchaseId: String) {
        Task {
            do {
                guard let url = URL(string: "\(AppConfig.baseURL)/api/purchases/\(purchaseId)/accept") else {
                    throw URLError(.badURL)
                }

                var request = URLRequest(url: url)
                request.httpMethod = "POST"

                if let token = TokenStorage.shared.getToken() {
                    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                }

                let (data, _) = try await URLSession.shared.data(for: request)
                let response = try JSONDecoder().decode(PurchaseAcceptResponse.self, from: data)

                self.successMessage = response.message
                // Refresh purchase details
                fetchPurchaseDetails(purchaseId: purchaseId)
            } catch {
                self.errorMessage = error.localizedDescription
            }
        }
    }

    func declinePurchase(purchaseId: String) {
        Task {
            do {
                guard let url = URL(string: "\(AppConfig.baseURL)/api/purchases/\(purchaseId)/decline") else {
                    throw URLError(.badURL)
                }

                var request = URLRequest(url: url)
                request.httpMethod = "POST"

                if let token = TokenStorage.shared.getToken() {
                    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                }

                let (data, _) = try await URLSession.shared.data(for: request)
                let response = try JSONDecoder().decode(PurchaseDeclineResponse.self, from: data)

                self.successMessage = response.message
            } catch {
                self.errorMessage = error.localizedDescription
            }
        }
    }
}

#Preview {
    NavigationView {
        TransactionDetailView(purchaseId: "test-id")
    }
}
