//
//  ModernOnboardingView.swift
//  Brrow
//
//  Clean white and green onboarding with liquid animations
//

import SwiftUI

struct ModernOnboardingView: View {
    @State private var currentPage = 0
    @State private var animateContent = false
    @State private var liquidOffset: CGFloat = 0
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("shouldStartInSignupMode") private var shouldStartInSignupMode = false

    private let onboardingPages = OnboardingData.pages
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Clean white background
                Color.white
                    .ignoresSafeArea()
                
                // Liquid green wave animation
                liquidWaveBackground
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Skip button
                    HStack {
                        Spacer()
                        Button("Skip") {
                            completeOnboarding()
                        }
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Theme.Colors.primary.opacity(0.7))
                        .padding(.horizontal, 24)
                        .padding(.top, geometry.safeAreaInsets.top + 16)
                    }
                    
                    // Main content area
                    TabView(selection: $currentPage) {
                        ForEach(0..<onboardingPages.count, id: \.self) { index in
                            OnboardingPageContent(page: onboardingPages[index])
                                .tag(index)
                        }
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                    .animation(.easeInOut(duration: 0.5), value: currentPage)
                    
                    // Bottom navigation
                    VStack(spacing: 24) {
                        // Custom page indicator
                        pageIndicator
                        
                        // Navigation button
                        navigationButton
                    }
                    .padding(.horizontal, 32)
                    .padding(.bottom, 40)
                }
            }
        }
        .onAppear {
            startAnimations()
        }
    }
    
    // MARK: - Liquid Wave Background
    private var liquidWaveBackground: some View {
        VStack {
            Spacer()
            
            // Liquid wave shape
            WaveShape(offset: liquidOffset)
                .fill(
                    LinearGradient(
                        colors: [
                            Theme.Colors.primary.opacity(0.1),
                            Theme.Colors.primary.opacity(0.05)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(height: 200)
                .overlay(
                    WaveShape(offset: liquidOffset + 50)
                        .fill(Theme.Colors.primary.opacity(0.05))
                )
        }
        .animation(
            .linear(duration: 3)
            .repeatForever(autoreverses: false),
            value: liquidOffset
        )
    }
    
    // MARK: - Page Indicator
    private var pageIndicator: some View {
        HStack(spacing: 8) {
            ForEach(0..<onboardingPages.count, id: \.self) { index in
                Capsule()
                    .fill(currentPage == index ? Theme.Colors.primary : Color.gray.opacity(0.3))
                    .frame(width: currentPage == index ? 24 : 8, height: 8)
                    .animation(.spring(response: 0.5, dampingFraction: 0.7), value: currentPage)
            }
        }
    }
    
    // MARK: - Navigation Button
    private var navigationButton: some View {
        Button(action: {
            if currentPage < onboardingPages.count - 1 {
                withAnimation(.spring()) {
                    currentPage += 1
                }
            } else {
                completeOnboarding()
            }
        }) {
            HStack(spacing: 12) {
                Text(currentPage == onboardingPages.count - 1 ? "Get Started" : "Continue")
                    .font(.system(size: 17, weight: .semibold))
                
                if currentPage < onboardingPages.count - 1 {
                    Image(systemName: "arrow.right")
                        .font(.system(size: 16, weight: .semibold))
                }
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Theme.Colors.primary)
                    .shadow(color: Theme.Colors.primary.opacity(0.3), radius: 10, y: 5)
            )
            .scaleEffect(animateContent ? 1.0 : 0.95)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Helper Functions
    private func startAnimations() {
        withAnimation(.easeOut(duration: 0.8)) {
            animateContent = true
        }
        
        withAnimation {
            liquidOffset = 200
        }
    }
    
    private func completeOnboarding() {
        withAnimation {
            hasCompletedOnboarding = true
            shouldStartInSignupMode = true // Set flag to show signup mode after onboarding
        }

        // Track achievement for completing onboarding
        AchievementManager.shared.trackOnboardingCompleted()
    }
}

// MARK: - Onboarding Page Content
struct OnboardingPageContent: View {
    let page: OnboardingData.Page
    @State private var isAnimated = false
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Illustration/Icon container
            ZStack {
                // Soft background circle
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Theme.Colors.primary.opacity(0.1),
                                Theme.Colors.primary.opacity(0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 180, height: 180)
                    .blur(radius: 10)
                
                // Icon container with border
                Circle()
                    .stroke(Theme.Colors.primary.opacity(0.2), lineWidth: 2)
                    .frame(width: 140, height: 140)
                    .background(
                        Circle()
                            .fill(Color.white)
                            .shadow(color: Color.black.opacity(0.05), radius: 10, y: 5)
                    )
                    .overlay(
                        Image(systemName: page.iconName)
                            .font(.system(size: 56, weight: .medium))
                            .foregroundColor(Theme.Colors.primary)
                            .symbolRenderingMode(.hierarchical)
                    )
            }
            .scaleEffect(isAnimated ? 1.0 : 0.8)
            .opacity(isAnimated ? 1.0 : 0)
            
            // Text content
            VStack(spacing: 20) {
                // Title
                Text(page.title)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.black)
                    .multilineTextAlignment(.center)
                
                // Description
                Text(page.description)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 20)
                
                // Feature tags
                if !page.features.isEmpty {
                    HStack(spacing: 8) {
                        ForEach(page.features, id: \.self) { feature in
                            FeatureTag(text: feature)
                        }
                    }
                    .padding(.top, 8)
                }
            }
            .opacity(isAnimated ? 1.0 : 0)
            .offset(y: isAnimated ? 0 : 20)
            
            Spacer()
            Spacer()
        }
        .padding(.horizontal, 24)
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.2)) {
                isAnimated = true
            }
        }
        .onDisappear {
            isAnimated = false
        }
    }
}

// MARK: - Feature Tag
struct FeatureTag: View {
    let text: String
    
    var body: some View {
        Text(text)
            .font(.system(size: 13, weight: .medium))
            .foregroundColor(Theme.Colors.primary)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(Theme.Colors.primary.opacity(0.1))
                    .overlay(
                        Capsule()
                            .stroke(Theme.Colors.primary.opacity(0.2), lineWidth: 1)
                    )
            )
    }
}

// MARK: - Wave Shape
struct WaveShape: Shape {
    var offset: CGFloat
    
    var animatableData: CGFloat {
        get { offset }
        set { offset = newValue }
    }
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        
        path.move(to: CGPoint(x: 0, y: height * 0.5))
        
        // Create smooth wave
        path.addCurve(
            to: CGPoint(x: width * 0.5, y: height * 0.3),
            control1: CGPoint(x: width * 0.25, y: height * 0.5 - offset.truncatingRemainder(dividingBy: 50)),
            control2: CGPoint(x: width * 0.25, y: height * 0.3)
        )
        
        path.addCurve(
            to: CGPoint(x: width, y: height * 0.5),
            control1: CGPoint(x: width * 0.75, y: height * 0.3),
            control2: CGPoint(x: width * 0.75, y: height * 0.5 + offset.truncatingRemainder(dividingBy: 50))
        )
        
        path.addLine(to: CGPoint(x: width, y: height))
        path.addLine(to: CGPoint(x: 0, y: height))
        path.closeSubpath()
        
        return path
    }
}

// MARK: - Onboarding Data
struct OnboardingData {
    struct Page {
        let iconName: String
        let title: String
        let description: String
        let features: [String]
    }
    
    static let pages: [Page] = [
        Page(
            iconName: "cube.box.fill",
            title: "Share Your Items",
            description: "Turn your unused items into income by sharing them with your community.",
            features: ["Easy listing", "Set your price", "You're in control"]
        ),
        Page(
            iconName: "magnifyingglass.circle.fill",
            title: "Find What You Need",
            description: "Discover items available for rent in your neighborhood at a fraction of the cost.",
            features: ["Save money", "Local pickup", "Verified items"]
        ),
        Page(
            iconName: "heart.circle.fill",
            title: "Community First",
            description: "We believe in people and fair pricing. Brrow is free to use - no hidden fees or outrageous charges.",
            features: ["Always free to browse", "No subscription fees", "Fair pricing guaranteed"]
        ),
        Page(
            iconName: "lock.shield.fill",
            title: "Safe & Secure",
            description: "Secure payments powered by Stripe. Optional insurance protection available for added peace of mind.",
            features: ["ID verified", "Optional insurance", "24/7 support"]
        )
    ]
}

#Preview {
    ModernOnboardingView()
}