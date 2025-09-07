//
//  ProfessionalLoginView.swift
//  Brrow
//
//  Production-Ready Professional Login Screen
//

import SwiftUI
import AuthenticationServices

struct ProfessionalLoginView: View {
    @StateObject private var viewModel = LoginViewModel()
    @EnvironmentObject var authManager: AuthManager
    @State private var isShowingSignUp = false
    @State private var showingForgotPassword = false
    @FocusState private var focusedField: Field?
    
    enum Field {
        case email, password
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                Color(UIColor.systemBackground)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 32) {
                        // Logo and title
                        VStack(spacing: 16) {
                            Image(systemName: "bag.fill")
                                .font(.system(size: 64))
                                .foregroundColor(Theme.Colors.primary)
                                .padding(.top, 60)
                            
                            Text("Brrow")
                                .font(.system(size: 42, weight: .bold, design: .rounded))
                                .foregroundColor(.primary)
                            
                            Text("Borrow, lend, and share with your community")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        
                        // Login form
                        VStack(spacing: 16) {
                            // Email/Username field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Email or Username")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .textCase(.uppercase)
                                
                                HStack {
                                    Image(systemName: "person.circle")
                                        .foregroundColor(.secondary)
                                        .frame(width: 20)
                                    
                                    TextField("Email or username", text: $viewModel.email)
                                        .textFieldStyle(.plain)
                                        .autocapitalization(.none)
                                        .keyboardType(.emailAddress)
                                        .textContentType(.username)
                                        .focused($focusedField, equals: .email)
                                        .submitLabel(.next)
                                        .onSubmit {
                                            focusedField = .password
                                        }
                                }
                                .padding()
                                .background(Color(UIColor.secondarySystemBackground))
                                .cornerRadius(10)
                            }
                            
                            // Password field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Password")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .textCase(.uppercase)
                                
                                HStack {
                                    Image(systemName: "lock")
                                        .foregroundColor(.secondary)
                                        .frame(width: 20)
                                    
                                    if viewModel.showPassword {
                                        TextField("Password", text: $viewModel.password)
                                            .textFieldStyle(.plain)
                                            .textContentType(.password)
                                            .focused($focusedField, equals: .password)
                                            .submitLabel(.go)
                                            .onSubmit {
                                                login()
                                            }
                                    } else {
                                        SecureField("Password", text: $viewModel.password)
                                            .textFieldStyle(.plain)
                                            .textContentType(.password)
                                            .focused($focusedField, equals: .password)
                                            .submitLabel(.go)
                                            .onSubmit {
                                                login()
                                            }
                                    }
                                    
                                    Button(action: { viewModel.showPassword.toggle() }) {
                                        Image(systemName: viewModel.showPassword ? "eye.slash" : "eye")
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .padding()
                                .background(Color(UIColor.secondarySystemBackground))
                                .cornerRadius(10)
                            }
                            
                            // Forgot password
                            HStack {
                                Spacer()
                                Button("Forgot Password?") {
                                    showingForgotPassword = true
                                }
                                .font(.footnote)
                                .foregroundColor(Theme.Colors.primary)
                            }
                        }
                        .padding(.horizontal)
                        
                        // Login button
                        Button(action: login) {
                            Group {
                                if viewModel.isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                } else {
                                    Text("Sign In")
                                        .fontWeight(.semibold)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .foregroundColor(.white)
                            .background(Theme.Colors.primary)
                            .cornerRadius(10)
                        }
                        .disabled(viewModel.isLoading || viewModel.email.isEmpty || viewModel.password.isEmpty)
                        .padding(.horizontal)
                        
                        // Divider
                        HStack {
                            Rectangle()
                                .fill(Color(UIColor.separator))
                                .frame(height: 1)
                            
                            Text("OR")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 8)
                            
                            Rectangle()
                                .fill(Color(UIColor.separator))
                                .frame(height: 1)
                        }
                        .padding(.horizontal)
                        
                        // Social sign in options
                        VStack(spacing: 12) {
                            // Sign in with Apple
                            SignInWithAppleButton(
                                .signIn,
                                onRequest: { request in
                                    request.requestedScopes = [.fullName, .email]
                                },
                                onCompletion: { result in
                                    handleAppleSignIn(result)
                                }
                            )
                            .signInWithAppleButtonStyle(.black)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .cornerRadius(10)
                        }
                        .padding(.horizontal)
                        
                        // Sign up link
                        HStack {
                            Text("Don't have an account?")
                                .foregroundColor(.secondary)
                            
                            Button("Sign Up") {
                                isShowingSignUp = true
                            }
                            .foregroundColor(Theme.Colors.primary)
                            .fontWeight(.semibold)
                        }
                        .font(.footnote)
                        
                        // Guest browsing option - moved up right under sign up
                        Button(action: {
                            authManager.loginAsGuest()
                        }) {
                            Text("Browse as Guest")
                                .font(.footnote)
                                .foregroundColor(.secondary)
                                .underline()
                        }
                        .padding(.top, 8)
                        
                        // Bottom spacer for safe area
                        Spacer()
                            .frame(height: 40)
                    }
                }
            }
            .navigationBarHidden(true)
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage)
            }
            .sheet(isPresented: $isShowingSignUp) {
                ProfessionalSignUpView()
            }
            .sheet(isPresented: $showingForgotPassword) {
                ForgotPasswordView()
            }
        }
    }
    
    private func login() {
        // Dismiss keyboard to avoid any potential NaN issues
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        
        Task {
            await viewModel.login()
        }
    }
    
    private func handleAppleSignIn(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let auth):
            guard let appleIDCredential = auth.credential as? ASAuthorizationAppleIDCredential else {
                viewModel.errorMessage = "Invalid Apple credentials"
                viewModel.showError = true
                return
            }
            
            // Extract user info
            let userIdentifier = appleIDCredential.user
            let email = appleIDCredential.email
            let fullName = appleIDCredential.fullName
            let identityToken = appleIDCredential.identityToken
            
            // Convert identity token to string
            guard let identityToken = identityToken,
                  let tokenString = String(data: identityToken, encoding: .utf8) else {
                viewModel.errorMessage = "Failed to get identity token"
                viewModel.showError = true
                return
            }
            
            // Create full name string
            let firstName = fullName?.givenName
            let lastName = fullName?.familyName
            
            // Sign in with Apple
            Task {
                await viewModel.signInWithApple(
                    userIdentifier: userIdentifier,
                    email: email,
                    firstName: firstName,
                    lastName: lastName,
                    identityToken: tokenString
                )
            }
            
        case .failure(let error):
            viewModel.errorMessage = error.localizedDescription
            viewModel.showError = true
        }
    }
}


#Preview {
    ProfessionalLoginView()
        .environmentObject(AuthManager.shared)
}