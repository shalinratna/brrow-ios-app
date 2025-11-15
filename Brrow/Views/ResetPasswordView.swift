//
//  ResetPasswordView.swift
//  Brrow
//
//  Complete password reset with token
//

import SwiftUI

struct ResetPasswordView: View {
    let email: String
    @Environment(\.dismiss) private var dismiss
    @State private var token = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var successMessage = ""
    @State private var showSuccess = false
    @State private var showPassword = false
    @State private var showConfirmPassword = false
    @FocusState private var focusedField: Field?

    enum Field {
        case token, newPassword, confirmPassword
    }

    var body: some View {
        ZStack {
            // Background
            Theme.Colors.background
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 30) {
                    // Icon
                    ZStack {
                        Circle()
                            .fill(Theme.Colors.success.opacity(0.1))
                            .frame(width: 100, height: 100)

                        Image(systemName: "lock.rotation")
                            .font(.system(size: 40, weight: .medium))
                            .foregroundColor(Theme.Colors.success)
                    }
                    .padding(.top, 40)

                    // Title and description
                    VStack(spacing: 12) {
                        Text("Create New Password")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(Theme.Colors.text)

                        Text("Enter the reset code from your email and create a new secure password.")
                            .font(.system(size: 16))
                            .foregroundColor(Theme.Colors.secondaryText)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                    }

                    // Form fields
                    VStack(alignment: .leading, spacing: 20) {
                        // Token field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Reset Code")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(Theme.Colors.text)

                            HStack {
                                Image(systemName: "number.circle.fill")
                                    .foregroundColor(Theme.Colors.secondaryText)
                                    .font(.system(size: 16))

                                TextField("Enter reset code from email", text: $token)
                                    .textContentType(.oneTimeCode)
                                    .autocapitalization(.none)
                                    .autocorrectionDisabled()
                                    .focused($focusedField, equals: .token)
                                    .font(.system(size: 16))
                                    .foregroundColor(Theme.Colors.text)
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Theme.Colors.secondaryBackground)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(focusedField == .token ? Theme.Colors.primary : Color.clear, lineWidth: 2)
                                    )
                            )
                        }

                        // New password field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("New Password")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(Theme.Colors.text)

                            HStack {
                                Image(systemName: "lock.fill")
                                    .foregroundColor(Theme.Colors.secondaryText)
                                    .font(.system(size: 16))

                                if showPassword {
                                    TextField("At least 8 characters", text: $newPassword)
                                        .textContentType(.newPassword)
                                        .autocapitalization(.none)
                                        .autocorrectionDisabled()
                                        .focused($focusedField, equals: .newPassword)
                                        .font(.system(size: 16))
                                        .foregroundColor(Theme.Colors.text)
                                } else {
                                    SecureField("At least 8 characters", text: $newPassword)
                                        .textContentType(.newPassword)
                                        .autocapitalization(.none)
                                        .autocorrectionDisabled()
                                        .focused($focusedField, equals: .newPassword)
                                        .font(.system(size: 16))
                                        .foregroundColor(Theme.Colors.text)
                                }

                                Button(action: { showPassword.toggle() }) {
                                    Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                                        .foregroundColor(Theme.Colors.secondaryText)
                                        .font(.system(size: 16))
                                }
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Theme.Colors.secondaryBackground)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(focusedField == .newPassword ? Theme.Colors.primary : Color.clear, lineWidth: 2)
                                    )
                            )

                            if !newPassword.isEmpty && newPassword.count < 8 {
                                Text("Password must be at least 8 characters")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(Theme.Colors.error)
                                    .padding(.leading, 4)
                            }
                        }

                        // Confirm password field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Confirm Password")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(Theme.Colors.text)

                            HStack {
                                Image(systemName: "lock.fill")
                                    .foregroundColor(Theme.Colors.secondaryText)
                                    .font(.system(size: 16))

                                if showConfirmPassword {
                                    TextField("Re-enter password", text: $confirmPassword)
                                        .textContentType(.newPassword)
                                        .autocapitalization(.none)
                                        .autocorrectionDisabled()
                                        .focused($focusedField, equals: .confirmPassword)
                                        .font(.system(size: 16))
                                        .foregroundColor(Theme.Colors.text)
                                } else {
                                    SecureField("Re-enter password", text: $confirmPassword)
                                        .textContentType(.newPassword)
                                        .autocapitalization(.none)
                                        .autocorrectionDisabled()
                                        .focused($focusedField, equals: .confirmPassword)
                                        .font(.system(size: 16))
                                        .foregroundColor(Theme.Colors.text)
                                }

                                Button(action: { showConfirmPassword.toggle() }) {
                                    Image(systemName: showConfirmPassword ? "eye.slash.fill" : "eye.fill")
                                        .foregroundColor(Theme.Colors.secondaryText)
                                        .font(.system(size: 16))
                                }
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Theme.Colors.secondaryBackground)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(focusedField == .confirmPassword ? Theme.Colors.primary : Color.clear, lineWidth: 2)
                                    )
                            )

                            if !confirmPassword.isEmpty && newPassword != confirmPassword {
                                Text("Passwords do not match")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(Theme.Colors.error)
                                    .padding(.leading, 4)
                            }
                        }
                    }
                    .padding(.horizontal, 24)

                    // Error message
                    if !errorMessage.isEmpty {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(Theme.Colors.error)
                            Text(errorMessage)
                                .font(.system(size: 14))
                                .foregroundColor(Theme.Colors.error)
                        }
                        .padding()
                        .background(Theme.Colors.error.opacity(0.1))
                        .cornerRadius(12)
                        .padding(.horizontal, 24)
                    }

                    // Reset button
                    Button(action: resetPassword) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                                Text("Resetting...")
                                    .font(.system(size: 17, weight: .semibold))
                            } else {
                                Text("Reset Password")
                                    .font(.system(size: 17, weight: .semibold))
                            }
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(
                                    LinearGradient(
                                        colors: [Theme.Colors.success, Theme.Colors.success.opacity(0.9)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        )
                        .shadow(color: Theme.Colors.success.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    .disabled(!isFormValid || isLoading)
                    .opacity(!isFormValid || isLoading ? 0.7 : 1.0)
                    .scaleEffect(!isFormValid || isLoading ? 0.98 : 1.0)
                    .padding(.horizontal, 24)
                    .padding(.top, 10)

                    Spacer()
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    dismiss()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(Theme.Colors.primary)
                }
            }
        }
        .alert("Password Reset Successful", isPresented: $showSuccess) {
            Button("Sign In") {
                dismiss()
            }
        } message: {
            Text(successMessage)
        }
    }

    private var isFormValid: Bool {
        !token.isEmpty &&
        newPassword.count >= 8 &&
        newPassword == confirmPassword
    }

    private func resetPassword() {
        errorMessage = ""
        isLoading = true

        Task {
            do {
                try await APIClient.shared.resetPassword(
                    email: email,
                    token: token,
                    newPassword: newPassword
                )

                await MainActor.run {
                    isLoading = false
                    successMessage = "Your password has been reset successfully. You can now sign in with your new password."
                    showSuccess = true
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    if let apiError = error as? BrrowAPIError {
                        errorMessage = apiError.localizedDescription
                    } else {
                        errorMessage = "Failed to reset password. Please check your reset code and try again."
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationView {
        ResetPasswordView(email: "test@example.com")
    }
}
