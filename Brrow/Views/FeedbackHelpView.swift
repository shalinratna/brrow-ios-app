//
//  FeedbackHelpView.swift
//  Brrow
//
//  Feedback and Help system with Discord webhook integration
//

import SwiftUI

struct FeedbackHelpView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedType: FeedbackType = .feedback
    @State private var subject = ""
    @State private var message = ""
    @State private var email = ""
    @State private var isSending = false
    @State private var showSuccess = false
    @State private var errorMessage = ""
    @EnvironmentObject var authManager: AuthManager
    
    enum FeedbackType: String, CaseIterable {
        case feedback = "Feedback"
        case bug = "Bug Report"
        case feature = "Feature Request"
        case help = "Help"
        case other = "Other"
        
        var icon: String {
            switch self {
            case .feedback: return "bubble.left.and.bubble.right.fill"
            case .bug: return "ladybug.fill"
            case .feature: return "lightbulb.fill"
            case .help: return "questionmark.circle.fill"
            case .other: return "ellipsis.circle.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .feedback: return Theme.Colors.primary
            case .bug: return .red
            case .feature: return .purple
            case .help: return .blue
            case .other: return .gray
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Theme.Colors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Quick help links first
                        VStack(spacing: 16) {
                            HStack {
                                Text("Quick Help")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(Theme.Colors.text)
                                Spacer()
                            }
                            
                            VStack(spacing: 12) {
                                QuickHelpLink(
                                    icon: "book.fill",
                                    title: "User Guide",
                                    subtitle: "Learn how to use Brrow"
                                )
                                
                                QuickHelpLink(
                                    icon: "questionmark.circle.fill",
                                    title: "FAQs",
                                    subtitle: "Frequently asked questions"
                                )
                                
                                QuickHelpLink(
                                    icon: "shield.fill",
                                    title: "Safety Tips",
                                    subtitle: "Stay safe while sharing"
                                )
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Theme.Colors.cardBackground)
                        )
                        .padding(.horizontal)
                        .padding(.top, 10)
                        
                        // Divider
                        HStack {
                            Rectangle()
                                .fill(Theme.Colors.secondary.opacity(0.2))
                                .frame(height: 1)
                            Text("OR")
                                .font(.caption.bold())
                                .foregroundColor(Theme.Colors.secondaryText)
                                .padding(.horizontal, 12)
                            Rectangle()
                                .fill(Theme.Colors.secondary.opacity(0.2))
                                .frame(height: 1)
                        }
                        .padding(.horizontal)
                        
                        // Type selector
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Report an Issue")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(Theme.Colors.text)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(FeedbackType.allCases, id: \.self) { type in
                                        FeedbackTypeButton(
                                            type: type,
                                            isSelected: selectedType == type
                                        ) {
                                            withAnimation(.spring(response: 0.3)) {
                                                selectedType = type
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                        
                        // Form fields
                        VStack(spacing: 16) {
                            // Subject field
                            VStack(alignment: .leading, spacing: 8) {
                                Label("Subject", systemImage: "text.quote")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(Theme.Colors.secondaryText)
                                
                                TextField("What's this about?", text: $subject)
                                    .font(.system(size: 16))
                                    .padding()
                                    .background(Theme.Colors.secondaryBackground)
                                    .cornerRadius(12)
                            }
                            
                            // Email field (auto-filled if logged in)
                            VStack(alignment: .leading, spacing: 8) {
                                Label("Email (optional)", systemImage: "envelope")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(Theme.Colors.secondaryText)
                                
                                TextField("Your email for replies", text: $email)
                                    .font(.system(size: 16))
                                    .keyboardType(.emailAddress)
                                    .autocapitalization(.none)
                                    .padding()
                                    .background(Theme.Colors.secondaryBackground)
                                    .cornerRadius(12)
                            }
                            
                            // Message field
                            VStack(alignment: .leading, spacing: 8) {
                                Label("Message", systemImage: "text.alignleft")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(Theme.Colors.secondaryText)
                                
                                TextEditor(text: $message)
                                    .font(.system(size: 16))
                                    .frame(minHeight: 150)
                                    .padding(8)
                                    .background(Theme.Colors.secondaryBackground)
                                    .cornerRadius(12)
                            }
                        }
                        .padding(.horizontal)
                        
                        // Submit button
                        Button(action: sendFeedback) {
                            HStack {
                                if isSending {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: "paperplane.fill")
                                    Text("Send \(selectedType.rawValue)")
                                }
                            }
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(isFormValid ? Theme.Colors.primary : Color.gray)
                            )
                        }
                        .disabled(!isFormValid || isSending)
                        .padding(.horizontal)
                        .padding(.bottom, 30)
                    }
                }
            }
            .navigationTitle("Help & Feedback")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(Theme.Colors.primary)
                }
            }
            .alert("Success!", isPresented: $showSuccess) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Your \(selectedType.rawValue.lowercased()) has been sent. We'll get back to you soon!")
            }
            .alert("Error", isPresented: .constant(!errorMessage.isEmpty)) {
                Button("OK") {
                    errorMessage = ""
                }
            } message: {
                Text(errorMessage)
            }
        }
        .onAppear {
            // Auto-fill email if user is logged in
            if let user = authManager.currentUser {
                email = user.email
            }
        }
    }
    
    private var isFormValid: Bool {
        !subject.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private func sendFeedback() {
        guard isFormValid else { return }
        
        isSending = true
        
        // Discord webhook URL
        let webhookURL = "https://discord.com/api/webhooks/1403155923354124390/yNsYchXTUpZBtJSplPr1CZCsI0CTlfRznc-zHgrBFmoelqOl1BFM0yjyMSHBFREP8zMi"
        
        // Prepare Discord embed
        let username = authManager.currentUser?.username ?? "Guest"
        let userId = authManager.currentUser?.apiId ?? "Unknown"
        let deviceInfo = "\(UIDevice.current.model) - iOS \(UIDevice.current.systemVersion)"
        
        let embedColor: Int = {
            switch selectedType {
            case .feedback: return 0x2ABF5A // Green
            case .bug: return 0xFF3B30 // Red
            case .feature: return 0x9B59B6 // Purple
            case .help: return 0x007AFF // Blue
            case .other: return 0x95A5A6 // Gray
            }
        }()
        
        let payload: [String: Any] = [
            "username": "Brrow Support Bot",
            "avatar_url": "https://brrowapp.com/assets/icon.png",
            "embeds": [[
                "title": "📬 New \(selectedType.rawValue)",
                "color": embedColor,
                "fields": [
                    [
                        "name": "Subject",
                        "value": subject,
                        "inline": false
                    ],
                    [
                        "name": "Message",
                        "value": String(message.prefix(1000)), // Discord limit
                        "inline": false
                    ],
                    [
                        "name": "User",
                        "value": username,
                        "inline": true
                    ],
                    [
                        "name": "User ID",
                        "value": userId,
                        "inline": true
                    ],
                    [
                        "name": "Email",
                        "value": email.isEmpty ? "Not provided" : email,
                        "inline": false
                    ],
                    [
                        "name": "Device",
                        "value": deviceInfo,
                        "inline": true
                    ],
                    [
                        "name": "App Version",
                        "value": getAppVersion(),
                        "inline": true
                    ]
                ],
                "timestamp": ISO8601DateFormatter().string(from: Date()),
                "footer": [
                    "text": "Brrow iOS App",
                    "icon_url": "https://brrowapp.com/assets/icon.png"
                ]
            ]]
        ]
        
        guard let url = URL(string: webhookURL),
              let jsonData = try? JSONSerialization.data(withJSONObject: payload) else {
            errorMessage = "Failed to prepare feedback"
            isSending = false
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        
        URLSession.shared.dataTask(with: request) { _, response, error in
            DispatchQueue.main.async {
                isSending = false
                
                if let httpResponse = response as? HTTPURLResponse,
                   httpResponse.statusCode == 204 {
                    // Discord returns 204 No Content on success
                    showSuccess = true
                } else if let error = error {
                    errorMessage = "Failed to send feedback: \(error.localizedDescription)"
                } else {
                    errorMessage = "Failed to send feedback. Please try again."
                }
            }
        }.resume()
    }
    
    private func getAppVersion() -> String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
        return "\(version) (\(build))"
    }
}

// MARK: - Feedback Type Button
struct FeedbackTypeButton: View {
    let type: FeedbackHelpView.FeedbackType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: type.icon)
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? .white : type.color)
                
                Text(type.rawValue)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(isSelected ? .white : Theme.Colors.text)
            }
            .frame(width: 90, height: 90)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? type.color : Theme.Colors.secondaryBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? type.color : Color.clear, lineWidth: 2)
            )
        }
    }
}

// MARK: - Quick Help Link
struct QuickHelpLink: View {
    let icon: String
    let title: String
    let subtitle: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(Theme.Colors.primary)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Theme.Colors.text)
                
                Text(subtitle)
                    .font(.system(size: 14))
                    .foregroundColor(Theme.Colors.secondaryText)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14))
                .foregroundColor(Theme.Colors.tertiaryText)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Theme.Colors.background)
        )
    }
}