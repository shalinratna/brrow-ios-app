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
    @StateObject private var authManager = AuthManager.shared
    @State private var showingUnlinkConfirmation = false
    @State private var providerToUnlink: OAuthProvider?
    @State private var showingPasswordPrompt = false
    @State private var password = ""

    var body: some View {
        List {
            Section {
                Text("Link your Google or Apple account to sign in with one tap")
                    .font(.footnote)
                    .foregroundColor(Theme.Colors.secondaryText)
            }

            Section("Linked Accounts") {
                // Google Account
                if let googleAccount = viewModel.linkedAccounts.first(where: { $0.provider == "google" }) {
                    linkedAccountRow(
                        provider: .google,
                        email: googleAccount.email,
                        isLinked: true
                    )
                } else {
                    unlinkableAccountRow(provider: .google)
                }

                // Apple Account
                if let appleAccount = viewModel.linkedAccounts.first(where: { $0.provider == "apple" }) {
                    linkedAccountRow(
                        provider: .apple,
                        email: appleAccount.email,
                        isLinked: true
                    )
                } else {
                    unlinkableAccountRow(provider: .apple)
                }
            }

            if viewModel.isLoading {
                Section {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                }
            }

            if let error = viewModel.errorMessage {
                Section {
                    Text(error)
                        .font(.footnote)
                        .foregroundColor(.red)
                }
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
            Text("You'll still be able to sign in with your email and password. Are you sure you want to unlink this account?")
        }
    }

    private func linkedAccountRow(provider: OAuthProvider, email: String?, isLinked: Bool) -> some View {
        HStack {
            Image(systemName: provider.icon)
                .foregroundColor(provider.color)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 4) {
                Text(provider.displayName)
                    .foregroundColor(Theme.Colors.text)

                if let email = email {
                    Text(email)
                        .font(.caption)
                        .foregroundColor(Theme.Colors.secondaryText)
                }
            }

            Spacer()

            if isLinked {
                Button(action: {
                    providerToUnlink = provider
                    showingUnlinkConfirmation = true
                }) {
                    Text("Unlink")
                        .font(.subheadline)
                        .foregroundColor(.red)
                }
                .buttonStyle(BorderlessButtonStyle())
            }
        }
        .padding(.vertical, 4)
    }

    private func unlinkableAccountRow(provider: OAuthProvider) -> some View {
        Button(action: {
            Task {
                await viewModel.linkAccount(provider: provider)
            }
        }) {
            HStack {
                Image(systemName: provider.icon)
                    .foregroundColor(provider.color)
                    .frame(width: 24)

                Text("Link \(provider.displayName) Account")
                    .foregroundColor(Theme.Colors.text)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(Theme.Colors.secondaryText)
            }
            .padding(.vertical, 4)
        }
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
    @Published var isLoading = false
    @Published var errorMessage: String?

    func fetchLinkedAccounts() async {
        isLoading = true
        errorMessage = nil

        do {
            let accounts = try await AccountLinkingService.shared.fetchLinkedAccounts()
            self.linkedAccounts = accounts
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
}

#Preview {
    NavigationView {
        LinkedAccountsView()
    }
}
