//
//  ListingInquiryView.swift
//  Brrow
//
//  Send inquiry about a listing
//

import SwiftUI

struct ListingInquiryView: View {
    let listing: Listing
    @State private var message = ""
    @State private var inquiryType = "general"
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showSuccess = false
    @State private var conversationId: Int?
    
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authManager: AuthManager
    @ObservedObject private var apiClient = APIClient.shared
    
    private let inquiryTypes = [
        ("general", "General Question", "bubble.left.and.bubble.right"),
        ("availability", "Check Availability", "calendar"),
        ("price_negotiation", "Negotiate Price", "dollarsign.circle"),
        ("condition", "Item Condition", "info.circle")
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Listing Preview
                    listingPreview
                    
                    // Inquiry Type Selection
                    inquiryTypeSelector
                    
                    // Message Input
                    messageInput
                    
                    // Quick Templates
                    quickTemplates
                    
                    // Send Button
                    sendButton
                }
                .padding()
            }
            .navigationTitle("Send Inquiry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
        .sheet(isPresented: $showSuccess) {
            InquirySuccessView(listing: listing, conversationId: conversationId)
        }
    }
    
    private var listingPreview: some View {
        HStack(spacing: 12) {
            // Listing Image
            if !listing.images.isEmpty,
               let firstImage = listing.imageUrls.first,
               let url = URL(string: firstImage) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .overlay(
                            ProgressView()
                        )
                }
                .frame(width: 80, height: 80)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(listing.title)
                    .font(.headline)
                    .lineLimit(2)
                
                Text("$\(listing.price, specifier: "%.2f")/\(listing.rentalPeriod ?? "day")")
                    .font(.subheadline)
                    .foregroundColor(Theme.Colors.primary)
                
                HStack {
                    Image(systemName: "person.circle.fill")
                        .font(.caption)
                    Text(listing.ownerUsername ?? "Seller")
                        .font(.caption)
                        .foregroundColor(Theme.Colors.secondaryText)
                }
            }
            
            Spacer()
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private var inquiryTypeSelector: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("What's your inquiry about?")
                .font(.headline)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(inquiryTypes, id: \.0) { type in
                        InquiryTypeButton(
                            title: type.1,
                            icon: type.2,
                            isSelected: inquiryType == type.0
                        ) {
                            inquiryType = type.0
                            generateTemplate(for: type.0)
                        }
                    }
                }
            }
        }
    }
    
    private var messageInput: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Your Message")
                .font(.headline)
            
            TextEditor(text: $message)
                .frame(minHeight: 120)
                .padding(8)
                .background(Color.gray.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
            
            Text("\(message.count)/1000")
                .font(.caption)
                .foregroundColor(message.count > 900 ? .red : Theme.Colors.secondaryText)
        }
    }
    
    private var quickTemplates: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Quick Templates")
                .font(.subheadline)
                .foregroundColor(Theme.Colors.secondaryText)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    TemplateButton(text: "Is this still available?") {
                        let listingType = listing.dailyRate != nil ? "for rent" : "for sale"
                        message = "Hi! I'm interested in \(listing.title). Is it still available \(listingType)?"
                    }
                    
                    TemplateButton(text: "What's the condition?") {
                        message = "Hello! Could you tell me more about the condition of \(listing.title)?"
                    }
                    
                    TemplateButton(text: "Can we negotiate?") {
                        let action = listing.dailyRate != nil ? "renting" : "buying"
                        message = "Hi there! I'm interested in \(action) \(listing.title). Would you be open to discussing the price?"
                    }
                }
            }
        }
    }
    
    private var sendButton: some View {
        Button(action: sendInquiry) {
            HStack {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "paperplane.fill")
                    Text("Send Inquiry")
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                message.isEmpty ? Color.gray : Theme.Colors.primary
            )
            .foregroundColor(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .disabled(message.isEmpty || isLoading)
    }
    
    private func generateTemplate(for type: String) {
        switch type {
        case "availability":
            message = "Hi! I'm interested in renting \(listing.title). Is it available for the next few days?"
        case "price_negotiation":
            message = "Hello! I'd like to rent \(listing.title). Would you consider a different price for a longer rental period?"
        case "condition":
            message = "Hi there! Could you provide more details about the current condition of \(listing.title)?"
        default:
            message = ""
        }
    }
    
    private func sendInquiry() {
        guard !message.isEmpty else { return }
        
        isLoading = true
        errorMessage = ""
        
        Task {
            do {
                let response = try await apiClient.sendListingInquiry(
                    listingId: listing.listingId,
                    message: message,
                    inquiryType: inquiryType
                )
                
                await MainActor.run {
                    conversationId = response.conversationId
                    isLoading = false
                    showSuccess = true
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
}

// MARK: - Supporting Views

struct InquiryTypeButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                Text(title)
                    .font(.system(size: 14, weight: .medium))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? Theme.Colors.primary : Color.gray.opacity(0.1))
            .foregroundColor(isSelected ? .white : Theme.Colors.text)
            .clipShape(Capsule())
        }
    }
}

struct TemplateButton: View {
    let text: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(text)
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.blue.opacity(0.1))
                .foregroundColor(.blue)
                .clipShape(Capsule())
        }
    }
}

struct InquirySuccessView: View {
    let listing: Listing
    let conversationId: Int?
    @Environment(\.dismiss) private var dismiss
    @State private var navigateToChat = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Spacer()
                
                // Success Icon
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(Theme.Colors.primary)
                
                Text("Inquiry Sent!")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Your message has been sent to \(listing.ownerUsername ?? "the seller"). They'll be notified and can respond through the chat.")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(Theme.Colors.secondaryText)
                    .padding(.horizontal)
                
                Spacer()
                
                // Action Buttons
                VStack(spacing: 12) {
                    Button(action: {
                        navigateToChat = true
                    }) {
                        HStack {
                            Image(systemName: "message.fill")
                            Text("Go to Chat")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Theme.Colors.primary)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    
                    Button(action: {
                        dismiss()
                    }) {
                        Text("Done")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .foregroundColor(Theme.Colors.text)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                .padding()
            }
            .navigationBarHidden(true)
        }
        .fullScreenCover(isPresented: $navigateToChat) {
            // Navigate to chat view with the conversation
            if let conversationId = conversationId {
                // ChatDetailView(conversationId: conversationId)
                Text("Chat View - Conversation ID: \(conversationId)")
            }
        }
    }
}