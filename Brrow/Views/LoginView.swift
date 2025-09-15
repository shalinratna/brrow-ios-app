//
//  LoginView.swift
//  Brrow
//
//  Created by Shalin Ratna on 7/16/25.
//

import SwiftUI

struct LoginView: View {
    @StateObject private var viewModel = LoginViewModel()
    @State private var showPassword = false
    
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                ScrollView {
                    VStack(spacing: 0) {
                        // Top gradient section
                        topGradientSection
                            .frame(height: geometry.size.height * 0.4)
                        
                        // White form section
                        formContainer
                            .background(Theme.Colors.background)
                            .clipShape(RoundedRectangle(cornerRadius: 24))
                            .offset(y: -24)
                    }
                }
                .background(
                    LinearGradient(
                        colors: [Theme.Colors.primary, Theme.Colors.secondary],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .ignoresSafeArea(.all, edges: .top)
            }
            .navigationBarHidden(true)
            .onTapGesture {
                hideKeyboard()
            }
        }
        .fullScreenCover(isPresented: $viewModel.isLoggedIn) {
            MainTabView()
        }
    }
    
    // MARK: - Top Gradient Section
    private var topGradientSection: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Spacer()
            
            // App logo/icon
            Circle()
                .fill(.white.opacity(0.2))
                .frame(width: 80, height: 80)
                .overlay(
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.system(size: 36, weight: .medium))
                        .foregroundColor(.white)
                )
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
            
            VStack(spacing: Theme.Spacing.sm) {
                Text("Welcome to Brrow")
                    .font(.system(size: 28, weight: .bold, design: .default))
                    .foregroundColor(.white)
                
                Text("Share what you have, borrow what you need")
                    .font(Theme.Typography.body)
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
        }
        .padding(.horizontal, Theme.Spacing.lg)
    }
    
    // MARK: - Form Container
    private var formContainer: some View {
        VStack(spacing: Theme.Spacing.lg) {
            // Mode indicator
            HStack {
                Text(viewModel.isLoginMode ? "Sign In" : "Create Account")
                    .font(.system(size: 24, weight: .bold, design: .default))
                    .foregroundColor(Theme.Colors.text)
                Spacer()
            }
            .padding(.top, Theme.Spacing.xl)
            
            // Form fields
            modernFormSection
            
            // Submit button
            modernSubmitButton
            
            // Social login divider and buttons
            socialLoginSection
            
            // Toggle mode
            modernToggleSection
            
            // Error message
            if !viewModel.errorMessage.isEmpty {
                modernErrorView
            }
            
            Spacer(minLength: 50)
        }
        .padding(.horizontal, Theme.Spacing.lg)
    }
    
    // MARK: - Modern Form Section
    private var modernFormSection: some View {
        VStack(spacing: Theme.Spacing.md) {
            // Username Field (Registration only)
            if !viewModel.isLoginMode {
                ModernTextField(
                    title: "Username",
                    text: $viewModel.username,
                    placeholder: "Choose a username",
                    icon: "person.circle",
                    keyboardType: .default,
                    isValid: viewModel.isValidUsername
                )
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                
                // Birthdate Field (Registration only)
                ModernDatePicker(
                    title: "Date of Birth",
                    selection: $viewModel.birthdate,
                    isValid: viewModel.isValidAge
                )
            }
            
            // Email Field
            ModernTextField(
                title: "Email",
                text: $viewModel.email,
                placeholder: "Enter your email address",
                icon: "envelope.circle",
                keyboardType: .emailAddress,
                isValid: viewModel.isValidEmail
            )
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            
            // Password Field
            ModernSecureField(
                title: "Password",
                text: $viewModel.password,
                placeholder: "Enter your password",
                showPassword: $showPassword,
                isValid: viewModel.isValidPassword
            )
        }
    }
    
    // MARK: - Modern Submit Button
    private var modernSubmitButton: some View {
        Button(action: {
            if viewModel.isLoginMode {
                Task {
                    await viewModel.login()
                }
            } else {
                viewModel.register()
            }
        }) {
            HStack(spacing: Theme.Spacing.sm) {
                if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.9)
                } else {
                    Text(viewModel.isLoginMode ? "Sign In" : "Create Account")
                        .font(.system(size: 17, weight: .semibold, design: .default))
                    
                    Image(systemName: "arrow.right")
                        .font(.system(size: 16, weight: .semibold))
                }
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(
                LinearGradient(
                    colors: viewModel.canSubmit ? 
                        [Theme.Colors.primary, Theme.Colors.primary.opacity(0.8)] :
                        [Theme.Colors.border, Theme.Colors.border],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(Theme.CornerRadius.card)
            .shadow(
                color: viewModel.canSubmit ? Theme.Colors.primary.opacity(0.3) : Color.clear,
                radius: 8,
                x: 0,
                y: 4
            )
        }
        .disabled(!viewModel.canSubmit)
        .scaleEffect(viewModel.canSubmit ? 1.0 : 0.98)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: viewModel.canSubmit)
    }
    
    // MARK: - Modern Toggle Section
    private var modernToggleSection: some View {
        Button(action: {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                viewModel.toggleMode()
            }
        }) {
            HStack(spacing: 4) {
                Text(viewModel.isLoginMode ? "Don't have an account?" : "Already have an account?")
                    .font(Theme.Typography.body)
                    .foregroundColor(Theme.Colors.secondaryText)
                
                Text(viewModel.isLoginMode ? "Sign Up" : "Sign In")
                    .font(Theme.Typography.body)
                    .fontWeight(.semibold)
                    .foregroundColor(Theme.Colors.primary)
                    .underline()
            }
        }
        .padding(.top, Theme.Spacing.lg)
    }
    
    // MARK: - Modern Error View
    private var modernErrorView: some View {
        HStack(spacing: Theme.Spacing.sm) {
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundColor(Theme.Colors.error)
                .font(.system(size: 16))
            
            Text(viewModel.errorMessage)
                .font(Theme.Typography.body)
                .foregroundColor(Theme.Colors.error)
                .multilineTextAlignment(.leading)
            
            Spacer()
        }
        .padding(Theme.Spacing.md)
        .background(Theme.Colors.error.opacity(0.08))
        .cornerRadius(Theme.CornerRadius.card)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.card)
                .stroke(Theme.Colors.error.opacity(0.2), lineWidth: 1)
        )
        .transition(.asymmetric(
            insertion: .scale.combined(with: .opacity),
            removal: .opacity
        ))
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.errorMessage)
    }
    
    // MARK: - Social Login Section
    private var socialLoginSection: some View {
        VStack(spacing: Theme.Spacing.md) {
            // Divider with "or" text
            HStack {
                Rectangle()
                    .fill(Theme.Colors.border)
                    .frame(height: 1)
                
                Text("or")
                    .font(Theme.Typography.body)
                    .foregroundColor(Theme.Colors.secondaryText)
                    .padding(.horizontal, Theme.Spacing.md)
                
                Rectangle()
                    .fill(Theme.Colors.border)
                    .frame(height: 1)
            }
            .padding(.vertical, Theme.Spacing.sm)
            
            // Google Sign-In Button
            googleSignInButton
        }
    }
    
    // MARK: - Google Sign-In Button
    @StateObject private var googleAuthService = GoogleAuthService.shared
    
    private var googleSignInButton: some View {
        Button(action: {
            Task {
                await googleAuthService.signIn()
            }
        }) {
            HStack(spacing: Theme.Spacing.sm) {
                if googleAuthService.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: Theme.Colors.text))
                        .scaleEffect(0.9)
                } else {
                    // Google icon
                    Image(systemName: "globe")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(Theme.Colors.text)
                    
                    Text("Continue with Google")
                        .font(.system(size: 16, weight: .medium, design: .default))
                        .foregroundColor(Theme.Colors.text)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(Theme.Colors.surface)
            .cornerRadius(Theme.CornerRadius.card)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.card)
                    .stroke(Theme.Colors.border, lineWidth: 1.5)
            )
            .shadow(
                color: Theme.Colors.text.opacity(0.05),
                radius: 4,
                x: 0,
                y: 2
            )
        }
        .disabled(googleAuthService.isLoading)
        .scaleEffect(googleAuthService.isLoading ? 0.98 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: googleAuthService.isLoading)
    }
    
    // MARK: - Helper Methods
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// MARK: - Modern Form Components
struct ModernTextField: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    let icon: String
    let keyboardType: UIKeyboardType
    let isValid: Bool
    var textContentType: UITextContentType? = nil  // Added for autofill support
    
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            Text(title)
                .font(.system(size: 15, weight: .medium, design: .default))
                .foregroundColor(Theme.Colors.text)
            
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(text.isEmpty ? Theme.Colors.secondaryText.opacity(0.6) : Theme.Colors.primary)
                    .frame(width: 24)
                
                TextField(placeholder, text: $text)
                    .font(.system(size: 16, weight: .regular, design: .rounded))
                    .foregroundColor(Theme.Colors.text)
                    .textContentType(textContentType)  // Apply autofill type
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 15)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Theme.Colors.surface)
                    .shadow(color: Theme.Colors.primary.opacity(text.isEmpty ? 0 : 0.08), radius: 6, x: 0, y: 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(borderColor, lineWidth: text.isEmpty ? 1 : 2)
            )
            .keyboardType(keyboardType)
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: text)
        }
    }
    
    private var borderColor: Color {
        if text.isEmpty {
            return Theme.Colors.border
        } else if isValid {
            return Theme.Colors.primary.opacity(0.6)
        } else {
            return Theme.Colors.error
        }
    }
}

struct ModernSecureField: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    @Binding var showPassword: Bool
    let isValid: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            Text(title)
                .font(.system(size: 15, weight: .medium, design: .default))
                .foregroundColor(Theme.Colors.text)
            
            HStack(spacing: Theme.Spacing.sm) {
                Image(systemName: "lock.circle")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(text.isEmpty ? Theme.Colors.secondaryText : Theme.Colors.primary)
                    .frame(width: 20)
                
                Group {
                    if showPassword {
                        TextField(placeholder, text: $text)
                            .textContentType(.password)  // Enable password autofill
                    } else {
                        SecureField(placeholder, text: $text)
                            .textContentType(.password)  // Enable password autofill
                    }
                }
                .font(.system(size: 16, weight: .regular, design: .default))
                .foregroundColor(Theme.Colors.text)
                
                Button(action: {
                    withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
                        showPassword.toggle()
                    }
                }) {
                    Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Theme.Colors.secondaryText)
                }
            }
            .padding(Theme.Spacing.md)
            .background(Theme.Colors.surface)
            .cornerRadius(Theme.CornerRadius.card)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.card)
                    .stroke(borderColor, lineWidth: 1.5)
            )
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: text)
        }
    }
    
    private var borderColor: Color {
        if text.isEmpty {
            return Theme.Colors.border
        } else if isValid {
            return Theme.Colors.primary.opacity(0.6)
        } else {
            return Theme.Colors.error
        }
    }
}

struct ModernDatePicker: View {
    let title: String
    @Binding var selection: Date
    let isValid: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            Text(title)
                .font(.system(size: 15, weight: .medium, design: .default))
                .foregroundColor(Theme.Colors.text)
            
            HStack(spacing: Theme.Spacing.sm) {
                Image(systemName: "calendar.circle")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Theme.Colors.primary)
                    .frame(width: 20)
                
                DatePicker(
                    "",
                    selection: $selection,
                    in: ...Date(),
                    displayedComponents: .date
                )
                .datePickerStyle(CompactDatePickerStyle())
                .font(.system(size: 16, weight: .regular, design: .default))
                .foregroundColor(Theme.Colors.text)
            }
            .padding(Theme.Spacing.md)
            .background(Theme.Colors.surface)
            .cornerRadius(Theme.CornerRadius.card)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.card)
                    .stroke(borderColor, lineWidth: 1.5)
            )
            
            if !isValid {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(Theme.Colors.error)
                    
                    Text("You must be 13 years or older to register")
                        .font(.system(size: 12, weight: .medium, design: .default))
                        .foregroundColor(Theme.Colors.error)
                }
                .padding(.horizontal, 4)
                .transition(.asymmetric(
                    insertion: .scale.combined(with: .opacity),
                    removal: .opacity
                ))
            }
        }
    }
    
    private var borderColor: Color {
        return isValid ? Theme.Colors.primary.opacity(0.6) : Theme.Colors.error
    }
}

// MARK: - Legacy Custom Text Field
struct CustomTextField: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    let keyboardType: UIKeyboardType
    let isValid: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            Text(title)
                .font(Theme.Typography.callout)
                .fontWeight(.medium)
                .foregroundColor(Theme.Colors.text)
            
            TextField(placeholder, text: $text)
                .font(Theme.Typography.body)
                .padding(Theme.Spacing.md)
                .background(Theme.Colors.cardBackground)
                .cornerRadius(Theme.CornerRadius.md)
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                        .stroke(borderColor, lineWidth: 1)
                )
                .keyboardType(keyboardType)
                .textInputAutocapitalization(.never)
        }
    }
    
    private var borderColor: Color {
        if text.isEmpty {
            return Theme.Colors.divider
        } else if isValid {
            return Theme.Colors.success
        } else {
            return Theme.Colors.error
        }
    }
}

// MARK: - Custom Secure Field
struct CustomSecureField: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    @Binding var showPassword: Bool
    let isValid: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            Text(title)
                .font(Theme.Typography.callout)
                .fontWeight(.medium)
                .foregroundColor(Theme.Colors.text)
            
            HStack {
                Group {
                    if showPassword {
                        TextField(placeholder, text: $text)
                    } else {
                        SecureField(placeholder, text: $text)
                    }
                }
                .font(Theme.Typography.body)
                
                Button(action: {
                    showPassword.toggle()
                }) {
                    Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                        .foregroundColor(Theme.Colors.secondaryText)
                }
            }
            .padding(Theme.Spacing.md)
            .background(Theme.Colors.cardBackground)
            .cornerRadius(Theme.CornerRadius.md)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                    .stroke(borderColor, lineWidth: 1)
            )
        }
    }
    
    private var borderColor: Color {
        if text.isEmpty {
            return Theme.Colors.divider
        } else if isValid {
            return Theme.Colors.success
        } else {
            return Theme.Colors.error
        }
    }
}

// MARK: - Custom Date Picker
struct CustomDatePicker: View {
    let title: String
    @Binding var selection: Date
    let isValid: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            Text(title)
                .font(Theme.Typography.callout)
                .fontWeight(.medium)
                .foregroundColor(Theme.Colors.text)
            
            DatePicker(
                "",
                selection: $selection,
                in: ...Date(),
                displayedComponents: .date
            )
            .datePickerStyle(CompactDatePickerStyle())
            .padding(Theme.Spacing.md)
            .background(Theme.Colors.cardBackground)
            .cornerRadius(Theme.CornerRadius.md)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                    .stroke(borderColor, lineWidth: 1)
            )
            
            if !isValid {
                Text("You must be 13 years or older to register")
                    .font(Theme.Typography.caption)
                    .foregroundColor(Theme.Colors.error)
                    .padding(.horizontal, Theme.Spacing.xs)
            }
        }
    }
    
    private var borderColor: Color {
        return isValid ? Theme.Colors.success : Theme.Colors.error
    }
}

// MARK: - Preview
struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
    }
}