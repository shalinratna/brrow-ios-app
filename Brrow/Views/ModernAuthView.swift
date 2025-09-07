//
//  ModernAuthView.swift
//  Brrow
//
//  Simple, clean authentication interface matching app design
//

import SwiftUI
import AuthenticationServices

struct ModernAuthView: View {
    @StateObject private var viewModel = LoginViewModel()
    @EnvironmentObject private var authManager: AuthManager
    @State private var isSignUpMode = false
    @State private var showPassword = false
    @State private var animateContent = false
    @State private var logoScale: CGFloat = 1.0
    @FocusState private var focusedField: Field?
    
    enum Field: Hashable {
        case email, username, password, firstName, lastName
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 30) {
                    // Logo and Title
                    VStack(spacing: 20) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Theme.Colors.primary.opacity(0.1), Theme.Colors.primary.opacity(0.05)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 120, height: 120)
                                .blur(radius: 20)
                            
                            Image("AppIcon")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 100, height: 100)
                                .cornerRadius(24)
                                .shadow(color: Theme.Colors.primary.opacity(0.3), radius: 15, x: 0, y: 8)
                                .scaleEffect(logoScale)
                                .onAppear {
                                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                        logoScale = 1.05
                                    }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                            logoScale = 1.0
                                        }
                                    }
                                }
                        }
                        
                        VStack(spacing: 8) {
                            Text("Welcome to Brrow")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundColor(Theme.Colors.text)
                                .opacity(animateContent ? 1 : 0)
                                .offset(y: animateContent ? 0 : 20)
                            
                            Text(isSignUpMode ? "Create your account" : "Sign in to continue")
                                .font(.system(size: 17, weight: .medium))
                                .foregroundColor(Theme.Colors.secondaryText)
                                .opacity(animateContent ? 1 : 0)
                                .offset(y: animateContent ? 0 : 20)
                        }
                    }
                    .padding(.top, 50)
                    .onAppear {
                        withAnimation(.easeOut(duration: 0.5).delay(0.1)) {
                            animateContent = true
                        }
                    }
                    
                    // Form Fields
                    VStack(spacing: 20) {
                        // Email Field
                        ModernTextField(
                            title: "Email",
                            text: $viewModel.email,
                            placeholder: "Enter your email",
                            icon: "envelope.fill",
                            keyboardType: .emailAddress,
                            isValid: viewModel.errorMessage.isEmpty
                        )
                        .focused($focusedField, equals: .email)
                        
                        // Username Field (Sign Up Only)
                        if isSignUpMode {
                            ModernTextField(
                                title: "Username",
                                text: $viewModel.username,
                                placeholder: "Choose a username",
                                icon: "person.fill",
                                keyboardType: .default,
                                isValid: viewModel.errorMessage.isEmpty
                            )
                            .focused($focusedField, equals: .username)
                        }
                        
                        // Password Field
                        ModernSecureField(
                            title: "Password",
                            text: $viewModel.password,
                            placeholder: isSignUpMode ? "Create a password" : "Enter your password",
                            showPassword: $showPassword,
                            isValid: viewModel.errorMessage.isEmpty
                        )
                        .focused($focusedField, equals: .password)
                        
                        // First Name Field (Sign Up Only)
                        if isSignUpMode {
                            ModernTextField(
                                title: "First Name",
                                text: $viewModel.firstName,
                                placeholder: "Enter your first name",
                                icon: "person.fill",
                                keyboardType: .default,
                                isValid: viewModel.errorMessage.isEmpty
                            )
                            .focused($focusedField, equals: .firstName)
                        }
                        
                        // Last Name Field (Sign Up Only)
                        if isSignUpMode {
                            ModernTextField(
                                title: "Last Name",
                                text: $viewModel.lastName,
                                placeholder: "Enter your last name",
                                icon: "person.fill",
                                keyboardType: .default,
                                isValid: viewModel.errorMessage.isEmpty
                            )
                            .focused($focusedField, equals: .lastName)
                        }
                        
                        // Birthdate Field (Sign Up Only)
                        if isSignUpMode {
                            let age = Calendar.current.dateComponents([.year], from: viewModel.birthdate, to: Date()).year ?? 0
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Date of Birth")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(Theme.Colors.text.opacity(0.8))
                                
                                HStack {
                                    Image(systemName: "calendar")
                                        .font(.system(size: 18, weight: .medium))
                                        .foregroundColor(age >= 13 ? Theme.Colors.primary : Theme.Colors.error)
                                        .frame(width: 24)
                                    
                                    DatePicker(
                                        "",
                                        selection: $viewModel.birthdate,
                                        in: ...Date(),
                                        displayedComponents: .date
                                    )
                                    .datePickerStyle(.compact)
                                    .labelsHidden()
                                    .accentColor(Theme.Colors.primary)
                                }
                                .padding(16)
                                .background(
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(Theme.Colors.secondaryBackground)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 14)
                                                .stroke(
                                                    age >= 13 ? Theme.Colors.border : Theme.Colors.error,
                                                    lineWidth: 1.5
                                                )
                                        )
                                )
                                
                                if age < 13 && age > 0 {
                                    Text("You must be at least 13 years old")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(Theme.Colors.error)
                                        .padding(.leading, 4)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    
                    // Error Message
                    if viewModel.showError && !viewModel.errorMessage.isEmpty {
                        HStack {
                            Image(systemName: "exclamationmark.circle.fill")
                                .foregroundColor(Theme.Colors.error)
                            Text(viewModel.errorMessage)
                                .font(.system(size: 14))
                                .foregroundColor(Theme.Colors.error)
                        }
                        .padding(.horizontal, 24)
                    }
                    
                    // Action Buttons
                    VStack(spacing: 16) {
                        // Primary Action Button
                        Button(action: {
                            hideKeyboard()
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                // Button press animation
                            }
                            Task {
                                if isSignUpMode {
                                    await viewModel.register()
                                } else {
                                    await viewModel.login()
                                }
                            }
                        }) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                Theme.Colors.primary,
                                                Theme.Colors.primary.opacity(0.9)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .shadow(color: Theme.Colors.primary.opacity(0.3), radius: 8, x: 0, y: 4)
                                
                                HStack {
                                    if viewModel.isLoading {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                            .scaleEffect(0.8)
                                    } else {
                                        Text(isSignUpMode ? "Sign Up" : "Sign In")
                                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                                    }
                                }
                                .foregroundColor(.white)
                            }
                            .frame(height: 56)
                        }
                        .disabled(viewModel.isLoading || !isFormValid)
                        .opacity((viewModel.isLoading || !isFormValid) ? 0.7 : 1.0)
                        .scaleEffect((viewModel.isLoading || !isFormValid) ? 0.98 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isFormValid)
                        
                        // Toggle Mode Button
                        Button(action: {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                isSignUpMode.toggle()
                                viewModel.clearForm()
                                animateContent = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    withAnimation(.easeOut(duration: 0.3)) {
                                        animateContent = true
                                    }
                                }
                            }
                        }) {
                            HStack(spacing: 4) {
                                Text(isSignUpMode ? "Already have an account?" : "Don't have an account?")
                                    .font(.system(size: 15, weight: .regular))
                                    .foregroundColor(Theme.Colors.secondaryText)
                                
                                Text(isSignUpMode ? "Sign In" : "Sign Up")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(Theme.Colors.primary)
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    
                    // Divider
                    HStack {
                        Rectangle()
                            .frame(height: 1)
                            .foregroundColor(Theme.Colors.separator)
                        
                        Text("OR")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Theme.Colors.secondaryText)
                            .padding(.horizontal, 16)
                        
                        Rectangle()
                            .frame(height: 1)
                            .foregroundColor(Theme.Colors.separator)
                    }
                    .padding(.horizontal, 24)
                    
                    // Social Login Options
                    VStack(spacing: 12) {
                        // Apple Sign In
                        SignInWithAppleButton(
                            .signIn,
                            onRequest: { request in
                                request.requestedScopes = [.fullName, .email]
                            },
                            onCompletion: handleAppleSignIn
                        )
                        .signInWithAppleButtonStyle(.black)
                        .frame(height: 56)
                        .cornerRadius(14)
                        .shadow(color: Color.black.opacity(0.15), radius: 6, x: 0, y: 3)
                        
                        // Guest Mode
                        Button(action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                authManager.loginAsGuest()
                            }
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: "person.circle")
                                    .font(.system(size: 20, weight: .medium))
                                    .foregroundColor(Theme.Colors.secondaryText)
                                
                                Text("Continue as Guest")
                                    .font(.system(size: 17, weight: .medium))
                                    .foregroundColor(Theme.Colors.secondaryText)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Theme.Colors.secondaryBackground)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14)
                                            .stroke(Theme.Colors.border, lineWidth: 1)
                                    )
                            )
                        }
                    }
                    .padding(.horizontal, 24)
                    
                    // Footer Links
                    HStack(spacing: 4) {
                        Text("By continuing, you agree to our")
                            .font(.system(size: 12))
                            .foregroundColor(Theme.Colors.secondaryText)
                        
                        Button("Terms") {
                            // Show terms
                        }
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Theme.Colors.primary)
                        
                        Text("and")
                            .font(.system(size: 12))
                            .foregroundColor(Theme.Colors.secondaryText)
                        
                        Button("Privacy Policy") {
                            // Show privacy policy
                        }
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Theme.Colors.primary)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                }
            }
            .background(
                LinearGradient(
                    colors: [
                        Color(.systemBackground),
                        Theme.Colors.primary.opacity(0.02)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .navigationBarHidden(true)
            .opacity(animateContent ? 1 : 0.8)
            .animation(.easeOut(duration: 0.3), value: animateContent)
            .onTapGesture {
                hideKeyboard()
            }
            .gesture(
                DragGesture(minimumDistance: 10)
                    .onChanged { _ in
                        hideKeyboard()
                    }
            )
        }
    }
    
    // MARK: - Helper Methods
    private var isFormValid: Bool {
        if isSignUpMode {
            let age = Calendar.current.dateComponents([.year], from: viewModel.birthdate, to: Date()).year ?? 0
            return !viewModel.email.isEmpty &&
                   !viewModel.username.isEmpty &&
                   !viewModel.firstName.isEmpty &&
                   !viewModel.lastName.isEmpty &&
                   viewModel.password.count >= 8 &&
                   age >= 13
        } else {
            // For login, accept email OR username
            return !viewModel.email.isEmpty && !viewModel.password.isEmpty
        }
    }
    
    private func handleAppleSignIn(result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            guard let appleCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                viewModel.errorMessage = "Invalid Apple credentials"
                return
            }
            
            Task {
                let firstName = appleCredential.fullName?.givenName
                let lastName = appleCredential.fullName?.familyName
                let email = appleCredential.email
                let userIdentifier = appleCredential.user
                
                guard let identityToken = appleCredential.identityToken,
                      let tokenString = String(data: identityToken, encoding: .utf8) else {
                    viewModel.errorMessage = "Unable to process Apple Sign In"
                    return
                }
                
                await viewModel.signInWithApple(
                    userIdentifier: userIdentifier,
                    email: email,
                    firstName: firstName,
                    lastName: lastName,
                    identityToken: tokenString
                )
            }
            
        case .failure(let error):
            if let authError = error as? ASAuthorizationError {
                switch authError.code {
                case .canceled:
                    // User canceled - don't show error
                    break
                case .failed:
                    viewModel.errorMessage = "Sign in failed. Please try again."
                case .invalidResponse:
                    viewModel.errorMessage = "Invalid response from Apple. Please try again."
                case .notHandled:
                    viewModel.errorMessage = "Unable to complete sign in."
                case .unknown:
                    viewModel.errorMessage = "An unknown error occurred."
                @unknown default:
                    viewModel.errorMessage = "Sign in failed."
                }
            } else {
                viewModel.errorMessage = error.localizedDescription
            }
        }
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// MARK: - Modern Form Components
// Note: ModernTextField, ModernSecureField, ModernDatePicker, and SafariView are defined in LoginView.swift


#Preview {
    ModernAuthView()
        .environmentObject(AuthManager.shared)
}