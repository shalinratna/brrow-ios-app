//
//  ForgotPasswordView.swift
//  Brrow
//
//  Password reset request view
//

import SwiftUI

struct ForgotPasswordView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var email = ""
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var successMessage = ""
    @State private var showSuccess = false
    @FocusState private var isEmailFocused: Bool

    var body: some View {
        NavigationView {
            ZStack {
                // Background
                Theme.Colors.background
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 30) {
                        // Icon
                        ZStack {
                            Circle()
                                .fill(Theme.Colors.primary.opacity(0.1))
                                .frame(width: 100, height: 100)

                            Image(systemName: "key.fill")
                                .font(.system(size: 40, weight: .medium))
                                .foregroundColor(Theme.Colors.primary)
                        }
                        .padding(.top, 40)

                        // Title and description
                        VStack(spacing: 12) {
                            Text("Reset Password")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(Theme.Colors.text)

                            Text("Enter your email address and we'll send you a link to reset your password.")
                                .font(.system(size: 16))
                                .foregroundColor(Theme.Colors.secondaryText)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 20)
                        }

                        // Email field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Email Address")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(Theme.Colors.text)

                            HStack {
                                Image(systemName: "envelope.fill")
                                    .foregroundColor(Theme.Colors.secondaryText)
                                    .font(.system(size: 16))

                                TextField("Enter your email", text: $email)
                                    .textContentType(.emailAddress)
                                    .keyboardType(.emailAddress)
                                    .autocapitalization(.none)
                                    .autocorrectionDisabled()
                                    .focused($isEmailFocused)
                                    .font(.system(size: 16))
                                    .foregroundColor(Theme.Colors.text)
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Theme.Colors.secondaryBackground)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(isEmailFocused ? Theme.Colors.primary : Color.clear, lineWidth: 2)
                                    )
                            )
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 20)

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

                        // Send button
                        Button(action: sendResetLink) {
                            HStack {
                                if isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                    Text("Sending...")
                                        .font(.system(size: 17, weight: .semibold))
                                } else {
                                    Text("Send Reset Link")
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
                                            colors: [Theme.Colors.primary, Theme.Colors.primary.opacity(0.9)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                            )
                            .shadow(color: Theme.Colors.primary.opacity(0.3), radius: 8, x: 0, y: 4)
                        }
                        .disabled(email.isEmpty || isLoading)
                        .opacity(email.isEmpty || isLoading ? 0.7 : 1.0)
                        .scaleEffect(email.isEmpty || isLoading ? 0.98 : 1.0)
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
                            Image(systemName: "chevron.left")
                                .font(.system(size: 14, weight: .semibold))
                            Text("Back")
                                .font(.system(size: 17, weight: .medium))
                        }
                        .foregroundColor(Theme.Colors.primary)
                    }
                }
            }
            .alert("Email Sent", isPresented: $showSuccess) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text(successMessage)
            }
        }
        .onAppear {
            // Auto-focus email field
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isEmailFocused = true
            }
        }
    }

    private func sendResetLink() {
        errorMessage = ""
        isLoading = true

        Task {
            do {
                try await APIClient.shared.requestPasswordReset(email: email)

                await MainActor.run {
                    isLoading = false
                    successMessage = "A password reset link has been sent to \(email). Please check your inbox and spam folder."
                    showSuccess = true
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    if let apiError = error as? BrrowAPIError {
                        errorMessage = apiError.localizedDescription
                    } else {
                        errorMessage = "Failed to send reset link. Please check your email and try again."
                    }
                }
            }
        }
    }
}

#Preview {
    ForgotPasswordView()
}
