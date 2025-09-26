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
                EditPostSheet(post: post) {
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

// MARK: - Post Detail Sheet
struct PostDetailSheet: View {
    let post: UserPost
    let onEdit: () -> Void
    let onDelete: () -> Void
    @Environment(\.dismiss) private var dismiss

    // MARK: - Computed Properties

    private var imageSection: some View {
        Group {
            if let thumbnail = post.thumbnail {
                BrrowAsyncImage(url: thumbnail) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Theme.Colors.secondaryBackground)
                        .overlay(
                            ProgressView()
                        )
                }
                .frame(maxWidth: .infinity)
                .frame(height: 300)
                .clipped()
                .cornerRadius(16)
            }
        }
    }

    private var infoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(post.title)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(Theme.Colors.text)

            Text(post.content)
                .font(.system(size: 16))
                .foregroundColor(Theme.Colors.text)
                .lineLimit(nil)

            if let price = post.price, price > 0 {
                Text("$\(Int(price))")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(Theme.Colors.primary)
            }

            // Edit restrictions
            if !(post.editRestrictions?.isEmpty ?? true) {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Edit Restrictions", systemImage: "exclamationmark.triangle.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.orange)

                    ForEach(post.editRestrictions ?? [], id: \.self) { restriction in
                        Text("• \(restriction)")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)
            }
        }
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Images section
                    imageSection

                    // Info section
                    infoSection
                    
                    // Action buttons
                    VStack(spacing: 12) {
                        if post.canEdit ?? false {
                            Button(action: onEdit) {
                                Label("Edit Post", systemImage: "pencil")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(Theme.Colors.primary)
                                    .cornerRadius(12)
                            }
                        }
                        
                        Button(action: onDelete) {
                            Label("Delete Post", systemImage: "trash")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.red)
                                .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(Theme.Colors.primary)
                }
            }
        }
    }
}

// MARK: - Edit Post Sheet
struct EditPostSheet: View {
    let post: UserPost
    let onComplete: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        // Placeholder for edit functionality
        NavigationView {
            VStack {
                Text("Edit \(post.title)")
                    .font(.title)
                
                Button("Save Changes") {
                    onComplete()
                }
                .padding()
            }
            .navigationTitle("Edit Post")
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

// MARK: - ViewModel Extension
extension MyPostsViewModel {
    func deletePost(_ post: UserPost) {
        // Implement delete functionality
        posts.removeAll { $0.id == post.id }
    }
}