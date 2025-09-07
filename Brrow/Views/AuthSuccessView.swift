//
//  AuthSuccessView.swift
//  Brrow
//
//  Success animation view for authentication
//

import SwiftUI

struct AuthSuccessView: View {
    @State private var animateCheckmark = false
    @State private var animateText = false
    @State private var animateBackground = false
    let onComplete: () -> Void
    
    var body: some View {
        ZStack {
            // Animated background
            LinearGradient(
                colors: [
                    Color(hexString: "43e97b"),
                    Color(hexString: "38f9d7")
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
                    
                    Image(systemName: "checkmark")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor(.white)
                        .scaleEffect(animateCheckmark ? 1.0 : 0.1)
                }
                .animation(.spring(response: 0.6, dampingFraction: 0.6).delay(0.2), value: animateCheckmark)
                
                // Success text
                VStack(spacing: 12) {
                    Text("Welcome to Brrow!")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                        .opacity(animateText ? 1 : 0)
                        .offset(y: animateText ? 0 : 20)
                    
                    Text("You're all set to start borrowing and lending")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .opacity(animateText ? 1 : 0)
                        .offset(y: animateText ? 0 : 20)
                }
                .animation(.easeOut(duration: 0.8).delay(0.6), value: animateText)
            }
        }
        .ignoresSafeArea()
        .onAppear {
            startAnimations()
            
            // Auto-dismiss after animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
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
    AuthSuccessView {
        print("Success animation complete")
    }
}