//
//  ChatOptionsSheet.swift
//  Brrow
//
//  3-dots menu options for chat conversations
//  Includes: Profile, Listing, Mute, Block, Report, Delete, Clear, Search, Share
//

import SwiftUI

struct ChatOptionsSheet: View {
    let conversation: Conversation
    @Environment(\.dismiss) var dismiss
    @Binding var showingUserProfile: Bool
    @Binding var showingListingDetail: Bool
    @Binding var showingSearch: Bool
    @State private var showingMuteOptions = false
    @State private var showingBlockConfirmation = false
    @State private var showingReportSheet = false
    @State private var showingDeleteConfirmation = false
    @State private var showingClearConfirmation = false
    @State private var showingShareSheet = false
    @State private var isMuted = false

    var body: some View {
        NavigationView {
            List {
                // View Profile
                Section {
                    Button(action: {
                        dismiss()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            showingUserProfile = true
                        }
                    }) {
                        Label {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("View Profile")
                                    .foregroundColor(Theme.Colors.text)
                                Text("See @\(conversation.otherUser.username)'s profile")
                                    .font(.caption)
                                    .foregroundColor(Theme.Colors.secondaryText)
                            }
                        } icon: {
                            Image(systemName: "person.circle.fill")
                                .foregroundColor(Theme.Colors.primary)
                        }
                    }

                    // View Listing (if this is a listing chat)
                    if conversation.isListingChat, let listing = conversation.listing {
                        Button(action: {
                            dismiss()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                showingListingDetail = true
                            }
                        }) {
                            Label {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("View Listing")
                                        .foregroundColor(Theme.Colors.text)
                                    Text(listing.title)
                                        .font(.caption)
                                        .foregroundColor(Theme.Colors.secondaryText)
                                        .lineLimit(1)
                                }
                            } icon: {
                                Image(systemName: "tag.fill")
                                    .foregroundColor(Theme.Colors.accent)
                            }
                        }
                    }

                    // Search in Conversation
                    Button(action: {
                        dismiss()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            showingSearch = true
                        }
                    }) {
                        Label("Search in Conversation", systemImage: "magnifyingglass")
                            .foregroundColor(Theme.Colors.text)
                    }
                }

                // Conversation Settings
                Section {
                    // Mute Conversation
                    Button(action: {
                        showingMuteOptions = true
                    }) {
                        Label {
                            Text(isMuted ? "Unmute Conversation" : "Mute Conversation")
                                .foregroundColor(Theme.Colors.text)
                        } icon: {
                            Image(systemName: isMuted ? "speaker.wave.2.fill" : "speaker.slash.fill")
                                .foregroundColor(.orange)
                        }
                    }

                    // Share Listing
                    if conversation.isListingChat {
                        Button(action: {
                            showingShareSheet = true
                        }) {
                            Label("Share Listing", systemImage: "square.and.arrow.up")
                                .foregroundColor(Theme.Colors.text)
                        }
                    }
                }

                // Conversation Management
                Section {
                    Button(action: {
                        showingClearConfirmation = true
                    }) {
                        Label("Clear Chat History", systemImage: "trash")
                            .foregroundColor(.orange)
                    }
                }

                // Dangerous Actions
                Section {
                    Button(action: {
                        showingBlockConfirmation = true
                    }) {
                        Label("Block User", systemImage: "hand.raised.fill")
                            .foregroundColor(.red)
                    }

                    Button(action: {
                        showingReportSheet = true
                    }) {
                        Label("Report User", systemImage: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                    }

                    Button(action: {
                        showingDeleteConfirmation = true
                    }) {
                        Label("Delete Conversation", systemImage: "trash.fill")
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Chat Options")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Done") {
                dismiss()
            })
        }
        .actionSheet(isPresented: $showingMuteOptions) {
            ActionSheet(
                title: Text("Mute Conversation"),
                message: Text("Choose how long to mute notifications"),
                buttons: [
                    .default(Text("For 1 Hour")) {
                        muteConversation(duration: .hour)
                    },
                    .default(Text("For 8 Hours")) {
                        muteConversation(duration: .hours8)
                    },
                    .default(Text("For 1 Week")) {
                        muteConversation(duration: .week)
                    },
                    .default(Text("Until I Turn It Back On")) {
                        muteConversation(duration: .forever)
                    },
                    .cancel()
                ]
            )
        }
        .alert("Block User", isPresented: $showingBlockConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Block", role: .destructive) {
                blockUser()
            }
        } message: {
            Text("Blocked users cannot message you or view your profile. Are you sure you want to block @\(conversation.otherUser.username)?")
        }
        .alert("Delete Conversation", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteConversation()
            }
        } message: {
            Text("This conversation will be permanently deleted. This action cannot be undone.")
        }
        .alert("Clear Chat History", isPresented: $showingClearConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Clear", role: .destructive) {
                clearChatHistory()
            }
        } message: {
            Text("All messages in this conversation will be permanently deleted from your device.")
        }
        .sheet(isPresented: $showingReportSheet) {
            ReportUserSheet(userId: conversation.otherUser.id, username: conversation.otherUser.username)
        }
        .sheet(isPresented: $showingShareSheet) {
            if let listing = conversation.listing {
                ShareListingSheet(listing: listing)
            }
        }
    }

    // MARK: - Actions

    enum MuteDuration {
        case hour
        case hours8
        case week
        case forever

        var seconds: TimeInterval {
            switch self {
            case .hour: return 3600
            case .hours8: return 28800
            case .week: return 604800
            case .forever: return 999999999
            }
        }
    }

    private func muteConversation(duration: MuteDuration) {
        isMuted = true

        // Store mute settings locally
        let mutedUntil = Date().addingTimeInterval(duration.seconds)
        UserDefaults.standard.set(mutedUntil, forKey: "muted_\(conversation.id)")

        print("🔕 Muted conversation \(conversation.id) until \(mutedUntil)")

        // TODO: Send to backend API
        Task {
            await muteConversationOnServer(conversationId: conversation.id, duration: duration)
        }

        dismiss()
    }

    private func muteConversationOnServer(conversationId: String, duration: MuteDuration) async {
        // API call to mute conversation
        print("📡 Sending mute request to server for conversation: \(conversationId)")
    }

    private func blockUser() {
        Task {
            do {
                try await APIClient.shared.blockUser(userId: conversation.otherUser.id)
                print("✅ Successfully blocked user: @\(conversation.otherUser.username)")

                await MainActor.run {
                    dismiss()
                    // Navigate back and close conversation
                    NotificationCenter.default.post(
                        name: NSNotification.Name("UserBlocked"),
                        object: conversation.otherUser.id
                    )
                }
            } catch {
                print("❌ Failed to block user: \(error)")
            }
        }
    }

    private func deleteConversation() {
        Task {
            do {
                try await APIClient.shared.deleteConversation(conversationId: conversation.id)
                print("✅ Successfully deleted conversation: \(conversation.id)")

                await MainActor.run {
                    dismiss()
                    // Navigate back to chat list
                    NotificationCenter.default.post(
                        name: NSNotification.Name("ConversationDeleted"),
                        object: conversation.id
                    )
                }
            } catch {
                print("❌ Failed to delete conversation: \(error)")
            }
        }
    }

    private func clearChatHistory() {
        Task {
            do {
                try await APIClient.shared.clearChatHistory(conversationId: conversation.id)
                print("✅ Successfully cleared chat history: \(conversation.id)")

                await MainActor.run {
                    dismiss()
                    // Refresh messages
                    NotificationCenter.default.post(
                        name: NSNotification.Name("ChatHistoryCleared"),
                        object: conversation.id
                    )
                }
            } catch {
                print("❌ Failed to clear chat history: \(error)")
            }
        }
    }
}

// MARK: - Report User Sheet
struct ReportUserSheet: View {
    let userId: String
    let username: String
    @Environment(\.dismiss) var dismiss
    @State private var selectedReason: ReportReason = .spam
    @State private var additionalDetails = ""
    @State private var isSubmitting = false

    enum ReportReason: String, CaseIterable {
        case spam = "Spam"
        case harassment = "Harassment"
        case inappropriate = "Inappropriate Content"
        case scam = "Scam or Fraud"
        case impersonation = "Impersonation"
        case other = "Other"

        var description: String {
            return self.rawValue
        }
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Reason for Report")) {
                    Picker("Reason", selection: $selectedReason) {
                        ForEach(ReportReason.allCases, id: \.self) { reason in
                            Text(reason.description).tag(reason)
                        }
                    }
                    .pickerStyle(.menu)
                }

                Section(header: Text("Additional Details (Optional)")) {
                    TextEditor(text: $additionalDetails)
                        .frame(height: 100)
                }

                Section {
                    Button(action: submitReport) {
                        if isSubmitting {
                            HStack {
                                Spacer()
                                ProgressView()
                                Text("Submitting...")
                                    .padding(.leading, 8)
                                Spacer()
                            }
                        } else {
                            Text("Submit Report")
                                .frame(maxWidth: .infinity)
                                .foregroundColor(.white)
                        }
                    }
                    .listRowBackground(Theme.Colors.primary)
                    .disabled(isSubmitting)
                }

                Section {
                    Text("Your report is anonymous and will be reviewed by our team. False reports may result in account suspension.")
                        .font(.caption)
                        .foregroundColor(Theme.Colors.secondaryText)
                }
            }
            .navigationTitle("Report @\(username)")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Cancel") {
                dismiss()
            })
        }
    }

    private func submitReport() {
        isSubmitting = true

        Task {
            do {
                try await APIClient.shared.reportUser(
                    userId: userId,
                    reason: selectedReason.rawValue,
                    details: additionalDetails
                )

                await MainActor.run {
                    print("✅ Report submitted successfully")
                    isSubmitting = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    print("❌ Failed to submit report: \(error)")
                    isSubmitting = false
                }
            }
        }
    }
}

// MARK: - Share Listing Sheet
struct ShareListingSheet: View {
    let listing: ListingPreview
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 60))
                    .foregroundColor(Theme.Colors.primary)
                    .padding(.top, 40)

                Text("Share Listing")
                    .font(.title2)
                    .fontWeight(.bold)

                Text(listing.title)
                    .font(.body)
                    .foregroundColor(Theme.Colors.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                if let price = listing.price {
                    Text("$\(String(format: "%.2f", price))")
                        .font(.headline)
                        .foregroundColor(Theme.Colors.primary)
                }

                VStack(spacing: 12) {
                    ShareButton(icon: "message.fill", title: "Share via Message", color: .blue) {
                        shareViaMessage()
                    }

                    ShareButton(icon: "link", title: "Copy Link", color: .gray) {
                        copyLink()
                    }

                    ShareButton(icon: "square.and.arrow.up", title: "More Options", color: Theme.Colors.primary) {
                        showSystemShareSheet()
                    }
                }
                .padding(.horizontal)

                Spacer()
            }
            .navigationBarItems(trailing: Button("Done") {
                dismiss()
            })
        }
    }

    private func shareViaMessage() {
        // TODO: Implement message sharing
        print("Share via message: \(listing.id)")
        dismiss()
    }

    private func copyLink() {
        let link = "https://brrowapp.com/listing/\(listing.id)"
        UIPasteboard.general.string = link
        print("✅ Link copied: \(link)")
        dismiss()
    }

    private func showSystemShareSheet() {
        let link = "https://brrowapp.com/listing/\(listing.id)"
        let activityVC = UIActivityViewController(
            activityItems: [link],
            applicationActivities: nil
        )

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(activityVC, animated: true)
        }

        dismiss()
    }
}

struct ShareButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 20))
                Text(title)
                    .fontWeight(.medium)
                Spacer()
            }
            .padding()
            .foregroundColor(.white)
            .background(color)
            .cornerRadius(12)
        }
    }
}
