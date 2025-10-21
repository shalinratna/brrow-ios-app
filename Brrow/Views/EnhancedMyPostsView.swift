//
//  EnhancedMyPostsView.swift
//  Brrow
//
//  Enhanced My Posts view with full functionality and proper theme
//

import SwiftUI

struct EnhancedMyPostsView: View {
    @StateObject private var viewModel = MyPostsViewModel()
    @State private var selectedFilter: PostFilter = .all
    @State private var selectedPost: UserPost?
    @State private var showingEditView = false
    @State private var showingDetailView = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            Theme.Colors.background
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Custom header (no native navigation)
                customHeader
                
                // Filter section
                filterSection
                    .padding(.horizontal)
                    .padding(.vertical, 12)
                
                // Content
                if viewModel.isLoading && viewModel.posts.isEmpty {
                    loadingView
                } else if viewModel.posts.isEmpty {
                    emptyState
                } else {
                    postsScrollView
                }
            }
        }
        .onAppear {
            viewModel.loadPosts()
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("RefreshMyPosts"))) { notification in
            print("🔄 [MY POSTS] Received RefreshMyPosts notification - reloading posts")
            // Reload posts to show updated status
            viewModel.loadPosts()
        }
        .sheet(isPresented: $showingDetailView) {
            if let post = selectedPost {
                PostDetailSheet(post: post, onEdit: {
                    showingDetailView = false
                    showingEditView = true
                }, onDelete: {
                    viewModel.deletePost(post)
                    showingDetailView = false
                })
            }
        }
        .sheet(isPresented: $showingEditView) {
            if let post = selectedPost {
                EnhancedEditListingView(listing: convertPostToListing(post))
                    .onDisappear {
                        viewModel.loadPosts()
                        showingEditView = false
                    }
            }
        }
    }
    
    // MARK: - Custom Header
    private var customHeader: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.left")
                    .font(.title3)
                    .foregroundColor(Theme.Colors.primary)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(Theme.Colors.cardBackground)
                            .shadow(color: Theme.Shadows.card, radius: 4)
                    )
            }
            
            Spacer()
            
            Text("My Posts")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(Theme.Colors.text)
            
            Spacer()
            
            // Stats button
            Button(action: { /* Show stats */ }) {
                Image(systemName: "chart.bar.fill")
                    .font(.title3)
                    .foregroundColor(Theme.Colors.primary)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(Theme.Colors.cardBackground)
                            .shadow(color: Theme.Shadows.card, radius: 4)
                    )
            }
        }
        .padding(.horizontal)
        .padding(.top, 60)
        .padding(.bottom, 16)
        .background(Theme.Colors.background)
    }
    
    // MARK: - Filter Section
    private var filterSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(PostFilter.allCases, id: \.self) { filter in
                    PostFilterChip(
                        title: filter.title,
                        count: viewModel.getCount(for: filter),
                        isSelected: selectedFilter == filter,
                        color: filter.color
                    ) {
                        withAnimation(.spring(response: 0.3)) {
                            selectedFilter = filter
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Posts ScrollView
    private var postsScrollView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(filteredPosts) { post in
                    EnhancedPostCard(post: post)
                        .onTapGesture {
                            selectedPost = post
                            showingDetailView = true
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
    
    // MARK: - Loading View
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: Theme.Colors.primary))
                .scaleEffect(1.5)
            
            Text("Loading your posts...")
                .font(.system(size: 16))
                .foregroundColor(Theme.Colors.secondaryText)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: 24) {
            Image(systemName: "square.stack.3d.up.slash")
                .font(.system(size: 80))
                .foregroundColor(Theme.Colors.primary.opacity(0.3))
            
            VStack(spacing: 8) {
                Text("No Posts Yet")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(Theme.Colors.text)
                
                Text("Start sharing items, creating seeks,\nor hosting garage sales")
                    .font(.system(size: 16))
                    .foregroundColor(Theme.Colors.secondaryText)
                    .multilineTextAlignment(.center)
            }
            
            Button(action: {
                dismiss()
                TabSelectionManager.shared.selectedTab = 2
            }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Create Your First Post")
                }
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 32)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 30)
                        .fill(Theme.Colors.primary)
                )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // Convert UserPost to Listing for editing using JSON encoding/decoding
    private func convertPostToListing(_ post: UserPost) -> Listing {
        // Create a JSON representation of the post data
        let listingJSON: [String: Any] = [
            "id": post.id,
            "title": post.title,
            "description": post.content,
            "categoryId": post.category ?? "other",
            "condition": "good",
            "price": post.price ?? 0.0,
            "isNegotiable": false,
            "availabilityStatus": "AVAILABLE",
            "location": [
                "address": "Unknown",
                "city": "Unknown",
                "state": "Unknown",
                "zipCode": "00000",
                "country": "Unknown",
                "latitude": 0.0,
                "longitude": 0.0
            ],
            "userId": AuthManager.shared.currentUser?.apiId ?? "",
            "viewCount": 0,
            "favoriteCount": 0,
            "isActive": post.status == "active",
            "isPremium": false,
            "tags": [],
            "createdAt": post.createdAt,
            "updatedAt": post.updatedAt,
            "images": [],
            "imageUrl": post.imageUrl ?? ""
        ]

        // Convert to JSON data and decode as Listing
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: listingJSON)
            let listing = try JSONDecoder().decode(Listing.self, from: jsonData)
            return listing
        } catch {
            print("Error converting post to listing: \(error)")
            // Return a basic example listing as fallback
            return Listing.example
        }
    }
}

// MARK: - Enhanced Post Card
struct EnhancedPostCard: View {
    let post: UserPost
    
    var body: some View {
        HStack(spacing: 16) {
            // Thumbnail
            if let thumbnail = post.thumbnail {
                BrrowAsyncImage(url: thumbnail) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Theme.Colors.secondaryBackground)
                        .overlay(
                            Image(systemName: postIcon)
                                .font(.title2)
                                .foregroundColor(Theme.Colors.secondary)
                        )
                }
                .frame(width: 100, height: 100)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Theme.Colors.secondaryBackground)
                    .frame(width: 100, height: 100)
                    .overlay(
                        Image(systemName: postIcon)
                            .font(.title2)
                            .foregroundColor(Theme.Colors.secondary)
                    )
            }
            
            // Content
            VStack(alignment: .leading, spacing: 8) {
                // Type badge and status
                HStack {
                    Label(postTypeBadge, systemImage: postIcon)
                        .font(.caption.bold())
                        .foregroundColor(postTypeColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(postTypeColor.opacity(0.1))
                        )
                    
                    Spacer()
                    
                    PostStatusBadge(status: post.status)
                }
                
                // Title
                Text(post.title)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Theme.Colors.text)
                    .lineLimit(1)
                
                // Price or urgency
                if post.postType == "seek" {
                    HStack(spacing: 4) {
                        Image(systemName: "clock.fill")
                            .font(.caption)
                        Text(post.urgency ?? "Normal")
                            .font(.caption)
                    }
                    .foregroundColor(urgencyColor(post.urgency))
                } else if (post.price ?? 0) > 0 {
                    Text("$\(Int(post.price ?? 0))")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(Theme.Colors.primary)
                }
                
                // Date
                Text(formattedDate)
                    .font(.caption)
                    .foregroundColor(Theme.Colors.secondaryText)
            }
            
            Spacer()
            
            // Action indicator
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Theme.Colors.secondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Theme.Colors.cardBackground)
                .shadow(color: Theme.Shadows.card, radius: 4, y: 2)
        )
    }
    
    private var postIcon: String {
        switch post.postType {
        case "listing": return "cube.box.fill"
        case "seek": return "magnifyingglass.circle.fill"
        case "garage_sale": return "house.fill"
        default: return "square.fill"
        }
    }
    
    private var postTypeBadge: String {
        switch post.postType {
        case "listing": return "Listing"
        case "seek": return "Seek"
        case "garage_sale": return "Garage Sale"
        default: return "Post"
        }
    }
    
    private var postTypeColor: Color {
        switch post.postType {
        case "listing": return Theme.Colors.primary
        case "seek": return Theme.Colors.accentBlue
        case "garage_sale": return Theme.Colors.accentOrange
        default: return Theme.Colors.secondary
        }
    }
    
    private func urgencyColor(_ urgency: String?) -> Color {
        switch urgency {
        case "high": return .red
        case "medium": return .orange
        default: return Theme.Colors.secondary
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

// MARK: - Post Filter Chip
struct PostFilterChip: View {
    let title: String
    let count: Int
    let isSelected: Bool
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                
                if count > 0 {
                    Text("\(count)")
                        .font(.system(size: 12, weight: .bold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(isSelected ? Color.white.opacity(0.3) : color.opacity(0.2))
                        )
                }
            }
            .foregroundColor(isSelected ? .white : Theme.Colors.text)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(isSelected ? color : Theme.Colors.secondaryBackground)
            )
        }
    }
}

// MARK: - Post Status Badge
struct PostStatusBadge: View {
    let status: String
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(statusColor)
                .frame(width: 6, height: 6)
            
            Text(status.capitalized)
                .font(.caption.bold())
                .foregroundColor(statusColor)
        }
    }
    
    private var statusColor: Color {
        switch status {
        case "active": return .green
        case "pending": return .orange
        case "completed", "fulfilled": return .blue
        case "deleted", "cancelled": return .red
        default: return .gray
        }
    }
}

// MARK: - Universal Post Detail Panel
struct PostDetailSheet: View {
    let post: UserPost
    let onEdit: () -> Void
    let onDelete: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var selectedImageIndex = 0
    @State private var showingStats = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    // Enhanced Image Gallery
                    imageGallerySection

                    // Content Container
                    VStack(spacing: 24) {
                        // Header Info Section
                        headerInfoSection

                        // Stats and Performance Section
                        statsSection

                        // Details Grid Section
                        detailsGridSection

                        // Description Section
                        descriptionSection

                        // Action Buttons
                        actionButtonsSection
                    }
                    .padding(20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(Theme.Colors.primary)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: onEdit) {
                            Label("Edit Listing", systemImage: "pencil")
                        }

                        Button(role: .destructive, action: onDelete) {
                            Label("Delete Listing", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundColor(Theme.Colors.primary)
                    }
                }
            }
        }
    }

    // MARK: - Enhanced Image Gallery
    private var imageGallerySection: some View {
        Group {
            if let thumbnail = post.thumbnail {
                BrrowAsyncImage(url: thumbnail) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
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
                        .overlay(
                            VStack {
                                Image(systemName: "photo")
                                    .font(.system(size: 40))
                                    .foregroundColor(Theme.Colors.primary.opacity(0.5))
                                Text("Loading image...")
                                    .font(.caption)
                                    .foregroundColor(Theme.Colors.secondaryText)
                            }
                        )
                }
                .frame(height: 350)
                .clipped()
            } else {
                Rectangle()
                    .fill(Theme.Colors.secondaryBackground)
                    .frame(height: 350)
                    .overlay(
                        VStack {
                            Image(systemName: "photo.badge.plus")
                                .font(.system(size: 40))
                                .foregroundColor(Theme.Colors.primary.opacity(0.5))
                            Text("No image available")
                                .font(.caption)
                                .foregroundColor(Theme.Colors.secondaryText)
                        }
                    )
            }
        }
    }

    // MARK: - Header Info Section
    private var headerInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(post.title)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(Theme.Colors.text)
                        .lineLimit(3)

                    if let category = post.category {
                        Text(category.capitalized)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Theme.Colors.primary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(
                                Theme.Colors.primary.opacity(0.1)
                                    .clipShape(Capsule())
                            )
                    }
                }

                Spacer()

                if let price = post.price, price > 0 {
                    VStack(alignment: .trailing) {
                        Text("$\(Int(price))")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(Theme.Colors.primary)

                        Text(post.postType.capitalized)
                            .font(.caption)
                            .foregroundColor(Theme.Colors.secondaryText)
                    }
                }
            }
        }
    }

    // MARK: - Stats Section
    private var statsSection: some View {
        HStack(spacing: 16) {
            StatCardView(
                title: "Views",
                value: "0",
                icon: "eye",
                color: Theme.Colors.primary
            )

            StatCardView(
                title: "Saves",
                value: "0",
                icon: "heart",
                color: .red
            )

            StatCardView(
                title: "Status",
                value: "\(post.status.capitalized)",
                icon: "checkmark.circle",
                color: .green
            )

            StatCardView(
                title: "Status",
                value: post.status.capitalized,
                icon: post.status == "active" ? "checkmark.circle" : "clock",
                color: post.status == "active" ? .green : .orange
            )
        }
    }

    // MARK: - Details Grid
    private var detailsGridSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Details")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(Theme.Colors.text)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                DetailRowView(title: "Created", value: formatDate(post.createdAt))
                DetailRowView(title: "Updated", value: formatDate(post.updatedAt))
                DetailRowView(title: "Post ID", value: "#\(post.id)")
                DetailRowView(title: "Type", value: post.postType.capitalized)
            }
        }
    }

    // MARK: - Description Section
    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Description")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(Theme.Colors.text)

            Text(post.content.isEmpty ? "No description provided" : post.content)
                .font(.system(size: 16))
                .foregroundColor(post.content.isEmpty ? Theme.Colors.secondaryText : Theme.Colors.text)
                .lineLimit(nil)
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Theme.Colors.secondaryBackground)
                )
        }
    }

    // MARK: - Action Buttons
    private var actionButtonsSection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Button(action: onEdit) {
                    HStack {
                        Image(systemName: "pencil")
                        Text("Edit Listing")
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Theme.Colors.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                Button(action: { showingStats.toggle() }) {
                    HStack {
                        Image(systemName: "chart.bar")
                        Text("Analytics")
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Theme.Colors.primary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Theme.Colors.primary, lineWidth: 2)
                    )
                }
            }

            Button(role: .destructive, action: onDelete) {
                HStack {
                    Image(systemName: "trash")
                    Text("Delete Listing")
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.red)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.red, lineWidth: 2)
                )
            }
        }
    }

    // MARK: - Helper Functions
    private func formatDate(_ dateString: String?) -> String {
        guard let dateString = dateString else { return "Unknown" }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"

        if let date = formatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .medium
            displayFormatter.timeStyle = .short
            return displayFormatter.string(from: date)
        }

        return dateString
    }
}

// MARK: - Supporting Components
struct StatCardView: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)

            Text(value)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(Theme.Colors.text)

            Text(title)
                .font(.system(size: 12))
                .foregroundColor(Theme.Colors.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Theme.Colors.secondaryBackground)
        )
    }
}

struct DetailRowView: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Theme.Colors.secondaryText)

            Text(value)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Theme.Colors.text)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Theme.Colors.secondaryBackground)
        )
    }
}


// MARK: - Post Filter Extension
extension PostFilter {
    var color: Color {
        switch self {
        case .all: return Theme.Colors.primary
        case .listings: return Theme.Colors.primary
        case .seeks: return Theme.Colors.accentBlue
        case .garageSales: return Theme.Colors.accentOrange
        }
    }
}

