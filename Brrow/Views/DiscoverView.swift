//
//  DiscoverView.swift
//  Brrow
//
//  Revolutionary Social Discovery Experience
//

import SwiftUI
import CoreLocation
import AVFoundation

struct DiscoverView: View {
    @EnvironmentObject var viewModel: HomeViewModel
    @StateObject private var discoverViewModel = DiscoverViewModel()
    @State private var selectedTab = "nearby"
    @State private var showingCamera = false
    @State private var searchText = ""
    @State private var showingFilters = false
    
    private let tabs = ["nearby", "trending", "stories", "challenges"]
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [Theme.Colors.background, Theme.Colors.secondary.opacity(0.1)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 0) {
                        // Header with search and camera
                        headerSection
                        
                        // Story row (BrrowStories feature)
                        if selectedTab == "stories" || selectedTab == "nearby" {
                            storiesSection
                        }
                        
                        // Tab selector
                        tabSelector
                        
                        // Content based on selected tab
                        switch selectedTab {
                        case "nearby":
                            nearbySection
                        case "trending":
                            trendingSection
                        case "stories":
                            storiesDetailSection
                        case "challenges":
                            challengesSection
                        default:
                            nearbySection
                        }
                    }
                }
                .refreshable {
                    await discoverViewModel.refreshContent()
                }
                
                // Floating action button
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        floatingActionButton
                    }
                }
                .padding()
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingCamera) {
                BrrowCameraView()
            }
            .sheet(isPresented: $showingFilters) {
                AdvancedFiltersView()
            }
        }
        .onAppear {
            discoverViewModel.loadNearbyContent()
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: Theme.Spacing.md) {
            HStack {
                // Location indicator
                HStack(spacing: 6) {
                    Image(systemName: "location.fill")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Theme.Colors.primary)
                    
                    Text(discoverViewModel.currentLocation)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Theme.Colors.text)
                }
                
                Spacer()
                
                // Karma credits display
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.orange)
                    
                    Text("0") // karma removed per user request
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.orange)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(.orange.opacity(0.1))
                .cornerRadius(16)
                
                // Notifications
                Button(action: {}) {
                    ZStack {
                        Image(systemName: "bell.fill")
                            .font(.system(size: 18))
                            .foregroundColor(Theme.Colors.text)
                        
                        if discoverViewModel.unreadNotifications > 0 {
                            Circle()
                                .fill(Theme.Colors.error)
                                .frame(width: 8, height: 8)
                                .offset(x: 8, y: -8)
                        }
                    }
                }
            }
            
            // Search bar with AI suggestions
            HStack(spacing: Theme.Spacing.sm) {
                HStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Theme.Colors.secondaryText)
                    
                    TextField("Search or ask BrrowAI...", text: $searchText)
                        .font(.system(size: 16))
                        .onSubmit {
                            discoverViewModel.searchWithAI(query: searchText)
                        }
                    
                    if !searchText.isEmpty {
                        Button(action: { searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(Theme.Colors.secondaryText)
                        }
                    }
                }
                .padding(Theme.Spacing.md)
                .background(Theme.Colors.surface)
                .cornerRadius(20)
                .shadow(color: Theme.Shadows.card.opacity(0.1), radius: 2, x: 0, y: 1)
                
                // Camera button for instant posting
                Button(action: { showingCamera = true }) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(Theme.Colors.primary)
                        .cornerRadius(22)
                        .shadow(color: Theme.Colors.primary.opacity(0.3), radius: 4, x: 0, y: 2)
                }
                .pressableScale()
                
                // Filters
                Button(action: { showingFilters = true }) {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Theme.Colors.text)
                        .frame(width: 44, height: 44)
                        .background(Theme.Colors.surface)
                        .cornerRadius(22)
                }
                .pressableScale()
            }
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.top, Theme.Spacing.sm)
    }
    
    // MARK: - Stories Section (New Feature)
    private var storiesSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Theme.Spacing.sm) {
                // Add your story
                VStack {
                    ZStack {
                        Circle()
                            .stroke(style: StrokeStyle(lineWidth: 2, dash: [5]))
                            .foregroundColor(Theme.Colors.border)
                            .frame(width: 60, height: 60)
                        
                        Image(systemName: "plus")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(Theme.Colors.primary)
                    }
                    
                    Text("Your Story")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(Theme.Colors.secondaryText)
                }
                .onTapGesture {
                    showingCamera = true
                }
                
                ForEach(discoverViewModel.stories, id: \.id) { story in
                    BrrowStoryView(story: story)
                }
            }
            .padding(.horizontal, Theme.Spacing.md)
        }
        .padding(.vertical, Theme.Spacing.sm)
    }
    
    // MARK: - Tab Selector
    private var tabSelector: some View {
        HStack(spacing: 0) {
            ForEach(tabs, id: \.self) { tab in
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        selectedTab = tab
                        discoverViewModel.switchTab(to: tab)
                    }
                }) {
                    VStack(spacing: 4) {
                        HStack(spacing: 6) {
                            Image(systemName: iconForTab(tab))
                                .font(.system(size: 16, weight: .medium))
                            
                            Text(tab.capitalized)
                                .font(.system(size: 14, weight: .medium))
                        }
                        .foregroundColor(selectedTab == tab ? Theme.Colors.primary : Theme.Colors.secondaryText)
                        
                        Rectangle()
                            .fill(selectedTab == tab ? Theme.Colors.primary : Color.clear)
                            .frame(height: 2)
                            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: selectedTab)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.bottom, Theme.Spacing.sm)
    }
    
    // MARK: - Content Sections
    private var nearbySection: some View {
        LazyVStack(spacing: Theme.Spacing.md) {
            ForEach(discoverViewModel.nearbyListings, id: \.id) { listing in
                SocialListingCard(listing: listing, showDistance: true)
            }
        }
        .padding(.horizontal, Theme.Spacing.md)
    }
    
    private var trendingSection: some View {
        LazyVStack(spacing: Theme.Spacing.md) {
            ForEach(discoverViewModel.trendingListings, id: \.id) { listing in
                TrendingListingCard(listing: listing)
            }
        }
        .padding(.horizontal, Theme.Spacing.md)
    }
    
    private var storiesDetailSection: some View {
        LazyVStack(spacing: Theme.Spacing.lg) {
            ForEach(discoverViewModel.stories, id: \.id) { story in
                StoryDetailCard(story: story)
            }
        }
        .padding(.horizontal, Theme.Spacing.md)
    }
    
    private var challengesSection: some View {
        LazyVStack(spacing: Theme.Spacing.md) {
            ForEach(discoverViewModel.activeChallenges, id: \.id) { challenge in
                ChallengeCard(challenge: challenge)
            }
        }
        .padding(.horizontal, Theme.Spacing.md)
    }
    
    // MARK: - Floating Action Button
    private var floatingActionButton: some View {
        Button(action: {
            // Quick post action
        }) {
            Image(systemName: "plus")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 56, height: 56)
                .background(
                    LinearGradient(
                        colors: [Theme.Colors.primary, Theme.Colors.secondary],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .cornerRadius(28)
                .shadow(color: Theme.Colors.primary.opacity(0.4), radius: 8, x: 0, y: 4)
        }
        .pressableScale()
    }
    
    // MARK: - Helper Functions
    private func iconForTab(_ tab: String) -> String {
        switch tab {
        case "nearby": return "location.circle.fill"
        case "trending": return "flame.fill"
        case "stories": return "play.circle.fill"
        case "challenges": return "trophy.fill"
        default: return "circle"
        }
    }
}

// MARK: - Supporting Views
struct BrrowStoryView: View {
    let story: BrrowStory
    
    var body: some View {
        VStack {
            ZStack {
                AsyncImage(url: URL(string: story.thumbnailUrl)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Theme.Colors.secondary.opacity(0.3))
                }
                .frame(width: 60, height: 60)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [Theme.Colors.primary, Theme.Colors.secondary],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                )
            }
            
            Text(story.username)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(Theme.Colors.text)
                .lineLimit(1)
        }
        .frame(width: 70)
    }
}

struct SocialListingCard: View {
    let listing: Listing
    let showDistance: Bool
    @State private var isLiked = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // User header
            HStack {
                Circle()
                    .fill(Theme.Colors.secondary.opacity(0.3))
                    .frame(width: 32, height: 32)
                    .overlay(
                        Text("U")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                    )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("User #\(Int(listing.userId) ?? 0)")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Theme.Colors.text)
                    
                    if showDistance {
                        Text("2.3 km away")
                            .font(.system(size: 12))
                            .foregroundColor(Theme.Colors.secondaryText)
                    }
                }
                
                Spacer()
                
                // More options
                Button(action: {}) {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 16))
                        .foregroundColor(Theme.Colors.secondaryText)
                }
            }
            .padding(Theme.Spacing.md)
            
            // Image
            AsyncImage(url: URL(string: listing.firstImageUrl ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(Theme.Colors.secondary.opacity(0.2))
                    .overlay(
                        Image(systemName: "photo")
                            .font(.system(size: 32))
                            .foregroundColor(Theme.Colors.secondaryText)
                    )
            }
            .frame(height: 250)
            .clipped()
            
            // Action buttons (like Instagram)
            HStack(spacing: Theme.Spacing.md) {
                Button(action: { 
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        isLiked.toggle()
                    }
                }) {
                    Image(systemName: isLiked ? "heart.fill" : "heart")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(isLiked ? .red : Theme.Colors.text)
                        .scaleEffect(isLiked ? 1.2 : 1.0)
                }
                
                Button(action: {}) {
                    Image(systemName: "message")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(Theme.Colors.text)
                }
                
                Button(action: {}) {
                    Image(systemName: "paperplane")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(Theme.Colors.text)
                }
                
                Spacer()
                
                Button(action: {}) {
                    Image(systemName: "bookmark")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(Theme.Colors.text)
                }
            }
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.top, Theme.Spacing.sm)
            
            // Content
            VStack(alignment: .leading, spacing: 6) {
                Text(listing.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Theme.Colors.text)
                
                Text(listing.description)
                    .font(.system(size: 14))
                    .foregroundColor(Theme.Colors.secondaryText)
                    .lineLimit(2)
                
                HStack {
                    Text(listing.isFree ? "FREE" : "$\(Int(listing.price))/day")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(listing.isFree ? Theme.Colors.success : Theme.Colors.primary)
                    
                    Spacer()
                    
                    Text("2 hours ago")
                        .font(.system(size: 12))
                        .foregroundColor(Theme.Colors.secondaryText)
                }
            }
            .padding(Theme.Spacing.md)
        }
        .background(Theme.Colors.surface)
        .cornerRadius(Theme.CornerRadius.card)
        .shadow(color: Theme.Shadows.card.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

#Preview {
    DiscoverView()
        .environmentObject(HomeViewModel())
}