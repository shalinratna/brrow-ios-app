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
    @State private var hasInteractedWithPassword = false
    @State private var hasInteractedWithEmail = false
    @State private var hasInteractedWithUsername = false
    @State private var hasInteractedWithFirstName = false
    @State private var hasInteractedWithLastName = false
    @State private var isGoogleSignInLoading = false
    
    enum Field: Hashable {
        case email, username, password, firstName, lastName
    }
    
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                ScrollView {
                    VStack(spacing: 20) {
                        logoSection
                        formFieldsSection
                        errorMessageSection
                        actionButtonsSection
                        dividerSection
                        socialLoginSection
                        Spacer(minLength: 20)
                        footerSection
                    }
                    .frame(minHeight: geometry.size.height)
                }
                .background(backgroundGradient)
            }
            .navigationBarHidden(true)
            .opacity(animateContent ? 1 : 0.8)
            .animation(.easeOut(duration: 0.3), value: animateContent)
            .contentShape(Rectangle())
            .onTapGesture {
                if focusedField != nil {
                    hideKeyboard()
                }
            }
        }
        .alert("Special Username", isPresented: $viewModel.showSpecialUsernameAlert) {
            TextField("Access Code", text: $viewModel.specialUsernameCode)
                .textInputAutocapitalization(.never)
            Button("Submit") {
                viewModel.proceedWithSpecialRegistration()
            }
            Button("Cancel", role: .cancel) {
                viewModel.showSpecialUsernameAlert = false
                viewModel.specialUsernameCode = ""
            }
        } message: {
            Text("The username '\(viewModel.username)' requires a special access code to register.")
        }
    }
    
    // MARK: - View Components
    
    private var logoSection: some View {
        VStack(spacing: 15) {
            logoView
            titleView
        }
        .padding(.top, 30)
        .onAppear {
            withAnimation(.easeOut(duration: 0.5).delay(0.1)) {
                animateContent = true
            }
        }
    }
    
    private var logoView: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Theme.Colors.primary.opacity(0.1), Theme.Colors.primary.opacity(0.05)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 100, height: 100)
                .blur(radius: 20)

            Image("AppIcon")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 80, height: 80)
                .cornerRadius(24)
                .shadow(color: Theme.Colors.primary.opacity(0.3), radius: 15, x: 0, y: 8)
                .scaleEffect(logoScale)
                .onAppear {
                    animateLogo()
                }
        }
    }
    
    private var titleView: some View {
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
    
    private var formFieldsSection: some View {
        VStack(spacing: 15) {
            if isSignUpMode {
                usernameField
                emailField
            } else {
                emailField
            }
            passwordField
            if isSignUpMode {
                firstNameField
                lastNameField
                birthdateField
            }
        }
        .padding(.horizontal, 24)
    }
    
    private var emailField: some View {
        VStack(alignment: .leading, spacing: 4) {
            ModernTextField(
                title: isSignUpMode ? "Email" : "Email or Username",
                text: $viewModel.email,
                placeholder: isSignUpMode ? "Enter your email" : "Email or username",
                icon: isSignUpMode ? "envelope.fill" : "person.crop.circle",
                keyboardType: isSignUpMode ? .emailAddress : .default,
                isValid: !hasInteractedWithEmail || !viewModel.email.isEmpty,
                textContentType: isSignUpMode ? .emailAddress : nil
            )
            .focused($focusedField, equals: .email)
            .onChange(of: focusedField) { newValue in
                if newValue == .email {
                    hasInteractedWithEmail = true
                }
            }
            
            if hasInteractedWithEmail && viewModel.email.isEmpty && focusedField != nil {
                Text("Email is required")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Theme.Colors.error)
                    .padding(.leading, 4)
            }
        }
    }
    
    private var usernameField: some View {
        VStack(alignment: .leading, spacing: 4) {
            ModernTextField(
                title: "Username",
                text: $viewModel.username,
                placeholder: "Choose a username",
                icon: "person.fill",
                keyboardType: .default,
                isValid: !hasInteractedWithUsername || !viewModel.username.isEmpty
            )
            .focused($focusedField, equals: .username)
            .onChange(of: focusedField) { newValue in
                if newValue == .username {
                    hasInteractedWithUsername = true
                }
            }
            
            usernameValidationMessage
        }
    }
    
    @ViewBuilder
    private var usernameValidationMessage: some View {
        if hasInteractedWithUsername && focusedField != nil {
            if !viewModel.usernameValidationMessage.isEmpty {
                Text(viewModel.usernameValidationMessage)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Theme.Colors.error)
                    .padding(.leading, 4)
            } else if !viewModel.username.isEmpty && viewModel.isValidUsername {
                Text("✓ Username is available")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Theme.Colors.success)
                    .padding(.leading, 4)
            }
        }
    }
    
    private var passwordField: some View {
        VStack(alignment: .leading, spacing: 4) {
            ModernSecureField(
                title: "Password",
                text: $viewModel.password,
                placeholder: isSignUpMode ? "Create a password" : "Enter your password",
                showPassword: $showPassword,
                isValid: !hasInteractedWithPassword || (isSignUpMode ? viewModel.password.count >= 8 : !viewModel.password.isEmpty)
            )
            .focused($focusedField, equals: .password)
            .onChange(of: focusedField) { newValue in
                if newValue == .password {
                    hasInteractedWithPassword = true
                }
            }
            
            passwordValidationMessage
        }
    }
    
    @ViewBuilder
    private var passwordValidationMessage: some View {
        if isSignUpMode && hasInteractedWithPassword && viewModel.password.count < 8 && focusedField != nil {
            Text("Password must be at least 8 characters")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Theme.Colors.error)
                .padding(.leading, 4)
        } else if !isSignUpMode && hasInteractedWithPassword && viewModel.password.isEmpty && focusedField != nil {
            Text("Password is required")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Theme.Colors.error)
                .padding(.leading, 4)
        }
    }
    
    private var firstNameField: some View {
        VStack(alignment: .leading, spacing: 4) {
            ModernTextField(
                title: "First Name",
                text: $viewModel.firstName,
                placeholder: "Enter your first name",
                icon: "person.fill",
                keyboardType: .default,
                isValid: viewModel.errorMessage.isEmpty,
                textContentType: .givenName
            )
            .focused($focusedField, equals: .firstName)
            
            if focusedField == .firstName || focusedField == .lastName {
                privacyNotice
            }
        }
    }
    
    private var lastNameField: some View {
        VStack(alignment: .leading, spacing: 4) {
            ModernTextField(
                title: "Last Name",
                text: $viewModel.lastName,
                placeholder: "Enter your last name",
                icon: "person.fill",
                keyboardType: .default,
                isValid: viewModel.errorMessage.isEmpty,
                textContentType: .familyName
            )
            .focused($focusedField, equals: .lastName)
            
            if focusedField == .lastName {
                privacyNotice
            }
        }
    }
    
    private var privacyNotice: some View {
        Text("🔒 Your name will remain private on the platform")
            .font(.system(size: 11, weight: .medium))
            .foregroundColor(Theme.Colors.secondaryText)
            .padding(.leading, 4)
            .transition(.opacity)
    }
    
    private var birthdateField: some View {
        let age = Calendar.current.dateComponents([.year], from: viewModel.birthdate, to: Date()).year ?? 0
        return VStack(alignment: .leading, spacing: 4) {
            ModernTextField(
                title: "Date of Birth",
                text: $viewModel.birthdateText,
                placeholder: "MM/DD/YYYY",
                icon: "calendar",
                keyboardType: .numbersAndPunctuation,
                isValid: viewModel.birthdateText.isEmpty || age >= 13,
                textContentType: nil  // iOS doesn't have a specific birthdate content type, we'll use custom approach
            )
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .autocapitalization(.none)
            .disableAutocorrection(true)
            .onChange(of: viewModel.birthdateText) { newValue in
                viewModel.parseBirthdate(newValue)
            }
            
            if age < 13 && !viewModel.birthdateText.isEmpty {
                Text("You must be at least 13 years old")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Theme.Colors.error)
                    .padding(.leading, 4)
            }
        }
    }
    
    @ViewBuilder
    private var errorMessageSection: some View {
        if viewModel.showError && !viewModel.errorMessage.isEmpty {
            HStack {
                Image(systemName: "exclamationmark.circle.fill")
                    .foregroundColor(Theme.Colors.error)
                    .font(.system(size: 16))
                Text(viewModel.errorMessage)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Theme.Colors.error)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Theme.Colors.error.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Theme.Colors.error.opacity(0.3), lineWidth: 1)
                    )
            )
            .padding(.horizontal, 24)
            .transition(.asymmetric(
                insertion: .scale(scale: 0.8).combined(with: .opacity).animation(.spring(response: 0.4, dampingFraction: 0.8)),
                removal: .scale(scale: 0.9).combined(with: .opacity).animation(.easeOut(duration: 0.2))
            ))
        }
    }
    
    private var actionButtonsSection: some View {
        VStack(spacing: 16) {
            primaryActionButton
            toggleModeButton
        }
        .padding(.horizontal, 24)
    }
    
    private var primaryActionButton: some View {
        Button(action: performPrimaryAction) {
            ZStack {
                buttonBackground
                buttonContent
            }
            .frame(height: 56)
        }
        .disabled(viewModel.isLoading || !isFormValid)
        .opacity((viewModel.isLoading || !isFormValid) ? 0.7 : 1.0)
        .scaleEffect((viewModel.isLoading || !isFormValid) ? 0.98 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isFormValid)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: viewModel.isLoading)
        .buttonStyle(PlainButtonStyle())
        .onTapGesture {
            // Haptic feedback for better UX
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
        }
    }
    
    private var buttonBackground: some View {
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
    }
    
    private var buttonContent: some View {
        HStack {
            if viewModel.isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(0.8)
                    .transition(.scale.combined(with: .opacity))
            } else {
                Text(isSignUpMode ? "Sign Up" : "Sign In")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .foregroundColor(.white)
        .animation(.easeInOut(duration: 0.3), value: viewModel.isLoading)
    }
    
    private var toggleModeButton: some View {
        Button(action: toggleAuthMode) {
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
    
    private var dividerSection: some View {
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
    }
    
    private var socialLoginSection: some View {
        VStack(spacing: 14) {
            appleSignInButton
            googleSignInButton
            guestModeButton
        }
        .padding(.horizontal, 24)
    }
    
    private var appleSignInButton: some View {
        SignInWithAppleButton(
            isSignUpMode ? .signUp : .signIn,
            onRequest: { request in
                request.requestedScopes = [.fullName, .email]
                print("🍎 [APPLE SIGN-IN] Request initiated - Mode: \(isSignUpMode ? "Sign Up" : "Sign In")")
                print("🍎 [APPLE SIGN-IN] Requested scopes: fullName, email")
            },
            onCompletion: { result in
                print("🍎 [APPLE SIGN-IN] Completion handler called")
                print("🍎 [APPLE SIGN-IN] Result type: \(type(of: result))")
                handleAppleSignIn(result: result)
            }
        )
        .signInWithAppleButtonStyle(.black)
        .frame(height: 56)
        .cornerRadius(14)
        .disabled(viewModel.isLoading || isGoogleSignInLoading)
        .shadow(color: Color.black.opacity(0.15), radius: 6, x: 0, y: 3)
    }
    
    private var googleSignInButton: some View {
        Button(action: handleGoogleSignIn) {
            HStack(spacing: 12) {
                // Enhanced Google logo with better styling
                Group {
                    if UIImage(named: "google-logo") != nil {
                        Image("google-logo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 22, height: 22)
                    } else {
                        // Improved Google "G" logo
                        ZStack {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.white)
                                .frame(width: 22, height: 22)
                            Text("G")
                                .font(.system(size: 16, weight: .bold, design: .default))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [Color(red: 0.26, green: 0.52, blue: 0.96),
                                                Color(red: 0.22, green: 0.45, blue: 0.86)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        }
                    }
                }

                if isGoogleSignInLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .primary))
                        .scaleEffect(0.9)
                    Text("Signing in...")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.primary)
                } else {
                    Text("Continue with Google")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.primary)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(.systemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color(.systemGray4), lineWidth: 1.5)
                    )
            )
            .shadow(color: Color.black.opacity(0.12), radius: 8, x: 0, y: 4)
        }
        .scaleEffect(isGoogleSignInLoading || viewModel.isLoading ? 0.98 : 1.0)
        .disabled(isGoogleSignInLoading || viewModel.isLoading)
        .opacity(isGoogleSignInLoading || viewModel.isLoading ? 0.7 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isGoogleSignInLoading)
        .onTapGesture {
            // Haptic feedback for better UX
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
        }
    }
    
    private var guestModeButton: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                authManager.loginAsGuest()
            }
        }) {
            HStack(spacing: 12) {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(Theme.Colors.secondaryText.opacity(0.8))

                Text("Continue as Guest")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(Theme.Colors.secondaryText)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Theme.Colors.secondaryBackground.opacity(0.5))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Theme.Colors.border.opacity(0.6), lineWidth: 1)
                    )
            )
            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
        .disabled(viewModel.isLoading)
        .opacity(viewModel.isLoading ? 0.5 : 1.0)
    }
    
    private var guestButtonBackground: some View {
        RoundedRectangle(cornerRadius: 14)
            .fill(Theme.Colors.secondaryBackground)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Theme.Colors.border, lineWidth: 1)
            )
    }
    
    private var footerSection: some View {
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
        .padding(.bottom, 20)
    }
    
    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                Color(.systemBackground),
                Theme.Colors.primary.opacity(0.02)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
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
            return !viewModel.email.isEmpty && !viewModel.password.isEmpty
        }
    }
    
    private func animateLogo() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            logoScale = 1.05
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                logoScale = 1.0
            }
        }
    }
    
    private func performPrimaryAction() {
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
    }
    
    private func toggleAuthMode() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            isSignUpMode.toggle()
            viewModel.clearForm()
            resetInteractionFlags()
            animateContent = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeOut(duration: 0.3)) {
                    animateContent = true
                }
            }
        }
    }
    
    private func resetInteractionFlags() {
        hasInteractedWithEmail = false
        hasInteractedWithUsername = false
        hasInteractedWithPassword = false
        hasInteractedWithFirstName = false
        hasInteractedWithLastName = false
    }
    
    // MARK: - Apple Sign In
    private func handleGoogleSignIn() {
        print("🔵 Google Sign-In button tapped")

        withAnimation(.easeInOut(duration: 0.2)) {
            isGoogleSignInLoading = true
        }

        Task {
            print("🔵 Starting Google Sign-In...")
            await GoogleAuthService.shared.signIn()
            print("🔵 Google Sign-In completed")

            await MainActor.run {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isGoogleSignInLoading = false
                }
            }
        }
    }
    
    private func handleAppleSignIn(result: Result<ASAuthorization, Error>) {
        print("🍎 [APPLE SIGN-IN] handleAppleSignIn called")

        switch result {
        case .success(let authorization):
            print("🍎 [APPLE SIGN-IN] Authorization successful")
            print("🍎 [APPLE SIGN-IN] Credential type: \(type(of: authorization.credential))")

            Task {
                if let appleCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
                    print("🍎 [APPLE SIGN-IN] Apple credential extracted")

                    let firstName = appleCredential.fullName?.givenName
                    let lastName = appleCredential.fullName?.familyName
                    let email = appleCredential.email
                    let userIdentifier = appleCredential.user

                    print("🍎 [APPLE SIGN-IN] User ID: \(userIdentifier)")
                    print("🍎 [APPLE SIGN-IN] Email: \(email ?? "nil")")
                    print("🍎 [APPLE SIGN-IN] First Name: \(firstName ?? "nil")")
                    print("🍎 [APPLE SIGN-IN] Last Name: \(lastName ?? "nil")")

                    guard let identityToken = appleCredential.identityToken,
                          let tokenString = String(data: identityToken, encoding: .utf8) else {
                        print("❌ [APPLE SIGN-IN] Failed to extract identity token")
                        await MainActor.run {
                            viewModel.errorMessage = "Unable to process Apple Sign In"
                            viewModel.showError = true
                        }
                        return
                    }

                    print("🍎 [APPLE SIGN-IN] Identity token extracted (length: \(tokenString.count))")
                    print("🍎 [APPLE SIGN-IN] Calling viewModel.signInWithApple...")

                    await viewModel.signInWithApple(
                        userIdentifier: userIdentifier,
                        email: email,
                        firstName: firstName,
                        lastName: lastName,
                        identityToken: tokenString
                    )

                    print("🍎 [APPLE SIGN-IN] viewModel.signInWithApple completed")
                } else {
                    print("❌ [APPLE SIGN-IN] Failed to cast credential to ASAuthorizationAppleIDCredential")
                }
            }

        case .failure(let error):
            print("❌ [APPLE SIGN-IN] Authorization failed with error: \(error.localizedDescription)")

            if let authError = error as? ASAuthorizationError {
                print("❌ [APPLE SIGN-IN] ASAuthorizationError code: \(authError.code.rawValue)")

                switch authError.code {
                case .canceled:
                    print("ℹ️ [APPLE SIGN-IN] User canceled")
                    break
                case .failed:
                    print("❌ [APPLE SIGN-IN] Sign in failed")
                    viewModel.errorMessage = "Sign in failed. Please try again."
                    viewModel.showError = true
                case .invalidResponse:
                    print("❌ [APPLE SIGN-IN] Invalid response")
                    viewModel.errorMessage = "Invalid response from Apple. Please try again."
                    viewModel.showError = true
                case .notHandled:
                    print("❌ [APPLE SIGN-IN] Not handled")
                    viewModel.errorMessage = "Unable to complete sign in."
                    viewModel.showError = true
                case .unknown:
                    print("❌ [APPLE SIGN-IN] Unknown error")
                    viewModel.errorMessage = "An unknown error occurred."
                    viewModel.showError = true
                @unknown default:
                    print("❌ [APPLE SIGN-IN] Default error case")
                    viewModel.errorMessage = "Sign in failed."
                    viewModel.showError = true
                }
            } else {
                print("❌ [APPLE SIGN-IN] Generic error: \(error)")
                viewModel.errorMessage = error.localizedDescription
                viewModel.showError = true
            }
        }
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// MARK: - Modern Form Components
// Note: ModernTextField, ModernSecureField, ModernDatePicker, and SafariView are defined in LoginView.swift