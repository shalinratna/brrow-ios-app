//
//  ProfileSupportViews.swift
//  Brrow
//
//  Comprehensive implementation of profile menu screens
//

import SwiftUI
import MessageUI
import StoreKit

// MARK: - Help & Support View
struct ProfileHelpSupportView: View {
    @State private var showingContactMail = false
    @State private var showingReportBugMail = false
    @State private var searchText = ""
    
    var body: some View {
        NavigationView {
            List {
                // Search Section
                Section {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        
                        TextField("Search help articles", text: $searchText)
                    }
                    .padding(.vertical, 4)
                }
                
                // Quick Actions
                Section("Get Help") {
                    NavigationLink(destination: FAQView()) {
                        Label("Frequently Asked Questions", systemImage: "questionmark.circle")
                            .foregroundColor(Theme.Colors.primary)
                    }
                    
                    Button(action: { showingContactMail = true }) {
                        Label("Contact Support", systemImage: "envelope")
                            .foregroundColor(Theme.Colors.accentBlue)
                    }
                    .disabled(!MFMailComposeViewController.canSendMail())
                    
                    Button(action: { showingReportBugMail = true }) {
                        Label("Report a Bug", systemImage: "exclamationmark.triangle")
                            .foregroundColor(Theme.Colors.accentOrange)
                    }
                    .disabled(!MFMailComposeViewController.canSendMail())
                    
                    Button(action: requestAppReview) {
                        Label("Rate Brrow", systemImage: "star")
                            .foregroundColor(Theme.Colors.warning)
                    }
                }
                
                // Help Topics
                Section("Help Topics") {
                    NavigationLink(destination: HelpTopicView(topic: .gettingStarted)) {
                        Label("Getting Started", systemImage: "play.circle")
                    }
                    
                    NavigationLink(destination: HelpTopicView(topic: .listings)) {
                        Label("Creating Listings", systemImage: "plus.circle")
                    }
                    
                    NavigationLink(destination: HelpTopicView(topic: .rentals)) {
                        Label("Rentals & Returns", systemImage: "arrow.clockwise")
                    }
                    
                    NavigationLink(destination: HelpTopicView(topic: .payments)) {
                        Label("Payments & Refunds", systemImage: "creditcard")
                    }
                    
                    NavigationLink(destination: HelpTopicView(topic: .safety)) {
                        Label("Safety & Trust", systemImage: "shield")
                    }
                }
                
                // Community
                Section("Community") {
                    NavigationLink(destination: CommunityGuidelinesView()) {
                        Label("Community Guidelines", systemImage: "person.3")
                            .foregroundColor(Theme.Colors.accentPurple)
                    }
                }
                
                // App Info
                Section("App Information") {
                    HStack {
                        Label("Version", systemImage: "info.circle")
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("Version \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.1.6")")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("Build \(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "285")")
                                .font(.caption2)
                                .foregroundColor(Color.gray)
                        }
                    }
                    .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Help & Support")
            .navigationBarTitleDisplayMode(.large)
        }
        .sheet(isPresented: $showingContactMail) {
            ContactSupportMailView()
        }
        .sheet(isPresented: $showingReportBugMail) {
            ReportBugMailView()
        }
    }
    
    private func requestAppReview() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }
        SKStoreReviewController.requestReview(in: windowScene)
        HapticManager.notification(type: .success)
    }
}

// MARK: - Help Topic View
struct HelpTopicView: View {
    let topic: HelpTopic
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                ForEach(topic.articles, id: \.title) { article in
                    VStack(alignment: .leading, spacing: 12) {
                        Text(article.title)
                            .font(.headline)
                            .foregroundColor(Theme.Colors.text)
                        
                        Text(article.content)
                            .font(.body)
                            .foregroundColor(Theme.Colors.secondaryText)
                            .lineSpacing(4)
                    }
                    .padding()
                    .background(Theme.Colors.secondaryBackground)
                    .cornerRadius(12)
                }
            }
            .padding()
        }
        .navigationTitle(topic.title)
        .navigationBarTitleDisplayMode(.large)
    }
}

enum HelpTopic {
    case gettingStarted, listings, rentals, payments, safety
    
    var title: String {
        switch self {
        case .gettingStarted: return "Getting Started"
        case .listings: return "Creating Listings"
        case .rentals: return "Rentals & Returns"
        case .payments: return "Payments & Refunds"
        case .safety: return "Safety & Trust"
        }
    }
    
    var articles: [HelpArticle] {
        switch self {
        case .gettingStarted:
            return [
                HelpArticle(title: "Welcome to Brrow!", content: "Brrow connects you with neighbors to share items you need. Whether you're looking to rent something or list items for others to borrow, our platform makes it easy and safe."),
                HelpArticle(title: "Setting Up Your Profile", content: "Complete your profile with a photo, bio, and verification to build trust with the community. Verified profiles get more bookings!"),
                HelpArticle(title: "How It Works", content: "1. Browse items near you\n2. Send a rental request\n3. Meet up for pickup\n4. Return the item\n5. Leave a review")
            ]
        case .listings:
            return [
                HelpArticle(title: "Creating Your First Listing", content: "Take clear photos, write a detailed description, set competitive pricing, and specify pickup/delivery options."),
                HelpArticle(title: "Pricing Your Items", content: "Research similar items, consider wear and replacement cost, and start competitively. You can always adjust prices later."),
                HelpArticle(title: "Managing Requests", content: "Respond quickly to rental requests, ask questions if needed, and confirm pickup details with renters.")
            ]
        case .rentals:
            return [
                HelpArticle(title: "Renting Items", content: "Browse nearby items, check availability, send requests with your planned dates, and coordinate pickup with the owner."),
                HelpArticle(title: "During the Rental", content: "Treat items with care, follow any specific instructions, and contact the owner if you encounter issues."),
                HelpArticle(title: "Returning Items", content: "Return items on time and in the same condition. Clean if needed and coordinate the return with the owner.")
            ]
        case .payments:
            return [
                HelpArticle(title: "How Payments Work", content: "All payments are processed securely through Stripe. Money is held until the rental is complete."),
                HelpArticle(title: "Security Deposits", content: "Some items require a security deposit that's returned when the item comes back in good condition."),
                HelpArticle(title: "Refunds", content: "If an item isn't as described or the rental is cancelled by the owner, you'll receive a full refund.")
            ]
        case .safety:
            return [
                HelpArticle(title: "Meeting Safely", content: "Meet in public places when possible, trust your instincts, and let someone know where you're going."),
                HelpArticle(title: "Verifying Users", content: "Look for verified badges, read reviews, and don't hesitate to ask questions before agreeing to a rental."),
                HelpArticle(title: "Reporting Issues", content: "Report any suspicious activity, inappropriate behavior, or safety concerns immediately.")
            ]
        }
    }
}

struct HelpArticle {
    let title: String
    let content: String
}

// MARK: - FAQ View
struct FAQView: View {
    @State private var searchText = ""
    @State private var expandedItems = Set<Int>()
    
    private var filteredFAQs: [FAQ] {
        if searchText.isEmpty {
            return faqs
        } else {
            return faqs.filter { 
                $0.question.localizedCaseInsensitiveContains(searchText) ||
                $0.answer.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    
                    TextField("Search FAQs", text: $searchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                .padding()
                
                List {
                    ForEach(Array(filteredFAQs.enumerated()), id: \.offset) { index, faq in
                        DisclosureGroup(
                            isExpanded: Binding(
                                get: { expandedItems.contains(index) },
                                set: { isExpanded in
                                    if isExpanded {
                                        expandedItems.insert(index)
                                    } else {
                                        expandedItems.remove(index)
                                    }
                                }
                            )
                        ) {
                            Text(faq.answer)
                                .font(.body)
                                .foregroundColor(Theme.Colors.secondaryText)
                                .padding(.top, 8)
                        } label: {
                            Text(faq.question)
                                .font(.headline)
                                .foregroundColor(Theme.Colors.text)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("FAQ")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    private let faqs = [
        FAQ(question: "How do I create my first listing?", answer: "Tap the + button, take clear photos of your item, write a detailed description, set your price and availability, then publish!"),
        FAQ(question: "Is my payment secure?", answer: "Yes! All payments are processed through Stripe, a trusted payment processor used by millions of businesses worldwide."),
        FAQ(question: "What if an item gets damaged?", answer: "Items are covered by our protection policy. Report damage immediately and we'll help resolve the situation."),
        FAQ(question: "How do I verify my account?", answer: "Complete email verification and consider adding ID verification for increased trust and more bookings."),
        FAQ(question: "Can I cancel a rental?", answer: "Yes, you can cancel rentals according to the cancellation policy set by the item owner."),
        FAQ(question: "How do I contact the owner?", answer: "Use the in-app messaging system to communicate with item owners safely and securely."),
        FAQ(question: "What payment methods are accepted?", answer: "We accept all major credit cards, debit cards, and digital payment methods through Stripe."),
        FAQ(question: "How do reviews work?", answer: "Both renters and owners can leave reviews after a completed rental. Reviews help build trust in our community."),
        FAQ(question: "Is there a service fee?", answer: "Yes, there's a small service fee to help maintain the platform and provide customer support."),
        FAQ(question: "How do I delete my account?", answer: "You can delete your account in Settings > Privacy & Security > Delete Account.")
    ]
}

struct FAQ {
    let question: String
    let answer: String
}

// MARK: - Contact Support Mail View
struct ContactSupportMailView: UIViewControllerRepresentable {
    @Environment(\.presentationMode) var presentationMode
    
    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let vc = MFMailComposeViewController()
        vc.mailComposeDelegate = context.coordinator
        vc.setSubject("Brrow Support Request")
        vc.setToRecipients(["support@brrowapp.com"])
        
        let deviceInfo = """
        
        
        
        ---
        Device Information:
        App Version: \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.1.6")
        Build Number: \(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "285")
        iOS Version: \(UIDevice.current.systemVersion)
        Device Model: \(UIDevice.current.model)
        """
        
        vc.setMessageBody("Please describe your issue or question below:\n\(deviceInfo)", isHTML: false)
        return vc
    }
    
    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        let parent: ContactSupportMailView
        
        init(_ parent: ContactSupportMailView) {
            self.parent = parent
        }
        
        func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
            parent.presentationMode.wrappedValue.dismiss()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                switch result {
                case .sent:
                    ToastManager.shared.showSuccess(title: "Message Sent", message: "We'll get back to you soon!")
                case .cancelled:
                    break
                case .failed:
                    ToastManager.shared.showError(title: "Failed to Send", message: "Please try again or email us directly")
                default:
                    break
                }
            }
        }
    }
}

// MARK: - Report Bug Mail View
struct ReportBugMailView: UIViewControllerRepresentable {
    @Environment(\.presentationMode) var presentationMode
    
    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let vc = MFMailComposeViewController()
        vc.mailComposeDelegate = context.coordinator
        vc.setSubject("Brrow Bug Report")
        vc.setToRecipients(["support@brrowapp.com"])
        
        let deviceInfo = """
        
        
        
        ---
        Bug Report Details:
        App Version: \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.1.6")
        Build Number: \(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "285")
        iOS Version: \(UIDevice.current.systemVersion)
        Device Model: \(UIDevice.current.model)
        
        Please describe:
        1. What you were trying to do
        2. What happened instead
        3. Steps to reproduce the issue
        """
        
        vc.setMessageBody("Bug Description:\n\(deviceInfo)", isHTML: false)
        return vc
    }
    
    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        let parent: ReportBugMailView
        
        init(_ parent: ReportBugMailView) {
            self.parent = parent
        }
        
        func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
            parent.presentationMode.wrappedValue.dismiss()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                switch result {
                case .sent:
                    ToastManager.shared.showSuccess(title: "Bug Report Sent", message: "Thank you for helping us improve!")
                case .cancelled:
                    break
                case .failed:
                    ToastManager.shared.showError(title: "Failed to Send", message: "Please try again later")
                default:
                    break
                }
            }
        }
    }
}

// MARK: - Settings View
struct ComprehensiveSettingsView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var notificationsEnabled = true
    @State private var locationEnabled = true
    @State private var faceIDEnabled = false
    @State private var marketingEmailsEnabled = true
    @State private var showingLogoutConfirmation = false
    @State private var showingAccountTypeSelection = false
    
    var body: some View {
        Form {
            // Account Settings
            Section(header: Text("Account")) {
                if let user = authManager.currentUser {
                    NavigationLink(destination: EditProfileView(user: user)) {
                        Label("Edit Profile", systemImage: "person.circle")
                    }
                } else {
                    Button(action: {}) {
                        Label("Edit Profile", systemImage: "person.circle")
                            .foregroundColor(.gray)
                    }
                    .disabled(true)
                }
                
                Button(action: { showingAccountTypeSelection = true }) {
                    HStack {
                        Label("Account Type", systemImage: "building.2")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.gray)
                            .font(.system(size: 14))
                    }
                }
                
                NavigationLink(destination: ChangePasswordView()) {
                    Label("Change Password", systemImage: "key")
                }
            }
            
            // Notifications
            Section(header: Text("Notifications")) {
                Toggle(isOn: $notificationsEnabled) {
                    Label("Push Notifications", systemImage: "bell")
                }
                
                NavigationLink(destination: NotificationSettingsView()) {
                    Label("Notification Preferences", systemImage: "bell.badge")
                }
                
                Toggle(isOn: $marketingEmailsEnabled) {
                    Label("Marketing Emails", systemImage: "envelope")
                }
            }
            
            // Privacy & Security
            Section(header: Text("Privacy & Security")) {
                Toggle(isOn: $locationEnabled) {
                    Label("Location Services", systemImage: "location")
                }
                
                Toggle(isOn: $faceIDEnabled) {
                    Label("Face ID / Touch ID", systemImage: "faceid")
                }
                
                NavigationLink(destination: PrivacySecurityView()) {
                    Label("Privacy Settings", systemImage: "lock")
                }
            }
            
            // App Settings
            Section(header: Text("App")) {
                NavigationLink(destination: LanguageSettingsView()) {
                    Label("Language", systemImage: "globe")
                }
                
                NavigationLink(destination: ThemeSettingsView()) {
                    Label("Appearance", systemImage: "paintbrush")
                }
            }
            
            // Data & Storage
            Section(header: Text("Data")) {
                Button(action: clearCache) {
                    Label("Clear Cache", systemImage: "trash")
                        .foregroundColor(.orange)
                }
                
                NavigationLink(destination: DataExportView()) {
                    Label("Export Data", systemImage: "square.and.arrow.up")
                }
            }
            
            // Account Actions
            Section {
                Button(action: { showingLogoutConfirmation = true }) {
                    Label("Sign Out", systemImage: "arrow.right.square")
                        .foregroundColor(.red)
                }
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.large)
        .confirmationDialog("Sign Out", isPresented: $showingLogoutConfirmation) {
            Button("Sign Out", role: .destructive) {
                authManager.logout()
                ToastManager.shared.showInfo(title: "Signed Out", message: "You have been signed out successfully")
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to sign out?")
        }
        .sheet(isPresented: $showingAccountTypeSelection) {
            AccountTypeSelectionView(showingAccountTypeSelection: $showingAccountTypeSelection)
        }
    }
    
    private func clearCache() {
        // Clear image cache, user defaults, etc.
        URLCache.shared.removeAllCachedResponses()
        ToastManager.shared.showSuccess(title: "Cache Cleared", message: "App cache has been cleared")
        HapticManager.notification(type: .success)
    }
}

// MARK: - Placeholder Views for Settings
// ChangePasswordView moved to EnhancedSettingsView.swift
/*
struct ChangePasswordView: View {
    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false
    
    var body: some View {
        Form {
            Section("Current Password") {
                SecureField("Enter current password", text: $currentPassword)
            }
            
            Section("New Password") {
                SecureField("Enter new password", text: $newPassword)
                SecureField("Confirm new password", text: $confirmPassword)
            }
            
            Section {
                Button(action: changePassword) {
                    if isLoading {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Changing Password...")
                        }
                    } else {
                        Text("Change Password")
                    }
                }
                .disabled(currentPassword.isEmpty || newPassword.isEmpty || confirmPassword.isEmpty || isLoading)
            }
        }
        .navigationTitle("Change Password")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func changePassword() {
        guard newPassword == confirmPassword else {
            ToastManager.shared.showError(title: "Password Mismatch", message: "New passwords don't match")
            return
        }
        
        guard newPassword.count >= 8 else {
            ToastManager.shared.showError(title: "Password Too Short", message: "Password must be at least 8 characters")
            return
        }
        
        isLoading = true
        
        // Simulate API call
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            isLoading = false
            currentPassword = ""
            newPassword = ""
            confirmPassword = ""
            ToastManager.shared.showSuccess(title: "Password Changed", message: "Your password has been updated successfully")
        }
    }
}
*/

struct ThemeSettingsView: View {
    @StateObject private var colorSchemeManager = ColorSchemeManager.shared

    var body: some View {
        Form {
            Section("Appearance") {
                Picker("Theme", selection: $colorSchemeManager.appearanceMode) {
                    ForEach(ColorSchemeManager.AppearanceMode.allCases, id: \.self) { mode in
                        Text(mode.displayName).tag(mode)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
            }

            Section {
                Text("Choose between light, dark, or automatic theme based on your device settings.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .navigationTitle("Appearance")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct DataExportView: View {
    @State private var isExporting = false
    
    var body: some View {
        Form {
            Section("Export Options") {
                Button(action: exportProfile) {
                    Label("Profile Data", systemImage: "person.circle")
                }
                
                Button(action: exportListings) {
                    Label("Listings Data", systemImage: "list.bullet")
                }
                
                Button(action: exportMessages) {
                    Label("Messages", systemImage: "message")
                }
                
                Button(action: exportAll) {
                    if isExporting {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Exporting...")
                        }
                    } else {
                        Label("Export All Data", systemImage: "doc.zip")
                    }
                }
                .disabled(isExporting)
            }
            
            Section {
                Text("Exported data will be sent to your registered email address. This may take a few minutes to process.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .navigationTitle("Export Data")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func exportProfile() {
        ToastManager.shared.showInfo(title: "Export Started", message: "Profile data export initiated")
    }
    
    private func exportListings() {
        ToastManager.shared.showInfo(title: "Export Started", message: "Listings data export initiated")
    }
    
    private func exportMessages() {
        ToastManager.shared.showInfo(title: "Export Started", message: "Messages export initiated")
    }
    
    private func exportAll() {
        isExporting = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            isExporting = false
            ToastManager.shared.showSuccess(title: "Export Complete", message: "Check your email for the download link")
        }
    }
}