//
//  SimplifiedListingDetailViewFixed.swift
//  Brrow
//
//  Fixed version with simplified expressions
//

import SwiftUI

struct SimplifiedListingDetailView: View {
    @StateObject private var viewModel: ListingDetailViewModel
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.dismiss) private var dismiss
    
    // State variables
    @State private var showingOfferFlow = false
    @State private var showingMakeOffer = false
    @State private var showingBuyNow = false
    @State private var showingBorrowFlow = false
    @State private var showingMessageComposer = false
    @State private var isFavorited = false
    @State private var selectedImageIndex = 0
    @State private var showingFullScreenImage = false
    @State private var showingReportSheet = false
    @State private var showingSellerProfile = false
    @State private var showingEditView = false
    @State private var showingShareSheet = false
    @State private var showingDeleteAlert = false
    @State private var showingMarkAsSoldConfirmation = false

    // Animation state for delete
    @State private var isDeleting = false
    @State private var deleteAnimationScale: CGFloat = 1.0
    @State private var deleteAnimationOpacity: Double = 1.0
    @State private var deleteAnimationOffset: CGSize = .zero
    
    init(listing: Listing) {
        _viewModel = StateObject(wrappedValue: ListingDetailViewModel(listing: listing))
    }

    private var isOwner: Bool {
        guard let currentUser = authManager.currentUser else { return false }
        // FIXED: Compare with apiId instead of id (userId is API ID, not database ID)
        // currentUser.id = "cmfrmr7l30000nz01qfyr0lc4" (database ID)
        // currentUser.apiId = "usr_mfrmr7l11t" (API ID)
        // viewModel.listing.userId = "usr_mfrmr7l11t" (API ID from backend)
        return viewModel.listing.userId == currentUser.apiId
    }

    // Check if listing is new (updated in last 48 hours and available)
    private var isNewListing: Bool {
        guard viewModel.listing.availabilityStatus == .available else { return false }

        // Parse the updatedAt timestamp
        let formatter = ISO8601DateFormatter()
        guard let updatedDate = formatter.date(from: viewModel.listing.updatedAt) else {
            return false
        }

        // Check if updated within last 48 hours
        let fortyEightHoursAgo = Date().addingTimeInterval(-48 * 60 * 60)
        return updatedDate > fortyEightHoursAgo
    }

    // Get last 8-10 characters of listing ID for support purposes
    private var truncatedListingId: String {
        let id = viewModel.listing.id
        if id.count > 10 {
            return "..." + id.suffix(10)
        }
        return id
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                imageCarousel
                mainContent
            }
        }
        .navigationBarHidden(true)
        .overlay(
            navigationBar,
            alignment: .top
        )
        .overlay(
            bottomBar,
            alignment: .bottom
        )
        // Apply delete animation
        .scaleEffect(deleteAnimationScale)
        .opacity(deleteAnimationOpacity)
        .offset(deleteAnimationOffset)
        .sheet(isPresented: $showingMakeOffer) {
            ModernMakeOfferView(listing: viewModel.listing)
        }
        .sheet(isPresented: $showingBuyNow) {
            BuyNowConfirmationView(listing: viewModel.listing)
        }
        .sheet(isPresented: $showingBorrowFlow) {
            ModernMakeOfferView(listing: viewModel.listing)
        }
        .sheet(isPresented: $showingSellerProfile) {
            if let seller = viewModel.seller {
                FullSellerProfileView(user: seller)
            }
        }
        .sheet(isPresented: $showingEditView) {
            EnhancedEditListingView(listing: viewModel.listing)
                .environmentObject(authManager)
        }
        .sheet(isPresented: $showingMessageComposer) {
            ModernMessageComposer(
                recipient: viewModel.seller,
                listing: viewModel.listing
            )
        }
        .alert("Delete Listing", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteListing()
            }
        } message: {
            Text("Are you sure you want to delete this listing? This action cannot be undone.")
        }
        .alert("Mark as \(viewModel.listing.listingType == "sale" ? "Sold" : "Rented")", isPresented: $showingMarkAsSoldConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Confirm", role: .none) {
                Task {
                    do {
                        try await viewModel.markAsSoldOrRented()
                    } catch {
                        // Handle error
                        print("Failed to update status: \(error)")
                    }
                }
            }
        } message: {
            Text("Are you sure you want to mark this listing as \(viewModel.listing.listingType == "sale" ? "sold" : "rented")? This will update the status and notify potential buyers/renters.")
        }
        .onAppear {
            viewModel.loadListingDetails()
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("RefreshListingDetail"))) { notification in
            // Check if this notification is for our listing
            if let listingId = notification.userInfo?["listingId"] as? String,
               listingId == viewModel.listing.id {
                print("🔄 [SIMPLIFIED LISTING DETAIL] Received refresh notification for listing: \(listingId)")
                // Reload the listing details to show updated status
                viewModel.loadListingDetails()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("DismissListingDetail"))) { notification in
            // Check if this notification is for our listing
            if let listingId = notification.userInfo?["listingId"] as? String,
               listingId == viewModel.listing.listingId {
                print("🗑️ [SIMPLIFIED LISTING DETAIL] Received dismiss notification - closing view after delete")
                // Dismiss the view (already animated)
                dismiss()
            }
        }
    }
    
    private var navigationBar: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(Theme.Colors.text)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(Theme.Colors.background.opacity(0.9)))
            }
            
            Spacer()
            
            HStack(spacing: 12) {
                Button(action: shareItem) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(Theme.Colors.text)
                        .frame(width: 44, height: 44)
                        .background(Circle().fill(Theme.Colors.background.opacity(0.9)))
                }
                
                Button(action: toggleFavorite) {
                    Image(systemName: isFavorited ? "heart.fill" : "heart")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(isFavorited ? .red : Theme.Colors.text)
                        .frame(width: 44, height: 44)
                        .background(Circle().fill(Theme.Colors.background.opacity(0.9)))
                }
            }
        }
        .padding(.horizontal)
        .padding(.top, 50)
    }
    
    private var imageCarousel: some View {
        ZStack(alignment: .topLeading) {
            TabView(selection: $selectedImageIndex) {
                ForEach(Array(viewModel.listing.imageUrls.enumerated()), id: \.offset) { index, imageUrl in
                    BrrowAsyncImage(url: imageUrl)
                        .frame(height: 400)
                        .clipped()
                        .tag(index)
                }
            }
            .tabViewStyle(PageTabViewStyle())
            .frame(height: 400)
            .overlay(
                imageIndicator,
                alignment: .bottom
            )

            // Status badge (top-left) - only show if not AVAILABLE
            if viewModel.listing.availabilityStatus != .available {
                ListingStatusBadge(listing: viewModel.listing, size: .medium)
                    .padding(12)
            }
        }
    }
    
    private var imageIndicator: some View {
        HStack(spacing: 8) {
            ForEach(0..<viewModel.listing.imageUrls.count, id: \.self) { index in
                Circle()
                    .fill(selectedImageIndex == index ? Color.white : Color.white.opacity(0.5))
                    .frame(width: 8, height: 8)
            }
        }
        .padding(.bottom, 20)
    }
    
    private var mainContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Title and price
            VStack(alignment: .leading, spacing: 8) {
                Text(viewModel.listing.title)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(Theme.Colors.text)

                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        // Pricing type label
                        Text(viewModel.listing.pricingType == "RENTAL" ? "Price per day" : "Sale price")
                            .font(.caption)
                            .foregroundColor(Theme.Colors.secondaryText)

                        Text(viewModel.listing.priceDisplay)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(Theme.Colors.primary)
                    }

                    // Negotiable badge
                    if viewModel.listing.isNegotiable {
                        HStack(spacing: 4) {
                            Image(systemName: "hand.raised.fill")
                                .font(.caption2)
                            Text("Negotiable")
                                .font(.caption.weight(.medium))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(Color.green)
                        )
                    }

                    // NEW badge (if updated in last 48 hours and available)
                    if isNewListing {
                        HStack(spacing: 4) {
                            Image(systemName: "sparkles")
                                .font(.caption2)
                            Text("NEW")
                                .font(.caption.weight(.bold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(Color.blue)
                        )
                    }
                }
            }
            .padding(.horizontal)
            
            // Location
            HStack {
                Image(systemName: "location")
                    .font(.system(size: 14))
                    .foregroundColor(Theme.Colors.secondaryText)
                
                Text(viewModel.listing.locationString)
                    .font(.system(size: 14))
                    .foregroundColor(Theme.Colors.secondaryText)
            }
            .padding(.horizontal)
            
            Divider()
            
            // Description
            VStack(alignment: .leading, spacing: 8) {
                Text("Description")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Theme.Colors.text)
                
                Text(viewModel.listing.description)
                    .font(.system(size: 14))
                    .foregroundColor(Theme.Colors.text)
                    .lineSpacing(4)
            }
            .padding(.horizontal)
            
            // Owner info
            if !isOwner {
                Divider()
                
                Button(action: { showingSellerProfile = true }) {
                    HStack {
                        // Profile picture
                        if let profilePic = viewModel.listing.ownerProfilePicture {
                            BrrowAsyncImage(url: profilePic)
                                .frame(width: 50, height: 50)
                                .clipShape(Circle())
                        } else {
                            Circle()
                                .fill(Theme.Colors.secondaryBackground)
                                .frame(width: 50, height: 50)
                                .overlay(
                                    Image(systemName: "person.fill")
                                        .foregroundColor(Theme.Colors.secondaryText)
                                )
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(viewModel.listing.ownerUsername ?? "User")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(Theme.Colors.text)
                            
                            if let rating = viewModel.listing.ownerRating {
                                HStack(spacing: 4) {
                                    Image(systemName: "star.fill")
                                        .font(.system(size: 12))
                                        .foregroundColor(.yellow)
                                    
                                    Text(String(format: "%.1f", rating))
                                        .font(.system(size: 14))
                                        .foregroundColor(Theme.Colors.secondaryText)
                                }
                            }
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14))
                            .foregroundColor(Theme.Colors.secondaryText)
                    }
                    .padding(.horizontal)
                }
            }
            
            // Subtle listing ID for support purposes
            HStack {
                Spacer()
                Text("ID: \(truncatedListingId)")
                    .font(.system(size: 8))
                    .foregroundColor(.gray.opacity(0.5))
                    .padding(.trailing)
            }
            .padding(.top, 20)

            // Add some bottom padding for the action bar
            Color.clear.frame(height: 100)
        }
        .padding(.top, 20)
    }
    
    private var bottomBar: some View {
        HStack(spacing: 12) {
            if isOwner {
                VStack(spacing: 12) {
                    HStack(spacing: 12) {
                        Button(action: { showingEditView = true }) {
                            HStack {
                                Image(systemName: "pencil")
                                    .font(.system(size: 16, weight: .semibold))
                                Text("Edit")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Theme.Colors.primary)
                            .cornerRadius(25)
                        }

                        Button(action: { showingDeleteAlert = true }) {
                            HStack {
                                Image(systemName: "trash")
                                    .font(.system(size: 16, weight: .semibold))
                                Text("Delete")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.red)
                            .cornerRadius(25)
                        }
                    }

                    Button(action: { showingMarkAsSoldConfirmation = true }) {
                        HStack {
                            Image(systemName: "checkmark.circle")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Mark as \(viewModel.listing.listingType == "sale" ? "Sold" : "Rented")")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.green)
                        .cornerRadius(25)
                    }
                }
            } else {
                // Message button
                Button(action: {
                    showingMessageComposer = true
                }) {
                    Image(systemName: "message")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(Theme.Colors.primary)
                        .frame(width: 50, height: 50)
                        .background(Theme.Colors.primary.opacity(0.15))
                        .cornerRadius(25)
                }

                // Main action button based on listing type
                if viewModel.listing.type == "rental" {
                    Button(action: { showingBorrowFlow = true }) {
                        HStack {
                            Image(systemName: "calendar")
                                .font(.system(size: 18, weight: .semibold))

                            Text("Request to Rent")
                                .font(.system(size: 18, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Theme.Colors.primary)
                        .cornerRadius(25)
                    }
                } else {
                    // For sale items - show Make Offer or Buy Now
                    HStack(spacing: 12) {
                        // Make Offer button
                        Button(action: { showingMakeOffer = true }) {
                            HStack {
                                Image(systemName: "tag")
                                    .font(.system(size: 16, weight: .semibold))

                                Text("Make Offer")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            .foregroundColor(Theme.Colors.primary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Theme.Colors.primary.opacity(0.15))
                            .cornerRadius(25)
                        }

                        // Buy Now button
                        Button(action: { showingBuyNow = true }) {
                            HStack {
                                Image(systemName: "cart")
                                    .font(.system(size: 16, weight: .semibold))

                                Text("Buy Now")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Theme.Colors.primary)
                            .cornerRadius(25)
                        }
                    }
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(
            Rectangle()
                .fill(Theme.Colors.background)
                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: -5)
                .ignoresSafeArea()
        )
    }
    
    private func toggleFavorite() {
        isFavorited.toggle()
        Task {
            await viewModel.toggleFavorite()
        }
    }
    
    private func shareItem() {
        // Share functionality
        let url = URL(string: "https://brrowapp.com/listing/\(viewModel.listing.id)")!
        let activityController = UIActivityViewController(
            activityItems: [viewModel.listing.title, url],
            applicationActivities: nil
        )
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            rootViewController.present(activityController, animated: true)
        }
    }
    
    private func deleteListing() {
        print("🗑️ [DELETE ANIMATION] Starting delete animation")
        isDeleting = true

        // Step 1: Scale down and fade (0.3s)
        withAnimation(.easeIn(duration: 0.3)) {
            deleteAnimationScale = 0.6
            deleteAnimationOpacity = 0.5
        }

        // Step 2: Move to trash position (bottom-right corner) (0.4s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.easeInOut(duration: 0.4)) {
                // Calculate screen bounds to move to bottom-right
                let screenWidth = UIScreen.main.bounds.width
                let screenHeight = UIScreen.main.bounds.height
                self.deleteAnimationOffset = CGSize(
                    width: screenWidth / 2 + 50,
                    height: screenHeight / 2 + 100
                )
                self.deleteAnimationScale = 0.1
                self.deleteAnimationOpacity = 0.0
            }
        }

        // Step 3: Call API delete after animation (0.8s total)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            Task {
                print("🗑️ [DELETE] Calling delete API")
                await self.viewModel.deleteListing()
                // The notification listener will handle dismissal
            }
        }
    }
}