//
//  PendingOfferCard.swift
//  Brrow
//
//  Card component for displaying pending offers requiring review
//

import SwiftUI

struct PendingOfferCard: View {
    let offer: Offer
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            ZStack {
                // Background gradient (Orange)
                LinearGradient(
                    colors: [
                        Color(hex: "#FF9500"),  // iOS Orange
                        Color(hex: "#FF6B00")   // Darker Orange
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                VStack(alignment: .leading, spacing: 0) {
                    // Content
                    VStack(alignment: .leading, spacing: 12) {
                        // Header
                        HStack {
                            Image(systemName: "tag.fill")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(.white)

                            Text("New Offer")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white.opacity(0.9))
                                .textCase(.uppercase)
                                .tracking(0.5)

                            Spacer()

                            // Status badge
                            if isExpiringSoon {
                                Text("EXPIRING SOON")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.red.opacity(0.8))
                                    .cornerRadius(6)
                            } else {
                                Text("PENDING")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.white.opacity(0.25))
                                    .cornerRadius(6)
                            }
                        }

                        // Listing title
                        Text(offer.listing?.title ?? "Item")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)

                        // Offer details
                        VStack(alignment: .leading, spacing: 6) {
                            // Offer amount
                            HStack(spacing: 6) {
                                Image(systemName: "dollarsign.circle.fill")
                                    .font(.system(size: 12))
                                Text("$\(String(format: "%.2f", offer.amount))")
                                    .font(.system(size: 15, weight: .bold))
                                Text("offered")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.white.opacity(0.9))
                            }
                            .foregroundColor(.white)

                            // Original price comparison (if available)
                            if let listing = offer.listing {
                                HStack(spacing: 6) {
                                    Image(systemName: "chart.bar.fill")
                                        .font(.system(size: 12))
                                    let difference = listing.price - offer.amount
                                    let percentOff = (difference / listing.price) * 100
                                    Text("\(Int(percentOff))% off asking price")
                                        .font(.system(size: 13, weight: .medium))
                                }
                                .foregroundColor(.white.opacity(0.95))
                            }

                            // Expiration time
                            if let expiresAt = offer.expiresAt {
                                HStack(spacing: 6) {
                                    Image(systemName: "clock.fill")
                                        .font(.system(size: 12))
                                    Text(expirationText(expiresAt))
                                        .font(.system(size: 13, weight: .medium))
                                }
                                .foregroundColor(.white.opacity(0.95))
                            }

                            // Borrower info
                            if let borrower = offer.borrower {
                                HStack(spacing: 8) {
                                    Text("From:")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(.white.opacity(0.8))

                                    if let profilePicture = borrower.profilePicture, !profilePicture.isEmpty {
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

                                    Text(borrower.username)
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(.white)
                                        .lineLimit(1)

                                    // Verification badge
                                    if borrower.isVerified == true {
                                        Image(systemName: "checkmark.seal.fill")
                                            .font(.system(size: 14))
                                            .foregroundColor(.white.opacity(0.9))
                                    }
                                }
                            }
                        }

                        // Action button
                        HStack {
                            Spacer()
                            Text("Review Offer")
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

    private var isExpiringSoon: Bool {
        guard let expiresAt = offer.expiresAt else { return false }
        let hoursRemaining = Calendar.current.dateComponents([.hour], from: Date(), to: expiresAt).hour ?? 0
        return hoursRemaining < 24
    }

    private func expirationText(_ expiresAt: Date) -> String {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.day, .hour, .minute], from: now, to: expiresAt)

        if let days = components.day, days > 0 {
            return "Expires in \(days) day\(days == 1 ? "" : "s")"
        } else if let hours = components.hour, hours > 0 {
            return "Expires in \(hours) hour\(hours == 1 ? "" : "s")"
        } else if let minutes = components.minute, minutes > 0 {
            return "Expires in \(minutes) min\(minutes == 1 ? "" : "s")"
        } else {
            return "Expiring soon"
        }
    }
}
