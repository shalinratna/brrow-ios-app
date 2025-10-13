//
//  PurchaseSuccessView.swift
//  Brrow
//
//  Epic Nike-style success screen with confetti animation
//

import SwiftUI
import AVFoundation
import AudioToolbox

struct PurchaseSuccessView: View {
    let listing: Listing
    let onContinue: () -> Void

    @State private var showConfetti = false
    @State private var showCheckmark = false
    @State private var showText = false
    @State private var pulseAnimation = false

    var body: some View {
        ZStack {
            // Background gradient - Vibrant emerald and teal
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(hex: "059669") ?? Theme.Colors.primary,  // Deep emerald green
                    Color(hex: "10B981") ?? Theme.Colors.primary,  // Emerald
                    Color(hex: "06B6D4") ?? .cyan,  // Vibrant cyan
                    Color(hex: "14B8A6") ?? .teal   // Teal
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // Confetti overlay
            if showConfetti {
                ConfettiView()
            }

            VStack(spacing: 30) {
                Spacer()

                // Animated checkmark with glow effects
                ZStack {
                    // Outer glow pulse
                    Circle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [
                                    (Color(hex: "10B981") ?? .green).opacity(0.4),
                                    Color.clear
                                ]),
                                center: .center,
                                startRadius: 0,
                                endRadius: 100
                            )
                        )
                        .frame(width: pulseAnimation ? 240 : 180, height: pulseAnimation ? 240 : 180)
                        .scaleEffect(pulseAnimation ? 1.3 : 1.0)
                        .opacity(pulseAnimation ? 0 : 0.6)

                    // Secondary pulse
                    Circle()
                        .fill(Color.white.opacity(0.3))
                        .frame(width: pulseAnimation ? 200 : 160, height: pulseAnimation ? 200 : 160)
                        .scaleEffect(pulseAnimation ? 1.2 : 1.0)
                        .opacity(pulseAnimation ? 0 : 1)

                    // Main circle with gradient
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [.white, Color(hex: "F0FDF4") ?? .white]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 160, height: 160)
                        .scaleEffect(showCheckmark ? 1.0 : 0.5)
                        .opacity(showCheckmark ? 1 : 0)

                    // Checkmark with vibrant green
                    Image(systemName: "checkmark")
                        .font(.system(size: 80, weight: .bold))
                        .foregroundStyle(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(hex: "10B981") ?? .green,
                                    Color(hex: "059669") ?? .green
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .scaleEffect(showCheckmark ? 1.0 : 0.5)
                        .opacity(showCheckmark ? 1 : 0)
                }
                .shadow(color: (Color(hex: "10B981") ?? .green).opacity(0.5), radius: 30)
                .shadow(color: .black.opacity(0.2), radius: 20)

                // Success text
                VStack(spacing: 12) {
                    Text("You Got It!")
                        .font(.system(size: 48, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                        .scaleEffect(showText ? 1.0 : 0.8)
                        .opacity(showText ? 1 : 0)

                    Text(listing.title)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .scaleEffect(showText ? 1.0 : 0.8)
                        .opacity(showText ? 1 : 0)
                        .padding(.horizontal, 40)

                    Text("Payment Secured • Seller Notified")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                        .scaleEffect(showText ? 1.0 : 0.8)
                        .opacity(showText ? 1 : 0)
                }

                Spacer()

                // Continue button
                Button(action: {
                    onContinue()
                }) {
                    HStack(spacing: 12) {
                        Text("View Receipt")
                            .font(.system(size: 20, weight: .bold))
                        Image(systemName: "arrow.right")
                            .font(.system(size: 18, weight: .bold))
                    }
                    .foregroundColor(Color(hex: "059669") ?? Theme.Colors.primary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 60)
                    .background(
                        RoundedRectangle(cornerRadius: 30)
                            .fill(Color.white)
                            .shadow(color: (Color(hex: "10B981") ?? .green).opacity(0.3), radius: 15)
                            .shadow(color: .black.opacity(0.1), radius: 5)
                    )
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 50)
                .scaleEffect(showText ? 1.0 : 0.8)
                .opacity(showText ? 1 : 0)
            }
        }
        .onAppear {
            // Play success sound (cha-ching)
            AudioServicesPlaySystemSound(1054) // Payment success sound

            // Haptic feedback - stronger impact
            let impactGenerator = UIImpactFeedbackGenerator(style: .heavy)
            impactGenerator.impactOccurred()

            // Additional success notification feedback
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                let notificationGenerator = UINotificationFeedbackGenerator()
                notificationGenerator.notificationOccurred(.success)
            }

            // Animate in sequence
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                showCheckmark = true
            }

            // Start pulse animation
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: false)) {
                pulseAnimation = true
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                showConfetti = true

                withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.2)) {
                    showText = true
                }
            }
        }
    }
}

#Preview {
    PurchaseSuccessView(listing: Listing.example) {
        print("Continue tapped")
    }
}
