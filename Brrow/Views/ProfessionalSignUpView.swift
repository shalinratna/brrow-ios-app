//
//  ProfessionalSignUpView.swift
//  Brrow
//
//  Ultra-Modern Sign Up Screen with Beautiful Animations
//

import SwiftUI

struct ProfessionalSignUpView: View {
    @StateObject private var viewModel = SignUpViewModel()
    @Environment(\.dismiss) var dismiss
    @FocusState private var focusedField: Field?
    @State private var animateGradient = false
    @State private var showContent = false
    
    enum Field {
        case username, email, password, confirmPassword
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Dynamic animated gradient background
                SignUpAnimatedGradientBackground()
                
                ScrollView {
                    VStack(spacing: 32) {
                        // Modern floating header with animation
                        VStack(spacing: 16) {
                            // Animated welcome icon
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [Color.white.opacity(0.3), Color.white.opacity(0.1)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 80, height: 80)
                                    .blur(radius: 20)
                                
                                Image(systemName: "person.crop.circle.badge.plus")
                                    .font(.system(size: 40, weight: .light))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [.white, Color.white.opacity(0.8)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
                            }
                            .scaleEffect(showContent ? 1 : 0.5)
                            .opacity(showContent ? 1 : 0)
                            .animation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.2), value: showContent)
                            
                            VStack(spacing: 8) {
                                Text("Join Brrow")
                                    .font(.system(size: 32, weight: .bold, design: .rounded))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [.white, Color.white.opacity(0.9)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 2)
                                
                                Text("Create your account and start borrowing")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.white.opacity(0.8))
                                    .multilineTextAlignment(.center)
                            }
                            .offset(y: showContent ? 0 : 20)
                            .opacity(showContent ? 1 : 0)
                            .animation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.4), value: showContent)
                        }
                        .padding(.top, 40)
                        
                        // Modern glass morphism form
                        VStack(spacing: 20) {
                            // Username field
                            ModernInputField(
                                title: "Username",
                                text: $viewModel.username,
                                placeholder: "Choose a username",
                                icon: "person.circle.fill",
                                focusedField: $focusedField,
                                field: .username,
                                nextField: .email
                            )
                            .offset(y: showContent ? 0 : 30)
                            .opacity(showContent ? 1 : 0)
                            .animation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.6), value: showContent)
                            
                            // Email field
                            ModernInputField(
                                title: "Email",
                                text: $viewModel.email,
                                placeholder: "your@email.com",
                                icon: "envelope.circle.fill",
                                keyboardType: .emailAddress,
                                focusedField: $focusedField,
                                field: .email,
                                nextField: .password
                            )
                            .offset(y: showContent ? 0 : 30)
                            .opacity(showContent ? 1 : 0)
                            .animation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.7), value: showContent)
                            
                            // Password field
                            VStack(spacing: 12) {
                                SignUpModernSecureField(
                                    title: "Password",
                                    text: $viewModel.password,
                                    placeholder: "Create a secure password",
                                    icon: "lock.circle.fill",
                                    focusedField: $focusedField,
                                    field: .password,
                                    nextField: .confirmPassword
                                )
                                
                                // Modern password requirements
                                if !viewModel.password.isEmpty {
                                    VStack(spacing: 8) {
                                        ModernPasswordRequirement(text: "At least 8 characters", isMet: viewModel.password.count >= 8)
                                        ModernPasswordRequirement(text: "Contains uppercase letter", isMet: viewModel.password.contains(where: { $0.isUppercase }))
                                        ModernPasswordRequirement(text: "Contains lowercase letter", isMet: viewModel.password.contains(where: { $0.isLowercase }))
                                        ModernPasswordRequirement(text: "Contains number", isMet: viewModel.password.contains(where: { $0.isNumber }))
                                    }
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(.ultraThinMaterial)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 16)
                                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                            )
                                    )
                                    .animation(.spring(response: 0.6, dampingFraction: 0.8), value: viewModel.password)
                                }
                            }
                            .offset(y: showContent ? 0 : 30)
                            .opacity(showContent ? 1 : 0)
                            .animation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.8), value: showContent)
                            
                            // Confirm password field
                            SignUpModernSecureField(
                                title: "Confirm Password",
                                text: $viewModel.confirmPassword,
                                placeholder: "Confirm your password",
                                icon: "checkmark.circle.fill",
                                focusedField: $focusedField,
                                field: .confirmPassword,
                                nextField: nil
                            )
                            .offset(y: showContent ? 0 : 30)
                            .opacity(showContent ? 1 : 0)
                            .animation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.9), value: showContent)
                            
                            // Modern date picker
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Image(systemName: "calendar.circle.fill")
                                        .font(.title2)
                                        .foregroundStyle(
                                            LinearGradient(
                                                colors: [Color.white, Color.white.opacity(0.7)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                    
                                    Text("Date of Birth")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.white)
                                    
                                    Spacer()
                                    
                                    if let ageMessage = viewModel.ageValidationMessage {
                                        Text(ageMessage)
                                            .font(.caption)
                                            .foregroundColor(.red)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(Color.red.opacity(0.2))
                                            .cornerRadius(8)
                                    }
                                }
                                
                                DatePicker(
                                    "Date of Birth",
                                    selection: $viewModel.birthdate,
                                    in: ...Date(),
                                    displayedComponents: .date
                                )
                                .datePickerStyle(.compact)
                                .labelsHidden()
                                .colorScheme(.dark)
                                .accentColor(.white)
                            }
                            .padding(20)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(.ultraThinMaterial)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 20)
                                            .stroke(
                                                LinearGradient(
                                                    colors: [Color.white.opacity(0.3), Color.white.opacity(0.1)],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                ),
                                                lineWidth: 1
                                            )
                                    )
                            )
                            .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                            .offset(y: showContent ? 0 : 30)
                            .opacity(showContent ? 1 : 0)
                            .animation(.spring(response: 0.8, dampingFraction: 0.8).delay(1.0), value: showContent)
                        }
                        .padding(.horizontal, 24)
                        
                        // Modern terms and conditions
                        ModernTermsToggle(isAgreed: $viewModel.agreedToTerms)
                            .offset(y: showContent ? 0 : 30)
                            .opacity(showContent ? 1 : 0)
                            .animation(.spring(response: 0.8, dampingFraction: 0.8).delay(1.1), value: showContent)
                        
                        // Ultra-modern CTA button
                        Button(action: signUp) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(
                                        LinearGradient(
                                            colors: viewModel.isFormValid ? 
                                                [Color.white, Color.white.opacity(0.9)] :
                                                [Color.gray.opacity(0.6), Color.gray.opacity(0.4)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .shadow(color: .black.opacity(0.2), radius: 15, x: 0, y: 8)
                                
                                HStack(spacing: 12) {
                                    if viewModel.isLoading {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .black))
                                            .scaleEffect(0.8)
                                    } else {
                                        Image(systemName: "arrow.right.circle.fill")
                                            .font(.title2)
                                            .foregroundColor(.black.opacity(0.8))
                                        
                                        Text("Create Account")
                                            .font(.system(size: 18, weight: .bold))
                                            .foregroundColor(.black.opacity(0.9))
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 60)
                            }
                        }
                        .disabled(!viewModel.isFormValid || viewModel.isLoading)
                        .scaleEffect(viewModel.isLoading ? 0.95 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: viewModel.isLoading)
                        .padding(.horizontal, 24)
                        .offset(y: showContent ? 0 : 30)
                        .opacity(showContent ? 1 : 0)
                        .animation(.spring(response: 0.8, dampingFraction: 0.8).delay(1.2), value: showContent)
                        
                        // Modern sign in link
                        VStack(spacing: 16) {
                            // Divider with text
                            HStack {
                                Rectangle()
                                    .frame(height: 1)
                                    .foregroundColor(.white.opacity(0.3))
                                
                                Text("or")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white.opacity(0.7))
                                    .padding(.horizontal, 16)
                                
                                Rectangle()
                                    .frame(height: 1)
                                    .foregroundColor(.white.opacity(0.3))
                            }
                            .padding(.horizontal, 24)
                            
                            // Sign in button
                            Button(action: { dismiss() }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "person.crop.circle")
                                        .font(.title3)
                                    
                                    Text("Already have an account? Sign In")
                                        .font(.system(size: 16, weight: .semibold))
                                }
                                .foregroundColor(.white)
                                .padding(.vertical, 16)
                                .padding(.horizontal, 24)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(.ultraThinMaterial)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16)
                                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                        )
                                )
                            }
                        }
                        .offset(y: showContent ? 0 : 30)
                        .opacity(showContent ? 1 : 0)
                        .animation(.spring(response: 0.8, dampingFraction: 0.8).delay(1.3), value: showContent)
                        .padding(.bottom, 40)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarHidden(true)
            .onAppear {
                withAnimation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.1)) {
                    showContent = true
                }
            }
            .overlay(
                // Modern close button
                VStack {
                    HStack {
                        Spacer()
                        
                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title2)
                                .foregroundStyle(
                                    .ultraThinMaterial,
                                    LinearGradient(
                                        colors: [Color.white, Color.white.opacity(0.7)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 2)
                        }
                        .padding(.top, 50)
                        .padding(.trailing, 24)
                    }
                    
                    Spacer()
                }
            )
            .alert("Sign Up Error", isPresented: $viewModel.showError) {
                Button("Try Again", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage)
            }
        }
    }
    
    private func signUp() {
        Task {
            await viewModel.signUp()
            if viewModel.isSignedUp {
                dismiss()
            }
        }
    }
}

// MARK: - Modern UI Components

struct SignUpAnimatedGradientBackground: View {
    @State private var animateGradient = false
    
    var body: some View {
        LinearGradient(
            colors: [
                Color(red: 0.2, green: 0.6, blue: 0.4),
                Color(red: 0.1, green: 0.4, blue: 0.6),
                Color(red: 0.3, green: 0.5, blue: 0.7),
                Color(red: 0.2, green: 0.7, blue: 0.5)
            ],
            startPoint: animateGradient ? .topLeading : .bottomTrailing,
            endPoint: animateGradient ? .bottomTrailing : .topLeading
        )
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
                animateGradient.toggle()
            }
        }
    }
}

struct ModernInputField: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    let icon: String
    var keyboardType: UIKeyboardType = .default
    @FocusState.Binding var focusedField: ProfessionalSignUpView.Field?
    let field: ProfessionalSignUpView.Field
    let nextField: ProfessionalSignUpView.Field?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.white, Color.white.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
            }
            
            TextField(placeholder, text: $text)
                .font(.system(size: 16))
                .foregroundColor(.white)
                .accentColor(.white)
                .autocapitalization(field == .email ? .none : .sentences)
                .keyboardType(keyboardType)
                .textContentType(field == .email ? .emailAddress : field == .username ? .username : .none)
                .focused($focusedField, equals: field)
                .submitLabel(nextField != nil ? .next : .done)
                .onSubmit {
                    if let nextField = nextField {
                        focusedField = nextField
                    }
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(
                                    focusedField == field ?
                                        LinearGradient(
                                            colors: [Color.white.opacity(0.6), Color.white.opacity(0.3)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ) :
                                        LinearGradient(
                                            colors: [Color.white.opacity(0.3), Color.white.opacity(0.1)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                    lineWidth: focusedField == field ? 2 : 1
                                )
                        )
                )
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                .scaleEffect(focusedField == field ? 1.02 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: focusedField == field)
        }
    }
}

struct SignUpModernSecureField: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    let icon: String
    @FocusState.Binding var focusedField: ProfessionalSignUpView.Field?
    let field: ProfessionalSignUpView.Field
    let nextField: ProfessionalSignUpView.Field?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.white, Color.white.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
            }
            
            SecureField(placeholder, text: $text)
                .font(.system(size: 16))
                .foregroundColor(.white)
                .accentColor(.white)
                .textContentType(.newPassword)
                .focused($focusedField, equals: field)
                .submitLabel(nextField != nil ? .next : .done)
                .onSubmit {
                    if let nextField = nextField {
                        focusedField = nextField
                    }
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(
                                    focusedField == field ?
                                        LinearGradient(
                                            colors: [Color.white.opacity(0.6), Color.white.opacity(0.3)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ) :
                                        LinearGradient(
                                            colors: [Color.white.opacity(0.3), Color.white.opacity(0.1)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                    lineWidth: focusedField == field ? 2 : 1
                                )
                        )
                )
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                .scaleEffect(focusedField == field ? 1.02 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: focusedField == field)
        }
    }
}

struct ModernPasswordRequirement: View {
    let text: String
    let isMet: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(isMet ? Color.green : Color.white.opacity(0.2))
                    .frame(width: 20, height: 20)
                
                Image(systemName: isMet ? "checkmark" : "circle")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(isMet ? .white : Color.white.opacity(0.6))
            }
            .scaleEffect(isMet ? 1.1 : 1.0)
            .animation(.spring(response: 0.4, dampingFraction: 0.6), value: isMet)
            
            Text(text)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(isMet ? .white : Color.white.opacity(0.7))
                .animation(.easeInOut(duration: 0.3), value: isMet)
            
            Spacer()
        }
    }
}

struct ModernTermsToggle: View {
    @Binding var isAgreed: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            Toggle(isOn: $isAgreed) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Terms & Privacy")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    
                    HStack(spacing: 4) {
                        Text("I agree to the")
                            .foregroundColor(.white.opacity(0.7))
                        Button("Terms of Service") {
                            // Show terms
                        }
                        .foregroundColor(.white)
                        .fontWeight(.semibold)
                        Text("and")
                            .foregroundColor(.white.opacity(0.7))
                        Button("Privacy Policy") {
                            // Show privacy
                        }
                        .foregroundColor(.white)
                        .fontWeight(.semibold)
                    }
                    .font(.system(size: 14))
                }
            }
            .toggleStyle(SwitchToggleStyle(tint: .white))
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            LinearGradient(
                                colors: [Color.white.opacity(0.3), Color.white.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        .padding(.horizontal, 24)
    }
}

// MARK: - Sign Up View Model
class SignUpViewModel: ObservableObject {
    @Published var username = ""
    @Published var email = ""
    @Published var password = ""
    @Published var confirmPassword = ""
    @Published var birthdate = Date()
    @Published var agreedToTerms = false
    @Published var isLoading = false
    @Published var showError = false
    @Published var errorMessage = ""
    @Published var isSignedUp = false
    
    var isFormValid: Bool {
        !username.isEmpty &&
        !email.isEmpty &&
        isValidEmail(email) &&
        password.count >= 8 &&
        password == confirmPassword &&
        agreedToTerms &&
        isAtLeast13YearsOld()
    }
    
    var ageValidationMessage: String? {
        if !isAtLeast13YearsOld() {
            return "You must be at least 13 years old to create an account"
        }
        return nil
    }
    
    private func isAtLeast13YearsOld() -> Bool {
        let calendar = Calendar.current
        let now = Date()
        let ageComponents = calendar.dateComponents([.year], from: birthdate, to: now)
        let age = ageComponents.year ?? 0
        return age >= 13
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegex)
        return emailPred.evaluate(with: email)
    }
    
    @MainActor
    func signUp() async {
        // Validate age before making API call
        if !isAtLeast13YearsOld() {
            errorMessage = "You must be at least 13 years old to create an account"
            showError = true
            return
        }
        
        // Validate password match
        if password != confirmPassword {
            errorMessage = "Passwords do not match"
            showError = true
            return
        }
        
        // Validate email format
        if !isValidEmail(email) {
            errorMessage = "Please enter a valid email address"
            showError = true
            return
        }
        
        isLoading = true
        errorMessage = ""
        
        do {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let birthdateString = dateFormatter.string(from: birthdate)
            
            let response = try await APIClient.shared.register(
                username: username,
                email: email,
                password: password,
                birthdate: birthdateString
            )
            
            AuthManager.shared.handleAuthSuccess(response)
            isSignedUp = true
        } catch {
            // Parse error message from API if available
            if let apiError = error as? BrrowAPIError {
                switch apiError {
                case .serverError(let message):
                    errorMessage = message
                default:
                    errorMessage = "Failed to create account. Please try again."
                }
            } else {
                errorMessage = error.localizedDescription
            }
            showError = true
        }
        
        isLoading = false
    }
}

#Preview {
    ProfessionalSignUpView()
}