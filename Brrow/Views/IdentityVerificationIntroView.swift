//
//  IdentityVerificationIntroView.swift
//  Brrow
//
//  Created by Claude on 1/21/25.
//  Welcome screen for Stripe Identity verification
//

import SwiftUI

struct IdentityVerificationIntroView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authManager: AuthManager
    @State private var showingGuide = false
    @State private var animateShield = false
    @State private var animateCheckmarks = false
    @State private var showEmailVerificationAlert = false

    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [
                        Theme.Colors.primary.opacity(0.05),
                        Color.white
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 32) {
                        // Hero Icon
                        ZStack {
                            // Pulsing background
                            Circle()
                                .fill(Theme.Colors.primary.opacity(0.1))
                                .frame(width: 140, height: 140)
                                .scaleEffect(animateShield ? 1.1 : 1.0)
                                .animation(
                                    Animation.easeInOut(duration: 2.0)
                                        .repeatForever(autoreverses: true),
                                    value: animateShield
                                )

                            // Shield icon
                            Image(systemName: "checkmark.shield.fill")
                                .font(.system(size: 64))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [Theme.Colors.primary, Theme.Colors.primary.opacity(0.7)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .scaleEffect(animateShield ? 1.05 : 1.0)
                                .animation(
                                    Animation.easeInOut(duration: 2.0)
                                        .repeatForever(autoreverses: true),
                                    value: animateShield
                                )
                        }
                        .padding(.top, 40)

                        // Title
                        VStack(spacing: 12) {
                            Text("Verify Your Identity")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(.primary)

                            Text("Join our trusted community")
                                .font(.system(size: 17))
                                .foregroundColor(.secondary)
                        }
                        .multilineTextAlignment(.center)

                        // Benefits
                        VStack(spacing: 20) {
                            IdentityBenefitRow(
                                icon: "star.fill",
                                title: "Unlock Full Access",
                                description: "Get the blue verified badge and access all features",
                                animate: animateCheckmarks,
                                delay: 0.1
                            )

                            IdentityBenefitRow(
                                icon: "shield.checkered",
                                title: "Build Trust",
                                description: "Show others you're a verified, trustworthy member",
                                animate: animateCheckmarks,
                                delay: 0.2
                            )

                            IdentityBenefitRow(
                                icon: "lock.shield.fill",
                                title: "Secure & Private",
                                description: "Your data is encrypted and never shared",
                                animate: animateCheckmarks,
                                delay: 0.3
                            )

                            IdentityBenefitRow(
                                icon: "clock.fill",
                                title: "Takes 2 Minutes",
                                description: "Quick and easy verification process",
                                animate: animateCheckmarks,
                                delay: 0.4
                            )
                        }
                        .padding(.horizontal)

                        // What's Required Section
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Image(systemName: "info.circle.fill")
                                    .foregroundColor(Theme.Colors.primary)
                                Text("What You'll Need")
                                    .font(.system(size: 18, weight: .semibold))
                            }

                            VStack(alignment: .leading, spacing: 12) {
                                IdentityRequirementRow(icon: "doc.text.fill", text: "Government-issued ID (Driver's License, Passport, or ID Card)")
                                IdentityRequirementRow(icon: "camera.fill", text: "Camera for live selfie verification")
                                IdentityRequirementRow(icon: "lightbulb.fill", text: "Good lighting for clear photos")
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(.systemBackground))
                                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 2)
                        )
                        .padding(.horizontal)

                        // Cost Information
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(Theme.Colors.primary)
                            Text("100% Free")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 8)

                        Spacer(minLength: 20)

                        // CTA Button
                        Button(action: {
                            // Check email verification before proceeding
                            if authManager.currentUser?.emailVerified == true {
                                showingGuide = true
                            } else {
                                showEmailVerificationAlert = true
                            }
                        }) {
                            HStack(spacing: 12) {
                                Text("Get Started")
                                    .font(.system(size: 18, weight: .semibold))
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                LinearGradient(
                                    colors: [Theme.Colors.primary, Theme.Colors.primary.opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(16)
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 32)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(Theme.Colors.primary)
                }
            }
            .sheet(isPresented: $showingGuide) {
                IdentityVerificationGuideView()
            }
            .alert("Email Verification Required", isPresented: $showEmailVerificationAlert) {
                Button("Verify Email", role: .none) {
                    // Navigate to email verification
                    dismiss()
                    NotificationCenter.default.post(name: .openEmailVerification, object: nil)
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("You must verify your email address before verifying your identity. This helps us ensure account security and prevents fraud.")
            }
        }
        .onAppear {
            animateShield = true
            withAnimation(.easeOut(duration: 0.6).delay(0.3)) {
                animateCheckmarks = true
            }
        }
    }
}

// MARK: - Notification Extension
extension Notification.Name {
    static let openEmailVerification = Notification.Name("openEmailVerification")
}

// MARK: - Benefit Row Component
struct IdentityBenefitRow: View {
    let icon: String
    let title: String
    let description: String
    let animate: Bool
    let delay: Double

    @State private var appeared = false

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(Theme.Colors.primary.opacity(0.1))
                    .frame(width: 48, height: 48)

                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(Theme.Colors.primary)
            }
            .scaleEffect(appeared ? 1.0 : 0.5)
            .opacity(appeared ? 1.0 : 0.0)

            // Text
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)

                Text(description)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .offset(x: appeared ? 0 : 20)
            .opacity(appeared ? 1.0 : 0.0)

            Spacer()
        }
        .onChange(of: animate) { newValue in
            if newValue {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(delay)) {
                    appeared = true
                }
            }
        }
    }
}

// MARK: - Requirement Row Component
struct IdentityRequirementRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Theme.Colors.primary)
                .frame(width: 20)

            Text(text)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

#Preview {
    IdentityVerificationIntroView()
}
