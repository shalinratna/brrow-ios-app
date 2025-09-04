import SwiftUI

struct ListingResultView: View {
    let isSuccess: Bool
    let message: String
    let onDismiss: () -> Void
    
    @State private var iconScale: CGFloat = 0
    @State private var iconRotation: Double = 0
    @State private var messageOpacity: Double = 0
    @State private var confettiOpacity: Double = 0
    @State private var particleOffsets: [CGSize] = Array(repeating: .zero, count: 20)
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                gradient: Gradient(colors: [
                    isSuccess ? Theme.Colors.primary : Color.red,
                    isSuccess ? Theme.Colors.primary.opacity(0.8) : Color.red.opacity(0.8),
                    Color.black.opacity(0.9)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Confetti particles for success
            if isSuccess {
                ForEach(0..<20, id: \.self) { index in
                    Image(systemName: ["star.fill", "circle.fill", "triangle.fill", "square.fill"].randomElement()!)
                        .font(.system(size: CGFloat.random(in: 10...20)))
                        .foregroundColor([Color.white, Color.yellow, Color.orange, Color.green].randomElement()!)
                        .offset(particleOffsets[index])
                        .opacity(confettiOpacity)
                        .rotationEffect(.degrees(Double.random(in: 0...360)))
                }
            }
            
            VStack(spacing: 30) {
                // Icon
                ZStack {
                    // Glow effect
                    Circle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 150, height: 150)
                        .blur(radius: 30)
                        .scaleEffect(iconScale)
                    
                    // Main icon
                    Image(systemName: isSuccess ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .font(.system(size: 100))
                        .foregroundColor(.white)
                        .scaleEffect(iconScale)
                        .rotationEffect(.degrees(iconRotation))
                }
                
                // Message
                VStack(spacing: 16) {
                    Text(isSuccess ? "Success!" : "Oops!")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text(message)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                .opacity(messageOpacity)
                
                // Continue button
                Button(action: onDismiss) {
                    Text(isSuccess ? "View Listing" : "Try Again")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(isSuccess ? Theme.Colors.primary : .red)
                        .frame(width: 200, height: 50)
                        .background(
                            Capsule()
                                .fill(Color.white)
                        )
                }
                .opacity(messageOpacity)
                .scaleEffect(messageOpacity)
            }
        }
        .onAppear {
            animateAppearance()
        }
    }
    
    private func animateAppearance() {
        // Icon animation
        withAnimation(.spring(response: 0.6, dampingFraction: 0.5)) {
            iconScale = 1.0
            if isSuccess {
                iconRotation = 360
            }
        }
        
        // Message fade in
        withAnimation(.easeIn(duration: 0.5).delay(0.3)) {
            messageOpacity = 1.0
        }
        
        // Confetti animation for success
        if isSuccess {
            withAnimation(.easeOut(duration: 1.5)) {
                confettiOpacity = 1.0
                
                for index in 0..<particleOffsets.count {
                    let angle = Double.random(in: 0...(2 * .pi))
                    let distance = CGFloat.random(in: 100...300)
                    particleOffsets[index] = CGSize(
                        width: cos(angle) * distance,
                        height: sin(angle) * distance - 100
                    )
                }
            }
            
            // Fade out confetti
            withAnimation(.easeOut(duration: 0.5).delay(1.0)) {
                confettiOpacity = 0
            }
        }
    }
}

struct ListingResultView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ListingResultView(
                isSuccess: true,
                message: "Your listing is now live!",
                onDismiss: {}
            )
            .previewDisplayName("Success")
            
            ListingResultView(
                isSuccess: false,
                message: "Something went wrong. Please try again.",
                onDismiss: {}
            )
            .previewDisplayName("Failure")
        }
    }
}