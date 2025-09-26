//
//  ListingDetailView.swift
//  Brrow
//
//  Created by Shalin Ratna on 7/16/25.
//

import SwiftUI
import Combine

struct ListingDetailView: View {
    let listing: Listing
    
    var body: some View {
        // Using modern version for better UI and functionality
        ModernListingDetailView(listing: listing)
    }
}

// Legacy implementation kept for reference
struct LegacyListingDetailView: View {
    let listing: Listing
    @State private var selectedImageIndex = 0
    @State private var showingOfferSheet = false
    @State private var showingContactSheet = false
    @State private var showingBorrowVsBuyCalculator = false
    @State private var isFavorite = false
    @State private var cancellables = Set<AnyCancellable>()
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                // Image Carousel
                imageCarousel
                
                // Listing Info
                listingInfoSection
                
                // Owner Info
                ownerInfoSection
                
                // Description
                descriptionSection
                
                // Action Buttons
                actionButtons
                
                Spacer()
            }
        }
        .navigationTitle(listing.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    toggleFavorite()
                }) {
                    Image(systemName: isFavorite ? "heart.fill" : "heart")
                        .foregroundColor(isFavorite ? Theme.Colors.error : Theme.Colors.secondaryText)
                }
            }
        }
        .sheet(isPresented: $showingOfferSheet) {
            // MakeOfferView removed - using ProfessionalListingDetailView instead
            Text("Make Offer - Feature moved to ProfessionalListingDetailView")
        }
        .sheet(isPresented: $showingContactSheet) {
            // ContactOwnerView removed - using ProfessionalListingDetailView instead
            Text("Contact Owner - Feature moved to ProfessionalListingDetailView")
        }
        .sheet(isPresented: $showingBorrowVsBuyCalculator) {
            BorrowVsBuyCalculatorView(listing: listing)
        }
        .onAppear {
            isFavorite = listing.isFavorite
            trackListingView()
        }
    }
    
    // MARK: - Image Carousel
    private var imageCarousel: some View {
        VStack(spacing: 0) {
            if !listing.images.isEmpty {
                TabView(selection: $selectedImageIndex) {
                    ForEach(0..<listing.imageUrls.count, id: \.self) { index in
                        BrrowAsyncImage(url: listing.imageUrls[index]) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Rectangle()
                                .foregroundColor(Theme.Colors.divider)
                                .overlay(
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle())
                                )
                        }
                        .frame(height: 250)
                        .clipped()
                        .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle())
                .frame(height: 250)
                
                // Image indicators
                if listing.images.count > 1 {
                    HStack {
                        ForEach(0..<listing.images.count, id: \.self) { index in
                            Circle()
                                .fill(selectedImageIndex == index ? Theme.Colors.primary : Theme.Colors.divider)
                                .frame(width: 8, height: 8)
                        }
                    }
                    .padding(.top, Theme.Spacing.sm)
                }
            } else {
                Rectangle()
                    .foregroundColor(Theme.Colors.divider)
                    .frame(height: 250)
                    .overlay(
                        Image(systemName: "photo")
                            .font(.system(size: 50))
                            .foregroundColor(Theme.Colors.secondaryText)
                    )
            }
        }
    }
    
    // MARK: - Listing Info Section
    private var listingInfoSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            HStack {
                Text(listing.title)
                    .font(Theme.Typography.title)
                    .fontWeight(.bold)
                    .foregroundColor(Theme.Colors.text)
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text(listing.isFree ? LocalizationHelper.localizedString("free") : "$\(Int(listing.price))")
                        .font(Theme.Typography.headline)
                        .fontWeight(.bold)
                        .foregroundColor(listing.isFree ? Theme.Colors.success : Theme.Colors.primary)
                    
                    if !listing.isFree {
                        Text("$\(listing.price, specifier: "%.2f")/day")
                            .font(Theme.Typography.callout)
                            .foregroundColor(Theme.Colors.secondaryText)
                    }
                }
            }
            
            // Category and type
            HStack {
                Text(listing.category?.name ?? "General")
                    .font(Theme.Typography.callout)
                    .foregroundColor(Theme.Colors.primary)
                    .padding(.horizontal, Theme.Spacing.sm)
                    .padding(.vertical, Theme.Spacing.xs)
                    .background(Theme.Colors.primary.opacity(0.1))
                    .cornerRadius(Theme.CornerRadius.sm)
                
                Text(listing.price == 0 ? "Free" : "Daily")
                    .font(Theme.Typography.callout)
                    .foregroundColor(Theme.Colors.secondaryText)
                    .padding(.horizontal, Theme.Spacing.sm)
                    .padding(.vertical, Theme.Spacing.xs)
                    .background(Theme.Colors.divider.opacity(0.3))
                    .cornerRadius(Theme.CornerRadius.sm)
                
                Spacer()
            }
            
            // Location and stats
            HStack {
                Image(systemName: "location.fill")
                    .foregroundColor(Theme.Colors.primary)
                
                Text(listing.locationString)
                    .font(Theme.Typography.callout)
                    .foregroundColor(Theme.Colors.secondaryText)
                
                Spacer()
                
                Text("\(listing.views) views")
                    .font(Theme.Typography.caption)
                    .foregroundColor(Theme.Colors.secondaryText)
            }
        }
        .padding(.horizontal, Theme.Spacing.md)
    }
    
    // MARK: - Owner Info Section
    private var ownerInfoSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text(LocalizationHelper.localizedString("listed_by"))
                .font(Theme.Typography.headline)
                .fontWeight(.semibold)
                .foregroundColor(Theme.Colors.text)
            
            HStack {
                BrrowAsyncImage(url: "") { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Circle()
                        .foregroundColor(Theme.Colors.divider)
                        .overlay(
                            Image(systemName: "person.fill")
                                .foregroundColor(Theme.Colors.secondaryText)
                        )
                }
                .frame(width: 50, height: 50)
                .clipShape(Circle())
                
                VStack(alignment: .leading) {
                    Text("Owner")
                        .font(Theme.Typography.callout)
                        .fontWeight(.medium)
                        .foregroundColor(Theme.Colors.text)
                    
                    HStack {
                        Text("⭐ 4.8")
                            .font(Theme.Typography.caption)
                            .foregroundColor(Theme.Colors.warning)
                        
                        Text("• 23 transactions")
                            .font(Theme.Typography.caption)
                            .foregroundColor(Theme.Colors.secondaryText)
                    }
                }
                
                Spacer()
                
                Button(action: {
                    // Navigate to owner profile - placeholder for now
                    print("Navigate to profile of owner: Unknown")
                }) {
                    Text(LocalizationHelper.localizedString("view_profile"))
                        .font(Theme.Typography.caption)
                        .foregroundColor(Theme.Colors.primary)
                }
            }
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.vertical, Theme.Spacing.sm)
        .cardStyle()
        .padding(.horizontal, Theme.Spacing.md)
    }
    
    // MARK: - Description Section
    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text(LocalizationHelper.localizedString("description"))
                .font(Theme.Typography.headline)
                .fontWeight(.semibold)
                .foregroundColor(Theme.Colors.text)
            
            Text(listing.description)
                .font(Theme.Typography.body)
                .foregroundColor(Theme.Colors.secondaryText)
                .lineSpacing(4)
        }
        .padding(.horizontal, Theme.Spacing.md)
    }
    
    // MARK: - Action Buttons
    private var actionButtons: some View {
        VStack(spacing: Theme.Spacing.md) {
            // Borrow vs Buy Calculator (only show if item is for sale or has rental price)
            if listing.price > 0 {
                Button(action: {
                    showingBorrowVsBuyCalculator = true
                }) {
                    HStack {
                        Image(systemName: "chart.bar.xaxis")
                            .font(.system(size: 16, weight: .medium))
                        Text("Borrow vs Buy Calculator")
                            .font(.system(size: 16, weight: .medium))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Theme.Colors.primary, Theme.Colors.primary.opacity(0.8)]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
                    .shadow(color: Theme.Colors.primary.opacity(0.3), radius: 8, x: 0, y: 4)
                }
            }
            
            Button(action: {
                showingOfferSheet = true
            }) {
                Text(listing.isFree ? LocalizationHelper.localizedString("request_item") : LocalizationHelper.localizedString("make_offer"))
            }
            .primaryButtonStyle()
            
            Button(action: {
                showingContactSheet = true
            }) {
                Text(LocalizationHelper.localizedString("contact_owner"))
            }
            .secondaryButtonStyle()
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.top, Theme.Spacing.lg)
    }
    
    // MARK: - Helper Methods
    private func toggleFavorite() {
        isFavorite.toggle()
        PersistenceController.shared.toggleFavorite(listingId: listing.listingId)
        
        // Track achievement for adding favorite
        if isFavorite {
            AchievementManager.shared.trackFavoriteAdded()
        }
        
        // Track favorite action
        let event = AnalyticsEvent(
            eventName: isFavorite ? "listing_favorited" : "listing_unfavorited",
            eventType: "interaction",
            userId: AuthManager.shared.currentUser?.apiId,
            sessionId: AuthManager.shared.sessionId,
            timestamp: ISO8601DateFormatter().string(from: Date()),
            metadata: [
                "listing_id": listing.id,
                "listing_title": listing.title,
                "platform": "ios"
            ]
        )
        
        APIClient.shared.trackAnalytics(event: event)
            .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
            .store(in: &cancellables)
    }
    
    private func trackListingView() {
        // Track achievement for viewing listing
        AchievementManager.shared.trackListingViewed()
        
        let event = AnalyticsEvent(
            eventName: "listing_viewed",
            eventType: "content",
            userId: AuthManager.shared.currentUser?.apiId,
            sessionId: AuthManager.shared.sessionId,
            timestamp: ISO8601DateFormatter().string(from: Date()),
            metadata: [
                "listing_id": listing.id,
                "listing_title": listing.title,
                "category": listing.category?.name ?? "Unknown",
                "price_type": listing.isFree ? "free" : "daily",
                "platform": "ios"
            ]
        )
        
        APIClient.shared.trackAnalytics(event: event)
            .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
            .store(in: &cancellables)
    }
}

// MARK: - Placeholder Views (Removed to avoid conflicts with ProfessionalListingDetailView)

struct ListingDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ListingDetailView(listing: Listing.example)
        }
    }
}