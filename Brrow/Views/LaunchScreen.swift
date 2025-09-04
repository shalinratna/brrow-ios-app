import SwiftUI

struct LaunchScreen: View {
    @State private var isAnimating = false
    @State private var opacity = 0.0
    
    var body: some View {
        ZStack {
            Theme.Colors.primary
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // App Icon
                Image(systemName: "arrow.2.squarepath")
                    .font(.system(size: 80, weight: .light))
                    .foregroundColor(.white)
                    .scaleEffect(isAnimating ? 1.2 : 1.0)
                    .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: isAnimating)
                
                // App Name
                Text("Brrow")
                    .font(.custom("SF Pro Rounded", size: 32))
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .opacity(opacity)
                
                // Tagline
                Text("Borrow. Lend. Connect.")
                    .font(.custom("SF Pro Rounded", size: 16))
                    .foregroundColor(.white.opacity(0.8))
                    .opacity(opacity)
            }
        }
        .onAppear {
            withAnimation(.easeIn(duration: 0.5)) {
                opacity = 1.0
            }
            
            withAnimation(.easeInOut(duration: 1.0).delay(0.2)) {
                isAnimating = true
            }
        }
    }
}

#Preview {
    LaunchScreen()
}