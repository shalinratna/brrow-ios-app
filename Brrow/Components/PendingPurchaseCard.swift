//
//  PendingPurchaseCard.swift
//  Brrow
//
//  Card component for displaying pending purchases requiring verification
//

import SwiftUI

struct PendingPurchaseCard: View {
    let purchase: Purchase
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            ZStack {
                // Background gradient (Blue)
                LinearGradient(
                    colors: [
                        Color(hex: "#007AFF"),  // iOS Blue
                        Color(hex: "#0051D5")   // Darker Blue
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                VStack(alignment: .leading, spacing: 0) {
                    // Header section with icon
                    VStack(alignment: .leading, spacing: 12) {
                        // Header
                        HStack {
                            Image(systemName: "cart.fill.badge.questionmark")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(.white)

                            Text("Pending Purchase")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white.opacity(0.9))
                                .textCase(.uppercase)
                                .tracking(0.5)

                            Spacer()

                            // Urgency badge
                            Text(urgencyText)
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(urgencyColor)
                                .cornerRadius(6)
                        }

                        // Listing title
                        Text(purchase.listing?.title ?? "Purchase")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)

                        // Purchase details
                        VStack(alignment: .leading, spacing: 6) {
                            // Amount
                            HStack(spacing: 6) {
                                Image(systemName: "dollarsign.circle.fill")
                                    .font(.system(size: 12))
                                Text("$\(String(format: "%.2f", purchase.amount))")
                                    .font(.system(size: 15, weight: .bold))
                            }
                            .foregroundColor(.white)

                            // Deadline
                            HStack(spacing: 6) {
                                Image(systemName: "clock.fill")
                                    .font(.system(size: 12))
                                Text(deadlineText)
                                    .font(.system(size: 13, weight: .medium))
                            }
                            .foregroundColor(.white.opacity(0.95))

                            // Verification status
                            HStack(spacing: 6) {
                                Image(systemName: "checkmark.shield.fill")
                                    .font(.system(size: 12))
                                Text(verificationStatusText)
                                    .font(.system(size: 13, weight: .medium))
                            }
                            .foregroundColor(.white.opacity(0.95))

                            // Other party info
                            if let otherParty = purchase.seller ?? purchase.buyer {
                                HStack(spacing: 8) {
                                    Text("Seller:")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(.white.opacity(0.8))

                                    if let profilePicture = otherParty.profilePicture, !profilePicture.isEmpty {
                                        BrrowAsyncImage(url: profilePicture) { image in
                                            image
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                        } placeholder: {
                                            Circle()
                                                .fill(Color.white.opacity(0.3))
                                        }
                                        .frame(width: 24, height: 24)
                                        .clipShape(Circle())
                                    } else {
                                        Circle()
                                            .fill(Color.white.opacity(0.3))
                                            .frame(width: 24, height: 24)
                                    }

                                    Text(otherParty.username)
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(.white)
                                        .lineLimit(1)
                                }
                            }
                        }

                        // Action button
                        HStack {
                            Spacer()
                            Text("Verify Now")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.white)
                            Image(systemName: "arrow.right")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                        }
                        .padding(.top, 4)
                    }
                    .padding(16)
                }
            }
            .frame(width: 300, height: 240)
            .cornerRadius(20)
            .shadow(color: Color.black.opacity(0.25), radius: 15, x: 0, y: 8)
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - Computed Properties

    private var deadlineText: String {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.day, .hour], from: now, to: purchase.deadline)

        if let days = components.day, days > 0 {
            return "\(days) day\(days == 1 ? "" : "s") left"
        } else if let hours = components.hour, hours > 0 {
            return "\(hours) hour\(hours == 1 ? "" : "s") left"
        } else {
            return "Expiring soon"
        }
    }

    private var urgencyText: String {
        let calendar = Calendar.current
        let hoursRemaining = calendar.dateComponents([.hour], from: Date(), to: purchase.deadline).hour ?? 0

        if hoursRemaining < 24 {
            return "URGENT"
        } else if hoursRemaining < 48 {
            return "ACTION NEEDED"
        } else {
            return "PENDING"
        }
    }

    private var urgencyColor: Color {
        let calendar = Calendar.current
        let hoursRemaining = calendar.dateComponents([.hour], from: Date(), to: purchase.deadline).hour ?? 0

        if hoursRemaining < 24 {
            return Color.red.opacity(0.9)
        } else if hoursRemaining < 48 {
            return Color.orange.opacity(0.8)
        } else {
            return Color.white.opacity(0.25)
        }
    }

    private var verificationStatusText: String {
        switch purchase.verificationStatus {
        case .pending:
            return "Awaiting verification"
        case .sellerConfirmed:
            return "Seller confirmed"
        case .buyerConfirmed:
            return "Buyer confirmed"
        case .bothConfirmed:
            return "Both confirmed"
        case .failed:
            return "Verification failed"
        }
    }
}
