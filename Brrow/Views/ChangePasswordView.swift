//
//  ChangePasswordView.swift
//  Brrow
//
//  Change password for email-authenticated users
//

import SwiftUI

struct ChangePasswordView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var authManager: AuthManager

    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""

    @State private var isLoading = false
    @State private var showSuccessAlert = false
    @State private var errorMessage: String?
    @State private var showError = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Change Password")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(Theme.Colors.text)

                    Text("Enter your current password and choose a new secure password.")
                        .font(.subheadline)
                        .foregroundColor(Theme.Colors.secondaryText)
                }
                .padding(.bottom, 8)

                // Current Password
                SecureInputField(
                    "Current Password",
                    text: $currentPassword,
                    placeholder: "Enter current password"
                )

                Divider()

                // New Password
                SecureInputField(
                    "New Password",
                    text: $newPassword,
                    placeholder: "Enter new password"
                )

                // Password strength indicator
                if !newPassword.isEmpty {
                    PasswordStrengthIndicator(
                        password: newPassword,
                        showRequirements: true
                    )
                }

                // Confirm New Password
                SecureInputField(
                    "Confirm New Password",
                    text: $confirmPassword,
                    placeholder: "Re-enter new password"
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

                // Security Tips
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.blue)
                        Text("Password Security Tips")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(Theme.Colors.text)
                    }

                    SecurityTipRow(text: "Use a unique password you don't use elsewhere")
                    SecurityTipRow(text: "Avoid personal information like birthdays")
                    SecurityTipRow(text: "Consider using a password manager")
                }
                .padding(16)
                .background(Color.blue.opacity(0.05))
                .cornerRadius(12)

                // Change Password Button
                Button(action: changePassword) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                    } else {
                        Text("Change Password")
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
        .navigationTitle("Change Password")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }
        .alert("Password Changed", isPresented: $showSuccessAlert) {
            Button("OK") {
                presentationMode.wrappedValue.dismiss()
            }
        } message: {
            Text("Your password has been changed successfully.")
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage ?? "An error occurred")
        }
    }

    private var isFormValid: Bool {
        !currentPassword.isEmpty &&
        !newPassword.isEmpty &&
        !confirmPassword.isEmpty &&
        newPassword == confirmPassword &&
        currentPassword != newPassword &&
        PasswordRequirements.check(newPassword).allMet
    }

    private func changePassword() {
        guard isFormValid else { return }

        isLoading = true
        errorMessage = nil

        Task {
            do {
                // First validate the new password with backend
                let validation = try await APIClient.shared.validatePassword(password: newPassword)

                if !validation.valid {
                    throw NSError(
                        domain: "Brrow",
                        code: 400,
                        userInfo: [NSLocalizedDescriptionKey: validation.errors?.joined(separator: ", ") ?? "Password does not meet requirements"]
                    )
                }

                // Then change the password
                _ = try await APIClient.shared.changePassword(
                    currentPassword: currentPassword,
                    newPassword: newPassword
                )

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
                        case .unauthorized:
                            errorMessage = "Current password is incorrect"
                        default:
                            errorMessage = "Failed to change password. Please try again."
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

struct SecurityTipRow: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "checkmark.circle")
                .foregroundColor(.green)
                .font(.system(size: 14))
                .padding(.top, 2)

            Text(text)
                .font(.caption)
                .foregroundColor(Theme.Colors.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

#Preview {
    NavigationView {
        ChangePasswordView()
            .environmentObject(AuthManager.shared)
    }
}
