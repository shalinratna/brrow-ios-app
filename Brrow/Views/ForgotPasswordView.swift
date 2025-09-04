import SwiftUI

struct ForgotPasswordView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = ForgotPasswordViewModel()
    @State private var showingResetCodeView = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(UIColor.systemBackground)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: Theme.Spacing.lg) {
                        // Header
                        VStack(spacing: Theme.Spacing.sm) {
                            Image(systemName: "lock.circle.fill")
                                .font(.system(size: 60))
                                .foregroundColor(Theme.Colors.primary)
                                .padding(.top, Theme.Spacing.xl)
                            
                            Text("Forgot Password?")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(Theme.Colors.text)
                            
                            Text("No worries! Enter your email and we'll send you reset instructions.")
                                .font(.body)
                                .foregroundColor(Theme.Colors.secondaryText)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, Theme.Spacing.lg)
                        }
                        .padding(.top, Theme.Spacing.xl)
                        
                        // Email Input
                        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                            Text("Email Address")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(Theme.Colors.secondaryText)
                            
                            HStack {
                                Image(systemName: "envelope")
                                    .foregroundColor(Theme.Colors.secondaryText)
                                    .frame(width: 20)
                                
                                TextField("Enter your email", text: $viewModel.email)
                                    .keyboardType(.emailAddress)
                                    .autocapitalization(.none)
                                    .textContentType(.emailAddress)
                            }
                            .padding()
                            .background(Color(UIColor.secondarySystemBackground))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(viewModel.emailError != nil ? Color.red : Color.clear, lineWidth: 1)
                            )
                            
                            if let error = viewModel.emailError {
                                Text(error)
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                        }
                        .padding(.horizontal, Theme.Spacing.lg)
                        
                        // Send Reset Link Button
                        Button(action: {
                            viewModel.sendResetLink()
                        }) {
                            HStack {
                                if viewModel.isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                } else {
                                    Text("Send Reset Link")
                                        .fontWeight(.semibold)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Theme.Colors.primary)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .disabled(viewModel.isLoading || viewModel.email.isEmpty)
                        .opacity(viewModel.isLoading || viewModel.email.isEmpty ? 0.6 : 1)
                        .padding(.horizontal, Theme.Spacing.lg)
                        
                        // Back to Login
                        Button(action: {
                            dismiss()
                        }) {
                            HStack {
                                Image(systemName: "arrow.left")
                                    .font(.caption)
                                Text("Back to Login")
                                    .font(.subheadline)
                            }
                            .foregroundColor(Theme.Colors.primary)
                        }
                        .padding(.top, Theme.Spacing.md)
                        
                        Spacer(minLength: Theme.Spacing.xl)
                    }
                }
            }
            .navigationBarHidden(true)
            .alert("Check Your Email", isPresented: $viewModel.showSuccessAlert) {
                Button("OK") {
                    showingResetCodeView = true
                }
            } message: {
                Text("We've sent a password reset code to \(viewModel.email). Please check your email and enter the code on the next screen.")
            }
            .alert("Error", isPresented: $viewModel.showErrorAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(viewModel.errorMessage)
            }
            .sheet(isPresented: $showingResetCodeView) {
                ResetPasswordView(email: viewModel.email)
            }
        }
    }
}

// Reset Password View
struct ResetPasswordView: View {
    let email: String
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = ResetPasswordViewModel()
    @State private var showingSuccessAlert = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(UIColor.systemBackground)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: Theme.Spacing.lg) {
                        // Header
                        VStack(spacing: Theme.Spacing.sm) {
                            Image(systemName: "key.fill")
                                .font(.system(size: 60))
                                .foregroundColor(Theme.Colors.primary)
                                .padding(.top, Theme.Spacing.xl)
                            
                            Text("Reset Password")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(Theme.Colors.text)
                            
                            Text("Enter the code from your email and create a new password.")
                                .font(.body)
                                .foregroundColor(Theme.Colors.secondaryText)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, Theme.Spacing.lg)
                        }
                        .padding(.top, Theme.Spacing.xl)
                        
                        VStack(spacing: Theme.Spacing.lg) {
                            // Reset Code
                            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                                Text("Reset Code")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(Theme.Colors.secondaryText)
                                
                                HStack {
                                    Image(systemName: "number")
                                        .foregroundColor(Theme.Colors.secondaryText)
                                        .frame(width: 20)
                                    
                                    TextField("Enter code from email", text: $viewModel.resetCode)
                                        .autocapitalization(.none)
                                }
                                .padding()
                                .background(Color(UIColor.secondarySystemBackground))
                                .cornerRadius(12)
                            }
                            
                            // New Password
                            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                                Text("New Password")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(Theme.Colors.secondaryText)
                                
                                HStack {
                                    Image(systemName: "lock")
                                        .foregroundColor(Theme.Colors.secondaryText)
                                        .frame(width: 20)
                                    
                                    SecureField("Enter new password", text: $viewModel.newPassword)
                                        .textContentType(.newPassword)
                                }
                                .padding()
                                .background(Color(UIColor.secondarySystemBackground))
                                .cornerRadius(12)
                            }
                            
                            // Confirm Password
                            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                                Text("Confirm Password")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(Theme.Colors.secondaryText)
                                
                                HStack {
                                    Image(systemName: "lock.fill")
                                        .foregroundColor(Theme.Colors.secondaryText)
                                        .frame(width: 20)
                                    
                                    SecureField("Confirm new password", text: $viewModel.confirmPassword)
                                        .textContentType(.newPassword)
                                }
                                .padding()
                                .background(Color(UIColor.secondarySystemBackground))
                                .cornerRadius(12)
                            }
                            
                            // Password Requirements
                            if !viewModel.newPassword.isEmpty {
                                VStack(alignment: .leading, spacing: 4) {
                                    PasswordRequirementView(
                                        requirement: "At least 8 characters",
                                        isMet: viewModel.passwordValidation.hasMinLength
                                    )
                                    PasswordRequirementView(
                                        requirement: "One uppercase letter",
                                        isMet: viewModel.passwordValidation.hasUppercase
                                    )
                                    PasswordRequirementView(
                                        requirement: "One lowercase letter",
                                        isMet: viewModel.passwordValidation.hasLowercase
                                    )
                                    PasswordRequirementView(
                                        requirement: "One number",
                                        isMet: viewModel.passwordValidation.hasNumber
                                    )
                                }
                                .padding(.horizontal, 4)
                                .transition(.opacity)
                            }
                            
                            if let error = viewModel.errorMessage {
                                Text(error)
                                    .font(.caption)
                                    .foregroundColor(.red)
                                    .multilineTextAlignment(.center)
                            }
                        }
                        .padding(.horizontal, Theme.Spacing.lg)
                        
                        // Reset Password Button
                        Button(action: {
                            viewModel.resetPassword()
                        }) {
                            HStack {
                                if viewModel.isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                } else {
                                    Text("Reset Password")
                                        .fontWeight(.semibold)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Theme.Colors.primary)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .disabled(!viewModel.isValid || viewModel.isLoading)
                        .opacity(!viewModel.isValid || viewModel.isLoading ? 0.6 : 1)
                        .padding(.horizontal, Theme.Spacing.lg)
                        
                        // Resend Code
                        Button(action: {
                            viewModel.resendCode(email: email)
                        }) {
                            Text("Didn't receive the code? Resend")
                                .font(.subheadline)
                                .foregroundColor(Theme.Colors.primary)
                        }
                        .padding(.top, Theme.Spacing.md)
                        
                        Spacer(minLength: Theme.Spacing.xl)
                    }
                }
            }
            .navigationBarHidden(true)
            .alert("Success!", isPresented: $viewModel.showSuccessAlert) {
                Button("OK") {
                    dismiss()
                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                       let window = windowScene.windows.first {
                        window.rootViewController?.dismiss(animated: true)
                    }
                }
            } message: {
                Text("Your password has been reset successfully. You can now log in with your new password.")
            }
        }
    }
}

// Password Requirement View
struct PasswordRequirementView: View {
    let requirement: String
    let isMet: Bool
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: isMet ? "checkmark.circle.fill" : "circle")
                .foregroundColor(isMet ? .green : Color(UIColor.tertiaryLabel))
                .font(.caption)
            
            Text(requirement)
                .font(.caption)
                .foregroundColor(isMet ? Theme.Colors.text : Theme.Colors.secondaryText)
            
            Spacer()
        }
    }
}

#Preview {
    ForgotPasswordView()
}