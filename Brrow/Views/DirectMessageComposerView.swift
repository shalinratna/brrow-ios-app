//
//  DirectMessageComposerView.swift
//  Brrow
//
//  Direct message composer for user-to-user messaging (no listing)
//

import SwiftUI

struct DirectMessageComposerView: View {
    let recipient: User
    @Environment(\.dismiss) private var dismiss
    @State private var messageText = ""
    @State private var isLoading = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var showingSuccess = false
    @FocusState private var isTextEditorFocused: Bool

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Recipient info (stays at top)
                HStack(spacing: 12) {
                    if let profilePicture = recipient.profilePicture {
                        BrrowAsyncImage(url: profilePicture) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Image(systemName: "person.circle.fill")
                                .font(.system(size: 30))
                                .foregroundColor(Theme.Colors.secondary)
                        }
                        .frame(width: 40, height: 40)
                        .clipShape(Circle())
                    } else {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 40))
                            .foregroundColor(Theme.Colors.secondary)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        HStack {
                            Text(recipient.username)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(Theme.Colors.text)

                            if recipient.isVerified == true {
                                Image(systemName: "checkmark.seal.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(Theme.Colors.primary)
                            }
                        }

                        Text("Direct Message")
                            .font(.system(size: 14))
                            .foregroundColor(Theme.Colors.secondaryText)
                    }

                    Spacer()
                }
                .padding(16)
                .background(Theme.Colors.secondaryBackground)

                // Scrollable content area
                ScrollView {
                    VStack(spacing: 16) {
                        // Custom message input area
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Write your message")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(Theme.Colors.text)
                                .padding(.horizontal, 16)
                                .padding(.top, 16)

                            VStack(spacing: 8) {
                                TextEditor(text: $messageText)
                                    .focused($isTextEditorFocused)
                                    .padding(12)
                                    .background(Theme.Colors.secondaryBackground)
                                    .cornerRadius(12)
                                    .frame(minHeight: 200)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(isTextEditorFocused ? Theme.Colors.primary : Color.clear, lineWidth: 2)
                                    )
                                    .onAppear {
                                        // Auto-focus when view appears
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                            isTextEditorFocused = true
                                        }
                                    }

                                HStack {
                                    Text("\(messageText.count)/500")
                                        .font(.system(size: 12))
                                        .foregroundColor(Theme.Colors.secondaryText)

                                    Spacer()

                                    if messageText.count > 500 {
                                        Text("Message too long")
                                            .font(.system(size: 12, weight: .medium))
                                            .foregroundColor(.red)
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                        }

                        // Extra padding at bottom for send button
                        Color.clear.frame(height: 80)
                    }
                }

                // Send button (stays at bottom, above keyboard)
                VStack {
                    Divider()
                    Button(action: { sendMessage() }) {
                        HStack {
                            Text("Send Message")
                                .font(.system(size: 18, weight: .semibold))

                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            }
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Theme.Colors.primary)
                        .cornerRadius(12)
                        .opacity(messageText.isEmpty || isLoading ? 0.6 : 1)
                    }
                    .disabled(messageText.isEmpty || isLoading || messageText.count > 500)
                    .padding(16)
                }
                .background(Theme.Colors.background)
            }
            .navigationTitle("Direct Message")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .navigationBarItems(leading:
                Button("Cancel") {
                    dismiss()
                }
            )
            .ignoresSafeArea(.keyboard, edges: .bottom)
            .alert("Error", isPresented: $showingError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .overlay(
                Group {
                    if showingSuccess {
                        Color.black.opacity(0.4)
                            .ignoresSafeArea()
                            .overlay(
                                VStack(spacing: 16) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 60))
                                        .foregroundColor(.green)

                                    Text("Message Sent!")
                                        .font(.system(size: 20, weight: .semibold))
                                        .foregroundColor(.white)

                                    Text("Check your Messages tab")
                                        .font(.system(size: 16))
                                        .foregroundColor(.white.opacity(0.8))
                                }
                                .padding(40)
                                .background(Color.black.opacity(0.8))
                                .cornerRadius(20)
                            )
                            .transition(.opacity)
                    }
                }
            )
        }
    }

    private func sendMessage() {
        guard !messageText.isEmpty else { return }

        isLoading = true

        Task {
            do {
                // Create or find a direct conversation (no listing)
                guard let recipientId = recipient.apiId else {
                    throw BrrowAPIError.validationError("Recipient ID is required")
                }

                let conversation = try await APIClient.shared.createConversation(
                    otherUserId: recipientId,
                    listingId: nil
                )

                // Then send the message
                _ = try await APIClient.shared.sendMessage(
                    conversationId: conversation.id,
                    content: messageText,
                    messageType: .text
                )

                await MainActor.run {
                    isLoading = false

                    // Show success message
                    withAnimation {
                        showingSuccess = true
                    }

                    // Auto-dismiss after showing success
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        dismiss()
                    }
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                    showingError = true
                }
            }
        }
    }
}