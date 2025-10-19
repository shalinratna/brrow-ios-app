//
//  IDmeVerificationBanner.swift
//  Brrow
//
//  ID.me verification banner for profile and marketplace screens
//  Shows after email verification is complete
//

import SwiftUI

struct IDmeVerificationBanner: View {
    @State private var isVisible = true
    @State private var animateGradient = false
    @State private var isVerifying = false
    @State private var lastVerificationTime: Date?
    private let verificationCooldown: TimeInterval = 60 // 60 seconds cooldown
    let onVerifyTapped: () -> Void
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
                        .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: animateGradient)

                    VStack(alignment: .leading, spacing: 3) {
                        Text("Get Verified")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)

                        Text("Unlock full access")
                            .font(.footnote)
                            .foregroundColor(.white.opacity(0.95))
                    }

                    Spacer()

                    // Action buttons
                    HStack(spacing: 12) {
                        Button(action: {
                            // Check if we're in cooldown period
                            if let lastTime = lastVerificationTime {
                                let timeSinceLastVerification = Date().timeIntervalSince(lastTime)
                                if timeSinceLastVerification < verificationCooldown {
                                    let remainingTime = Int(verificationCooldown - timeSinceLastVerification)
                                    ToastManager.shared.showWarning(
                                        title: "Please Wait",
                                        message: "You can start verification again in \(remainingTime) seconds"
                                    )
                                    return
                                }
                            }

                            // Prevent multiple taps
                            guard !isVerifying else { return }

                            isVerifying = true
                            lastVerificationTime = Date()
                            HapticManager.impact(style: .medium)
                            onVerifyTapped()

                            // Reset the verifying state after 3 seconds
                            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                isVerifying = false
                            }
                        }) {
                            if isVerifying {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: Color(hex: "#7C3AED")))
                                    .scaleEffect(0.8)
                                    .frame(width: 90, height: 30)
                            } else {
                                Text("Verify Now")
                                    .font(.footnote)
                                    .fontWeight(.bold)
                                    .foregroundColor(Color(hex: "#7C3AED"))
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 7)
                            }
                        }
                        .background(Color.white)
                        .cornerRadius(20)
                        .disabled(isVerifying)

                        Button(action: {
                            HapticManager.impact(style: .light)
                            withAnimation(.spring()) {
                                isVisible = false
                            }
                            onDismiss()
                        }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(width: 24, height: 24)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    LinearGradient(
                        colors: [
                            Color(hex: "#7C3AED"), // Purple
                            Color(hex: "#4F46E5")  // Indigo/Blue
                        ],
                        startPoint: animateGradient ? .topLeading : .bottomLeading,
                        endPoint: animateGradient ? .bottomTrailing : .topTrailing
                    )
                    .animation(.easeInOut(duration: 3).repeatForever(autoreverses: true), value: animateGradient)
                )
                .cornerRadius(14)
                .shadow(color: Color(hex: "#7C3AED").opacity(0.25), radius: 6, x: 0, y: 3)
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
        }
    }
}

// MARK: - Usage Helper
extension View {
    func idmeVerificationBanner(
        showBanner: Bool,
        onVerifyTapped: @escaping () -> Void,
        onDismiss: @escaping () -> Void = {}
    ) -> some View {
        VStack(spacing: 0) {
            if showBanner {
                IDmeVerificationBanner(
                    onVerifyTapped: onVerifyTapped,
                    onDismiss: onDismiss
                )
            }

            self
        }
    }
}

// MARK: - Preview
struct IDmeVerificationBanner_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            IDmeVerificationBanner(
                onVerifyTapped: {
                    print("Verify with ID.me tapped")
                },
                onDismiss: {
                    print("Dismissed")
                }
            )

            Spacer()
        }
        .background(Color.gray.opacity(0.1))
        .previewLayout(.sizeThatFits)
    }
}
