//
//  WelcomeOnboardingView.swift
//  Brrow
//
//  Beautiful first-time welcome screen shown after successful registration
//

import SwiftUI

struct WelcomeOnboardingView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var animateContent = false
    @State private var rotationDegrees: Double = 0
    @State private var pulseScale: CGFloat = 1.0
    @State private var showButton = false
    @State private var shimmerOffset: CGFloat = -200

    var body: some View {
        ZStack {
            // Animated background gradient
            backgroundGradient

            // Main content
            VStack(spacing: 40) {
                Spacer()

                // Spinning logo animation
                logoSection

                // Welcome text
                textSection

                Spacer()

                // Ready button
                readyButton
                    .opacity(showButton ? 1 : 0)
                    .offset(y: showButton ? 0 : 20)

                Spacer(minLength: 60)
            }
            .padding(.horizontal, 32)
        }
        .ignoresSafeArea()
        .onAppear {
            startAnimations()
        }
    }

    // MARK: - View Components

    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                Theme.Colors.primary.opacity(0.15),
                Theme.Colors.primary.opacity(0.05),
                Color(.systemBackground),
                Theme.Colors.primary.opacity(0.05)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var logoSection: some View {
        ZStack {
            // Outer rotating ring
            Circle()
                .stroke(
                    AngularGradient(
                        colors: [
                            Theme.Colors.primary.opacity(0.3),
                            Theme.Colors.primary,
                            Theme.Colors.primary.opacity(0.3)
                        ],
                        center: .center,
                        startAngle: .degrees(0),
                        endAngle: .degrees(360)
                    ),
                    lineWidth: 3
                )
                .frame(width: 140, height: 140)
                .rotationEffect(.degrees(rotationDegrees))

            // Middle pulsing ring
            Circle()
                .stroke(Theme.Colors.primary.opacity(0.2), lineWidth: 2)
                .frame(width: 110, height: 110)
                .scaleEffect(pulseScale)

            // Glowing background circle
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Theme.Colors.primary.opacity(0.15),
                            Theme.Colors.primary.opacity(0.05),
                            .clear
                        ],
                        center: .center,
                        startRadius: 20,
                        endRadius: 80
                    )
                )
                .frame(width: 160, height: 160)
                .scaleEffect(pulseScale)

            // App icon
            Image("AppIcon")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 90, height: 90)
                .cornerRadius(28)
                .shadow(color: Theme.Colors.primary.opacity(0.4), radius: 20, x: 0, y: 10)
                .scaleEffect(animateContent ? 1.0 : 0.5)
                .opacity(animateContent ? 1 : 0)
        }
    }

    private var textSection: some View {
        VStack(spacing: 20) {
            // Welcome to Brrow
            Text("Welcome to")
                .font(.system(size: 28, weight: .medium, design: .rounded))
                .foregroundColor(Theme.Colors.secondaryText)
                .opacity(animateContent ? 1 : 0)
                .offset(y: animateContent ? 0 : 20)

            // BRROW with shimmer effect
            ZStack {
                // Shimmer background
                Text("BRROW")
                    .font(.system(size: 56, weight: .black, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Theme.Colors.primary,
                                Theme.Colors.primary.opacity(0.8),
                                Theme.Colors.primary
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .overlay(
                        // Shimmer effect
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        .clear,
                                        .white.opacity(0.5),
                                        .clear
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: 100)
                            .offset(x: shimmerOffset)
                            .mask(
                                Text("BRROW")
                                    .font(.system(size: 56, weight: .black, design: .rounded))
                            )
                    )
                    .shadow(color: Theme.Colors.primary.opacity(0.3), radius: 15, x: 0, y: 8)
            }
            .opacity(animateContent ? 1 : 0)
            .scaleEffect(animateContent ? 1.0 : 0.8)

            // Are you ready text
            Text("Are you ready?")
                .font(.system(size: 22, weight: .semibold, design: .rounded))
                .foregroundColor(Theme.Colors.text)
                .opacity(animateContent ? 1 : 0)
                .offset(y: animateContent ? 0 : 20)

            // Tagline
            Text("Discover amazing items to borrow\nand earn by sharing what you have")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Theme.Colors.secondaryText)
                .multilineTextAlignment(.center)
                .opacity(animateContent ? 1 : 0)
                .offset(y: animateContent ? 0 : 20)
        }
    }

    private var readyButton: some View {
        Button(action: completeOnboarding) {
            HStack(spacing: 12) {
                Text("Yes, Let's Go!")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                Image(systemName: "arrow.right.circle.fill")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 64)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(
                        LinearGradient(
                            colors: [
                                Theme.Colors.primary,
                                Theme.Colors.primary.opacity(0.85)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: Theme.Colors.primary.opacity(0.4), radius: 20, x: 0, y: 10)
            )
        }
        .scaleEffect(showButton ? 1.0 : 0.9)
        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: showButton)
    }

    // MARK: - Animation Methods

    private func startAnimations() {
        // Logo scale and fade in
        withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
            animateContent = true
        }

        // Continuous rotation
        withAnimation(.linear(duration: 3.0).repeatForever(autoreverses: false)) {
            rotationDegrees = 360
        }

        // Pulse animation
        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
            pulseScale = 1.1
        }

        // Shimmer effect
        withAnimation(.linear(duration: 2.5).repeatForever(autoreverses: false).delay(0.5)) {
            shimmerOffset = 400
        }

        // Show button after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                showButton = true
            }
        }
    }

    private func completeOnboarding() {
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()

        // Mark onboarding as complete
        UserDefaults.standard.set(false, forKey: "shouldShowWelcomeOnboarding")

        // Navigate to home (auth state will update automatically)
        // No need to call any auth method - the view will dismiss naturally
    }
}

// MARK: - Preview
struct WelcomeOnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        WelcomeOnboardingView()
            .environmentObject(AuthManager.shared)
    }
}
