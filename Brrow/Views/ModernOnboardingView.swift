//
//  ModernOnboardingView.swift
//  Brrow
//
//  Modern onboarding experience that leads into authentication
//  Inspired by Instagram, TikTok, and other social apps
//

import SwiftUI

struct ModernOnboardingView: View {
    @State private var currentPage = 0
    @State private var showingAuth = false
    @State private var animateContent = false
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    
    private let onboardingPages = OnboardingData.pages
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Dynamic background based on current page
                backgroundView
                
                VStack(spacing: 0) {
                    // Skip button
                    HStack {
                        Spacer()
                        Button("Skip") {
                            completeOnboarding()
                        }
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.top, geometry.safeAreaInsets.top + 16)
                    }
                    
                    Spacer()
                    
                    // Main content
                    VStack(spacing: 40) {
                        // Page content
                        pageContentView
                        
                        // Page indicator and navigation
                        VStack(spacing: 32) {
                            pageIndicator
                            navigationButtons
                        }
                    }
                    .padding(.horizontal, 32)
                    
                    Spacer()
                    Spacer()
                }
            }
        }
        .ignoresSafeArea()
        .onAppear {
            startAnimations()
        }
        .fullScreenCover(isPresented: $showingAuth) {
            ModernAuthView()
        }
    }
    
    // MARK: - Background View
    private var backgroundView: some View {
        ZStack {
            // Base gradient that changes based on current page
            LinearGradient(
                colors: onboardingPages[currentPage].gradientColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Animated particles
            ForEach(0..<15, id: \.self) { index in
                Circle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: CGFloat.random(in: 4...12))
                    .position(
                        x: CGFloat.random(in: 0...400),
                        y: CGFloat.random(in: 0...800)
                    )
                    .scaleEffect(animateContent ? 1.2 : 0.8)
                    .animation(
                        .easeInOut(duration: Double.random(in: 2...4))
                        .repeatForever(autoreverses: true)
                        .delay(Double(index) * 0.1),
                        value: animateContent
                    )
            }
            
            // Overlay texture
            Rectangle()
                .fill(Color.white.opacity(0.02))
                .blendMode(.overlay)
        }
        .animation(.easeInOut(duration: 0.8), value: currentPage)
    }
    
    // MARK: - Page Content
    private var pageContentView: some View {
        let page = onboardingPages[currentPage]
        
        return VStack(spacing: 32) {
            // Icon with animation
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.15))
                    .frame(width: 140, height: 140)
                    .blur(radius: 20)
                
                Circle()
                    .fill(Color.white.opacity(0.2))
                    .frame(width: 120, height: 120)
                
                Image(systemName: page.iconName)
                    .font(.system(size: 50, weight: .light))
                    .foregroundColor(.white)
            }
            .scaleEffect(animateContent ? 1.0 : 0.8)
            .animation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.2), value: animateContent)
            .animation(.spring(response: 0.6, dampingFraction: 0.7), value: currentPage)
            
            // Text content
            VStack(spacing: 16) {
                Text(page.title)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                
                Text(page.description)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 16)
            }
            .opacity(animateContent ? 1 : 0)
            .offset(y: animateContent ? 0 : 20)
            .animation(.easeOut(duration: 0.8).delay(0.4), value: animateContent)
        }
    }
    
    // MARK: - Page Indicator
    private var pageIndicator: some View {
        HStack(spacing: 12) {
            ForEach(0..<onboardingPages.count, id: \.self) { index in
                RoundedRectangle(cornerRadius: 4)
                    .fill(currentPage == index ? Color.white : Color.white.opacity(0.3))
                    .frame(width: currentPage == index ? 32 : 8, height: 8)
                    .animation(.spring(response: 0.5, dampingFraction: 0.7), value: currentPage)
            }
        }
    }
    
    // MARK: - Navigation Buttons
    private var navigationButtons: some View {
        HStack(spacing: 20) {
            // Back button (hidden on first page)
            Button(action: goBack) {
                HStack(spacing: 8) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                    Text("Back")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(width: 100, height: 50)
                .background(Color.white.opacity(0.2))
                .cornerRadius(25)
                .overlay(
                    RoundedRectangle(cornerRadius: 25)
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                )
            }
            .opacity(currentPage > 0 ? 1 : 0)
            .animation(.easeInOut(duration: 0.3), value: currentPage)
            
            Spacer()
            
            // Next/Get Started button
            Button(action: goNext) {
                HStack(spacing: 8) {
                    Text(currentPage == onboardingPages.count - 1 ? "Get Started" : "Continue")
                        .font(.system(size: 16, weight: .semibold))
                    
                    if currentPage < onboardingPages.count - 1 {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 16, weight: .semibold))
                    }
                }
                .foregroundColor(.white)
                .frame(width: currentPage == onboardingPages.count - 1 ? 140 : 120, height: 50)
                .background(Color.white.opacity(0.25))
                .cornerRadius(25)
                .overlay(
                    RoundedRectangle(cornerRadius: 25)
                        .stroke(Color.white.opacity(0.4), lineWidth: 1)
                )
                .shadow(color: .white.opacity(0.2), radius: 8, x: 0, y: 4)
            }
        }
    }
    
    // MARK: - Actions
    private func startAnimations() {
        withAnimation(.easeOut(duration: 0.6)) {
            animateContent = true
        }
    }
    
    private func goBack() {
        guard currentPage > 0 else { return }
        
        withAnimation(.easeInOut(duration: 0.5)) {
            currentPage -= 1
        }
        
        restartContentAnimation()
    }
    
    private func goNext() {
        if currentPage < onboardingPages.count - 1 {
            withAnimation(.easeInOut(duration: 0.5)) {
                currentPage += 1
            }
            restartContentAnimation()
        } else {
            // Last page - show auth
            completeOnboarding()
        }
    }
    
    private func completeOnboarding() {
        hasCompletedOnboarding = true
        showingAuth = true
    }
    
    private func restartContentAnimation() {
        animateContent = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.easeOut(duration: 0.6)) {
                animateContent = true
            }
        }
    }
}

// MARK: - Onboarding Data
struct OnboardingData {
    struct Page {
        let iconName: String
        let title: String
        let description: String
        let gradientColors: [Color]
    }
    
    static let pages: [Page] = [
        Page(
            iconName: "arrow.triangle.2.circlepath",
            title: "Welcome to Brrow",
            description: "Share items you don't use every day and borrow what you need from neighbors nearby.",
            gradientColors: [
                Color(hexString: "667eea"),
                Color(hexString: "764ba2")
            ]
        ),
        Page(
            iconName: "location.circle.fill",
            title: "Find Items Nearby",
            description: "Discover amazing items available for borrowing right in your neighborhood.",
            gradientColors: [
                Color(hexString: "f093fb"),
                Color(hexString: "f5576c")
            ]
        ),
        Page(
            iconName: "person.2.circle.fill",
            title: "Build Community",
            description: "Connect with your neighbors, build trust, and create a sharing community.",
            gradientColors: [
                Color(hexString: "4facfe"),
                Color(hexString: "00f2fe")
            ]
        ),
        Page(
            iconName: "leaf.circle.fill",
            title: "Live Sustainably",
            description: "Reduce waste, save money, and help create a more sustainable future together.",
            gradientColors: [
                Color(hexString: "43e97b"),
                Color(hexString: "38f9d7")
            ]
        )
    ]
}

#Preview {
    ModernOnboardingView()
}