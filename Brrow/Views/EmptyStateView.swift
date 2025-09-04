//
//  EmptyStateView.swift
//  Brrow
//
//  Reusable empty state view component
//

import SwiftUI

struct EmptyStateView: View {
    let title: String
    let message: String
    let systemImage: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil
    
    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Image(systemName: systemImage)
                .font(.system(size: 64))
                .foregroundColor(Theme.Colors.primary.opacity(0.6))
            
            VStack(spacing: Theme.Spacing.sm) {
                Text(title)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(Theme.Colors.text)
                
                Text(message)
                    .font(.system(size: 16))
                    .foregroundColor(Theme.Colors.secondaryText)
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
            }
            
            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, Theme.Spacing.xl)
                        .padding(.vertical, Theme.Spacing.md)
                        .background(Theme.Colors.primary)
                        .cornerRadius(Theme.CornerRadius.card)
                }
            }
        }
        .padding(Theme.Spacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    EmptyStateView(
        title: "No Items Found",
        message: "Try adjusting your search filters or browse different categories.",
        systemImage: "magnifyingglass",
        actionTitle: "Clear Filters",
        action: {}
    )
}