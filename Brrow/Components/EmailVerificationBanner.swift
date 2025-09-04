//
//  EmailVerificationBanner.swift
//  Brrow
//
//  Email verification banner for profile and settings screens
//

import SwiftUI

struct EmailVerificationBanner: View {
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
                    // Animated warning icon
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                        .scaleEffect(animateGradient ? 1.1 : 1.0)
                        .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: animateGradient)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Verify Your Email")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        
                        Text("Get a verified badge and build trust with other users")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.9))
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
                                        message: "You can send another verification email in \(remainingTime) seconds"
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
                                    .progressViewStyle(CircularProgressViewStyle(tint: Color(hex: "#FF9500")))
                                    .scaleEffect(0.8)
                                    .frame(width: 60, height: 30)
                            } else {
                                Text("Verify")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(Color(hex: "#FF9500"))
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
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
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [
                            Color(hex: "#FF9500"),
                            Color(hex: "#FF7A00")
                        ],
                        startPoint: animateGradient ? .topLeading : .bottomLeading,
                        endPoint: animateGradient ? .bottomTrailing : .topTrailing
                    )
                    .animation(.easeInOut(duration: 3).repeatForever(autoreverses: true), value: animateGradient)
                )
                .cornerRadius(16)
                .shadow(color: Color(hex: "#FF9500").opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
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
    func emailVerificationBanner(
        showBanner: Bool,
        onVerifyTapped: @escaping () -> Void,
        onDismiss: @escaping () -> Void = {}
    ) -> some View {
        VStack(spacing: 0) {
            if showBanner {
                EmailVerificationBanner(
                    onVerifyTapped: onVerifyTapped,
                    onDismiss: onDismiss
                )
            }
            
            self
        }
    }
}

// MARK: - Preview
struct EmailVerificationBanner_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            EmailVerificationBanner(
                onVerifyTapped: {
                    print("Verify tapped")
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