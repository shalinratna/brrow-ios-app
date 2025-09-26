//
//  ModernListingDetailView.swift
//  Brrow
//
//  Clean, modern listing detail view with full owner functionality
//

import SwiftUI
import MapKit

struct ModernListingDetailView: View {
    let listing: Listing
    @StateObject private var viewModel: ListingDetailViewModel
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authManager: AuthManager
    @State private var refreshID = UUID()
    
    // State variables
    @State private var selectedImageIndex = 0
    @State private var imageRefreshID = UUID()
    @State private var currentImageUrls: [String] = []
    @State private var showingEditSheet = false
    @State private var showingShareSheet = false
    @State private var showingDeleteAlert = false
    @State private var showingStatusMenu = false
    @State private var showingPriceEdit = false
    @State private var showingInventoryEdit = false
    @State private var showingChatView = false
    @State private var showingOfferSheet = false
    @State private var showingSellerProfile = false
    
    // Edit states for owner
    @State private var editedPrice: String = ""
    @State private var editedInventory: String = ""
    @State private var newStatus: String = ""
    
    private var isOwner: Bool {
        guard let currentUser = authManager.currentUser else { return false }
        return listing.userId == currentUser.id || 
               viewModel.listing.user?.apiId == currentUser.apiId
    }
    
    init(listing: Listing) {
        self.listing = listing
        self._viewModel = StateObject(wrappedValue: ListingDetailViewModel(listing: listing))
    }
    
    var body: some View {
        ZStack {
            // Main content
            ScrollView {
                VStack(spacing: 0) {
                    // Image carousel with overlay info
                    imageSection
                    
                    // Quick info bar
                    if isOwner {
                        ownerQuickStatsBar
                            .padding(.horizontal)
                            .padding(.top, -30)
                            .zIndex(1)
                    }
                    
                    // Main content sections
                    VStack(spacing: 24) {
                        // Title and price section
                        titlePriceSection
                        
                        // Key details grid
                        keyDetailsGrid
                        
                        // Description
                        descriptionSection
                        
                        // Seller or owner info
                        if isOwner {
                            ownerControlsSection
                        } else {
                            sellerInfoSection
                        }
                        
                        // Location
                        locationSection
                        
                        // Similar items (for non-owners)
                        if !isOwner && !viewModel.similarListings.isEmpty {
                            similarItemsSection
                        }
                    }
                    .padding()
                    .padding(.bottom, 100) // Space for bottom bar
                }
            }
            .ignoresSafeArea(edges: .top)
            
            // Custom navigation bar
            customNavigationBar
            
            // Bottom action bar
            VStack {
                Spacer()
                bottomActionBar
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            setupInitialValues()
            currentImageUrls = viewModel.listing.imageUrls
        }
        .onReceive(viewModel.$listing) { updatedListing in
            print("📱 View received listing update with \(updatedListing.imageUrls.count) images")
            if currentImageUrls != updatedListing.imageUrls {
                print("🔄 Updating image URLs from \(currentImageUrls.count) to \(updatedListing.imageUrls.count)")
                currentImageUrls = updatedListing.imageUrls
                imageRefreshID = UUID()
                // Reset index if out of bounds
                if selectedImageIndex >= currentImageUrls.count {
                    selectedImageIndex = 0
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            EditListingView(listing: listing)
        }
        .sheet(isPresented: $showingSellerProfile) {
            if let seller = viewModel.seller {
                NavigationView {
                    ProfileView()
                }
            }
        }
        .alert("Delete Listing", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteListing()
            }
        } message: {
            Text("Are you sure you want to delete this listing? This action cannot be undone.")
        }
    }
    
    // MARK: - Image Section
    
    private var imageSection: some View {
        ZStack(alignment: .bottom) {
            // Debug output
            let _ = print("🖼️ ModernListingDetailView rendering - Images count: \(currentImageUrls.count)")
            let _ = currentImageUrls.enumerated().forEach { index, url in
                print("  🖼️ Image \(index): \(url)")
            }
            
            if currentImageUrls.isEmpty {
                // Placeholder when no images
                Rectangle()
                    .fill(Color.gray.opacity(0.1))
                    .frame(height: 400)
                    .overlay(
                        VStack(spacing: 12) {
                            Image(systemName: "photo.on.rectangle.angled")
                                .font(.system(size: 50))
                                .foregroundColor(.gray.opacity(0.3))
                            Text("No images available")
                                .font(.system(size: 16))
                                .foregroundColor(.gray.opacity(0.5))
                        }
                    )
            } else {
                // Image carousel
                TabView(selection: $selectedImageIndex) {
                    ForEach(Array(currentImageUrls.enumerated()), id: \.1) { index, imageUrl in
                        BrrowAsyncImage(url: imageUrl) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(height: 400)
                                .clipped()
                        } placeholder: {
                            Rectangle()
                                .fill(Theme.Colors.divider.opacity(0.3))
                                .frame(height: 400)
                                .overlay(
                                    ProgressView()
                                        .scaleEffect(0.8)
                                )
                        }
                        .onAppear {
                            print("📸 TabView item \(index + 1) appeared with URL: \(imageUrl)")
                            // Pre-load adjacent images for smooth scrolling
                            if index > 0 {
                                ImageCacheManager.shared.preloadImages([currentImageUrls[index - 1]])
                            }
                            if index < currentImageUrls.count - 1 {
                                ImageCacheManager.shared.preloadImages([currentImageUrls[index + 1]])
                            }
                        }
                        .tag(index)
                    }
                }
                .frame(height: 400)
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .indexViewStyle(.page(backgroundDisplayMode: .never))
                .onAppear {
                    print("🎨 TabView appeared with \(currentImageUrls.count) images")
                }
                .id(imageRefreshID) // Force refresh when images change
                
                // Custom page indicator
                HStack(spacing: 8) {
                    ForEach(0..<currentImageUrls.count, id: \.self) { index in
                        Circle()
                            .fill(index == selectedImageIndex ? Color.white : Color.white.opacity(0.5))
                            .frame(width: 8, height: 8)
                    }
                }
                .padding(.bottom, 20)
            }
        }
    }
    
    // MARK: - Custom Navigation Bar
    
    private var customNavigationBar: some View {
        VStack {
            HStack {
                // Back button
                Button(action: { dismiss() }) {
                    Image(systemName: "arrow.left")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(Color.black.opacity(0.3))
                        .clipShape(Circle())
                }
                
                Spacer()
                
                // Share button
                Button(action: { showingShareSheet = true }) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(Color.black.opacity(0.3))
                        .clipShape(Circle())
                }
                
                // Favorite button (non-owners only)
                if !isOwner {
                    Button(action: { viewModel.toggleFavorite() }) {
                        Image(systemName: viewModel.isFavorited ? "heart.fill" : "heart")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(viewModel.isFavorited ? .red : .white)
                            .frame(width: 44, height: 44)
                            .background(Color.black.opacity(0.3))
                            .clipShape(Circle())
                    }
                }
            }
            .padding(.horizontal)
            .padding(.top, 50)
            
            Spacer()
        }
    }
    
    // MARK: - Owner Quick Stats Bar
    
    private var ownerQuickStatsBar: some View {
        HStack(spacing: 0) {
            // Status
            VStack(spacing: 4) {
                HStack(spacing: 4) {
                    Circle()
                        .fill(statusColor)
                        .frame(width: 8, height: 8)
                    Text(statusText)
                        .font(.system(size: 12, weight: .semibold))
                }
                Text("Status")
                    .font(.system(size: 10))
                    .foregroundColor(Theme.Colors.secondaryText)
            }
            .frame(maxWidth: .infinity)
            
            Divider()
                .frame(height: 30)
            
            // Views
            VStack(spacing: 4) {
                Text("\(viewModel.listing.views)")
                    .font(.system(size: 14, weight: .bold))
                Text("Views")
                    .font(.system(size: 10))
                    .foregroundColor(Theme.Colors.secondaryText)
            }
            .frame(maxWidth: .infinity)
            
            Divider()
                .frame(height: 30)
            
            // Interest
            VStack(spacing: 4) {
                Text("\(viewModel.listing.timesBorrowed)")
                    .font(.system(size: 14, weight: .bold))
                Text("Interest")
                    .font(.system(size: 10))
                    .foregroundColor(Theme.Colors.secondaryText)
            }
            .frame(maxWidth: .infinity)
            
            Divider()
                .frame(height: 30)
            
            // Stock
            VStack(spacing: 4) {
                Text("\(viewModel.listing.inventoryAmt)")
                    .font(.system(size: 14, weight: .bold))
                Text("Stock")
                    .font(.system(size: 10))
                    .foregroundColor(Theme.Colors.secondaryText)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(Theme.Colors.cardBackground)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 10, y: 5)
    }
    
    // MARK: - Title and Price Section
    
    private var titlePriceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Title
            Text(viewModel.listing.title)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(Theme.Colors.text)
            
            // Price row
            HStack(alignment: .bottom) {
                if isOwner {
                    // Editable price for owner
                    Button(action: { showingPriceEdit = true }) {
                        HStack(spacing: 4) {
                            Text(priceDisplay)
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundColor(Theme.Colors.primary)
                            Image(systemName: "pencil.circle.fill")
                                .font(.system(size: 16))
                                .foregroundColor(Theme.Colors.primary.opacity(0.7))
                        }
                    }
                    .alert("Edit Price", isPresented: $showingPriceEdit) {
                        TextField("Price", text: $editedPrice)
                            .keyboardType(.decimalPad)
                        Button("Cancel", role: .cancel) { }
                        Button("Save") {
                            updatePrice()
                        }
                    }
                } else {
                    Text(priceDisplay)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(Theme.Colors.primary)
                }
                
                Spacer()
                
                // Category badge
                Label(viewModel.listing.category?.name ?? "General", systemImage: "tag.fill")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Theme.Colors.primary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Theme.Colors.primary.opacity(0.1))
                    .cornerRadius(20)
            }
        }
    }
    
    // MARK: - Key Details Grid
    
    private var keyDetailsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            // Condition
            DetailCard(
                icon: "checkmark.shield",
                title: "Condition",
                value: viewModel.listing.condition,
                color: .green
            )
            
            // Type
            DetailCard(
                icon: viewModel.listing.price == 0 ? "gift" : "tag",
                title: "Type",
                value: viewModel.listing.price == 0 ? "Free" : "For Sale",
                color: Theme.Colors.primary
            )
            
            // Inventory (editable for owner)
            if isOwner {
                Button(action: { showingInventoryEdit = true }) {
                    DetailCard(
                        icon: "cube.box",
                        title: "Inventory",
                        value: "\(viewModel.listing.inventoryAmt) available",
                        color: Theme.Colors.accentOrange,
                        showEditIcon: true
                    )
                }
                .alert("Edit Inventory", isPresented: $showingInventoryEdit) {
                    TextField("Inventory", text: $editedInventory)
                        .keyboardType(.numberPad)
                    Button("Cancel", role: .cancel) { }
                    Button("Save") {
                        updateInventory()
                    }
                }
            } else {
                DetailCard(
                    icon: "cube.box",
                    title: "Available",
                    value: viewModel.listing.inventoryAmt > 0 ? "In Stock" : "Out of Stock",
                    color: viewModel.listing.inventoryAmt > 0 ? .green : Theme.Colors.error
                )
            }
            
            // Posted date
            DetailCard(
                icon: "calendar",
                title: "Posted",
                value: formatDate(ISO8601DateFormatter().date(from: listing.createdAt) ?? Date()),
                color: Theme.Colors.secondary
            )
        }
    }
    
    // MARK: - Description Section
    
    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Description")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(Theme.Colors.text)
            
            Text(listing.description)
                .font(.system(size: 15))
                .foregroundColor(Theme.Colors.secondaryText)
                .lineSpacing(6)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - Owner Controls Section
    
    private var ownerControlsSection: some View {
        VStack(spacing: 12) {
            Text("Quick Actions")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(Theme.Colors.text)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Quick action buttons grid
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                // Edit listing
                QuickActionButton(
                    icon: "pencil",
                    title: "Edit",
                    color: Theme.Colors.primary
                ) {
                    showingEditSheet = true
                }
                
                // Change status
                QuickActionButton(
                    icon: "flag",
                    title: statusActionText,
                    color: statusActionColor
                ) {
                    toggleListingStatus()
                }
                
                // Boost/Promote
                QuickActionButton(
                    icon: "rocket",
                    title: "Boost",
                    color: Theme.Colors.accentOrange
                ) {
                    // Boost listing
                }
                
                // Delete
                QuickActionButton(
                    icon: "trash",
                    title: "Delete",
                    color: Theme.Colors.error
                ) {
                    showingDeleteAlert = true
                }
            }
        }
    }
    
    // MARK: - Seller Info Section
    
    private var sellerInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Seller")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(Theme.Colors.text)
            
            Button(action: { showingSellerProfile = true }) {
                HStack(spacing: 12) {
                    // Profile picture
                    if let profilePicture = listing.ownerProfilePicture {
                        BrrowAsyncImage(url: profilePicture) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Circle()
                                .fill(Theme.Colors.divider.opacity(0.3))
                                .overlay(
                                    Image(systemName: "person.circle.fill")
                                        .foregroundColor(Theme.Colors.secondaryText)
                                )
                        }
                        .frame(width: 60, height: 60)
                        .clipShape(Circle())
                    } else {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(Theme.Colors.secondary)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(viewModel.listing.ownerUsername ?? "Seller")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Theme.Colors.text)
                        
                        HStack(spacing: 8) {
                            // Rating
                            if viewModel.ownerRating > 0 {
                                HStack(spacing: 2) {
                                    ForEach(0..<5) { index in
                                        Image(systemName: index < Int(viewModel.ownerRating.rounded()) ? "star.fill" : "star")
                                            .font(.system(size: 12))
                                            .foregroundColor(Theme.Colors.accentOrange)
                                    }
                                    Text("(\(Int(viewModel.reviewCount)))")
                                        .font(.system(size: 12))
                                        .foregroundColor(Theme.Colors.secondaryText)
                                }
                            }
                            
                            // Verified badge
                            if viewModel.seller?.idVerified == true {
                                Image(systemName: "checkmark.seal.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(Theme.Colors.primary)
                            }
                        }
                        
                        // Member since
                        Text("Active seller")
                            .font(.system(size: 12))
                            .foregroundColor(Theme.Colors.secondaryText)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14))
                        .foregroundColor(Theme.Colors.secondaryText)
                }
                .padding()
                .background(Theme.Colors.secondaryBackground)
                .cornerRadius(12)
            }
        }
    }
    
    // MARK: - Location Section
    
    private var locationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Location")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(Theme.Colors.text)
            
            HStack {
                Image(systemName: "location.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(Theme.Colors.primary)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(listing.location.city.isEmpty ? "Location" : "\(listing.location.city), \(listing.location.state)")
                        .font(.system(size: 15))
                        .foregroundColor(Theme.Colors.text)
                    
                    if let distance = viewModel.distanceFromUser {
                        Text(distance)
                            .font(.system(size: 13))
                            .foregroundColor(Theme.Colors.secondaryText)
                    }
                }
                
                Spacer()
            }
            .padding()
            .background(Theme.Colors.secondaryBackground)
            .cornerRadius(12)
        }
    }
    
    // MARK: - Similar Items Section
    
    private var similarItemsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Similar Items")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(Theme.Colors.text)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(viewModel.similarListings.prefix(5)) { item in
                        NavigationLink(destination: ModernListingDetailView(listing: item)) {
                            ModernSimilarItemCard(listing: item)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Bottom Action Bar
    
    private var bottomActionBar: some View {
        HStack(spacing: 12) {
            if isOwner {
                // Share listing
                Button(action: { showingShareSheet = true }) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 20))
                        .foregroundColor(Theme.Colors.primary)
                        .frame(width: 56, height: 56)
                        .background(Theme.Colors.primary.opacity(0.1))
                        .cornerRadius(28)
                }
                
                // Primary action based on status
                Button(action: primaryOwnerAction) {
                    HStack {
                        Image(systemName: primaryOwnerActionIcon)
                        Text(primaryOwnerActionText)
                            .font(.system(size: 18, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(primaryOwnerActionColor)
                    .cornerRadius(28)
                }
            } else {
                // Message seller
                Button(action: { showingChatView = true }) {
                    Image(systemName: "message.fill")
                        .font(.system(size: 20))
                        .foregroundColor(Theme.Colors.primary)
                        .frame(width: 56, height: 56)
                        .background(Theme.Colors.primary.opacity(0.1))
                        .cornerRadius(28)
                }
                
                // Primary action (Buy/Borrow)
                Button(action: { showingOfferSheet = true }) {
                    HStack {
                        Image(systemName: "listing" == "sale" ? "cart.fill" : "calendar.badge.clock")
                        Text("listing" == "sale" ? "Buy Now" : "Borrow")
                            .font(.system(size: 18, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Theme.Colors.primary)
                    .cornerRadius(28)
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 16)
        .background(
            Theme.Colors.background
                .shadow(color: .black.opacity(0.05), radius: 10, y: -5)
        )
    }
    
    // MARK: - Helper Functions
    
    private func setupInitialValues() {
        editedPrice = String(format: "%.2f", listing.price)
        editedInventory = String(listing.inventoryAmt)
        newStatus = listing.status
    }
    
    private var priceDisplay: String {
        if listing.price == 0 {
            return "Free"
        } else {
            return "$\(String(format: "%.2f", listing.price))"
        }
    }
    
    private var statusColor: Color {
        switch listing.status.lowercased() {
        case "active", "available": return .green
        case "pending", "pending_review": return .orange
        case "paused", "inactive": return .gray
        case "sold", "completed": return .blue
        default: return .gray
        }
    }
    
    private var statusText: String {
        switch listing.status.lowercased() {
        case "active", "available": return "Active"
        case "pending", "pending_review": return "Pending"
        case "paused": return "Paused"
        case "sold": return "Sold"
        default: return viewModel.listing.status.capitalized
        }
    }
    
    private var statusActionText: String {
        switch listing.status.lowercased() {
        case "active", "available": return "Pause"
        case "paused": return "Activate"
        case "pending", "pending_review": return "Pending"
        default: return "Update"
        }
    }
    
    private var statusActionColor: Color {
        switch listing.status.lowercased() {
        case "active", "available": return .orange
        case "paused": return .green
        default: return .gray
        }
    }
    
    private var primaryOwnerActionText: String {
        switch listing.status.lowercased() {
        case "active", "available": return "Edit Listing"
        case "paused": return "Reactivate"
        case "pending", "pending_review": return "View Status"
        case "sold": return "Mark Available"
        default: return "Manage"
        }
    }
    
    private var primaryOwnerActionIcon: String {
        switch listing.status.lowercased() {
        case "active", "available": return "pencil"
        case "paused": return "play.fill"
        case "pending", "pending_review": return "clock"
        case "sold": return "arrow.counterclockwise"
        default: return "gear"
        }
    }
    
    private var primaryOwnerActionColor: Color {
        switch listing.status.lowercased() {
        case "paused": return .green
        case "pending", "pending_review": return Theme.Colors.accentOrange
        default: return Theme.Colors.primary
        }
    }
    
    private func primaryOwnerAction() {
        switch listing.status.lowercased() {
        case "active", "available":
            showingEditSheet = true
        case "paused":
            toggleListingStatus()
        case "sold":
            markAsAvailable()
        default:
            break
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    // MARK: - Actions
    
    private func updatePrice() {
        guard let newPrice = Double(editedPrice), newPrice >= 0 else { return }
        Task {
            do {
                try await viewModel.updateListingPrice(newPrice)
            } catch {
                print("Failed to update price: \(error)")
            }
        }
    }
    
    private func updateInventory() {
        guard let newInventory = Int(editedInventory), newInventory >= 0 else { return }
        Task {
            do {
                try await viewModel.updateListingInventory(newInventory)
            } catch {
                print("Failed to update inventory: \(error)")
            }
        }
    }
    
    private func toggleListingStatus() {
        // Toggle between active and paused
        let newStatus = viewModel.listing.status.lowercased() == "active" ? "paused" : "active"
        Task {
            do {
                try await viewModel.updateListingStatus(newStatus)
            } catch {
                print("Failed to update status: \(error)")
            }
        }
    }
    
    private func markAsAvailable() {
        Task {
            do {
                try await viewModel.updateListingStatus("active")
            } catch {
                print("Failed to mark as available: \(error)")
            }
        }
    }
    
    private func deleteListing() {
        Task {
            do {
                try await viewModel.deleteListing()
                await MainActor.run {
                    dismiss()
                }
            } catch {
                print("Failed to delete listing: \(error)")
            }
        }
    }
}

// MARK: - Supporting Views

struct DetailCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    var showEditIcon: Bool = false
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)
                .frame(width: 32, height: 32)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 11))
                    .foregroundColor(Theme.Colors.secondaryText)
                Text(value)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Theme.Colors.text)
            }
            
            Spacer()
            
            if showEditIcon {
                Image(systemName: "pencil.circle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(color.opacity(0.5))
            }
        }
        .padding(12)
        .background(Theme.Colors.secondaryBackground)
        .cornerRadius(12)
    }
}

struct QuickActionButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(color)
                
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Theme.Colors.text)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 80)
            .background(color.opacity(0.1))
            .cornerRadius(12)
        }
    }
}

struct ModernSimilarItemCard: View {
    let listing: Listing
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let firstImage = listing.imageUrls.first {
                BrrowAsyncImage(url: firstImage) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Theme.Colors.divider.opacity(0.3))
                        .overlay(
                            ProgressView()
                                .scaleEffect(0.8)
                        )
                }
                .frame(width: 140, height: 140)
                .cornerRadius(12)
            } else {
                Rectangle()
                    .fill(Theme.Colors.divider.opacity(0.3))
                    .frame(width: 140, height: 140)
                    .cornerRadius(12)
                    .overlay(
                        Image(systemName: "photo")
                            .foregroundColor(Theme.Colors.secondaryText)
                    )
            }
            
            Text(listing.title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Theme.Colors.text)
                .lineLimit(1)
            
            Text("$\(String(format: "%.2f", listing.price))")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Theme.Colors.primary)
        }
        .frame(width: 140)
    }
}
