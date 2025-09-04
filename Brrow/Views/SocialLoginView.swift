//
//  SocialLoginView.swift
//  Brrow
//
//  Modern Social-Inspired Login Experience
//

import SwiftUI
import AuthenticationServices

struct SocialLoginView: View {
    @StateObject private var viewModel = SocialLoginViewModel()
    @State private var loginInput = "" // Can be email OR username
    @State private var password = ""
    @State private var showPassword = false
    @State private var isLoginMode = true
    @State private var animateBackground = false
    
    var body: some View {
        ZStack {
            // Animated background
            backgroundGradient
            
            ScrollView {
                VStack(spacing: 0) {
                    Spacer(minLength: 60)
                    
                    // App branding
                    brandingSection
                    
                    Spacer(minLength: 40)
                    
                    // Main form
                    formSection
                    
                    Spacer(minLength: 30)
                }
                .padding(.horizontal, 24)
            }
        }
        .ignoresSafeArea()
        .fullScreenCover(isPresented: $viewModel.isLoggedIn) {
            SocialMainTabView()
        }
        .onAppear {
            startBackgroundAnimation()
        }
    }
    
    // MARK: - Background
    private var backgroundGradient: some View {
        ZStack {
            // Base gradient
            LinearGradient(
                colors: [
                    Theme.Colors.primary,
                    Theme.Colors.secondary,
                    Theme.Colors.primary.opacity(0.8)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Animated overlay
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.white.opacity(0.2),
                            Color.clear
                        ],
                        center: .topTrailing,
                        startRadius: 0,
                        endRadius: 400
                    )
                )
                .scaleEffect(animateBackground ? 1.2 : 0.8)
                .offset(x: 100, y: -100)
                .animation(
                    .easeInOut(duration: 4).repeatForever(autoreverses: true),
                    value: animateBackground
                )
            
            // Floating elements
            ForEach(0..<6, id: \.self) { index in
                Circle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: CGFloat.random(in: 20...60))
                    .position(
                        x: CGFloat.random(in: 50...350),
                        y: CGFloat.random(in: 100...800)
                    )
                    .animation(
                        .easeInOut(duration: Double.random(in: 3...6))
                        .repeatForever(autoreverses: true)
                        .delay(Double(index) * 0.5),
                        value: animateBackground
                    )
            }
        }
    }
    
    // MARK: - Branding Section
    private var brandingSection: some View {
        VStack(spacing: 16) {
            // App icon with glow effect
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.15))
                    .frame(width: 120, height: 120)
                    .blur(radius: 20)
                
                Circle()
                    .fill(Color.white.opacity(0.2))
                    .frame(width: 100, height: 100)
                
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.system(size: 40, weight: .light))
                    .foregroundColor(.white)
            }
            .scaleEffect(animateBackground ? 1.05 : 0.95)
            .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: animateBackground)
            
            VStack(spacing: 8) {
                Text("Brrow")
                    .font(.system(size: 42, weight: .light, design: .rounded))
                    .foregroundColor(.white)
                
                Text("Share. Borrow. Connect.")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
                
                Text("Join the community of 50K+ neighbors")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.7))
            }
        }
    }
    
    // MARK: - Form Section
    private var formSection: some View {
        VStack(spacing: 20) {
            // Mode toggle
            modeToggle
            
            // Form fields in card
            VStack(spacing: 20) {
                // Email/Username field
                SocialTextField(
                    title: isLoginMode ? "Email or Username" : "Email",
                    text: $loginInput,
                    placeholder: isLoginMode ? "Enter email or username" : "Enter your email",
                    icon: "person.circle.fill",
                    keyboardType: .emailAddress
                )
                
                // Username field (registration only)
                if !isLoginMode {
                    SocialTextField(
                        title: "Username",
                        text: $viewModel.username,
                        placeholder: "Choose a unique username",
                        icon: "at.circle.fill",
                        keyboardType: .default
                    )
                }
                
                // Password field
                SocialSecureField(
                    title: "Password",
                    text: $password,
                    placeholder: "Enter your password",
                    showPassword: $showPassword
                )
                
                // Birthdate (registration only)
                if !isLoginMode {
                    SocialDatePicker(
                        title: "Date of Birth",
                        selection: $viewModel.birthdate
                    )
                }
                
                // Action button
                actionButton
                
                // Social login options
                socialLoginSection
                
                // Mode switch
                modeSwitchButton
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(.ultraThinMaterial)
                    .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 10)
            )
        }
    }
    
    // MARK: - Mode Toggle
    private var modeToggle: some View {
        HStack(spacing: 0) {
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    isLoginMode = true
                }
            }) {
                Text("Sign In")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(isLoginMode ? .white : .white.opacity(0.6))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(isLoginMode ? Color.white.opacity(0.2) : Color.clear)
                    )
            }
            
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    isLoginMode = false
                }
            }) {
                Text("Sign Up")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(!isLoginMode ? .white : .white.opacity(0.6))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(!isLoginMode ? Color.white.opacity(0.2) : Color.clear)
                    )
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.white.opacity(0.1))
        )
    }
    
    // MARK: - Action Button
    private var actionButton: some View {
        Button(action: {
            if isLoginMode {
                viewModel.signIn(loginInput: loginInput, password: password)
            } else {
                viewModel.signUp(email: loginInput, password: password)
            }
        }) {
            HStack {
                if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.9)
                } else {
                    Text(isLoginMode ? "Sign In" : "Create Account")
                        .font(.system(size: 18, weight: .semibold))
                    
                    Image(systemName: "arrow.right")
                        .font(.system(size: 16, weight: .semibold))
                }
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(
                LinearGradient(
                    colors: [
                        Theme.Colors.primary.opacity(0.8),
                        Theme.Colors.secondary.opacity(0.8)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(27)
            .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
        }
        .disabled(!viewModel.canSubmit(loginInput: loginInput, password: password, isLoginMode: isLoginMode))
        .scaleEffect(viewModel.canSubmit(loginInput: loginInput, password: password, isLoginMode: isLoginMode) ? 1.0 : 0.95)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: viewModel.canSubmit(loginInput: loginInput, password: password, isLoginMode: isLoginMode))
    }
    
    // MARK: - Social Login
    private var socialLoginSection: some View {
        VStack(spacing: 16) {
            HStack {
                Rectangle()
                    .fill(Color.white.opacity(0.3))
                    .frame(height: 1)
                
                Text("or continue with")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.8))
                    .padding(.horizontal, 16)
                
                Rectangle()
                    .fill(Color.white.opacity(0.3))
                    .frame(height: 1)
            }
            
            HStack(spacing: 16) {
                // Apple Sign In
                SignInWithAppleButton(.signIn) { request in
                    viewModel.handleAppleSignIn(request)
                } onCompletion: { result in
                    viewModel.handleAppleSignInResult(result)
                }
                .signInWithAppleButtonStyle(.white)
                .frame(height: 50)
                
                // Google Sign In (placeholder)
                Button(action: {
                    viewModel.signInWithGoogle()
                }) {
                    HStack {
                        Image(systemName: "globe")
                            .font(.system(size: 18))
                        Text("Google")
                            .font(.system(size: 16, weight: .medium))
                    }
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.white)
                    .cornerRadius(8)
                }
            }
        }
    }
    
    // MARK: - Mode Switch Button
    private var modeSwitchButton: some View {
        Button(action: {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                isLoginMode.toggle()
            }
        }) {
            HStack(spacing: 4) {
                Text(isLoginMode ? "Don't have an account?" : "Already have an account?")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.8))
                
                Text(isLoginMode ? "Sign Up" : "Sign In")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
            }
        }
    }
    
    // MARK: - Helper Functions
    private func startBackgroundAnimation() {
        withAnimation(.easeInOut(duration: 1)) {
            animateBackground = true
        }
    }
}

// MARK: - Custom Form Components
struct SocialTextField: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    let icon: String
    let keyboardType: UIKeyboardType
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.9))
            
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(.white.opacity(0.7))
                    .frame(width: 20)
                
                TextField(placeholder, text: $text)
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                    .keyboardType(keyboardType)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
            )
        }
    }
}

struct SocialSecureField: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    @Binding var showPassword: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.9))
            
            HStack(spacing: 12) {
                Image(systemName: "lock.circle.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.white.opacity(0.7))
                    .frame(width: 20)
                
                Group {
                    if showPassword {
                        TextField(placeholder, text: $text)
                    } else {
                        SecureField(placeholder, text: $text)
                    }
                }
                .font(.system(size: 16))
                .foregroundColor(.white)
                
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        showPassword.toggle()
                    }
                }) {
                    Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
            )
        }
    }
}

struct SocialDatePicker: View {
    let title: String
    @Binding var selection: Date
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.9))
            
            HStack(spacing: 12) {
                Image(systemName: "calendar.circle.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.white.opacity(0.7))
                    .frame(width: 20)
                
                DatePicker(
                    "",
                    selection: $selection,
                    in: ...Date(),
                    displayedComponents: .date
                )
                .datePickerStyle(CompactDatePickerStyle())
                .colorScheme(.dark)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
            )
        }
    }
}

#Preview {
    SocialLoginView()
}