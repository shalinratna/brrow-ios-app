//
//  OfferCardView.swift
//  Brrow
//
//  Offer card component for chat messages
//  Displays offer amount, status, and action buttons
//

import SwiftUI

struct OfferCardView: View {
    let message: Message
    let isFromCurrentUser: Bool
    let onAccept: () -> Void
    let onReject: () -> Void
    let onCounter: () -> Void

    // Parse offer data from message content
    private var offerData: OfferData? {
        guard let data = message.content.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(OfferData.self, from: data)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: "dollarsign.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(Theme.Colors.primary)

                Text("Offer")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Theme.Colors.text)

                Spacer()

                // Status badge
                if let status = offerData?.status {
                    statusBadge(status)
                }
            }

            // Offer amount
            if let amount = offerData?.offerAmount {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("$\(String(format: "%.2f", amount))")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(Theme.Colors.primary)

                    // Show original price if available
                    if let originalPrice = offerData?.listingPrice, originalPrice != amount {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Original: $\(String(format: "%.2f", originalPrice))")
                                .font(.system(size: 12))
                                .foregroundColor(Theme.Colors.secondaryText)
                                .strikethrough()

                            let discount = ((originalPrice - amount) / originalPrice) * 100
                            Text("\(Int(discount))% off")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(Theme.Colors.accent)
                        }
                    }
                }
            }

            // Offer message
            if let message = offerData?.message, !message.isEmpty {
                Text(message)
                    .font(.system(size: 14))
                    .foregroundColor(Theme.Colors.secondaryText)
                    .lineLimit(3)
            }

            // Duration (if available)
            if let duration = offerData?.duration, duration > 0 {
                HStack(spacing: 6) {
                    Image(systemName: "calendar")
                        .font(.system(size: 12))
                    Text("\(duration) day\(duration == 1 ? "" : "s")")
                        .font(.system(size: 13))
                }
                .foregroundColor(Theme.Colors.secondaryText)
            }

            // Action buttons (only show if recipient and status is pending)
            if !isFromCurrentUser, offerData?.status == "pending" {
                HStack(spacing: 8) {
                    // Reject button
                    Button(action: onReject) {
                        Text("Reject")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Theme.Colors.text)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Theme.Colors.surface)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Theme.Colors.border, lineWidth: 1)
                            )
                    }

                    // Counter button
                    Button(action: onCounter) {
                        Text("Counter")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Theme.Colors.primary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Theme.Colors.surface)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Theme.Colors.primary, lineWidth: 1)
                            )
                    }

                    // Accept button
                    Button(action: onAccept) {
                        Text("Accept")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Theme.Colors.primary)
                            .cornerRadius(8)
                    }
                }
            }

            // Timestamp
            HStack {
                Spacer()
                Text(message.timestamp.formatted(date: .abbreviated, time: .shortened))
                    .font(.system(size: 11))
                    .foregroundColor(Theme.Colors.secondaryText)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isFromCurrentUser ? Theme.Colors.primary.opacity(0.1) : Theme.Colors.surface)
                .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isFromCurrentUser ? Theme.Colors.primary.opacity(0.2) : Theme.Colors.border, lineWidth: 1)
        )
    }

    // MARK: - Status Badge

    @ViewBuilder
    private func statusBadge(_ status: String) -> some View {
        let (text, color) = statusInfo(status)

        Text(text)
            .font(.system(size: 11, weight: .medium))
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(color)
            )
    }

    private func statusInfo(_ status: String) -> (String, Color) {
        switch status.lowercased() {
        case "pending":
            return ("Pending", Color.orange)
        case "accepted":
            return ("Accepted", Theme.Colors.primary)
        case "rejected":
            return ("Rejected", Theme.Colors.accent)
        case "countered":
            return ("Countered", Color.blue)
        default:
            return (status.capitalized, Color.gray)
        }
    }
}

// MARK: - Offer Data Model

struct OfferData: Codable {
    let offerAmount: Double
    let listingPrice: Double?
    let status: String
    let message: String?
    let duration: Int?

    enum CodingKeys: String, CodingKey {
        case offerAmount = "offer_amount"
        case listingPrice = "listing_price"
        case status
        case message
        case duration
    }
}

// MARK: - Preview

#if DEBUG
struct OfferCardView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            // Pending offer with discount
            OfferCardView(
                message: Message(
                    id: "1",
                    chatId: "chat1",
                    senderId: "user1",
                    receiverId: "user2",
                    content: "{\"offer_amount\":80.0,\"listing_price\":100.0,\"status\":\"pending\",\"message\":\"Would you accept this offer?\",\"duration\":5}",
                    messageType: .offer,
                    mediaUrl: nil,
                    thumbnailUrl: nil,
                    listingId: nil,
                    isRead: false,
                    isEdited: false,
                    editedAt: nil,
                    deletedAt: nil,
                    sentAt: nil,
                    deliveredAt: nil,
                    readAt: nil,
                    createdAt: ISO8601DateFormatter().string(from: Date()),
                    sender: nil,
                    reactions: nil
                ),
                isFromCurrentUser: false,
                onAccept: { print("Accepted") },
                onReject: { print("Rejected") },
                onCounter: { print("Counter") }
            )
            .padding()

            // Accepted offer from current user
            OfferCardView(
                message: Message(
                    id: "2",
                    chatId: "chat1",
                    senderId: "user2",
                    receiverId: "user1",
                    content: "{\"offer_amount\":90.0,\"listing_price\":100.0,\"status\":\"accepted\",\"message\":\"Thanks for the offer!\"}",
                    messageType: .offer,
                    mediaUrl: nil,
                    thumbnailUrl: nil,
                    listingId: nil,
                    isRead: false,
                    isEdited: false,
                    editedAt: nil,
                    deletedAt: nil,
                    sentAt: nil,
                    deliveredAt: nil,
                    readAt: nil,
                    createdAt: ISO8601DateFormatter().string(from: Date()),
                    sender: nil,
                    reactions: nil
                ),
                isFromCurrentUser: true,
                onAccept: { print("Accepted") },
                onReject: { print("Rejected") },
                onCounter: { print("Counter") }
            )
            .padding()
        }
        .background(Theme.Colors.background)
    }
}
#endif
