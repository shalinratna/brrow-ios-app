//
//  InquiryView.swift
//  Brrow
//
//  Inquiry form for contacting listing owners
//

import SwiftUI

struct InquiryView: View {
    let listing: Listing
    @Binding var message: String
    let onSend: (String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var inquiryText = ""
    @State private var isLoading = false
    @State private var selectedTemplate = 0

    private let messageTemplates = [
        "Is this item still available?",
        "Hi! I'm interested in renting this item. Could you provide more details?",
        "What's the condition of this item?",
        "Are you flexible with the rental price?",
        "When would this be available for pickup?"
    ]

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 8) {
                    Text("Send Inquiry")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("Contact \(listing.ownerUsername ?? "the owner") about this item")
                        .font(.subheadline)
                        .foregroundColor(Theme.Colors.secondaryText)
                        .multilineTextAlignment(.center)
                }
                .padding(.top)

                // Item Preview
                HStack(spacing: 12) {
                    AsyncImage(url: URL(string: listing.firstImageUrl ?? "")) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                    }
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                    VStack(alignment: .leading, spacing: 4) {
                        Text(listing.title)
                            .font(.headline)
                            .lineLimit(2)

                        Text("$\(String(format: "%.2f", listing.price))/day")
                            .font(.subheadline)
                            .foregroundColor(Theme.Colors.primary)
                    }

                    Spacer()
                }
                .padding()
                .background(Theme.Colors.secondaryBackground)
                .cornerRadius(12)

                // Quick Templates
                VStack(alignment: .leading, spacing: 12) {
                    Text("Quick Messages")
                        .font(.headline)

                    ForEach(Array(messageTemplates.enumerated()), id: \.offset) { index, template in
                        Button(action: {
                            inquiryText = template
                        }) {
                            HStack {
                                Text(template)
                                    .font(.subheadline)
                                    .foregroundColor(Theme.Colors.text)
                                    .multilineTextAlignment(.leading)

                                Spacer()

                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(Theme.Colors.primary)
                            }
                            .padding()
                            .background(Theme.Colors.secondaryBackground)
                            .cornerRadius(8)
                        }
                    }
                }

                // Custom Message
                VStack(alignment: .leading, spacing: 8) {
                    Text("Your Message")
                        .font(.headline)

                    TextEditor(text: $inquiryText)
                        .frame(minHeight: 100, maxHeight: 150)
                        .padding(12)
                        .background(Theme.Colors.secondaryBackground)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )

                    if inquiryText.isEmpty {
                        Text("Type your message here...")
                            .foregroundColor(.gray)
                            .padding(.leading, 16)
                            .padding(.top, -110)
                            .allowsHitTesting(false)
                    }
                }

                Spacer()

                // Send Button
                Button(action: sendInquiry) {
                    HStack {
                        if isLoading {
                            ProgressView()
                                .scaleEffect(0.8)
                                .foregroundColor(.white)
                        } else {
                            Image(systemName: "paperplane.fill")
                                .font(.system(size: 16, weight: .medium))
                        }

                        Text("Send Message")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(inquiryText.isEmpty ? Color.gray : Theme.Colors.primary)
                    .cornerRadius(25)
                }
                .disabled(inquiryText.isEmpty || isLoading)
            }
            .padding()
            .navigationBarHidden(true)
            .overlay(
                // Custom Navigation Bar
                VStack {
                    HStack {
                        Button("Cancel") {
                            dismiss()
                        }
                        .foregroundColor(Theme.Colors.primary)

                        Spacer()

                        Text("New Message")
                            .font(.headline)

                        Spacer()

                        Button("Cancel") {
                            dismiss()
                        }
                        .opacity(0) // Invisible for centering
                    }
                    .padding()
                    .background(Theme.Colors.background)

                    Spacer()
                }
            )
        }
        .onAppear {
            // Set default message if provided
            if !message.isEmpty {
                inquiryText = message
            }
        }
    }

    private func sendInquiry() {
        guard !inquiryText.isEmpty else { return }

        isLoading = true
        onSend(inquiryText)

        // Update binding
        message = inquiryText

        // Close sheet after brief delay to show loading state
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            dismiss()
        }
    }
}

#Preview {
    InquiryView(
        listing: Listing.example,
        message: .constant(""),
        onSend: { message in
            print("Sending inquiry: \(message)")
        }
    )
}