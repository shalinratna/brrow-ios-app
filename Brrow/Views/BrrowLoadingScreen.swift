import SwiftUI

struct BrrowLoadingScreen: View {
    let statusText: String
    let progress: Double
    let onComplete: () -> Void
    
    @State private var logoScale: CGFloat = 0.5
    @State private var logoRotation: Double = 0
    @State private var pulseScale: CGFloat = 1.0
    @State private var checkmarkScale: CGFloat = 0
    @State private var checkmarkOpacity: Double = 0
    @State private var errorScale: CGFloat = 0
    @State private var errorOpacity: Double = 0
    @State private var progressRingAnimation: Double = 0
    
    private var isComplete: Bool {
        progress >= 1.0
    }
    
    private var isFailed: Bool {
        statusText == "Failed"
    }
    
    var body: some View {
        ZStack {
            // Animated gradient background
            LinearGradient(
                gradient: Gradient(colors: [
                    Theme.Colors.primary.opacity(0.9),
                    Theme.Colors.primary.opacity(0.7),
                    Color.black.opacity(0.8)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: pulseScale)
            
            VStack(spacing: 40) {
                // Animated Logo Container
                ZStack {
                    // Pulse ring effect
                    Circle()
                        .stroke(Color.white.opacity(0.2), lineWidth: 2)
                        .scaleEffect(pulseScale)
                        .opacity(2 - pulseScale)
                        .animation(.easeOut(duration: 1.5).repeatForever(autoreverses: false), value: pulseScale)
                    
                    // Progress ring
                    Circle()
                        .trim(from: 0, to: progressRingAnimation)
                        .stroke(
                            LinearGradient(
                                colors: [Color.white, Color.white.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 4, lineCap: .round)
                        )
                        .frame(width: 140, height: 140)
                        .rotationEffect(.degrees(-90))
                        .animation(.spring(response: 0.8), value: progressRingAnimation)
                    
                    // Logo
                    ZStack {
                        // B letter logo
                        Text("B")
                            .font(.system(size: 80, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .scaleEffect(logoScale)
                            .rotationEffect(.degrees(logoRotation))
                        
                        // Success checkmark
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 100))
                            .foregroundColor(.white)
                            .scaleEffect(checkmarkScale)
                            .opacity(checkmarkOpacity)
                        
                        // Error icon
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 100))
                            .foregroundColor(.red)
                            .scaleEffect(errorScale)
                            .opacity(errorOpacity)
                    }
                    .frame(width: 120, height: 120)
                    .background(
                        Circle()
                            .fill(Color.white.opacity(0.1))
                            .blur(radius: 20)
                    )
                }
                
                // Status text with animation
                VStack(spacing: 8) {
                    Text("Brrow")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text(statusText)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))
                        .transition(.opacity.combined(with: .scale))
                        .id(statusText) // Force animation on text change
                    
                    if progress > 0 && progress < 1 && !isFailed {
                        Text("\(Int(progress * 100))%")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                            .transition(.opacity)
                    }
                }
                
                // Modern progress dots
                if !isComplete && !isFailed {
                    HStack(spacing: 8) {
                        ForEach(0..<3) { index in
                            Circle()
                                .fill(Color.white.opacity(0.7))
                                .frame(width: 8, height: 8)
                                .scaleEffect(pulseScale)
                                .animation(
                                    .easeInOut(duration: 0.6)
                                    .repeatForever()
                                    .delay(Double(index) * 0.2),
                                    value: pulseScale
                                )
                        }
                    }
                    .padding(.top, 20)
                }
            }
        }
        .onAppear {
            startAnimations()
        }
        .onChange(of: progress) { newValue in
            withAnimation(.spring()) {
                progressRingAnimation = newValue
            }
            
            if newValue >= 1.0 {
                completeAnimation()
            }
        }
        .onChange(of: statusText) { newValue in
            if newValue == "Failed" {
                failAnimation()
            }
        }
    }
    
    private func startAnimations() {
        // Initial logo animation
        withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
            logoScale = 1.0
        }
        
        // Continuous rotation
        withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
            logoRotation = 360
        }
        
        // Start pulse
        pulseScale = 1.5
    }
    
    private func completeAnimation() {
        // Stop rotation and scale up
        withAnimation(.spring(response: 0.6)) {
            logoRotation = 0
            logoScale = 0.8
        }
        
        // Show checkmark
        withAnimation(.spring(response: 0.5).delay(0.2)) {
            checkmarkScale = 1.0
            checkmarkOpacity = 1.0
        }
        
        // Call completion after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            onComplete()
        }
    }
    
    private func failAnimation() {
        // Stop rotation and shake
        withAnimation(.spring(response: 0.6)) {
            logoRotation = 0
            logoScale = 0.8
        }
        
        // Show error icon
        withAnimation(.spring(response: 0.5).delay(0.2)) {
            errorScale = 1.0
            errorOpacity = 1.0
        }
    }
}

// Shake animation modifier
struct ShakeEffect: GeometryEffect {
    var amount: CGFloat = 10
    var shakesPerUnit = 3
    var animatableData: CGFloat
    
    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(CGAffineTransform(translationX:
            amount * sin(animatableData * .pi * CGFloat(shakesPerUnit)),
            y: 0))
    }
}

struct BrrowLoadingScreen_Previews: PreviewProvider {
    static var previews: some View {
        BrrowLoadingScreen(
            statusText: "Creating your listing...",
            progress: 0.5,
            onComplete: {}
        )
    }
}