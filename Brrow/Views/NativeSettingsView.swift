//
//  NativeSettingsView.swift
//  Brrow
//
//  Beautiful Native iOS Settings with Creative Menus
//

import SwiftUI
import MessageUI
import StoreKit

struct NativeSettingsView: View {
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var colorSchemeManager = ColorSchemeManager.shared
    @State private var showingLogoutAlert = false
    @State private var showingDeleteAccountAlert = false
    @State private var notificationsEnabled = true
    @State private var locationEnabled = true
    @State private var showingMailComposer = false
    @State private var mailResult: Result<MFMailComposeResult, Error>? = nil
    
    var body: some View {
        List {
                // Profile Section
                profileSection
                
                // Appearance Section
                appearanceSection
                
                // Notifications Section
                notificationsSection
                
                // Privacy & Security
                privacySection
                
                // Payment Methods
                paymentSection
                
                // Help & Support
                supportSection
                
                // About
                aboutSection
                
                // Danger Zone
                dangerSection
        }
        .listStyle(InsetGroupedListStyle())
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.large)
        .alert("Sign Out", isPresented: $showingLogoutAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Sign Out", role: .destructive) {
                authManager.logout()
            }
        } message: {
            Text("Are you sure you want to sign out?")
        }
        .sheet(isPresented: $showingMailComposer) {
            MailComposerView(result: $mailResult)
        }
    }
    
    // MARK: - Profile Section
    private var profileSection: some View {
        Section {
            if let user = authManager.currentUser {
                NavigationLink(destination: EditProfileView(user: user)) {
                    HStack(spacing: 16) {
                        // Profile Picture
                        BrrowAsyncImage(url: user.profilePicture ?? "") { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Image(systemName: "person.crop.circle.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.gray)
                        }
                        .frame(width: 60, height: 60)
                        .clipShape(Circle())
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(user.username)
                                .font(.headline)
                            Text(user.email)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            if user.verified ?? false {
                                Label("Verified", systemImage: "checkmark.seal.fill")
                                    .font(.caption2)
                                    .foregroundColor(Theme.Colors.primary)
                            }
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color(.tertiaryLabel))
                    }
                    .padding(.vertical, 8)
                }
            }
        }
    }
    
    // MARK: - Appearance Section
    private var appearanceSection: some View {
        Section("Appearance") {
            HStack {
                Label("Theme", systemImage: "paintbrush.fill")
                    .foregroundColor(Theme.Colors.accentBlue)
                
                Spacer()
                
                Picker("", selection: $colorSchemeManager.appearanceMode) {
                    ForEach(ColorSchemeManager.AppearanceMode.allCases, id: \.self) { mode in
                        Text(mode.displayName).tag(mode)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .labelsHidden()
            }
            
            NavigationLink(destination: ThemeCustomizationView()) {
                Label("Customize Colors", systemImage: "paintpalette.fill")
                    .foregroundColor(Theme.Colors.accentPurple)
            }
        }
    }
    
    // MARK: - Notifications Section
    private var notificationsSection: some View {
        Section("Notifications") {
            Toggle(isOn: $notificationsEnabled) {
                Label("Push Notifications", systemImage: "bell.fill")
                    .foregroundColor(Theme.Colors.accent)
            }
            
            NavigationLink(destination: ModernNotificationSettingsView()) {
                Label("Notification Preferences", systemImage: "bell.badge.fill")
                    .foregroundColor(Theme.Colors.accentOrange)
            }
        }
    }
    
    // MARK: - Privacy Section
    private var privacySection: some View {
        Section("Privacy & Security") {
            Toggle(isOn: $locationEnabled) {
                Label("Location Services", systemImage: "location.fill")
                    .foregroundColor(Theme.Colors.info)
            }
            
            NavigationLink(destination: PrivacySettingsView()) {
                Label("Privacy Settings", systemImage: "lock.fill")
                    .foregroundColor(Theme.Colors.primary)
            }
            
            NavigationLink(destination: BlockedUsersView()) {
                Label("Blocked Users", systemImage: "person.crop.circle.badge.xmark")
                    .foregroundColor(Theme.Colors.error)
            }
        }
    }
    
    // MARK: - Payment Section
    private var paymentSection: some View {
        Section("Payment") {
            NavigationLink(destination: PaymentMethodsView()) {
                Label("Payment Methods", systemImage: "creditcard.fill")
                    .foregroundColor(Theme.Colors.success)
            }
            
            NavigationLink(destination: EarningsView()) {
                Label("Earnings & Payouts", systemImage: "dollarsign.circle.fill")
                    .foregroundColor(Theme.Colors.primary)
            }
            
            if let user = authManager.currentUser, !(user.stripeLinked ?? false) {
                NavigationLink(destination: StripeSetupView()) {
                    HStack {
                        Label("Connect Stripe Account", systemImage: "link.circle.fill")
                            .foregroundColor(Theme.Colors.accentBlue)
                        Spacer()
                        Text("Required for payouts")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }
    
    // MARK: - Support Section
    private var supportSection: some View {
        Section("Help & Support") {
            NavigationLink(destination: FAQView()) {
                Label("FAQ", systemImage: "questionmark.circle.fill")
                    .foregroundColor(Theme.Colors.info)
            }
            
            Button(action: { showingMailComposer = true }) {
                Label("Contact Support", systemImage: "envelope.fill")
                    .foregroundColor(Theme.Colors.accentBlue)
            }
            .disabled(!MFMailComposeViewController.canSendMail())
            
            Button(action: { requestAppReview() }) {
                Label("Rate Brrow", systemImage: "star.fill")
                    .foregroundColor(Theme.Colors.warning)
            }
            
            NavigationLink(destination: CommunityGuidelinesView()) {
                Label("Community Guidelines", systemImage: "person.3.fill")
                    .foregroundColor(Theme.Colors.accentPurple)
            }
        }
    }
    
    // MARK: - About Section
    private var aboutSection: some View {
        Section("About") {
            NavigationLink(destination: AboutView()) {
                HStack {
                    Label("About Brrow", systemImage: "info.circle.fill")
                        .foregroundColor(Theme.Colors.primary)
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
            }
            
            Link(destination: URL(string: "https://brrowapp.com/privacy")!) {
                Label("Privacy Policy", systemImage: "hand.raised.fill")
                    .foregroundColor(Theme.Colors.info)
            }
            
            Link(destination: URL(string: "https://brrowapp.com/terms")!) {
                Label("Terms of Service", systemImage: "doc.text.fill")
                    .foregroundColor(Theme.Colors.secondary)
            }
            
            NavigationLink(destination: NativeLicensesView()) {
                Label("Open Source Licenses", systemImage: "doc.badge.gearshape.fill")
                    .foregroundColor(Theme.Colors.accentOrange)
            }
        }
    }
    
    // MARK: - Danger Section
    private var dangerSection: some View {
        Section {
            Button(action: { showingLogoutAlert = true }) {
                Label("Sign Out", systemImage: "arrow.right.square.fill")
                    .foregroundColor(Theme.Colors.error)
            }
            
            Button(action: { showingDeleteAccountAlert = true }) {
                Label("Delete Account", systemImage: "trash.fill")
                    .foregroundColor(.red)
            }
        }
    }
    
    private func requestAppReview() {
        if let windowScene = UIApplication.shared.windows.first?.windowScene {
            SKStoreReviewController.requestReview(in: windowScene)
        }
    }
}

// MARK: - Mail Composer
struct MailComposerView: UIViewControllerRepresentable {
    @Binding var result: Result<MFMailComposeResult, Error>?
    @Environment(\.presentationMode) var presentationMode
    
    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let vc = MFMailComposeViewController()
        vc.mailComposeDelegate = context.coordinator
        vc.setSubject("Brrow Support Request")
        vc.setToRecipients(["support@brrowapp.com"])
        
        // Add device info
        let deviceInfo = """
        \n\n\n
        ---
        Device Info:
        App Version: 1.0.0
        iOS Version: \(UIDevice.current.systemVersion)
        Device: \(UIDevice.current.model)
        """
        
        vc.setMessageBody(deviceInfo, isHTML: false)
        return vc
    }
    
    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        let parent: MailComposerView
        
        init(_ parent: MailComposerView) {
            self.parent = parent
        }
        
        func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
            if let error = error {
                parent.result = .failure(error)
            } else {
                parent.result = .success(result)
            }
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

// MARK: - Theme Customization View
struct ThemeCustomizationView: View {
    @State private var primaryColor = Color(hexString: "#2ABF5A")
    @State private var accentColor = Color(hexString: "#FF6B6B")
    
    var body: some View {
        Form {
            Section("Primary Color") {
                ColorPicker("Choose primary color", selection: $primaryColor)
                    .padding(.vertical, 8)
            }
            
            Section("Accent Colors") {
                ColorPicker("Accent color", selection: $accentColor)
                    .padding(.vertical, 8)
            }
            
            Section {
                Button("Reset to Defaults") {
                    primaryColor = Color(hexString: "#2ABF5A")
                    accentColor = Color(hexString: "#FF6B6B")
                }
                .foregroundColor(Theme.Colors.primary)
            }
        }
        .navigationTitle("Customize Theme")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NativeSettingsView()
        .environmentObject(AuthManager.shared)
}

// MARK: - Placeholder Views
// These are stub views that need to be implemented
// NotificationSettingsView and PrivacySettingsView are now defined in EditProfileView.swift

struct BlockedUsersView: View {
    var body: some View {
        Text("Blocked Users")
            .navigationTitle("Blocked Users")
    }
}

struct PaymentMethodsSettingsView: View {
    var body: some View {
        Text("Payment Methods")
            .navigationTitle("Payment Methods")
    }
}

struct StripeSetupView: View {
    var body: some View {
        Text("Connect Stripe Account")
            .navigationTitle("Stripe Setup")
    }
}

struct FAQSettingsView: View {
    var body: some View {
        Text("Frequently Asked Questions")
            .navigationTitle("FAQ")
    }
}

struct CommunityGuidelinesView: View {
    var body: some View {
        Text("Community Guidelines")
            .navigationTitle("Guidelines")
    }
}

// AboutView moved to EnhancedSettingsView.swift
/*
struct AboutView: View {
    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.1.6"
    }

    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "285"
    }

    var body: some View {
        Form {
            Section {
                VStack(alignment: .center, spacing: 16) {
                    // App Icon
                    Image("app-icon")
                        .resizable()
                        .frame(width: 80, height: 80)
                        .cornerRadius(16)
                        .shadow(radius: 4)

                    VStack(spacing: 8) {
                        Text("Brrow")
                            .font(.largeTitle)
                            .fontWeight(.bold)

                        Text("Borrow, don't buy")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        Text("Version \(appVersion) (\(buildNumber))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.top, 4)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            }

            Section("About") {
                Text("Brrow is a peer-to-peer rental marketplace that connects neighbors to share items they need. Our mission is to promote sustainability and build stronger communities by making it easy to borrow instead of buy.")
                    .font(.body)
                    .padding(.vertical, 8)
            }

            Section("Team") {
                HStack {
                    Text("© 2025 Brrow App")
                    Spacer()
                    Text("Made with ❤️")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
        }
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }
}
*/

extension Image {
    func onErrorAction(perform action: @escaping () -> Image) -> some View {
        self
    }
}

struct NativeLicensesView: View {
    var body: some View {
        Text("Open Source Licenses")
            .navigationTitle("Licenses")
    }
}