//
//  Theme.swift
//  Brrow
//
//  Created by Shalin Ratna on 7/16/25.
//

import SwiftUI

// MARK: - Color Extension for Hex Support
extension Color {
    init(hexString: String) {
        let hex = hexString.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Brrow Theme System
struct Theme {
    
    // MARK: - Dynamic Colors
    struct Colors {
        // Primary Brand Colors (Same for both modes)
        static let primary = Color(hexString: "#2ABF5A")        // Vivid emerald
        static let secondary = Color(hexString: "#A8E6B0")      // Softer mint
        static let primaryPressed = Color(hexString: "#219C4B") // Darker green
        
        // Bright accent colors for pop
        static let accent = Color(hexString: "#FF6B6B")         // Coral red
        static let accentBlue = Color(hexString: "#4ECDC4")    // Teal
        static let accentPurple = Color(hexString: "#9B59B6")  // Purple
        static let accentOrange = Color(hexString: "#FF8C42")  // Orange
        
        // Adaptive colors (automatically adjust for dark/light mode)
        static let background = Color(.systemBackground)
        static let secondaryBackground = Color(.secondarySystemBackground)
        static let tertiaryBackground = Color(.tertiarySystemBackground)
        static let groupedBackground = Color(.systemGroupedBackground)
        
        // Card and surface colors
        static let cardBackground = Color(.secondarySystemBackground)
        static let surface = Color(.systemBackground)
        static let inputBackground = Color(.secondarySystemBackground)
        
        // Text colors (adaptive)
        static let text = Color(.label)
        static let secondaryText = Color(.secondaryLabel)
        static let tertiaryText = Color(.tertiaryLabel)
        static let placeholderText = Color(.placeholderText)
        
        // Separators and borders
        static let separator = Color(.separator)
        static let border = Color(.separator).opacity(0.5)
        static let divider = Color(.separator)
        
        // System Colors
        static let success = Color(.systemGreen)
        static let warning = Color(.systemOrange)
        static let error = Color(.systemRed)
        static let info = Color(.systemBlue)
        
        // Custom gradient colors
        static let gradientStart = Color(hexString: "#2ABF5A")
        static let gradientEnd = Color(hexString: "#4ECDC4")
    }
    
    // MARK: - Typography (SF Pro Text - Brand Guidelines)
    struct Typography {
        // Brand Typography Hierarchy
        static let title = Font.system(size: 20, weight: .semibold, design: .default)     // Titles: 20pt Semibold
        static let body = Font.system(size: 16, weight: .regular, design: .default)       // Body: 16pt Regular
        static let label = Font.system(size: 13, weight: .medium, design: .default)       // Labels: 13pt Medium
        
        // Extended Typography
        static let largeTitle = Font.system(size: 28, weight: .bold, design: .default)
        static let headline = Font.system(size: 18, weight: .semibold, design: .default)
        static let callout = Font.system(size: 15, weight: .regular, design: .default)
        static let subheadline = Font.system(size: 14, weight: .regular, design: .default)
        static let footnote = Font.system(size: 12, weight: .regular, design: .default)
        static let caption = Font.system(size: 11, weight: .regular, design: .default)
    }
    
    // MARK: - Spacing (Brand Guidelines)
    struct Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let gutter: CGFloat = 12     // 12pt gutters between cards
        static let md: CGFloat = 16         // 16pt margins
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
    }
    
    // MARK: - Corner Radius (Brand Guidelines)
    struct CornerRadius {
        static let card: CGFloat = 8        // 8pt radius for cards (brand guideline)
        static let sm: CGFloat = 6
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 24
    }
    
    // MARK: - Shadows (Brand Guidelines)
    struct Shadows {
        static let card = Color.black.opacity(0.1)      // 10% opacity, 4px blur (brand guideline)
        static let cardRadius: CGFloat = 4
        static let button = Color.black.opacity(0.15)
        static let modal = Color.black.opacity(0.3)
        static let subtle = Color.black.opacity(0.05)
    }
}

// MARK: - Color Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - View Extensions
extension View {
    func cardStyle() -> some View {
        self
            .background(Theme.Colors.cardBackground)
            .cornerRadius(Theme.CornerRadius.card)
            .shadow(color: Theme.Shadows.card, radius: Theme.Shadows.cardRadius, x: 0, y: 2)
    }
    
    func primaryButtonStyle() -> some View {
        self
            .font(Theme.Typography.body)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(Theme.Colors.primary)
            .cornerRadius(Theme.CornerRadius.card)
            .scaleEffect(1.0)
            .animation(.easeInOut(duration: 0.1), value: true)
    }
    
    func secondaryButtonStyle() -> some View {
        self
            .font(Theme.Typography.body)
            .foregroundColor(Theme.Colors.primary)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(Theme.Colors.secondary.opacity(0.1))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.card)
                    .stroke(Theme.Colors.secondary, lineWidth: 1)
            )
            .cornerRadius(Theme.CornerRadius.card)
    }
    
    // MARK: - Brand Animations & Interactions
    func pressableScale() -> some View {
        self
            .scaleEffect(1.0)
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.1)) {
                    // 0.95× scale on press (brand guideline)
                }
            }
    }
    
    func shimmerLoading() -> some View {
        self
            .redacted(reason: .placeholder)
            .overlay(
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Theme.Colors.secondary.opacity(0.3),
                                Theme.Colors.secondary.opacity(0.1),
                                Theme.Colors.secondary.opacity(0.3)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .animation(
                        Animation.linear(duration: 1.5).repeatForever(autoreverses: false),
                        value: true
                    )
            )
    }
    
    func slideTransition() -> some View {
        self
            .transition(.asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .move(edge: .leading).combined(with: .opacity)
            ))
            .animation(.easeInOut(duration: 0.3), value: true)
    }
}

// MARK: - Brand-Specific Modifiers
extension View {
    func brandCard() -> some View {
        self
            .padding(Theme.Spacing.md)
            .background(Theme.Colors.surface)
            .cornerRadius(Theme.CornerRadius.card)
            .shadow(color: Theme.Shadows.card, radius: Theme.Shadows.cardRadius, x: 0, y: 2)
    }
    
    func pillButton(isSelected: Bool = false) -> some View {
        self
            .font(Theme.Typography.label)
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.vertical, Theme.Spacing.sm)
            .background(isSelected ? Theme.Colors.primary : Theme.Colors.secondary.opacity(0.2))
            .foregroundColor(isSelected ? .white : Theme.Colors.primary)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isSelected ? Color.clear : Theme.Colors.secondary, lineWidth: 1)
            )
            .scaleEffect(isSelected ? 1.05 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}
