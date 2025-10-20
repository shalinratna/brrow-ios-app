//
//  LinkedAccountsView.swift
//  Brrow
//
//  Linked accounts management for OAuth providers
//

import SwiftUI

struct LinkedAccountsView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var viewModel = LinkedAccountsViewModel()
    @EnvironmentObject var authManager: AuthManager
    @State private var showingUnlinkConfirmation = false
    @State private var providerToUnlink: OAuthProvider?
    @State private var showingLastMethodWarning = false

    var body: some View {
        NavigationView {
            ZStack {
                Theme.Colors.groupedBackground
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: Theme.Spacing.lg) {
                        // Header Card
                        headerSection

                        // Loading indicator
                        if viewModel.isLoading {
                            ProgressView()
                                .scaleEffect(1.5)
                                .padding(Theme.Spacing.xl)
                        }

                        // Error message
                        if let error = viewModel.errorMessage {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.red)
                                Text(error)
                                    .font(Theme.Typography.footnote)
                                    .foregroundColor(.red)
                            }
                            .padding(Theme.Spacing.md)
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(Theme.CornerRadius.sm)
                        }

                        // Linked Accounts Section
                        if !viewModel.isLoading {
                            accountsSection
                        }

                        // Info Section
                        infoSection
                    }
                    .padding(.horizontal, Theme.Spacing.md)
                    .padding(.vertical, Theme.Spacing.lg)
                }
            }
            .navigationTitle("Linked Accounts")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .onAppear {
                Task {
                    await viewModel.fetchLinkedAccounts()
                }
            }
            .alert("Cannot Unlink", isPresented: $showingLastMethodWarning) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("You cannot unlink your last sign-in method. Please link another account first or ensure you have an email/password login.")
            }
            .alert("Unlink Account", isPresented: $showingUnlinkConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Unlink", role: .destructive) {
                    Task {
                        if let provider = providerToUnlink {
                            await viewModel.unlinkAccount(provider: provider)
                        }
                    }
                }
            } message: {
                if let provider = providerToUnlink {
                    Text("Are you sure you want to unlink your \(provider.displayName) account? You can re-link it at any time.")
                } else {
                    Text("Are you sure you want to unlink this account?")
                }
            }
        }
    }

    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: Theme.Spacing.sm) {
            Image(systemName: "link.circle.fill")
                .font(.system(size: 48))
                .foregroundColor(Theme.Colors.primary)

            Text("One-Tap Sign In")
                .font(Theme.Typography.headline)
                .foregroundColor(Theme.Colors.text)

            Text("Link your accounts for quick and secure access")
                .font(Theme.Typography.footnote)
                .foregroundColor(Theme.Colors.secondaryText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(Theme.Spacing.lg)
        .background(Theme.Colors.surface)
        .cornerRadius(Theme.CornerRadius.card)
        .shadow(color: Theme.Shadows.card, radius: Theme.Shadows.cardRadius, x: 0, y: 2)
    }

    // MARK: - Accounts Section
    private var accountsSection: some View {
        VStack(spacing: Theme.Spacing.sm) {
            // Google Account
            if let googleAccount = viewModel.linkedAccounts.first(where: { $0.provider == "google" }) {
                linkedAccountCard(
                    provider: .google,
                    email: googleAccount.email,
                    linkedDate: googleAccount.createdAt
                )
            } else {
                unlinkableAccountCard(provider: .google)
            }

            // Apple Account
            if let appleAccount = viewModel.linkedAccounts.first(where: { $0.provider == "apple" }) {
                linkedAccountCard(
                    provider: .apple,
                    email: appleAccount.email,
                    linkedDate: appleAccount.createdAt
                )
            } else {
                unlinkableAccountCard(provider: .apple)
            }

            // Stripe Connect Section
            stripeConnectSection
        }
    }

    // MARK: - Linked Account Card
    private func linkedAccountCard(provider: OAuthProvider, email: String?, linkedDate: String) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            HStack(spacing: Theme.Spacing.md) {
                // Provider Icon
                ZStack {
                    Circle()
                        .fill(provider.color.opacity(0.1))
                        .frame(width: 50, height: 50)

                    Image(systemName: provider.icon)
                        .font(.system(size: 24))
                        .foregroundColor(provider.color)
                }

                // Account Info
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(provider.displayName)
                            .font(Theme.Typography.body)
                            .fontWeight(.semibold)
                            .foregroundColor(Theme.Colors.text)

                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.green)
                    }

                    if let email = email, !email.isEmpty {
                        Text(email)
                            .font(Theme.Typography.caption)
                            .foregroundColor(Theme.Colors.secondaryText)
                    } else {
                        Text("Linked")
                            .font(Theme.Typography.caption)
                            .foregroundColor(Theme.Colors.secondaryText)
                    }
                }

                Spacer()
            }

            // Unlink Button
            Button(action: {
                // Check if this is the last sign-in method
                // Count: linked accounts + password (if set)
                let totalSignInMethods = viewModel.linkedAccounts.count + (authManager.currentUser?.hasPassword == true ? 1 : 0)

                if totalSignInMethods <= 1 {
                    showingLastMethodWarning = true
                } else {
                    providerToUnlink = provider
                    showingUnlinkConfirmation = true
                }
            }) {
                HStack {
                    Image(systemName: "link.badge.minus")
                    Text("Unlink Account")
                }
                .font(Theme.Typography.callout)
                .foregroundColor(.red)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Theme.Spacing.sm)
                .background(Color.red.opacity(0.1))
                .cornerRadius(Theme.CornerRadius.sm)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(Theme.Spacing.md)
        .background(Theme.Colors.surface)
        .cornerRadius(Theme.CornerRadius.card)
        .shadow(color: Theme.Shadows.card, radius: Theme.Shadows.cardRadius, x: 0, y: 2)
    }

    // MARK: - Unlinkable Account Card
    private func unlinkableAccountCard(provider: OAuthProvider) -> some View {
        Button(action: {
            Task {
                await viewModel.linkAccount(provider: provider)
            }
        }) {
            HStack(spacing: Theme.Spacing.md) {
                // Provider Icon
                ZStack {
                    Circle()
                        .fill(provider.color.opacity(0.1))
                        .frame(width: 50, height: 50)

                    Image(systemName: provider.icon)
                        .font(.system(size: 24))
                        .foregroundColor(provider.color)
                }

                // Account Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(provider.displayName)
                        .font(Theme.Typography.body)
                        .fontWeight(.semibold)
                        .foregroundColor(Theme.Colors.text)

                    Text("Not linked")
                        .font(Theme.Typography.caption)
                        .foregroundColor(Theme.Colors.secondaryText)
                }

                Spacer()

                // Link Button
                HStack {
                    Text("Link")
                        .font(Theme.Typography.callout)
                        .fontWeight(.medium)
                    Image(systemName: "chevron.right")
                        .font(.caption)
                }
                .foregroundColor(Theme.Colors.primary)
            }
            .padding(Theme.Spacing.md)
            .background(Theme.Colors.surface)
            .cornerRadius(Theme.CornerRadius.card)
            .shadow(color: Theme.Shadows.card, radius: Theme.Shadows.cardRadius, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - Info Section
    private var infoSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            HStack {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(.blue)
                Text("How it works")
                    .font(Theme.Typography.callout)
                    .fontWeight(.semibold)
                    .foregroundColor(Theme.Colors.text)
            }

            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                infoRow(icon: "lock.shield.fill", text: "Your account security is maintained")
                infoRow(icon: "hand.raised.fill", text: "You control which accounts are linked")
                infoRow(icon: "arrow.triangle.2.circlepath", text: "Switch between accounts seamlessly")
                infoRow(icon: "checkmark.seal.fill", text: "One tap to sign in from any device")
            }
        }
        .padding(Theme.Spacing.md)
        .background(Color.blue.opacity(0.05))
        .cornerRadius(Theme.CornerRadius.card)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.card)
                .stroke(Color.blue.opacity(0.2), lineWidth: 1)
        )
    }

    private func infoRow(icon: String, text: String) -> some View {
        HStack(spacing: Theme.Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(.blue)
                .frame(width: 20)

            Text(text)
                .font(Theme.Typography.footnote)
                .foregroundColor(Theme.Colors.secondaryText)
        }
    }

    // MARK: - Stripe Connect Section
    private var stripeConnectSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            HStack(spacing: Theme.Spacing.md) {
                // Stripe Icon
                ZStack {
                    Circle()
                        .fill(Color.purple.opacity(0.1))
                        .frame(width: 50, height: 50)

                    Image(systemName: "creditcard.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.purple)
                }

                // Stripe Info
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Stripe Connect")
                            .font(Theme.Typography.body)
                            .fontWeight(.semibold)
                            .foregroundColor(Theme.Colors.text)

                        if let stripe = viewModel.stripeStatus, stripe.connected {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.green)
                        }
                    }

                    if let stripe = viewModel.stripeStatus, stripe.connected {
                        if let bankLast4 = stripe.bankLast4 {
                            Text("Bank account ending in \(bankLast4)")
                                .font(Theme.Typography.caption)
                                .foregroundColor(Theme.Colors.secondaryText)
                        } else if stripe.detailsSubmitted {
                            Text("Account verified")
                                .font(Theme.Typography.caption)
                                .foregroundColor(Theme.Colors.secondaryText)
                        } else {
                            Text("Setup incomplete")
                                .font(Theme.Typography.caption)
                                .foregroundColor(.orange)
                        }
                    } else {
                        Text("Connect to receive payments")
                            .font(Theme.Typography.caption)
                            .foregroundColor(Theme.Colors.secondaryText)
                    }
                }

                Spacer()
            }

            // Action Button
            if let stripe = viewModel.stripeStatus, stripe.connected {
                if !stripe.detailsSubmitted {
                    Button(action: {
                        // Open Stripe onboarding
                        Task {
                            await viewModel.openStripeOnboarding()
                        }
                    }) {
                        HStack {
                            Image(systemName: "arrow.right.circle")
                            Text("Complete Setup")
                        }
                        .font(Theme.Typography.callout)
                        .foregroundColor(.orange)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Theme.Spacing.sm)
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(Theme.CornerRadius.sm)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            } else {
                Button(action: {
                    // Open Stripe onboarding
                    Task {
                        await viewModel.openStripeOnboarding()
                    }
                }) {
                    HStack {
                        Image(systemName: "plus.circle")
                        Text("Connect Stripe Account")
                    }
                    .font(Theme.Typography.callout)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Theme.Spacing.sm)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.purple, Color.purple.opacity(0.8)]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(Theme.CornerRadius.sm)
                }
                .buttonStyle(PlainButtonStyle())
            }

            // Explanation
            Text("Link your bank account to receive payments when you sell items on Brrow")
                .font(Theme.Typography.caption)
                .foregroundColor(Theme.Colors.secondaryText)
                .multilineTextAlignment(.leading)
        }
        .padding(Theme.Spacing.md)
        .background(Theme.Colors.surface)
        .cornerRadius(Theme.CornerRadius.card)
        .shadow(color: Theme.Shadows.card, radius: Theme.Shadows.cardRadius, x: 0, y: 2)
    }
}

// MARK: - OAuth Provider Enum
enum OAuthProvider: String {
    case google
    case apple

    var displayName: String {
        switch self {
        case .google: return "Google"
        case .apple: return "Apple"
        }
    }

    var icon: String {
        switch self {
        case .google: return "g.circle.fill"
        case .apple: return "applelogo"
        }
    }

    var color: Color {
        switch self {
        case .google: return .red
        case .apple: return .primary
        }
    }
}

// MARK: - Linked Account Model
struct LinkedAccount: Codable, Identifiable {
    let id: String
    let provider: String
    let email: String?
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case provider
        case email
        case createdAt = "created_at"
    }
}

// MARK: - ViewModel
@MainActor
class LinkedAccountsViewModel: ObservableObject {
    @Published var linkedAccounts: [LinkedAccount] = []
    @Published var stripeStatus: StripeConnectStatus?
    @Published var isLoading = false
    @Published var errorMessage: String?

    func fetchLinkedAccounts() async {
        isLoading = true
        errorMessage = nil

        do {
            let accounts = try await AccountLinkingService.shared.fetchLinkedAccounts()
            self.linkedAccounts = accounts
            self.stripeStatus = AccountLinkingService.shared.stripeStatus
            isLoading = false
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }

    func linkAccount(provider: OAuthProvider) async {
        isLoading = true
        errorMessage = nil

        do {
            try await AccountLinkingService.shared.linkAccount(provider: provider)
            await fetchLinkedAccounts()
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }

    func unlinkAccount(provider: OAuthProvider) async {
        isLoading = true
        errorMessage = nil

        do {
            try await AccountLinkingService.shared.unlinkAccount(provider: provider)
            await fetchLinkedAccounts()
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }

    func openStripeOnboarding() async {
        do {
            // Call backend to get Stripe onboarding URL
            guard let token = AuthManager.shared.authToken else {
                errorMessage = "Authentication required"
                return
            }

            let baseURL = await APIClient.shared.getBaseURL()
            guard let url = URL(string: "\(baseURL)/api/stripe/connect/onboard") else {
                errorMessage = "Invalid URL"
                return
            }

            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                errorMessage = "Failed to create Stripe onboarding link"
                return
            }

            struct OnboardingResponse: Codable {
                let success: Bool
                let onboardingUrl: String
            }

            let onboardingResponse = try JSONDecoder().decode(OnboardingResponse.self, from: data)

            // Open URL in Safari
            if let stripeURL = URL(string: onboardingResponse.onboardingUrl) {
                await UIApplication.shared.open(stripeURL)
            }
        } catch {
            errorMessage = "Failed to open Stripe onboarding: \(error.localizedDescription)"
        }
    }
}

#Preview {
    NavigationView {
        LinkedAccountsView()
    }
}
