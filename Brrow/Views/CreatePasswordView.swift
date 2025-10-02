//
//  CreatePasswordView.swift
//  Brrow
//
//  Create password for OAuth users (Google, Apple)
//

import SwiftUI

struct CreatePasswordView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var authManager = AuthManager.shared

    let provider: String // "Google", "Apple", etc.

    @State private var newPassword = ""
    @State private var confirmPassword = ""

    @State private var isLoading = false
    @State private var showSuccessAlert = false
    @State private var errorMessage: String?
    @State private var showError = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header with info banner
                VStack(alignment: .leading, spacing: 16) {
                    Text("Create Password")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(Theme.Colors.text)

                    // Info banner
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(Theme.Colors.primary)
                            .font(.system(size: 20))

                        VStack(alignment: .leading, spacing: 4) {
                            Text("You signed in with \(provider)")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(Theme.Colors.text)

                            Text("Create a password to enable direct login to Brrow with your email. You can still use \(provider) to sign in.")
                                .font(.caption)
                                .foregroundColor(Theme.Colors.secondaryText)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .padding(16)
                    .background(Theme.Colors.primary.opacity(0.1))
                    .cornerRadius(12)
                }

                // New Password
                SecureInputField(
                    "New Password",
                    text: $newPassword,
                    placeholder: "Create a password"
                )

                // Password strength indicator
                if !newPassword.isEmpty {
                    PasswordStrengthIndicator(
                        password: newPassword,
                        showRequirements: true
                    )
                }

                // Confirm Password
                SecureInputField(
                    "Confirm Password",
                    text: $confirmPassword,
                    placeholder: "Re-enter your password"
                )

                // Password match indicator
                if !confirmPassword.isEmpty {
                    HStack(spacing: 8) {
                        Image(systemName: newPassword == confirmPassword ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(newPassword == confirmPassword ? .green : .red)

                        Text(newPassword == confirmPassword ? "Passwords match" : "Passwords do not match")
                            .font(.caption)
                            .foregroundColor(newPassword == confirmPassword ? .green : .red)
                    }
                }

                // Benefits section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Benefits:")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(Theme.Colors.text)

                    BenefitRow(icon: "checkmark.circle.fill", text: "Sign in with email and password")
                    BenefitRow(icon: "checkmark.circle.fill", text: "Continue using \(provider)")
                    BenefitRow(icon: "checkmark.circle.fill", text: "Access your account anytime")
                    BenefitRow(icon: "checkmark.circle.fill", text: "Enhanced account security")
                }
                .padding(16)
                .background(Color.gray.opacity(0.05))
                .cornerRadius(12)

                // Create Password Button
                Button(action: createPassword) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                    } else {
                        Text("Create Password")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                    }
                }
                .background(isFormValid ? Theme.Colors.primary : Color.gray)
                .cornerRadius(12)
                .disabled(!isFormValid || isLoading)

                Spacer()
            }
            .padding(20)
        }
        .navigationTitle("Create Password")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }
        .alert("Password Created", isPresented: $showSuccessAlert) {
            Button("OK") {
                presentationMode.wrappedValue.dismiss()
            }
        } message: {
            Text("You can now sign in to Brrow with your email and password.")
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage ?? "An error occurred")
        }
    }

    private var isFormValid: Bool {
        !newPassword.isEmpty &&
        !confirmPassword.isEmpty &&
        newPassword == confirmPassword &&
        PasswordRequirements.check(newPassword).allMet
    }

    private func createPassword() {
        guard isFormValid else { return }

        isLoading = true
        errorMessage = nil

        Task {
            do {
                // First validate the password with backend
                let validation = try await APIClient.shared.validatePassword(password: newPassword)

                if !validation.valid {
                    throw NSError(
                        domain: "Brrow",
                        code: 400,
                        userInfo: [NSLocalizedDescriptionKey: validation.errors?.joined(separator: ", ") ?? "Password does not meet requirements"]
                    )
                }

                // Then create the password
                _ = try await APIClient.shared.createPassword(newPassword: newPassword)

                await MainActor.run {
                    isLoading = false
                    showSuccessAlert = true
                }
            } catch {
                await MainActor.run {
                    isLoading = false

                    if let apiError = error as? BrrowAPIError {
                        switch apiError {
                        case .serverError(let message):
                            errorMessage = message
                        default:
                            errorMessage = "Failed to create password. Please try again."
                        }
                    } else {
                        errorMessage = error.localizedDescription
                    }

                    showError = true
                }
            }
        }
    }
}

struct BenefitRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.green)
                .font(.system(size: 18))

            Text(text)
                .font(.subheadline)
                .foregroundColor(Theme.Colors.text)
        }
    }
}

#Preview {
    NavigationView {
        CreatePasswordView(provider: "Google")
    }
}
