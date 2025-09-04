//
//  UsernameDisplay.swift
//  Brrow
//
//  Username display with subscription tier colors and shine effects
//

import SwiftUI

struct UsernameDisplay: View {
    let username: String
    let subscriptionTier: SubscriptionTier?
    let showShine: Bool
    let fontSize: CGFloat
    
    init(username: String, subscriptionTier: SubscriptionTier? = nil, showShine: Bool = true, fontSize: CGFloat = 16) {
        self.username = username
        self.subscriptionTier = subscriptionTier
        self.showShine = showShine
        self.fontSize = fontSize
    }
    
    var body: some View {
        Text(username)
            .font(.system(size: fontSize, weight: .semibold))
            .foregroundColor(usernameColor)
            .overlay(
                shineEffect
            )
    }
    
    private var usernameColor: Color {
        guard let tier = subscriptionTier else {
            return Color.primary
        }
        
        switch tier {
        case .green:
            return Color(hex: "#2ABF5A") // Brrow Green
        case .gold:
            return Color(hex: "#FFD700") // Gold
        case .fleet:
            return Color(hex: "#8A2BE2") // Blue Violet
        }
    }
    
    @ViewBuilder
    private var shineEffect: some View {
        if showShine && subscriptionTier != nil {
            LinearGradient(
                colors: [
                    Color.white.opacity(0.8),
                    Color.clear,
                    Color.white.opacity(0.6)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .mask(
                Text(username)
                    .font(.system(size: fontSize, weight: .semibold))
            )
            .blendMode(.overlay)
            .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: showShine)
        }
    }
}

// MARK: - Subscription Tier Enum
enum SubscriptionTier: String, CaseIterable {
    case green = "prod_SkNq4td70VeTPW"
    case gold = "prod_SkNrFVUCDy8vqx" 
    case fleet = "prod_SkNsil9sGFTCQv"
    
    var displayName: String {
        switch self {
        case .green: return "Brrow Green"
        case .gold: return "Brrow Gold"
        case .fleet: return "Brrow Fleet"
        }
    }
    
    var color: Color {
        switch self {
        case .green: return Color(hex: "#2ABF5A")
        case .gold: return Color(hex: "#FFD700")
        case .fleet: return Color(hex: "#8A2BE2")
        }
    }
    
    var price: String {
        switch self {
        case .green: return "$5.99/month"
        case .gold: return "$9.99/month"
        case .fleet: return "$29.99/month"
        }
    }
}

// MARK: - Preview
struct UsernameDisplay_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            UsernameDisplay(username: "john_doe", subscriptionTier: nil)
            
            UsernameDisplay(username: "premium_user", subscriptionTier: .green)
            
            UsernameDisplay(username: "gold_member", subscriptionTier: .gold)
            
            UsernameDisplay(username: "fleet_owner", subscriptionTier: .fleet)
            
            UsernameDisplay(username: "no_shine", subscriptionTier: .gold, showShine: false)
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}