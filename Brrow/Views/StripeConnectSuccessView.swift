//
//  StripeConnectSuccessView.swift
//  Brrow
//
//  Success animation view for Stripe Connect onboarding completion
//

import SwiftUI

struct StripeConnectSuccessView: View {
    @State private var animateCheckmark = false
    @State private var animateText = false
    @State private var animateBackground = false
    let onComplete: () -> Void

    var body: some View {
        ZStack {
            // Animated background - Stripe blue/green gradient
            LinearGradient(
                colors: [
                    Color(hexString: "635BFF"), // Stripe purple
                    Color(hexString: "00D924")  // Success green
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .scaleEffect(animateBackground ? 1.2 : 1.0)
            .animation(.easeInOut(duration: 0.8), value: animateBackground)

            VStack(spacing: 32) {
                // Success checkmark
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 120, height: 120)
                        .scaleEffect(animateCheckmark ? 1.0 : 0.5)

                    Circle()
                        .fill(Color.white.opacity(0.3))
                        .frame(width: 100, height: 100)
                        .scaleEffect(animateCheckmark ? 1.0 : 0.3)

                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 50, weight: .bold))
                        .foregroundColor(.white)
                        .scaleEffect(animateCheckmark ? 1.0 : 0.1)
                }
                .animation(.spring(response: 0.6, dampingFraction: 0.6).delay(0.2), value: animateCheckmark)

                // Success text
                VStack(spacing: 12) {
                    Text("You're All Set! 🎉")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                        .opacity(animateText ? 1 : 0)
                        .offset(y: animateText ? 0 : 20)

                    Text("Your Stripe account is connected.\nYou can now receive payouts from sales!")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .opacity(animateText ? 1 : 0)
                        .offset(y: animateText ? 0 : 20)

                    // Additional info
                    VStack(spacing: 8) {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.shield.fill")
                                .font(.system(size: 16))
                            Text("Payments are secure")
                        }
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.85))

                        HStack(spacing: 8) {
                            Image(systemName: "dollarsign.circle.fill")
                                .font(.system(size: 16))
                            Text("Automatic bank transfers")
                        }
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.85))
                    }
                    .padding(.top, 16)
                    .opacity(animateText ? 1 : 0)
                }
                .animation(.easeOut(duration: 0.8).delay(0.6), value: animateText)
            }
            .padding(.horizontal, 32)
        }
        .ignoresSafeArea()
        .onAppear {
            startAnimations()

            // Auto-dismiss after animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
                onComplete()
            }
        }
    }

    private func startAnimations() {
        withAnimation {
            animateBackground = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation {
                animateCheckmark = true
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation {
                animateText = true
            }
        }
    }
}

#Preview {
    StripeConnectSuccessView {
        print("Stripe Connect success animation complete")
    }
}
