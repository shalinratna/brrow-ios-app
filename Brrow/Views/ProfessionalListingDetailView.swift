import SwiftUI
import MapKit

// MARK: - Map Location for iOS 16 Map compatibility
struct ListingMapLocation: Identifiable {
    let id: Int
    let coordinate: CLLocationCoordinate2D
}

// MARK: - Scroll Offset Preference Key
struct ListingScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct ProfessionalListingDetailView: View {
    let initialListing: Listing
    @StateObject private var viewModel: ListingDetailViewModel
    @StateObject private var editViewModel: InlineEditViewModel
    @State private var selectedImageIndex = 0
    @State private var showingFullScreenImage = false
    @State private var showingMakeOffer = false
    @State private var showingReportListing = false
    @State private var showingShareSheet = false
    @State private var showingSellerProfile = false
    @State private var showingBorrowOptions = false
    @State private var showingInquiry = false
    @State private var showingEditView = false
    @State private var showingDeleteConfirmation = false
    @State private var showingEditListing = false
    @State private var showingAnalytics = false
    @State private var showingMarkAsSold = false
    @State private var showingMarkAsSoldConfirmation = false
    @State private var showingBuyNow = false
    @State private var showingInsuranceInfo = false
    @State private var showingMessageComposer = false
    @State private var mapRegion = MKCoordinateRegion()
    @State private var scrollOffset: CGFloat = 0
    @State private var imageScale: CGFloat = 1.0
    @State private var buttonScale: CGFloat = 1.0
    @State private var favoriteScale: CGFloat = 1.0
    @Environment(\.dismiss) private var dismiss

    private let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
    private let selectionFeedback = UISelectionFeedbackGenerator()

    init(listing: Listing) {
        self.initialListing = listing
        self._viewModel = StateObject(wrappedValue: ListingDetailViewModel(listing: listing))
        self._editViewModel = StateObject(wrappedValue: InlineEditViewModel(listing: listing))
    }
    
    var body: some View {
        ZStack {
            Color(UIColor.systemBackground)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    // Large image gallery like Facebook Marketplace
                    imageGallerySection
                        .frame(height: UIScreen.main.bounds.height * 0.5) // Half screen height
                    
                    // Simple full-width content
                    VStack(spacing: 0) {
                        // Main info section
                        VStack(alignment: .leading, spacing: 16) {
                            titlePriceSection
                            
                            // Simple stats row
                            HStack(spacing: 20) {
                                // Only show views count to the listing owner
                                let currentUser = AuthManager.shared.currentUser
                                let isOwner = currentUser != nil && (
                                    viewModel.listing.userId == currentUser?.id ||
                                    viewModel.listing.userId == currentUser?.apiId ||
                                    viewModel.listing.user?.apiId == currentUser?.apiId ||
                                    viewModel.listing.user?.id == currentUser?.id
                                )

                                if isOwner {
                                    Label("\(viewModel.listing.views) views", systemImage: "eye")
                                        .font(.system(size: 14))
                                        .foregroundColor(Theme.Colors.secondaryText)
                                }

                                if viewModel.reviewCount > 0 {
                                    Label("\(viewModel.averageRating, specifier: "%.1f")", systemImage: "star.fill")
                                        .font(.system(size: 14))
                                        .foregroundColor(.orange)
                                }

                                Spacer()

                                Text(viewModel.distanceFromUser ?? "")
                                    .font(.system(size: 14))
                                    .foregroundColor(Theme.Colors.secondaryText)
                            }
                            
                            quickActionsSection
                        }
                        .padding(20)
                        .background(Color(UIColor.systemBackground))
                        
                        Divider()
                        
                        // Content sections
                        VStack(spacing: 0) {
                        
                            // Seller info - full width
                            sellerInfoSection
                                .padding(20)
                                .background(Color(UIColor.systemBackground))
                            
                            Divider()
                            
                            // Description - full width
                            VStack(alignment: .leading, spacing: 16) {
                                descriptionSection
                                
                                if !viewModel.listing.specifications.isEmpty {
                                    Divider()
                                    specificationsSection
                                }
                            }
                            .padding(20)
                            .background(Color(UIColor.systemBackground))
                            
                            Divider()
                            
                            // Location - full width
                            locationSection
                                .padding(20)
                                .background(Color(UIColor.systemBackground))
                            
                            Divider()
                            
                            // Availability and Protection
                            VStack(spacing: 16) {
                                availabilitySection
                                brrowProtectionSection
                            }
                            .padding(20)
                            .background(Color(UIColor.systemBackground))
                        
                            // Similar Items if available
                            if !viewModel.similarItems.isEmpty {
                                Divider()
                                similarItemsSection
                                    .padding(20)
                                    .background(Color(UIColor.systemBackground))
                            }
                        }
                        
                        // Bottom padding for floating bar
                        Color.clear
                            .frame(height: 160)
                    }
                }
            }
            .ignoresSafeArea(edges: .top)
            .scrollIndicators(.hidden)
            .background(
                GeometryReader { proxy in
                    Color.clear.preference(
                        key: ListingScrollOffsetPreferenceKey.self,
                        value: proxy.frame(in: .global).minY
                    )
                }
            )
            .onPreferenceChange(ListingScrollOffsetPreferenceKey.self) { value in
                scrollOffset = value
            }
            .blur(radius: editViewModel.editingField != nil ? 8 : 0)
            .animation(.easeInOut(duration: 0.3), value: editViewModel.editingField)

            // Sticky Bottom Bar
            VStack {
                Spacer()
                bottomActionBar
            }
            .blur(radius: editViewModel.editingField != nil ? 8 : 0)
            .animation(.easeInOut(duration: 0.3), value: editViewModel.editingField)

            // Inline Edit Overlay
            if let field = editViewModel.editingField {
                EditFieldOverlay(field: field, viewModel: editViewModel)
                    .transition(.scale(scale: 0.95).combined(with: .opacity))
                    .zIndex(999)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                HStack(spacing: 16) {
                    Button(action: {
                        impactFeedback.impactOccurred()
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            favoriteScale = 1.3
                        }
                        viewModel.toggleFavorite()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                favoriteScale = 1.0
                            }
                        }
                    }) {
                        Image(systemName: viewModel.isFavorited ? "heart.fill" : "heart")
                            .foregroundColor(viewModel.isFavorited ? .red : Theme.Colors.text)
                            .scaleEffect(favoriteScale)
                            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: viewModel.isFavorited)
                    }

                    Button(action: { showingShareSheet = true }) {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundColor(Theme.Colors.text)
                    }
                }
            }

            ToolbarItem(placement: .confirmationAction) {
                Button("Done") {
                    dismiss()
                }
                .foregroundColor(Theme.Colors.primary)
                .fontWeight(.semibold)
            }
        }
        .sheet(isPresented: $showingMakeOffer) {
            ModernMakeOfferView(listing: viewModel.listing)
        }
        .sheet(isPresented: $showingBuyNow) {
            BuyNowConfirmationView(listing: viewModel.listing)
        }
        .sheet(isPresented: $showingReportListing) {
            ReportListingView(listing: viewModel.listing)
        }
        .sheet(isPresented: $showingSellerProfile) {
            if let seller = viewModel.seller {
                UniversalProfileView(user: seller)
                    .environmentObject(AuthManager.shared)
            }
        }
        .alert("Delete Listing", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                Task {
                    await viewModel.deleteListing()
                    dismiss()
                }
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
                        viewModel.errorMessage = "Failed to update listing status: \(error.localizedDescription)"
                    }
                }
            }
        } message: {
            Text("Are you sure you want to mark this listing as \(viewModel.listing.listingType == "sale" ? "sold" : "rented")? This will update the status and notify potential buyers/renters.")
        }
        .sheet(isPresented: $showingBorrowOptions) {
            BorrowOptionsView(listing: viewModel.listing)
        }
        .sheet(isPresented: $showingInquiry) {
            ModernMessageComposer(
                recipient: viewModel.seller,
                listing: viewModel.listing
            )
        }
        .sheet(isPresented: $showingMessageComposer) {
            ModernMessageComposer(
                recipient: viewModel.seller,
                listing: viewModel.listing
            )
        }
        .sheet(isPresented: $showingShareSheet) {
            if let url = URL(string: "https://brrowapp.com/listing/\(viewModel.listing.id)") {
                ShareSheet(activityItems: [url])
            }
        }
        .sheet(isPresented: $showingAnalytics) {
            PostsAnalyticsView(posts: [])
        }
        .fullScreenCover(isPresented: $showingFullScreenImage) {
            EnhancedImageGalleryView(images: viewModel.listing.imageUrls, selectedIndex: $selectedImageIndex)
        }
        .alert("Sign In Required", isPresented: $viewModel.showGuestAlert) {
            Button("Sign In") {
                AuthManager.shared.logout()
            }
            Button("Continue Browsing", role: .cancel) {}
        } message: {
            Text("You need to sign in to favorite items, send messages, or make offers.")
        }
        .onAppear {
            viewModel.loadListingDetails()
            setupMapRegion()
            impactFeedback.prepare()
            selectionFeedback.prepare()
            AnalyticsService.shared.trackListingView(listingId: viewModel.listing.id, listingTitle: viewModel.listing.title)
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("RefreshListingDetail"))) { notification in
            // Check if this notification is for our listing
            if let listingId = notification.userInfo?["listingId"] as? String,
               listingId == viewModel.listing.id {
                print("🔄 [LISTING DETAIL] Received refresh notification for listing: \(listingId)")
                // Reload the listing details to show updated status
                viewModel.loadListingDetails()
            }
        }
    }
    
    // MARK: - Image Gallery (Facebook Marketplace Style)
    private var imageGallerySection: some View {
        ZStack(alignment: .topLeading) {
            Group {
                if !viewModel.listing.imageUrls.isEmpty {
                    TabView(selection: $selectedImageIndex) {
                        ForEach(Array(viewModel.listing.imageUrls.enumerated()), id: \.offset) { index, imageUrl in
                            BrrowAsyncImage(url: imageUrl) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                    .clipped()
                                    .allowsHitTesting(true)
                            } placeholder: {
                                Rectangle()
                                    .fill(Color.gray.opacity(0.1))
                                    .overlay(
                                        ProgressView()
                                            .scaleEffect(1.2)
                                    )
                            }
                            .tag(index)
                            .onTapGesture {
                                showingFullScreenImage = true
                            }
                            .onAppear {
                                preloadAdjacentImages(currentIndex: index)
                            }
                        }
                    }
                    .tabViewStyle(PageTabViewStyle())
                    .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
                } else {
                    // No images placeholder
                    Rectangle()
                        .fill(Color.gray.opacity(0.1))
                        .overlay(
                            VStack(spacing: 12) {
                                Image(systemName: "photo.on.rectangle.angled")
                                    .font(.system(size: 60))
                                    .foregroundColor(.gray.opacity(0.4))
                                Text("No images available")
                                    .font(.body)
                                    .foregroundColor(.gray.opacity(0.6))
                            }
                        )
                }
            }

            // Status badge (top-left) - only show if not AVAILABLE
            if viewModel.listing.availabilityStatus != .available {
                ListingStatusBadge(listing: viewModel.listing, size: .medium)
                    .padding(12)
            }
        }
    }
    
    // MARK: - Title and Price (Simple & Clean)
    private var titlePriceSection: some View {
        let currentUser = AuthManager.shared.currentUser
        let isOwner = currentUser != nil && (
            viewModel.listing.userId == currentUser?.id ||
            viewModel.listing.userId == currentUser?.apiId ||
            viewModel.listing.user?.apiId == currentUser?.apiId ||
            viewModel.listing.user?.id == currentUser?.id
        )

        return VStack(alignment: .leading, spacing: 12) {
            // Price first (like Facebook Marketplace) - tappable for owners
            Button(action: {
                if isOwner {
                    editViewModel.startEditing(viewModel.listing.isRental ? .dailyRate : .price)
                }
            }) {
                HStack(alignment: .bottom, spacing: 4) {
                    HStack(spacing: 8) {
                        Text("$\(Int(viewModel.listing.displayPrice))")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(Theme.Colors.text)

                        if viewModel.listing.isRental {
                            Text("/day")
                                .font(.system(size: 16))
                                .foregroundColor(Theme.Colors.secondaryText)
                        }

                        if isOwner {
                            Image(systemName: "pencil.circle.fill")
                                .foregroundColor(Theme.Colors.primary.opacity(0.6))
                                .font(.system(size: 20))
                        }
                    }

                    Spacer()

                    // Simple badges
                    HStack(spacing: 8) {
                        if viewModel.listing.listingType == "sale" {
                            Text("FOR SALE")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(Color.red)
                                .cornerRadius(4)
                        } else if viewModel.listing.listingType == "rental" {
                            Text("FOR RENT")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(Theme.Colors.primary)
                                .cornerRadius(4)
                        }

                        if viewModel.listing.isNew ?? false {
                            Text("NEW")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(Color.green)
                                .cornerRadius(4)
                        }
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(!isOwner)

            // Title (tappable for owners)
            Button(action: {
                if isOwner {
                    editViewModel.startEditing(.title)
                }
            }) {
                HStack(spacing: 8) {
                    Text(viewModel.listing.title.isEmpty ? "Unnamed \(viewModel.listing.itemType)" : viewModel.listing.title)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(Theme.Colors.text)
                        .lineLimit(2)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    if isOwner {
                        Image(systemName: "pencil.circle.fill")
                            .foregroundColor(Theme.Colors.primary.opacity(0.6))
                            .font(.system(size: 18))
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(!isOwner)
            
            // Condition and negotiable
            HStack(spacing: 12) {
                Text("Condition: \(conditionDisplayName)")
                    .font(.system(size: 14))
                    .foregroundColor(Theme.Colors.secondaryText)
                
                if viewModel.listing.isNegotiable {
                    Text("• Negotiable")
                        .font(.system(size: 14))
                        .foregroundColor(Color.green)
                }
            }
            
            // Rating and Reviews
            HStack(spacing: 16) {
                HStack(spacing: 4) {
                    ForEach(0..<5) { star in
                        Image(systemName: star < Int(viewModel.averageRating) ? "star.fill" : "star")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                    Text("\(viewModel.averageRating, specifier: "%.1f")")
                        .font(.caption)
                        .foregroundColor(Theme.Colors.secondaryText)
                }
                
                Text(viewModel.reviewCount == 0 ? "No reviews yet" : "(\(viewModel.reviewCount) reviews)")
                    .font(.caption)
                    .foregroundColor(Theme.Colors.secondaryText)
                
                Spacer()
                
                // Listing Type Badge
                HStack(spacing: 4) {
                    if viewModel.listing.isNew ?? false {
                        Label("NEW", systemImage: "sparkles")
                            .font(.caption)
                            .fontWeight(.bold)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(Color.green.opacity(0.2))
                            .foregroundColor(.green)
                            .cornerRadius(12)
                    } else {
                        Text(viewModel.listing.listingType == "sale" ? "SALE" : "RENT")
                            .font(.caption)
                            .fontWeight(.bold)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(viewModel.listing.listingType == "sale" ? Color.red.opacity(0.2) : Color.blue.opacity(0.2))
                            .foregroundColor(viewModel.listing.listingType == "sale" ? .red : .blue)
                            .cornerRadius(12)
                    }
                }
            }
        }
    }
    
    // MARK: - Quick Actions
    private var quickActionsSection: some View {
        let currentUser = AuthManager.shared.currentUser
        let isOwner = currentUser != nil && (
            viewModel.listing.userId == currentUser?.id ||
            viewModel.listing.userId == currentUser?.apiId ||
            viewModel.listing.user?.apiId == currentUser?.apiId ||
            viewModel.listing.user?.id == currentUser?.id
        )
        let isPendingSale = viewModel.listing.availabilityStatus == .inTransaction

        // Debug ownership detection (only in debug builds)
        #if DEBUG
        if isOwner {
            print("🔍 User owns listing: \(viewModel.listing.title)")
        }
        #endif

        return VStack(spacing: 12) {

            // Show pending sale notice if in transaction
            if isPendingSale {
                pendingSaleNotice
            } else if isOwner {
                // Owner actions - Simple design
                VStack(spacing: 12) {
                    // Inline editing hint
                    HStack(spacing: 8) {
                        Image(systemName: "hand.tap.fill")
                            .foregroundColor(Theme.Colors.primary)
                        Text("Tap any field above to edit inline")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Theme.Colors.secondaryText)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Theme.Colors.primary.opacity(0.1))
                    .cornerRadius(8)

                    HStack(spacing: 12) {
                        Button(action: {
                            showingAnalytics = true
                        }) {
                            HStack {
                                Image(systemName: "chart.bar")
                                Text("Analytics")
                            }
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Theme.Colors.primary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Theme.Colors.primary, lineWidth: 1.5)
                            )
                        }

                        Button(action: {
                            showingMarkAsSoldConfirmation = true
                        }) {
                            HStack {
                                Image(systemName: "checkmark.circle")
                                Text("Mark as \(viewModel.listing.listingType == "sale" ? "Sold" : "Rented")")
                            }
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(Color.green)
                            .cornerRadius(8)
                        }
                    }
                }
            } else {
                // Simple action buttons
                VStack(spacing: 12) {
                    // Check if listing is unavailable (RENTED or SOLD)
                    if viewModel.listing.availabilityStatus == .rented || viewModel.listing.availabilityStatus == .sold {
                        // Unavailable state - show message
                        VStack(spacing: 12) {
                            HStack(spacing: 12) {
                                Image(systemName: "exclamationmark.circle.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(.orange)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Currently Unavailable")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(Theme.Colors.text)

                                    Text(viewModel.listing.availabilityStatus == .rented ?
                                         "This item is currently rented and unavailable" :
                                         "This item has been sold")
                                        .font(.system(size: 14))
                                        .foregroundColor(Theme.Colors.secondaryText)
                                }

                                Spacer()
                            }
                            .padding()
                            .background(Color.orange.opacity(0.1))
                            .cornerRadius(12)

                            // Still allow messaging the owner
                            Button(action: {
                                if viewModel.isGuestUser {
                                    viewModel.showGuestAlert = true
                                } else {
                                    showingMessageComposer = true
                                }
                            }) {
                                HStack {
                                    Image(systemName: "message.fill")
                                    Text("Message Owner")
                                }
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(Theme.Colors.primary)
                                .frame(maxWidth: .infinity)
                                .frame(height: 48)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Theme.Colors.primary, lineWidth: 1.5)
                                )
                            }
                        }
                    } else {
                        // Available state - show action buttons
                        HStack(spacing: 12) {
                            Button(action: {
                                if viewModel.isGuestUser {
                                    viewModel.showGuestAlert = true
                                } else {
                                    showingMessageComposer = true
                                }
                            }) {
                                HStack {
                                    Image(systemName: "message.fill")
                                    Text("Message")
                                }
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(Theme.Colors.primary)
                                .frame(maxWidth: .infinity)
                                .frame(height: 48)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Theme.Colors.primary, lineWidth: 1.5)
                                )
                            }

                            // Show "Make Offer" button for sale items (always) or negotiable rentals
                            if viewModel.listing.listingType == "sale" || viewModel.listing.isNegotiable {
                                Button(action: {
                                    showingMakeOffer = true
                                }) {
                                    HStack {
                                        Image(systemName: "tag")
                                        Text("Make Offer")
                                    }
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(Theme.Colors.primary)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 48)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Theme.Colors.primary, lineWidth: 1.5)
                                    )
                                }
                            }
                        }

                        Button(action: {
                            if viewModel.listing.listingType == "sale" {
                                showingBuyNow = true
                            } else {
                                showingBorrowOptions = true
                            }
                        }) {
                            Text(viewModel.listing.listingType == "sale" ? "Buy Now" : "Rent Now")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 48)
                                .background(viewModel.listing.listingType == "sale" ? Color.red : Theme.Colors.primary)
                                .cornerRadius(8)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Pending Sale Notice
    private var pendingSaleNotice: some View {
        let currentUser = AuthManager.shared.currentUser
        let isOwner = currentUser != nil && (
            viewModel.listing.userId == currentUser?.id ||
            viewModel.listing.userId == currentUser?.apiId ||
            viewModel.listing.user?.apiId == currentUser?.apiId ||
            viewModel.listing.user?.id == currentUser?.id
        )

        return VStack(spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: "clock.badge.checkmark.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.orange)

                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.listing.listingType == "rental" ? "Rental Pending" : "Sale Pending")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(Theme.Colors.text)

                    Text("Payment hold active – awaiting verification")
                        .font(.system(size: 14))
                        .foregroundColor(Theme.Colors.secondaryText)
                }

                Spacer()
            }
            .padding()
            .background(Color.orange.opacity(0.1))
            .cornerRadius(12)

            // Message seller button - only show if NOT the owner
            if !isOwner {
                Button(action: {
                    if viewModel.isGuestUser {
                        viewModel.showGuestAlert = true
                    } else {
                        showingMessageComposer = true
                    }
                }) {
                    HStack {
                        Image(systemName: "message.fill")
                        Text("Message Seller")
                    }
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Theme.Colors.primary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Theme.Colors.primary, lineWidth: 1.5)
                    )
                }
            }
        }
    }
    
    // MARK: - Seller Info (Simple)
    private var sellerInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Seller")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Theme.Colors.text)
            
            Button(action: { showingSellerProfile = true }) {
                HStack(spacing: 12) {
                    // Seller Avatar
                    if let avatarUrl = viewModel.listing.ownerProfilePicture {
                        BrrowAsyncImage(url: avatarUrl) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 44, height: 44)
                                .clipShape(Circle())
                        } placeholder: {
                            Circle()
                                .fill(Color.gray.opacity(0.2))
                                .frame(width: 44, height: 44)
                        }
                    } else {
                        Circle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: 44, height: 44)
                            .overlay(
                                Text(viewModel.listing.ownerUsername?.prefix(1).uppercased() ?? "S")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(Theme.Colors.text)
                            )
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        HStack {
                            Text(viewModel.listing.ownerUsername ?? "Seller")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(Theme.Colors.text)
                            
                            if viewModel.listing.ownerVerified {
                                Image(systemName: "checkmark.seal.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(.blue)
                            }
                        }
                        
                        HStack(spacing: 12) {
                            if viewModel.ownerRating > 0 {
                                HStack(spacing: 2) {
                                    Image(systemName: "star.fill")
                                        .font(.system(size: 12))
                                        .foregroundColor(.orange)
                                    Text("\(viewModel.ownerRating, specifier: "%.1f")")
                                        .font(.system(size: 13))
                                        .foregroundColor(Theme.Colors.secondaryText)
                                }
                            }
                            
                            Text("\(viewModel.sellerActiveListings) listings")
                                .font(.system(size: 13))
                                .foregroundColor(Theme.Colors.secondaryText)
                            
                            Text("Responds quickly")
                                .font(.system(size: 13))
                                .foregroundColor(Theme.Colors.secondaryText)
                        }
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14))
                        .foregroundColor(Theme.Colors.secondaryText)
                }
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    // MARK: - Description
    private var descriptionSection: some View {
        let currentUser = AuthManager.shared.currentUser
        let isOwner = currentUser != nil && (
            viewModel.listing.userId == currentUser?.id ||
            viewModel.listing.userId == currentUser?.apiId ||
            viewModel.listing.user?.apiId == currentUser?.apiId ||
            viewModel.listing.user?.id == currentUser?.id
        )

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("DESCRIPTION")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(Theme.Colors.secondaryText)

                Spacer()

                if isOwner {
                    Image(systemName: "pencil.circle.fill")
                        .foregroundColor(Theme.Colors.primary.opacity(0.6))
                        .font(.system(size: 16))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .onAppear {
                print("📝 Description section appeared with text: '\(viewModel.listing.description)'")
            }

            Button(action: {
                if isOwner {
                    editViewModel.startEditing(.description)
                }
            }) {
                Text(viewModel.listing.description.isEmpty ? "No description available for this item." : viewModel.listing.description)
                    .font(.body)
                    .foregroundColor(viewModel.listing.description.isEmpty ? Theme.Colors.secondaryText : Theme.Colors.text)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .multilineTextAlignment(.leading)
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(!isOwner)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - Specifications
    private var specificationsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("SPECIFICATIONS")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(Theme.Colors.secondaryText)
            
            VStack(spacing: 8) {
                ForEach(viewModel.listing.specifications, id: \.key) { spec in
                    HStack {
                        Text(spec.key)
                            .font(.body)
                            .foregroundColor(Theme.Colors.secondaryText)
                        
                        Spacer()
                        
                        Text(spec.value)
                            .font(.body)
                            .fontWeight(.medium)
                            .foregroundColor(Theme.Colors.text)
                    }
                    .padding(.vertical, 4)
                    
                    if spec.key != viewModel.listing.specifications.last?.key {
                        Divider()
                    }
                }
            }
            .padding()
            .background(Color.gray.opacity(0.05))
            .cornerRadius(12)
        }
    }
    
    // MARK: - Location
    private var locationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("PICKUP LOCATION")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(Theme.Colors.secondaryText)
            
            VStack(alignment: .leading, spacing: 8) {
                // Map Preview for approximate location (iOS 16 compatible)
                Map(coordinateRegion: .constant(mapRegion),
                    annotationItems: [ListingMapLocation(
                        id: 0,
                        coordinate: CLLocationCoordinate2D(
                            latitude: viewModel.listing.latitude,
                            longitude: viewModel.listing.longitude
                        )
                    )]) { location in
                    MapPin(coordinate: location.coordinate, tint: .blue)
                }
                .frame(height: 200)
                .cornerRadius(12)
                .disabled(true)
                
                // Distance
                HStack {
                    Image(systemName: "location.fill")
                        .foregroundColor(Theme.Colors.primary)
                    
                    Text("\(viewModel.distanceFromUser ?? "Calculating...") away")
                        .font(.body)
                        .foregroundColor(Theme.Colors.text)
                    
                    Spacer()
                    
                    Button(action: openInMaps) {
                        Text("Get Directions")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(Theme.Colors.primary)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    // MARK: - Availability
    private var availabilitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("AVAILABILITY")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(Theme.Colors.secondaryText)
            
            // Simple availability indicator
            HStack {
                Circle()
                    .fill(viewModel.listing.isAvailable ? Color.green : Color.red)
                    .frame(width: 8, height: 8)
                
                Text(viewModel.listing.isAvailable ?
                     (viewModel.listing.isRental ? "Available for rent" : "Available for purchase") :
                     (viewModel.listing.isRental ? "Currently rented" : "Sold"))
                    .font(.body)
                    .foregroundColor(Theme.Colors.text)
                
                Spacer()
                
                if !viewModel.listing.isAvailable, let nextAvailable = viewModel.nextAvailableDate {
                    Text("Available \(nextAvailable, style: .date)")
                        .font(.caption)
                        .foregroundColor(Theme.Colors.secondaryText)
                }
            }
            .padding()
            .background(Color.gray.opacity(0.05))
            .cornerRadius(12)
        }
    }
    
    // MARK: - Similar Items
    private var similarItemsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("SIMILAR ITEMS")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(Theme.Colors.secondaryText)
                
                Spacer()

                Button(action: { /* Navigate to browse view */ }) {
                    Text("See All")
                        .font(.caption)
                        .foregroundColor(Theme.Colors.primary)
                }
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(viewModel.similarItems, id: \.listingId) { item in
                        NavigationLink(destination: ProfessionalListingDetailView(listing: item)) {
                            SimilarItemCard(listing: item)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
        }
    }
    
    // MARK: - Brrow Protection
    private var brrowProtectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "shield.fill")
                    .foregroundColor(.blue)
                
                Text("Brrow Protection")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Theme.Colors.text)
                
                Spacer()
                
                Button(action: { showingInsuranceInfo = true }) {
                    Text("Learn More")
                        .font(.system(size: 14))
                        .foregroundColor(.blue)
                }
            }
            
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.system(size: 14))
                    Text("This listing is eligible for Brrow Protection")
                        .font(.system(size: 14))
                        .foregroundColor(Theme.Colors.text)
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("Basic Protection Plan available:")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Theme.Colors.text)
                    
                    HStack(spacing: 4) {
                        Text("•")
                        Text("Covers up to $120 in damages")
                    }
                    .font(.system(size: 13))
                    .foregroundColor(Theme.Colors.secondaryText)
                    
                    HStack(spacing: 4) {
                        Text("•")
                        Text("Only 10% added to rental cost")
                    }
                    .font(.system(size: 13))
                    .foregroundColor(Theme.Colors.secondaryText)
                    
                    HStack(spacing: 4) {
                        Text("•")
                        Text("Theft protection included")
                    }
                    .font(.system(size: 13))
                    .foregroundColor(Theme.Colors.secondaryText)
                }
                .padding(.leading, 4)
                
                Text("You can opt-in during checkout")
                    .font(.system(size: 12))
                    .foregroundColor(Color.green)
                    .padding(.top, 4)
            }
            .padding(12)
            .background(Color.blue.opacity(0.05))
            .cornerRadius(8)
        }
    }
    
    // MARK: - Safety Notice
    private var safetyNoticeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "shield.fill")
                    .foregroundColor(.blue)
                
                Text("Brrow Protection")
                    .font(.headline)
                    .foregroundColor(Theme.Colors.text)
            }
            
            Text("All rentals are protected by our insurance policy. Meet in public places and inspect items before renting.")
                .font(.caption)
                .foregroundColor(Theme.Colors.secondaryText)
            
            Button(action: { showingReportListing = true }) {
                Text("Report this listing")
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
        .padding()
        .background(Color.blue.opacity(0.05))
        .cornerRadius(12)
    }
    
    // MARK: - Bottom Action Bar (Simple)
    private var bottomActionBar: some View {
        let isPendingSale = viewModel.listing.availabilityStatus == .inTransaction

        return VStack(spacing: 0) {
            Divider()

            HStack(spacing: 16) {
                // Price
                VStack(alignment: .leading, spacing: 2) {
                    Text("$\(Int(viewModel.listing.displayPrice))")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(Theme.Colors.text)
                    if viewModel.listing.isRental {
                        Text("per day")
                            .font(.system(size: 12))
                            .foregroundColor(Theme.Colors.secondaryText)
                    }
                }

                Spacer()

                // Show different buttons based on ownership and pending status
                let isOwner = viewModel.listing.userId == AuthManager.shared.currentUser?.id ||
                             viewModel.listing.userId == AuthManager.shared.currentUser?.apiId

                if isPendingSale {
                    // Pending sale - show status badge
                    HStack(spacing: 8) {
                        Image(systemName: "clock.badge.checkmark.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.orange)
                        Text(viewModel.listing.listingType == "rental" ? "Rental Pending" : "Sale Pending")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.orange)
                    }
                    .padding(.horizontal, 20)
                    .frame(height: 44)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(22)
                } else if isOwner {
                    // Owner actions
                    Button(action: { showingDeleteConfirmation = true }) {
                        Image(systemName: "trash")
                            .font(.system(size: 20))
                            .foregroundColor(.red)
                            .frame(width: 44, height: 44)
                            .background(Circle().fill(Color.gray.opacity(0.1)))
                    }

                    Button(action: { showingAnalytics = true }) {
                        Image(systemName: "chart.bar")
                            .font(.system(size: 20))
                            .foregroundColor(Theme.Colors.primary)
                            .frame(width: 44, height: 44)
                            .background(Circle().fill(Color.gray.opacity(0.1)))
                    }
                } else {
                    // Non-owner actions
                    // Check if listing is unavailable (RENTED or SOLD)
                    if viewModel.listing.availabilityStatus == .rented || viewModel.listing.availabilityStatus == .sold {
                        // Unavailable state - show status badge
                        HStack(spacing: 8) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 18))
                                .foregroundColor(.gray)
                            Text(viewModel.listing.availabilityStatus == .rented ? "Currently Rented" : "Sold")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.gray)
                        }
                        .padding(.horizontal, 20)
                        .frame(height: 44)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(22)
                    } else {
                        // Available state - show action buttons
                        Button(action: {
                            if viewModel.isGuestUser {
                                viewModel.showGuestAlert = true
                            } else {
                                showingMessageComposer = true
                            }
                        }) {
                            Image(systemName: "message.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.white)
                                .frame(width: 44, height: 44)
                                .background(Circle().fill(Theme.Colors.primary))
                        }

                        Button(action: { showingShareSheet = true }) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 20))
                                .foregroundColor(.white)
                                .frame(width: 44, height: 44)
                                .background(Circle().fill(Theme.Colors.primary))
                        }

                        Button(action: {
                            if viewModel.listing.listingType == "sale" {
                                showingBuyNow = true
                            } else {
                                showingBorrowOptions = true
                            }
                        }) {
                            Text(viewModel.listing.isRental ? "Rent Now" : "Buy Now")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 24)
                                .frame(height: 44)
                                .background(viewModel.listing.isRental ? Theme.Colors.primary : Color.red)
                                .cornerRadius(22)
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color(UIColor.systemBackground))
        }
        .background(
            Color(UIColor.systemBackground)
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: -5)
        )
        .ignoresSafeArea(edges: .bottom)
    }
    
    // MARK: - Helper Methods
    private var conditionDisplayName: String {
        // Map backend condition strings to display names
        switch viewModel.listing.condition.uppercased() {
        case "NEW":
            return "Like New"
        case "EXCELLENT":
            return "Excellent"
        case "GOOD":
            return "Good"
        case "FAIR":
            return "Fair"
        case "POOR":
            return "Poor"
        default:
            // Fallback to capitalized version for unknown values
            return viewModel.listing.condition.capitalized
        }
    }

    private var conditionColor: Color {
        switch viewModel.listing.condition.lowercased() {
        case "new", "like new":
            return .green
        case "excellent", "very good":
            return .blue
        case "good":
            return .orange
        default:
            return .gray
        }
    }
    
    private func setupMapRegion() {
        mapRegion = MKCoordinateRegion(
            center: CLLocationCoordinate2D(
                latitude: viewModel.listing.latitude,
                longitude: viewModel.listing.longitude
            ),
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )
    }
    
    private func preloadAdjacentImages(currentIndex: Int) {
        let imageUrls = viewModel.listing.imageUrls
        
        // Preload previous image
        if currentIndex > 0 {
            Task {
                do {
                    _ = try await ImageCacheManager.shared.loadImage(from: imageUrls[currentIndex - 1])
                } catch {
                    print("Failed to preload previous image: \(error)")
                }
            }
        }
        
        // Preload next image
        if currentIndex < imageUrls.count - 1 {
            Task {
                do {
                    _ = try await ImageCacheManager.shared.loadImage(from: imageUrls[currentIndex + 1])
                } catch {
                    print("Failed to preload next image: \(error)")
                }
            }
        }
    }
    
    private func openInMaps() {
        let coordinate = CLLocationCoordinate2D(
            latitude: viewModel.listing.latitude,
            longitude: viewModel.listing.longitude
        )
        let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: coordinate))
        mapItem.name = viewModel.listing.title
        mapItem.openInMaps(launchOptions: [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
        ])
    }
}

// MARK: - Supporting Views
struct SimilarItemCard: View {
    let listing: Listing
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Image
            BrrowAsyncImage(url: listing.imageUrls.first ?? "") { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 150, height: 150)
                    .clipped()
            } placeholder: {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 150, height: 150)
            }
            .cornerRadius(8)
            
            // Title
            Text(listing.title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(Theme.Colors.text)
                .lineLimit(2)
                .frame(width: 150, alignment: .leading)
            
            // Price
            Text("$\(listing.displayPrice, specifier: "%.2f")\(listing.priceSuffix)")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(Theme.Colors.primary)
        }
    }
}

struct MakeOfferView: View {
    let listing: Listing
    @State private var offerAmount = ""
    @State private var message = ""
    @State private var isSubmitting = false
    @State private var errorMessage: String?
    @State private var showSuccessAlert = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Offer Amount
                VStack(alignment: .leading, spacing: 8) {
                    Text("Your Offer")
                        .font(.headline)
                    
                    HStack {
                        Text("$")
                            .font(.title2)
                            .foregroundColor(Theme.Colors.primary)
                        
                        TextField("0.00", text: $offerAmount)
                            .font(.title2)
                            .keyboardType(.decimalPad)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                    
                    Text("Original price: $\(listing.displayPrice, specifier: "%.2f")\(listing.priceSuffix)")
                        .font(.caption)
                        .foregroundColor(Theme.Colors.secondaryText)
                }
                
                // Message
                VStack(alignment: .leading, spacing: 8) {
                    Text("Message (Optional)")
                        .font(.headline)
                    
                    TextEditor(text: $message)
                        .frame(height: 100)
                        .padding(8)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(12)
                }
                
                Spacer()
                
                // Submit Button
                Button(action: submitOffer) {
                    if isSubmitting {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .frame(maxWidth: .infinity)
                            .padding()
                    } else {
                        Text("Send Offer")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                }
                .background(Theme.Colors.primary)
                .cornerRadius(12)
                .disabled(offerAmount.isEmpty || isSubmitting)
            }
            .padding()
            .navigationTitle("Make an Offer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Error", isPresented: .constant(errorMessage != nil)) {
                Button("OK") {
                    errorMessage = nil
                }
            } message: {
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                }
            }
            .alert("Success", isPresented: $showSuccessAlert) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Your offer has been sent successfully!")
            }
        }
    }

    private func submitOffer() {
        // Validate offer amount
        guard let amount = Double(offerAmount), amount > 0 else {
            errorMessage = "Please enter a valid offer amount greater than $0"
            return
        }

        // Check if offer is less than listing price (optional warning)
        if amount > listing.displayPrice * 1.5 {
            errorMessage = "Your offer is significantly higher than the listing price. Please review your amount."
            return
        }

        isSubmitting = true
        errorMessage = nil

        Task {
            do {
                // Create the offer request
                let offerRequest = CreateOfferRequest(
                    listingId: String(listing.id),
                    amount: amount,
                    message: message.isEmpty ? nil : message
                )

                // Submit the offer via API
                _ = try await APIClient.shared.createOffer(offerRequest)

                // Track analytics
                AnalyticsService.shared.trackOfferAction(
                    action: "offer_sent",
                    amount: amount,
                    listingId: String(listing.id)
                )

                // Show success
                await MainActor.run {
                    isSubmitting = false
                    showSuccessAlert = true
                }
            } catch {
                // Handle error
                await MainActor.run {
                    isSubmitting = false
                    if let apiError = error as? BrrowAPIError {
                        switch apiError {
                        case .serverError(let message):
                            errorMessage = message
                        case .unauthorized:
                            errorMessage = "Please sign in to make an offer"
                        case .networkError:
                            errorMessage = "Network error. Please check your connection and try again."
                        default:
                            errorMessage = "Failed to send offer. Please try again."
                        }
                    } else {
                        errorMessage = "Failed to send offer: \(error.localizedDescription)"
                    }
                }
            }
        }
    }
}

struct BorrowOptionsView: View {
    let listing: Listing
    @State private var selectedDuration = 1
    @State private var startDate = Date()
    @State private var includeInsurance = true
    @State private var showingPaymentFlow = false
    @Environment(\.dismiss) private var dismiss

    var endDate: Date {
        Calendar.current.date(byAdding: .day, value: selectedDuration, to: startDate) ?? startDate
    }

    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    // Duration Selection
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Image(systemName: "clock.fill")
                                .foregroundColor(Theme.Colors.primary)
                                .font(.system(size: 20))
                            Text("Rental Duration")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(Theme.Colors.text)
                        }

                        Picker("Duration", selection: $selectedDuration) {
                            ForEach(1...30, id: \.self) { days in
                                Text("\(days) \(days == 1 ? "day" : "days")")
                                    .tag(days)
                            }
                        }
                        .pickerStyle(WheelPickerStyle())
                        .frame(height: 120)
                        .clipped()
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Theme.Colors.cardBackground)
                            .shadow(color: Theme.Shadows.card, radius: Theme.Shadows.cardRadius, x: 0, y: 2)
                    )

                    // Rental Period Summary
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "calendar")
                                .foregroundColor(Theme.Colors.primary)
                                .font(.system(size: 20))
                            Text("Rental Period")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(Theme.Colors.text)
                        }

                        HStack(spacing: 16) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Start Date")
                                    .font(.caption)
                                    .foregroundColor(Theme.Colors.secondaryText)
                                Text(formatDate(startDate))
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(Theme.Colors.text)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Theme.Colors.secondaryBackground)
                            )

                            Image(systemName: "arrow.right")
                                .foregroundColor(Theme.Colors.primary)
                                .font(.system(size: 18, weight: .semibold))

                            VStack(alignment: .leading, spacing: 6) {
                                Text("Return Date")
                                    .font(.caption)
                                    .foregroundColor(Theme.Colors.secondaryText)
                                Text(formatDate(endDate))
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(Theme.Colors.text)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Theme.Colors.secondaryBackground)
                            )
                        }
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Theme.Colors.cardBackground)
                            .shadow(color: Theme.Shadows.card, radius: Theme.Shadows.cardRadius, x: 0, y: 2)
                    )

                    // Start Date Picker
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Image(systemName: "calendar.badge.clock")
                                .foregroundColor(Theme.Colors.primary)
                                .font(.system(size: 20))
                            Text("Select Start Date")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(Theme.Colors.text)
                        }

                        DatePicker("", selection: $startDate, in: Date()..., displayedComponents: .date)
                            .datePickerStyle(GraphicalDatePickerStyle())
                            .tint(Theme.Colors.primary)
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Theme.Colors.cardBackground)
                            .shadow(color: Theme.Shadows.card, radius: Theme.Shadows.cardRadius, x: 0, y: 2)
                    )

                    // Price Summary
                    VStack(spacing: 16) {
                        HStack {
                            Image(systemName: "dollarsign.circle.fill")
                                .foregroundColor(Theme.Colors.primary)
                                .font(.system(size: 20))
                            Text("Price Summary")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(Theme.Colors.text)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        VStack(spacing: 12) {
                            HStack {
                                Text("Rental Cost")
                                    .foregroundColor(Theme.Colors.text)
                                Spacer()
                                Text("$\(listing.displayPrice, specifier: "%.2f") × \(selectedDuration) \(selectedDuration == 1 ? "day" : "days")")
                                    .foregroundColor(Theme.Colors.secondaryText)
                            }
                            .font(.system(size: 15))

                            HStack {
                                Text("Subtotal")
                                    .foregroundColor(Theme.Colors.text)
                                Spacer()
                                Text("$\(listing.displayPrice * Double(selectedDuration), specifier: "%.2f")")
                                    .foregroundColor(Theme.Colors.text)
                            }
                            .font(.system(size: 15))

                            Divider()
                                .background(Theme.Colors.secondary.opacity(0.3))

                            HStack {
                                Text("Total")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(Theme.Colors.text)
                                Spacer()
                                Text("$\(listing.displayPrice * Double(selectedDuration), specifier: "%.2f")")
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundColor(Theme.Colors.primary)
                            }
                        }

                        Text("Additional fees and insurance will be calculated at checkout")
                            .font(.system(size: 13))
                            .foregroundColor(Theme.Colors.secondaryText)
                            .multilineTextAlignment(.center)
                            .padding(.top, 4)
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Theme.Colors.cardBackground)
                            .shadow(color: Theme.Shadows.card, radius: Theme.Shadows.cardRadius, x: 0, y: 2)
                    )

                    // Continue Button
                    Button(action: proceedToCheckout) {
                        HStack {
                            Text("Continue to Payment")
                                .font(.system(size: 17, weight: .semibold))
                            Image(systemName: "arrow.right")
                                .font(.system(size: 15, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [Theme.Colors.primary, Theme.Colors.primary.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(16)
                        .shadow(color: Theme.Colors.primary.opacity(0.3), radius: 10, x: 0, y: 5)
                    }
                    .padding(.top, 8)

                    // Bottom padding for safe area
                    Color.clear.frame(height: 20)
                }
                .padding(20)
            }
            .background(Theme.Colors.background)
            .navigationTitle("Rental Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(Theme.Colors.primary)
                }
            }
        }
        .fullScreenCover(isPresented: $showingPaymentFlow) {
            RentalPaymentFlowWrapper(
                listing: listing,
                startDate: startDate,
                endDate: endDate,
                onComplete: {
                    showingPaymentFlow = false
                    dismiss()
                }
            )
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }

    private func proceedToCheckout() {
        showingPaymentFlow = true
    }
}

// Wrapper view to pre-configure PaymentFlowView for rental
struct RentalPaymentFlowWrapper: View {
    let listing: Listing
    let startDate: Date
    let endDate: Date
    let onComplete: () -> Void

    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        RentalPaymentFlowView(
            listing: listing,
            startDate: startDate,
            endDate: endDate,
            onDismiss: {
                presentationMode.wrappedValue.dismiss()
                onComplete()
            }
        )
    }
}

// Modern rental payment flow view
struct RentalPaymentFlowView: View {
    let listing: Listing
    let startDate: Date
    let endDate: Date
    let onDismiss: () -> Void

    var body: some View {
        ModernRentalCheckoutView(
            listing: listing,
            startDate: startDate,
            endDate: endDate,
            onDismiss: onDismiss
        )
    }
}

// ReportListingView is now in a separate file

struct ImageGalleryView: View {
    let images: [String]
    @Binding var selectedIndex: Int
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
            
            TabView(selection: $selectedIndex) {
                ForEach(images.indices, id: \.self) { index in
                    BrrowAsyncImage(url: images[index]) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    } placeholder: {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    }
                    .tag(index)
                }
            }
            .tabViewStyle(PageTabViewStyle())
            .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
            
            // Close Button
            VStack {
                HStack {
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundColor(.white)
                            .background(Color.black.opacity(0.5))
                            .clipShape(Circle())
                    }
                    .padding()
                }
                Spacer()
            }
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

struct BasicUserProfileView: View {
    let user: User
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Profile Header
                VStack(spacing: 16) {
                    // Avatar
                    if let avatarUrl = user.profilePicture {
                        BrrowAsyncImage(url: avatarUrl) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 100, height: 100)
                                .clipShape(Circle())
                        } placeholder: {
                            Circle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 100, height: 100)
                        }
                    } else {
                        Circle()
                            .fill(Theme.Colors.primary.opacity(0.2))
                            .frame(width: 100, height: 100)
                            .overlay(
                                Text(user.name.prefix(1).uppercased())
                                    .font(.largeTitle)
                                    .fontWeight(.bold)
                                    .foregroundColor(Theme.Colors.primary)
                            )
                    }
                    
                    // Name and Verification
                    HStack {
                        Text(user.name)
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        if user.isVerified ?? false {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundColor(.blue)
                        }
                    }
                    
                    // Member Since
                    Text("Member since \(user.memberSince, style: .date)")
                        .font(.caption)
                        .foregroundColor(Theme.Colors.secondaryText)
                }
                .padding()
                
                // Stats
                HStack(spacing: 40) {
                    VStack(spacing: 4) {
                        Text("\(user.totalListings)")
                            .font(.title3)
                            .fontWeight(.bold)
                        Text("Listings")
                            .font(.caption)
                            .foregroundColor(Theme.Colors.secondaryText)
                    }
                    
                    VStack(spacing: 4) {
                        Text("\(user.completedRentals)")
                            .font(.title3)
                            .fontWeight(.bold)
                        Text("Rentals")
                            .font(.caption)
                            .foregroundColor(Theme.Colors.secondaryText)
                    }
                    
                    VStack(spacing: 4) {
                        HStack(spacing: 2) {
                            Image(systemName: "star.fill")
                                .font(.caption)
                                .foregroundColor(.orange)
                            Text("\(user.rating, specifier: "%.1f")")
                                .font(.title3)
                                .fontWeight(.bold)
                        }
                        Text("Rating")
                            .font(.caption)
                            .foregroundColor(Theme.Colors.secondaryText)
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
                .padding(.horizontal)
                
                // Bio
                if let bio = user.bio {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("About")
                            .font(.headline)
                        Text(bio)
                            .font(.body)
                            .foregroundColor(Theme.Colors.secondaryText)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                }
                
                // Response Time
                HStack {
                    Image(systemName: "clock.fill")
                        .foregroundColor(Theme.Colors.primary)
                    Text("Usually responds within \(user.responseTime)")
                        .font(.body)
                        .foregroundColor(Theme.Colors.text)
                }
                .padding()
                .background(Theme.Colors.primary.opacity(0.1))
                .cornerRadius(12)
                .padding(.horizontal)
                
                Spacer(minLength: 50)
            }
        }
        .navigationTitle("Seller Profile")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// Preview
struct ProfessionalListingDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ProfessionalListingDetailView(listing: Listing.example)
        }
    }
}