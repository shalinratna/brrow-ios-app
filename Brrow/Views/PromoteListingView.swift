//
//  PromoteListingView.swift
//  Brrow
//
//  Promotion options for listings
//

import SwiftUI

struct PromoteListingView: View {
    let listing: Listing
    @Environment(\.dismiss) private var dismiss
    @State private var selectedOption = "none"
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Boost your listing's visibility")
                    .font(.system(size: 16))
                    .foregroundColor(Theme.Colors.secondaryText)
                    .padding(.top, 20)
                
                VStack(spacing: 16) {
                    // No Promotion
                    PromotionOptionCard(
                        title: "Standard Listing",
                        price: "Free",
                        features: [
                            "Basic visibility",
                            "Appear in search results",
                            "Standard placement"
                        ],
                        isSelected: selectedOption == "none",
                        action: { selectedOption = "none" }
                    )
                    
                    // Featured Promotion
                    PromotionOptionCard(
                        title: "Featured Listing",
                        price: "$4.99/week",
                        features: [
                            "🌟 Featured badge",
                            "Top of search results",
                            "Homepage spotlight",
                            "3x more views"
                        ],
                        isSelected: selectedOption == "featured",
                        isRecommended: true,
                        action: { selectedOption = "featured" }
                    )
                    
                    // Premium Promotion
                    PromotionOptionCard(
                        title: "Premium Boost",
                        price: "$9.99/week",
                        features: [
                            "⚡ Premium badge",
                            "Priority placement",
                            "Push notifications to users",
                            "5x more views",
                            "Social media promotion"
                        ],
                        isSelected: selectedOption == "premium",
                        action: { selectedOption = "premium" }
                    )
                }
                .padding(.horizontal, 16)
                
                Spacer()
                
                Button(action: { applyPromotion() }) {
                    Text(selectedOption == "none" ? "Continue Without Promotion" : "Apply Promotion")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Theme.Colors.primary)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 20)
            }
            .navigationTitle("Promote Listing")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func applyPromotion() {
        if selectedOption == "none" {
            dismiss()
            return
        }
        
        isLoading = true
        // TODO: Implement promotion API call
        dismiss()
    }
}

struct PromotionOptionCard: View {
    let title: String
    let price: String
    let features: [String]
    let isSelected: Bool
    var isRecommended: Bool = false
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(title)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(Theme.Colors.text)
                    
                    Spacer()
                    
                    if isRecommended {
                        Text("RECOMMENDED")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Theme.Colors.accentOrange)
                            .cornerRadius(4)
                    }
                }
                
                Text(price)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(Theme.Colors.primary)
                
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(features, id: \.self) { feature in
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 14))
                                .foregroundColor(Theme.Colors.primary)
                            
                            Text(feature)
                                .font(.system(size: 14))
                                .foregroundColor(Theme.Colors.secondaryText)
                            
                            Spacer()
                        }
                    }
                }
            }
            .padding(16)
            .background(isSelected ? Theme.Colors.primary.opacity(0.05) : Theme.Colors.secondaryBackground)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Theme.Colors.primary : Color.clear, lineWidth: 2)
            )
        }
    }
}