//
//  AuthLoadingOverlay.swift
//  Brrow
//
//  Professional loading overlay for authentication processes
//

import SwiftUI

struct AuthLoadingOverlay: View {
    let message: String
    @State private var rotationAngle: Double = 0
    @State private var scale: CGFloat = 1.0
    
    var body: some View {
        ZStack {
            // Semi-transparent background
            Color.black.opacity(0.6)
                .ignoresSafeArea()
            
            // Loading card
            VStack(spacing: 20) {
                // Animated loading indicator
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.3), lineWidth: 3)
                        .frame(width: 50, height: 50)
                    
                    Circle()
                        .trim(from: 0, to: 0.3)
                        .stroke(Color.white, lineWidth: 3)
                        .frame(width: 50, height: 50)
                        .rotationEffect(.degrees(rotationAngle))
                        .animation(.linear(duration: 1).repeatForever(autoreverses: false), value: rotationAngle)
                }
                .scaleEffect(scale)
                .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: scale)
                
                // Loading message
                Text(message)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
            )
            .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
        }
        .onAppear {
            rotationAngle = 360
            scale = 1.1
        }
    }
}

#Preview {
    AuthLoadingOverlay(message: "Signing you in...")
}