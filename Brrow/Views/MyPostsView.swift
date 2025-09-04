//
//  MyPostsView.swift
//  Brrow
//
//  Unified view for managing all user posts (listings, seeks, garage sales)
//

import SwiftUI
import Foundation

struct MyPostsView: View {
    @StateObject private var viewModel = MyPostsViewModel()
    @State private var selectedFilter: PostFilter = .all
    @State private var selectedPost: UserPost?
    @State private var showingEditView = false
    @State private var showingAnalytics = false
    
    var body: some View {
        ZStack {
            Theme.Colors.background
                .ignoresSafeArea()
            
            if viewModel.isLoading && viewModel.posts.isEmpty {
                ProgressView("Loading posts...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                VStack(spacing: 0) {
                    // Filter Pills
                    filterSection
                        .padding(.horizontal)
                        .padding(.vertical, 12)
                    
                    if viewModel.posts.isEmpty {
                        emptyState
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(filteredPosts) { post in
                                    PostCard(post: post) {
                                        selectedPost = post
                                        showingEditView = true
                                    }
                                    .padding(.horizontal)
                                }
                                
                                if viewModel.isLoadingMore {
                                    ProgressView()
                                        .padding()
                                }
                            }
                            .padding(.vertical, 8)
                        }
                    }
                }
            }
        }
        .navigationTitle("My Posts")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingAnalytics = true }) {
                    Image(systemName: "chart.bar.xaxis")
                        .foregroundColor(Theme.Colors.primary)
                }
            }
        }
        .onAppear {
            viewModel.loadPosts()
        }
        .sheet(isPresented: $showingEditView) {
            if let post = selectedPost {
                EditPostNavigationView(post: post) {
                    // Refresh after edit
                    viewModel.loadPosts()
                }
            }
        }
        .sheet(isPresented: $showingAnalytics) {
            PostsAnalyticsView(posts: viewModel.posts)
        }
    }
    
    // MARK: - Filter Section
    private var filterSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(PostFilter.allCases, id: \.self) { filter in
                    FilterPill(
                        title: filter.title,
                        count: viewModel.getCount(for: filter),
                        isSelected: selectedFilter == filter
                    ) {
                        withAnimation(.spring(response: 0.3)) {
                            selectedFilter = filter
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Filtered Posts
    private var filteredPosts: [UserPost] {
        switch selectedFilter {
        case .all:
            return viewModel.posts
        case .listings:
            return viewModel.posts.filter { $0.postType == "listing" }
        case .seeks:
            return viewModel.posts.filter { $0.postType == "seek" }
        case .garageSales:
            return viewModel.posts.filter { $0.postType == "garage_sale" }
        }
    }
    
    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "square.stack.3d.up.slash")
                .font(.system(size: 60))
                .foregroundColor(Theme.Colors.secondary)
            
            Text("No Posts Yet")
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(Theme.Colors.text)
            
            Text("Start sharing items, creating seeks, or hosting garage sales")
                .font(.system(size: 16))
                .foregroundColor(Theme.Colors.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Button(action: {
                TabSelectionManager.shared.selectedTab = 2 // Post tab
            }) {
                Text("Create Your First Post")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Theme.Colors.primary)
                    .cornerRadius(25)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Post Card
struct PostCard: View {
    let post: UserPost
    let onEdit: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                // Thumbnail
                if let thumbnail = post.displayThumbnail {
                    AsyncImage(url: URL(string: thumbnail)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Rectangle()
                            .fill(Theme.Colors.secondary.opacity(0.2))
                            .overlay(
                                Image(systemName: iconForPostType)
                                    .font(.system(size: 24))
                                    .foregroundColor(Theme.Colors.secondary)
                            )
                    }
                    .frame(width: 80, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    Rectangle()
                        .fill(Theme.Colors.secondary.opacity(0.2))
                        .overlay(
                            Image(systemName: iconForPostType)
                                .font(.system(size: 24))
                                .foregroundColor(Theme.Colors.secondary)
                        )
                        .frame(width: 80, height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                
                // Content
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(post.title)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Theme.Colors.text)
                            .lineLimit(1)
                        
                        Spacer()
                        
                        // Post Type Badge
                        Text(postTypeBadge)
                            .font(.system(size: 11, weight: .medium))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(postTypeColor.opacity(0.2))
                            .foregroundColor(postTypeColor)
                            .cornerRadius(4)
                    }
                    
                    // Price/Budget
                    if post.price > 0 {
                        Text("$\(String(format: "%.2f", post.price))\(post.postType == "listing" ? "/day" : "")")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Theme.Colors.primary)
                    }
                    
                    // Status
                    HStack(spacing: 12) {
                        // Status Badge
                        HStack(spacing: 4) {
                            Circle()
                                .fill(statusColor)
                                .frame(width: 6, height: 6)
                            
                            Text(post.status.capitalized)
                                .font(.system(size: 12))
                                .foregroundColor(Theme.Colors.secondaryText)
                        }
                        
                        // Date
                        Text("Created \(formattedDate)")
                            .font(.system(size: 12))
                            .foregroundColor(Theme.Colors.tertiaryText)
                    }
                    
                    // Edit Restrictions
                    if !post.editRestrictions.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 10))
                                .foregroundColor(.orange)
                            
                            Text(post.editRestrictions.first ?? "")
                                .font(.system(size: 11))
                                .foregroundColor(.orange)
                                .lineLimit(1)
                        }
                    }
                }
                
                // Edit Button
                Button(action: onEdit) {
                    Image(systemName: post.canEdit ? "pencil" : "lock.fill")
                        .font(.system(size: 16))
                        .foregroundColor(post.canEdit ? Theme.Colors.primary : Theme.Colors.secondary)
                        .frame(width: 40, height: 40)
                        .background(Theme.Colors.secondaryBackground)
                        .clipShape(Circle())
                }
                .disabled(!post.canEdit)
            }
            .padding()
        }
        .background(Theme.Colors.cardBackground)
        .cornerRadius(12)
        .shadow(color: Theme.Shadows.card, radius: 4, x: 0, y: 2)
    }
    
    private var iconForPostType: String {
        switch post.postType {
        case "listing":
            return "tag.fill"
        case "seek":
            return "magnifyingglass"
        case "garage_sale":
            return "house.fill"
        default:
            return "square.fill"
        }
    }
    
    private var postTypeBadge: String {
        switch post.postType {
        case "listing":
            return "Listing"
        case "seek":
            return "Seek"
        case "garage_sale":
            return "Garage Sale"
        default:
            return "Post"
        }
    }
    
    private var postTypeColor: Color {
        switch post.postType {
        case "listing":
            return Theme.Colors.primary
        case "seek":
            return Theme.Colors.accentBlue
        case "garage_sale":
            return Theme.Colors.accentOrange
        default:
            return Theme.Colors.secondary
        }
    }
    
    private var statusColor: Color {
        switch post.status {
        case "active":
            return .green
        case "pending":
            return .orange
        case "completed", "fulfilled":
            return .blue
        case "deleted", "cancelled":
            return .red
        default:
            return .gray
        }
    }
    
    private var formattedDate: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        
        if let date = ISO8601DateFormatter().date(from: post.createdAt) {
            return formatter.localizedString(for: date, relativeTo: Date())
        }
        return ""
    }
}

// MARK: - Filter Pill
struct FilterPill: View {
    let title: String
    let count: Int
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                
                if count > 0 {
                    Text("\(count)")
                        .font(.system(size: 12, weight: .semibold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(isSelected ? Color.white.opacity(0.3) : Theme.Colors.primary.opacity(0.2))
                        )
                }
            }
            .foregroundColor(isSelected ? .white : Theme.Colors.text)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(isSelected ? Theme.Colors.primary : Theme.Colors.secondaryBackground)
            )
        }
    }
}

// MARK: - Post Filter
enum PostFilter: String, CaseIterable {
    case all = "All"
    case listings = "Listings"
    case seeks = "Seeks"
    case garageSales = "Garage Sales"
    
    var title: String { rawValue }
}

// MARK: - User Post Model
struct UserPost: Identifiable, Codable {
    let id: Int
    let listingId: String?
    let postType: String
    let title: String
    let description: String
    let price: Double
    let category: String
    let status: String
    let createdAt: String
    let updatedAt: String
    let images: [String]?  // Add images array from API
    let thumbnail: String? // Keep for backward compatibility
    let canEdit: Bool
    let editRestrictions: [String]
    
    // Additional fields for different post types
    let urgency: String?
    let startDate: String?
    let endDate: String?
    let hasActiveRental: Bool?
    let hasStarted: Bool?
    let hasEnded: Bool?
    
    // Computed property to get thumbnail from images array or thumbnail field
    var displayThumbnail: String? {
        if let firstImage = images?.first {
            return firstImage
        }
        return thumbnail
    }
    
    enum CodingKeys: String, CodingKey {
        case id, title, description, price, category, status, thumbnail, images, urgency
        case listingId = "listing_id"
        case postType = "post_type"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case canEdit = "can_edit"
        case editRestrictions = "edit_restrictions"
        case startDate = "start_date"
        case endDate = "end_date"
        case hasActiveRental = "has_active_rental"
        case hasStarted = "has_started"
        case hasEnded = "has_ended"
    }
}

// MARK: - View Model
class MyPostsViewModel: ObservableObject {
    @Published var posts: [UserPost] = []
    @Published var isLoading = false
    @Published var isLoadingMore = false
    private var offset = 0
    private let limit = 20
    private var hasMore = true
    
    func loadPosts() {
        isLoading = true
        offset = 0
        
        Task {
            do {
                // Debug: Check authentication status
                let currentUser = AuthManager.shared.currentUser
                let apiId = currentUser?.apiId ?? ""
                print("🔍 MyPostsView - Loading posts for user: \(apiId.isEmpty ? "NO USER" : apiId)")
                
                var allPosts: [UserPost] = []
                
                // Fetch user listings
                let listingsResponse = try await APIClient.shared.fetchUserListings(userId: apiId)
                print("📦 MyPostsView - Listings Response: success=\(listingsResponse.success), listings=\(listingsResponse.data?.listings.count ?? 0)")
                
                if listingsResponse.success, let listings = listingsResponse.data?.listings {
                    // Convert listings to UserPost format
                    let listingPosts = listings.map { listing -> UserPost in
                        // Format dates from listing
                        let formatter = ISO8601DateFormatter()
                        let createdAtString = formatter.string(from: listing.createdAt)
                        let updatedAtString = formatter.string(from: listing.updatedAt ?? listing.createdAt)
                        
                        return UserPost(
                            id: listing.id,  // Keep numeric ID for internal use
                            listingId: listing.listingId,  // Use API ID for all API calls
                            postType: "listing",
                            title: listing.title,
                            description: listing.description,
                            price: listing.price,
                            category: listing.category,
                            status: listing.status,
                            createdAt: createdAtString,
                            updatedAt: updatedAtString,
                            images: listing.images,  // Pass the images array
                            thumbnail: listing.images.first,  // Keep for backward compatibility
                            canEdit: true,
                            editRestrictions: [],
                            urgency: nil,
                            startDate: nil,
                            endDate: nil,
                            hasActiveRental: false,
                            hasStarted: nil,
                            hasEnded: nil
                        )
                    }
                    allPosts.append(contentsOf: listingPosts)
                }
                
                // Fetch user seeks
                do {
                    let seeksResponse = try await APIClient.shared.fetchUserSeeks(userId: apiId)
                    print("🔎 MyPostsView - Seeks Response: \(seeksResponse.count) seeks")
                    
                    let seekPosts = seeksResponse.map { seek -> UserPost in
                        return UserPost(
                            id: seek.id,
                            listingId: "seek_\(seek.id)",
                            postType: "seek",
                            title: seek.title,
                            description: seek.description,
                            price: seek.maxBudget ?? 0,
                            category: seek.category,
                            status: seek.status,
                            createdAt: seek.createdAt,
                            updatedAt: seek.createdAt, // Use createdAt since updatedAt doesn't exist
                            images: [],
                            thumbnail: nil,
                            canEdit: true,
                            editRestrictions: [],
                            urgency: seek.urgency,
                            startDate: nil,
                            endDate: nil,
                            hasActiveRental: false,
                            hasStarted: nil,
                            hasEnded: nil
                        )
                    }
                    allPosts.append(contentsOf: seekPosts)
                } catch {
                    print("⚠️ MyPostsView - Failed to load seeks: \(error)")
                }
                
                // Fetch user garage sales
                do {
                    let garageSalesResponse = try await APIClient.shared.fetchUserGarageSales(userId: apiId)
                    print("🏠 MyPostsView - Garage Sales Response: \(garageSalesResponse.count) sales")
                    
                    let garageSalePosts = garageSalesResponse.map { sale -> UserPost in
                        return UserPost(
                            id: sale.id,
                            listingId: "sale_\(sale.id)",
                            postType: "garage_sale",
                            title: sale.title,
                            description: sale.description ?? "",
                            price: 0,
                            category: "Garage Sale",
                            status: sale.status ?? sale.computedStatus,
                            createdAt: sale.startDate, // Use startDate since createdAt doesn't exist
                            updatedAt: sale.endDate, // Use endDate as updatedAt
                            images: sale.images,
                            thumbnail: sale.images.first,
                            canEdit: true,
                            editRestrictions: [],
                            urgency: nil,
                            startDate: sale.startDate,
                            endDate: sale.endDate,
                            hasActiveRental: false,
                            hasStarted: !sale.isUpcoming, // Started if not upcoming
                            hasEnded: sale.isPast
                        )
                    }
                    allPosts.append(contentsOf: garageSalePosts)
                } catch {
                    print("⚠️ MyPostsView - Failed to load garage sales: \(error)")
                }
                
                // Sort all posts by creation date
                allPosts.sort { post1, post2 in
                    post1.createdAt > post2.createdAt
                }
                
                await MainActor.run {
                    self.posts = allPosts
                    self.hasMore = false // API returns all posts at once
                    self.offset = allPosts.count
                    self.isLoading = false
                    print("✅ MyPostsView - Loaded \(allPosts.count) total posts")
                }
            } catch {
                print("❌ MyPostsView - Error loading posts: \(error)")
                await MainActor.run {
                    self.isLoading = false
                }
            }
        }
    }
    
    func loadMore() {
        // fetch_user_listings returns all posts at once, so no pagination needed
        guard !isLoadingMore && hasMore else { return }
        
        // Since we get all posts at once, just return
        isLoadingMore = false
        hasMore = false
    }
    
    func getCount(for filter: PostFilter) -> Int {
        switch filter {
        case .all:
            return posts.count
        case .listings:
            return posts.filter { $0.postType == "listing" }.count
        case .seeks:
            return posts.filter { $0.postType == "seek" }.count
        case .garageSales:
            return posts.filter { $0.postType == "garage_sale" }.count
        }
    }
}


// MARK: - Edit Post Navigation
struct EditPostNavigationView: View {
    let post: UserPost
    let onComplete: () -> Void
    @Environment(\.dismiss) var dismiss
    @State private var listing: Listing?
    @State private var isLoadingListing = false
    @StateObject private var listingNavManager = ListingNavigationManager.shared
    
    var body: some View {
        NavigationView {
            Group {
                switch post.postType {
                case "listing":
                    if let listing = listing {
                        // Show the full listing detail view which will include edit options since user owns it
                        ProfessionalListingDetailView(listing: listing)
                            .environmentObject(AuthManager.shared)
                            .navigationBarTitleDisplayMode(.inline)
                            .onDisappear {
                                // Refresh the posts after any changes
                                onComplete()
                            }
                    } else if isLoadingListing {
                        ProgressView("Loading listing...")
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        Text("Failed to load listing")
                            .foregroundColor(.red)
                    }
                case "seek":
                    // TODO: Load seek and show EditSeekView
                    Text("Edit Seek - Coming Soon")
                        .onAppear {
                            onComplete()
                            dismiss()
                        }
                case "garage_sale":
                    // TODO: Load garage sale and show EditGarageSaleView
                    Text("Edit Garage Sale - Coming Soon")
                        .onAppear {
                            onComplete()
                            dismiss()
                        }
                default:
                    Text("Unknown post type")
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            if post.postType == "listing" {
                loadListing()
            }
        }
    }
    
    private func loadListing() {
        isLoadingListing = true
        
        // Create a temporary listing from the post data
        // In a real app, you'd fetch the full listing from the API
        Task {
            await MainActor.run {
                self.listing = Listing(
                    id: post.id,
                    listingId: post.listingId ?? "lst_\(post.id)",
                    ownerId: 0, // Will be set from API
                    title: post.title,
                    description: post.description,
                    price: post.price,
                    priceType: .daily,
                    buyoutValue: nil,
                    createdAt: ISO8601DateFormatter().date(from: post.createdAt) ?? Date(),
                    updatedAt: ISO8601DateFormatter().date(from: post.updatedAt),
                    status: post.status,
                    category: post.category,
                    type: "listing",
                    location: Location(
                        address: "",
                        city: "San Francisco",
                        state: "CA",
                        zipCode: "94107",
                        country: "USA",
                        latitude: 37.7749,
                        longitude: -122.4194
                    ),
                    views: 0,
                    timesBorrowed: 0,
                    inventoryAmt: 1,
                    isActive: post.status == "active",
                    isArchived: false,
                    images: post.thumbnail != nil ? [post.thumbnail!] : [],
                    rating: nil
                )
                self.isLoadingListing = false
            }
        }
    }
}
