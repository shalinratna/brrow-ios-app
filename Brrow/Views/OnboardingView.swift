import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var currentPage = 0
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [Color.blue.opacity(0.1), Color.green.opacity(0.1)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack {
                // Skip button
                HStack {
                    Spacer()
                    Button("Skip") {
                        completeOnboarding()
                    }
                    .foregroundColor(.gray)
                    .padding()
                }
                
                // Content
                TabView(selection: $currentPage) {
                    OnboardingPageView(
                        icon: "hands.sparkles.fill",
                        title: "Welcome to Brrow",
                        description: "Share and borrow items in your community. Save money, reduce waste, and connect with neighbors.",
                        iconColor: .green
                    )
                    .tag(0)
                    
                    OnboardingPageView(
                        icon: "magnifyingglass.circle.fill",
                        title: "Find What You Need",
                        description: "Browse thousands of items available for rent in your area. From tools to party supplies, find exactly what you need.",
                        iconColor: .blue
                    )
                    .tag(1)
                    
                    OnboardingPageView(
                        icon: "dollarsign.circle.fill",
                        title: "Earn From Your Items",
                        description: "Turn your unused items into income. List anything from cameras to camping gear and start earning today.",
                        iconColor: .orange
                    )
                    .tag(2)
                    
                    OnboardingPageView(
                        icon: "shield.checkered",
                        title: "Safe & Secure",
                        description: "All transactions are protected. Verified users, secure payments, and insurance options give you peace of mind.",
                        iconColor: .purple
                    )
                    .tag(3)
                    
                    OnboardingPageView(
                        icon: "leaf.circle.fill",
                        title: "Join the Sharing Economy",
                        description: "Reduce waste and build community connections. Together, we can make a positive impact on our planet.",
                        iconColor: .green
                    )
                    .tag(4)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .animation(.easeInOut, value: currentPage)
                
                // Page indicators and buttons
                VStack(spacing: 20) {
                    // Custom page indicators
                    HStack(spacing: 8) {
                        ForEach(0..<5) { index in
                            Circle()
                                .fill(currentPage == index ? Color.primary : Color.gray.opacity(0.3))
                                .frame(width: 8, height: 8)
                                .scaleEffect(currentPage == index ? 1.2 : 1.0)
                                .animation(.spring(), value: currentPage)
                        }
                    }
                    .padding(.bottom, 20)
                    
                    // Navigation buttons
                    HStack(spacing: 20) {
                        if currentPage > 0 {
                            Button(action: {
                                withAnimation {
                                    currentPage -= 1
                                }
                            }) {
                                HStack {
                                    Image(systemName: "chevron.left")
                                    Text("Back")
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(12)
                            }
                        }
                        
                        Button(action: {
                            if currentPage < 4 {
                                withAnimation {
                                    currentPage += 1
                                }
                            } else {
                                completeOnboarding()
                            }
                        }) {
                            HStack {
                                Text(currentPage < 4 ? "Next" : "Get Started")
                                if currentPage < 4 {
                                    Image(systemName: "chevron.right")
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(LinearGradient(
                                gradient: Gradient(colors: [Color.blue, Color.green]),
                                startPoint: .leading,
                                endPoint: .trailing
                            ))
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal, 30)
                }
                .padding(.bottom, 50)
            }
        }
    }
    
    private func completeOnboarding() {
        withAnimation {
            hasCompletedOnboarding = true
        }
        
        // Track achievement for completing onboarding
        AchievementManager.shared.trackOnboardingCompleted()
    }
}

struct OnboardingPageView: View {
    let icon: String
    let title: String
    let description: String
    let iconColor: Color
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // Icon with animation
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.1))
                    .frame(width: 150, height: 150)
                
                Image(systemName: icon)
                    .font(.system(size: 70))
                    .foregroundColor(iconColor)
                    // .symbolEffect(.pulse) // iOS 17+ only
            }
            .padding(.bottom, 20)
            
            // Title
            Text(title)
                .font(.largeTitle)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            
            // Description
            Text(description)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .fixedSize(horizontal: false, vertical: true)
            
            Spacer()
            Spacer()
        }
    }
}

struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView()
    }
}