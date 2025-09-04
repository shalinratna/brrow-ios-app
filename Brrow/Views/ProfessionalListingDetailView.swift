import SwiftUI
import MapKit

struct ProfessionalListingDetailView: View {
    let initialListing: Listing
    @StateObject private var viewModel: ListingDetailViewModel
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
    @State private var mapRegion = MKCoordinateRegion()
    @Environment(\.dismiss) private var dismiss
    
    init(listing: Listing) {
        self.initialListing = listing
        self._viewModel = StateObject(wrappedValue: ListingDetailViewModel(listing: listing))
    }
    
    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 0) {
                    // Image Gallery
                    imageGallerySection
                    
                    VStack(spacing: 20) {
                        // Title and Price
                        titlePriceSection
                        
                        // Quick Actions
                        quickActionsSection
                        
                        // Seller Info
                        sellerInfoSection
                        
                        // Description
                        descriptionSection
                        
                        // Specifications
                        if !viewModel.listing.specifications.isEmpty {
                            specificationsSection
                        }
                        
                        // Location Map
                        locationSection
                        
                        // Availability Calendar
                        availabilitySection
                        
                        // Similar Items
                        similarItemsSection
                        
                        // Safety Notice
                        safetyNoticeSection
                    }
                    .padding()
                }
            }
            .ignoresSafeArea(edges: .top)
            
            // Sticky Bottom Bar
            VStack {
                Spacer()
                bottomActionBar
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 16) {
                    Button(action: { viewModel.toggleFavorite() }) {
                        Image(systemName: viewModel.isFavorited ? "heart.fill" : "heart")
                            .foregroundColor(viewModel.isFavorited ? .red : Theme.Colors.text)
                    }
                    
                    Button(action: { showingShareSheet = true }) {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundColor(Theme.Colors.text)
                    }
                }
            }
        }
        .sheet(isPresented: $showingMakeOffer) {
            MakeOfferView(listing: viewModel.listing)
        }
        .sheet(isPresented: $showingReportListing) {
            ReportListingView(listing: viewModel.listing)
        }
        .sheet(isPresented: $showingSellerProfile) {
            if let seller = viewModel.seller {
                FullSellerProfileView(user: seller)
            }
        }
        .sheet(isPresented: $showingEditView) {
            NavigationView {
                EditListingView(listing: viewModel.listing)
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
        .sheet(isPresented: $showingBorrowOptions) {
            BorrowOptionsView(listing: viewModel.listing)
        }
        .sheet(isPresented: $showingInquiry) {
            ListingInquiryView(listing: viewModel.listing)
        }
        .sheet(isPresented: $showingShareSheet) {
            if let url = URL(string: "https://brrowapp.com/listing/\(viewModel.listing.id)") {
                ShareSheet(activityItems: [url])
            }
        }
        .fullScreenCover(isPresented: $showingFullScreenImage) {
            EnhancedImageGalleryView(images: viewModel.listing.images, selectedIndex: $selectedImageIndex)
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
        }
    }
    
    // MARK: - Image Gallery
    private var imageGallerySection: some View {
        Group {
            if !viewModel.listing.images.isEmpty {
                ZStack(alignment: .bottomTrailing) {
                    TabView(selection: $selectedImageIndex) {
                        ForEach(Array(viewModel.listing.images.enumerated()), id: \.offset) { index, imageUrl in
                            let fullUrl = imageUrl.hasPrefix("http") ? imageUrl : "https://brrowapp.com\(imageUrl)"
                            
                            SimpleImageView(url: URL(string: fullUrl), contentMode: .fill)
                                .frame(height: 400)
                                .clipped()
                                .tag(index)
                                .onTapGesture {
                                    showingFullScreenImage = true
                                }
                        }
                    }
                    .frame(height: 400)
                    .tabViewStyle(PageTabViewStyle())
                    .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
                    
                    // Image Counter
                    if viewModel.listing.images.count > 1 {
                        HStack {
                            Image(systemName: "photo.fill")
                            Text("\(selectedImageIndex + 1)/\(viewModel.listing.images.count)")
                        }
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.black.opacity(0.6))
                        .cornerRadius(20)
                        .padding()
                    }
                }
            } else {
                // No images placeholder
                Rectangle()
                    .fill(Color.gray.opacity(0.1))
                    .frame(height: 400)
                    .overlay(
                        VStack(spacing: 12) {
                            Image(systemName: "photo.on.rectangle.angled")
                                .font(.system(size: 50))
                                .foregroundColor(.gray.opacity(0.5))
                            Text("No images available")
                                .font(.caption)
                                .foregroundColor(.gray.opacity(0.5))
                        }
                    )
            }
        }
    }
    
    // MARK: - Title and Price
    private var titlePriceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Pending status badge if applicable
            if viewModel.listing.moderationStatus == "pending" && viewModel.listing.isOwner == true {
                HStack {
                    Image(systemName: "clock.fill")
                        .font(.caption)
                    Text("Pending Review")
                        .font(.caption)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.orange)
                .cornerRadius(20)
            }
            
            Text(viewModel.listing.title.isEmpty ? "Unnamed Item" : viewModel.listing.title)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(Theme.Colors.text)
            
            HStack(alignment: .bottom, spacing: 4) {
                Text("$\(viewModel.listing.price, specifier: "%.2f")")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(Theme.Colors.primary)
                
                Text("/ \(viewModel.listing.rentalPeriod)")
                    .font(.body)
                    .foregroundColor(Theme.Colors.secondaryText)
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
                
                Text("(\(viewModel.reviewCount) reviews)")
                    .font(.caption)
                    .foregroundColor(Theme.Colors.secondaryText)
                
                Spacer()
                
                // Condition Badge
                Text(viewModel.listing.condition)
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(conditionColor.opacity(0.2))
                    .foregroundColor(conditionColor)
                    .cornerRadius(12)
            }
        }
    }
    
    // MARK: - Quick Actions
    private var quickActionsSection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Button(action: { showingBorrowOptions = true }) {
                    Label("Borrow Now", systemImage: "calendar.badge.plus")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Theme.Colors.primary)
                        .cornerRadius(12)
                }
                
                Button(action: { showingMakeOffer = true }) {
                    Label("Make Offer", systemImage: "tag")
                        .font(.headline)
                        .foregroundColor(Theme.Colors.primary)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Theme.Colors.primary, lineWidth: 2)
                        )
                }
            }
            
        }
    }
    
    // MARK: - Seller Info
    private var sellerInfoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("SELLER INFORMATION")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(Theme.Colors.secondaryText)
            
            Button(action: { showingSellerProfile = true }) {
                HStack(spacing: 12) {
                    // Seller Avatar
                    if let avatarUrl = viewModel.seller?.profilePicture {
                        AsyncImage(url: URL(string: avatarUrl)) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 50, height: 50)
                                .clipShape(Circle())
                        } placeholder: {
                            Circle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 50, height: 50)
                        }
                    } else {
                        Circle()
                            .fill(Theme.Colors.primary.opacity(0.2))
                            .frame(width: 50, height: 50)
                            .overlay(
                                Text(viewModel.seller?.name.prefix(1).uppercased() ?? "?")
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                    .foregroundColor(Theme.Colors.primary)
                            )
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(viewModel.seller?.name ?? viewModel.listing.ownerUsername ?? "Seller")
                            .font(.headline)
                            .foregroundColor(Theme.Colors.text)
                        
                        HStack(spacing: 8) {
                            // Verified Badge
                            if viewModel.seller?.isVerified ?? false {
                                HStack(spacing: 2) {
                                    Image(systemName: "checkmark.seal.fill")
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                    Text("Verified")
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                }
                            }
                            
                            // Response Time
                            Text("Responds in ~\(viewModel.seller?.responseTime ?? "2 hours")")
                                .font(.caption)
                                .foregroundColor(Theme.Colors.secondaryText)
                        }
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(Theme.Colors.secondaryText)
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
            }
            .buttonStyle(PlainButtonStyle())
            
            // Seller Stats
            HStack(spacing: 20) {
                VStack(spacing: 4) {
                    Text("\(viewModel.seller?.totalListings ?? 0)")
                        .font(.headline)
                        .foregroundColor(Theme.Colors.text)
                    Text("Items")
                        .font(.caption)
                        .foregroundColor(Theme.Colors.secondaryText)
                }
                
                Divider()
                    .frame(height: 30)
                
                VStack(spacing: 4) {
                    Text("\(viewModel.seller?.completedRentals ?? 0)")
                        .font(.headline)
                        .foregroundColor(Theme.Colors.text)
                    Text("Rentals")
                        .font(.caption)
                        .foregroundColor(Theme.Colors.secondaryText)
                }
                
                Divider()
                    .frame(height: 30)
                
                VStack(spacing: 4) {
                    HStack(spacing: 2) {
                        Image(systemName: "star.fill")
                            .font(.caption)
                            .foregroundColor(.orange)
                        Text("\(viewModel.seller?.rating ?? 0.0, specifier: "%.1f")")
                            .font(.headline)
                            .foregroundColor(Theme.Colors.text)
                    }
                    Text("Rating")
                        .font(.caption)
                        .foregroundColor(Theme.Colors.secondaryText)
                }
                
                Spacer()
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
    
    // MARK: - Description
    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("DESCRIPTION")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(Theme.Colors.secondaryText)
            
            Text(viewModel.listing.description.isEmpty ? "No description available for this item." : viewModel.listing.description)
                .font(.body)
                .foregroundColor(viewModel.listing.description.isEmpty ? Theme.Colors.secondaryText : Theme.Colors.text)
                .fixedSize(horizontal: false, vertical: true)
        }
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
                // Map Preview
                Map(coordinateRegion: $mapRegion, annotationItems: [viewModel.listing]) { item in
                    MapMarker(coordinate: CLLocationCoordinate2D(
                        latitude: item.latitude,
                        longitude: item.longitude
                    ), tint: Theme.Colors.primary)
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
                
                Text(viewModel.listing.isAvailable ? "Available for rent" : "Currently rented")
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
                
                NavigationLink(destination: BrowseView()) {
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
    
    // MARK: - Bottom Action Bar
    private var bottomActionBar: some View {
        HStack(spacing: 16) {
            // Price
            VStack(alignment: .leading, spacing: 2) {
                Text("Total")
                    .font(.caption)
                    .foregroundColor(Theme.Colors.secondaryText)
                
                Text("$\(viewModel.listing.price, specifier: "%.2f")")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(Theme.Colors.text)
            }
            
            Spacer()
            
            // Show different buttons based on ownership
            if viewModel.listing.isOwner == true {
                // Owner actions: Edit and Delete
                Button(action: { 
                    // Navigate to edit view
                    showingEditView = true 
                }) {
                    HStack {
                        Image(systemName: "pencil")
                        Text("Edit")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .frame(height: 50)
                    .background(Theme.Colors.primary)
                    .cornerRadius(25)
                }
                
                Button(action: { 
                    showingDeleteConfirmation = true 
                }) {
                    Image(systemName: "trash")
                        .font(.title3)
                        .foregroundColor(.red)
                        .frame(width: 50, height: 50)
                        .background(
                            Circle()
                                .fill(Color.red.opacity(0.1))
                        )
                }
            } else {
                // Non-owner actions: Message and Borrow
                Button(action: { viewModel.messageOwner() }) {
                    Image(systemName: "message.fill")
                        .font(.title3)
                        .foregroundColor(Theme.Colors.primary)
                        .frame(width: 50, height: 50)
                        .background(
                            Circle()
                                .fill(Theme.Colors.primary.opacity(0.1))
                        )
                }
                
                Button(action: { showingBorrowOptions = true }) {
                    Text("Borrow Now")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 32)
                        .frame(height: 50)
                        .background(Theme.Colors.primary)
                        .cornerRadius(25)
                }
            }
        }
        .padding()
        .background(
            Color.white
                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: -5)
        )
    }
    
    // MARK: - Helper Methods
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
            AsyncImage(url: URL(string: listing.images.first ?? "")) { image in
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
            Text("$\(listing.price, specifier: "%.2f")/\(listing.rentalPeriod ?? "day")")
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
                    
                    Text("Original price: $\(listing.price, specifier: "%.2f")")
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
                    Text("Send Offer")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Theme.Colors.primary)
                        .cornerRadius(12)
                }
                .disabled(offerAmount.isEmpty)
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
        }
    }
    
    private func submitOffer() {
        // Submit offer logic
        dismiss()
    }
}

struct BorrowOptionsView: View {
    let listing: Listing
    @State private var selectedDuration = 1
    @State private var startDate = Date()
    @State private var includeInsurance = true
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Duration Selection
                VStack(alignment: .leading, spacing: 12) {
                    Text("Rental Duration")
                        .font(.headline)
                    
                    Picker("Duration", selection: $selectedDuration) {
                        ForEach(1...7, id: \.self) { days in
                            Text("\(days) \(days == 1 ? "day" : "days")")
                                .tag(days)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                // Start Date
                VStack(alignment: .leading, spacing: 12) {
                    Text("Start Date")
                        .font(.headline)
                    
                    DatePicker("", selection: $startDate, displayedComponents: .date)
                        .datePickerStyle(GraphicalDatePickerStyle())
                }
                
                // Insurance Option
                Toggle(isOn: $includeInsurance) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Include Insurance")
                            .font(.headline)
                        Text("$5.00 additional")
                            .font(.caption)
                            .foregroundColor(Theme.Colors.secondaryText)
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
                
                // Price Summary
                VStack(spacing: 12) {
                    HStack {
                        Text("Rental (\(selectedDuration) days)")
                        Spacer()
                        Text("$\(listing.price * Double(selectedDuration), specifier: "%.2f")")
                    }
                    
                    if includeInsurance {
                        HStack {
                            Text("Insurance")
                            Spacer()
                            Text("$5.00")
                        }
                    }
                    
                    Divider()
                    
                    HStack {
                        Text("Total")
                            .font(.headline)
                        Spacer()
                        Text("$\(calculateTotal(), specifier: "%.2f")")
                            .font(.headline)
                            .foregroundColor(Theme.Colors.primary)
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.05))
                .cornerRadius(12)
                
                Spacer()
                
                // Continue Button
                Button(action: proceedToCheckout) {
                    Text("Continue to Payment")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Theme.Colors.primary)
                        .cornerRadius(12)
                }
            }
            .padding()
            .navigationTitle("Borrow Options")
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
    
    private func calculateTotal() -> Double {
        let rentalCost = listing.price * Double(selectedDuration)
        let insuranceCost = includeInsurance ? 5.0 : 0.0
        return rentalCost + insuranceCost
    }
    
    private func proceedToCheckout() {
        // Proceed to payment
        dismiss()
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
                    AsyncImage(url: URL(string: images[index])) { image in
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
                        AsyncImage(url: URL(string: avatarUrl)) { image in
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
                        
                        if user.isVerified {
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