//
//  IdentityVerificationBanner.swift
//  Brrow
//
//  Created by Claude on 1/21/25.
//  Stripe Identity verification banner for profile and marketplace screens
//  Shows after email verification is complete to prompt for ID verification
//

import SwiftUI

struct IdentityVerificationBanner: View {
    @State private var isVisible = true
    @State private var animateGradient = false
    @State private var isVerifying = false
    @State private var showingVerificationFlow = false
    let onDismiss: () -> Void

    var body: some View {
        if isVisible {
            VStack(spacing: 0) {
                HStack(spacing: 12) {
                    // Animated shield icon
                    Image(systemName: "checkmark.shield.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                        .scaleEffect(animateGradient ? 1.1 : 1.0)
                        .animation(
                            .easeInOut(duration: 1.5).repeatForever(autoreverses: true),
                            value: animateGradient
                        )

                    VStack(alignment: .leading, spacing: 3) {
                        Text("Get Verified")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)

                        Text("Help keep Brrow safe and secure")
                            .font(.footnote)
                            .foregroundColor(.white.opacity(0.95))
                    }

                    Spacer()

                    // Action buttons
                    HStack(spacing: 12) {
                        Button(action: {
                            guard !isVerifying else { return }
                            isVerifying = true
                            HapticManager.impact(style: .medium)
                            showingVerificationFlow = true

                            // Reset verifying state
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                isVerifying = false
                            }
                        }) {
                            if isVerifying {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: Theme.Colors.primary))
                                    .scaleEffect(0.9)
                                    .frame(width: 100, height: 38)
                            } else {
                                Text("Verify Now")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(Theme.Colors.primary)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 10)
                            }
                        }
                        .background(Color.white)
                        .cornerRadius(22)
                        .disabled(isVerifying)

                        Button(action: {
                            HapticManager.impact(style: .light)
                            withAnimation(.spring()) {
                                isVisible = false
                            }
                            onDismiss()
                        }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 28, height: 28)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    LinearGradient(
                        colors: [
                            Theme.Colors.primary, // Brrow green
                            Theme.Colors.primary.opacity(0.8)
                        ],
                        startPoint: animateGradient ? .topLeading : .bottomLeading,
                        endPoint: animateGradient ? .bottomTrailing : .topTrailing
                    )
                    .animation(
                        .easeInOut(duration: 3).repeatForever(autoreverses: true),
                        value: animateGradient
                    )
                )
                .cornerRadius(14)
                .shadow(color: Theme.Colors.primary.opacity(0.25), radius: 6, x: 0, y: 3)
            }
            .padding(.horizontal, 16)
            .padding(.top, 6)
            .onAppear {
                animateGradient = true
            }
            .transition(.asymmetric(
                insertion: .move(edge: .top).combined(with: .opacity),
                removal: .move(edge: .top).combined(with: .opacity)
            ))
            .sheet(isPresented: $showingVerificationFlow) {
                IdentityVerificationIntroView()
            }
        }
    }
}

// MARK: - Usage Helper
extension View {
    /// Displays identity verification banner if conditions are met
    /// - Parameters:
    ///   - showBanner: Whether to show the banner (email verified but not ID verified)
    ///   - onDismiss: Callback when banner is dismissed
    func identityVerificationBanner(
        showBanner: Bool,
        onDismiss: @escaping () -> Void = {}
    ) -> some View {
        VStack(spacing: 0) {
            if showBanner {
                IdentityVerificationBanner(onDismiss: onDismiss)
            }

            self
        }
    }
}

// MARK: - Preview
struct IdentityVerificationBanner_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            IdentityVerificationBanner(
                onDismiss: {
                    print("Banner dismissed")
                }
            )

            Spacer()
        }
        .background(Color.gray.opacity(0.1))
        .previewLayout(.sizeThatFits)
    }
}
