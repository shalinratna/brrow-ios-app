import SwiftUI
import MapKit

struct FullScreenListingDetailView: View {
    let listing: Listing
    @StateObject private var viewModel: ListingDetailViewModel
    @State private var selectedImageIndex = 0
    @State private var showingInquiry = false
    @State private var showingShareSheet = false
    @State private var showingSellerProfile = false
    @State private var showingBorrowOptions = false
    @State private var inquiryMessage = ""
    @State private var animateContent = false
    @State private var showingErrorAlert = false
    @State private var errorMessage = ""
    @Environment(\.dismiss) private var dismiss
    
    init(listing: Listing) {
        self.listing = listing
        self._viewModel = StateObject(wrappedValue: ListingDetailViewModel(listing: listing))
    }
    
    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Custom Header
                customHeader
                
                ScrollView {
                    VStack(spacing: 0) {
                        // Image Gallery
                        imageGallerySection
                        
                        VStack(spacing: 20) {
                            // Title and Price
                            titlePriceSection
                            
                            // Quick Stats
                            quickStatsSection
                            
                            // Seller Info
                            sellerInfoSection
                            
                            // Description
                            descriptionSection
                            
                            // Specifications
                            if !listing.specifications.isEmpty {
                                specificationsSection
                            }
                            
                            // Location
                            locationSection
                            
                            // Similar Items
                            similarItemsSection
                        }
                        .padding()
                        .padding(.bottom, 100) // Space for bottom bar
                    }
                }
                .ignoresSafeArea(edges: .top)
            }
            
            // Sticky Bottom Bar
            VStack {
                Spacer()
                bottomActionBar
            }
        }
        .navigationBarHidden(true)
        .alert("Error", isPresented: $showingErrorAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        .sheet(isPresented: $showingInquiry) {
            FullScreenInquiryView(listing: listing, message: $inquiryMessage) { message in
                sendInquiry(message: message)
            }
        }
        .sheet(isPresented: $showingSellerProfile) {
            if let seller = viewModel.seller {
                BasicUserProfileView(user: seller)
            }
        }
        .sheet(isPresented: $showingShareSheet) {
            ShareSheet(activityItems: [
                "Check out this item on Brrow: \(listing.title)",
                URL(string: "https://brrowapp.com/listing/\(listing.id)")!
            ])
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.3)) {
                animateContent = true
            }
        }
    }
    
    // MARK: - Custom Header
    private var customHeader: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(Theme.Colors.text)
                    .frame(width: 44, height: 44)
                    .background(Color.white)
                    .clipShape(Circle())
                    .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
            }
            
            Spacer()
            
            HStack(spacing: 12) {
                Button(action: { viewModel.toggleFavorite() }) {
                    Image(systemName: viewModel.isFavorited ? "heart.fill" : "heart")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(viewModel.isFavorited ? .red : Theme.Colors.text)
                        .frame(width: 44, height: 44)
                        .background(Color.white)
                        .clipShape(Circle())
                        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                }
                
                Button(action: { showingShareSheet = true }) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(Theme.Colors.text)
                        .frame(width: 44, height: 44)
                        .background(Color.white)
                        .clipShape(Circle())
                        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(Color.white.opacity(0.95))
    }
    
    // MARK: - Image Gallery
    private var imageGallerySection: some View {
        TabView(selection: $selectedImageIndex) {
            ForEach(Array(listing.imageUrls.enumerated()), id: \.offset) { index, imageUrl in
                BrrowAsyncImage(url: imageUrl) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .background(Color.black)
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.1))
                        .overlay(
                            ProgressView()
                        )
                }
                .tag(index)
            }
        }
        .tabViewStyle(PageTabViewStyle())
        .frame(height: 400)
        .overlay(
            // Image counter
            HStack {
                Spacer()
                Text("\(selectedImageIndex + 1)/\(listing.images.count)")
                    .font(.system(size: 14, weight: .medium))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.black.opacity(0.6))
                    .foregroundColor(.white)
                    .cornerRadius(20)
                    .padding()
            }
            .padding(.top, 60),
            alignment: .topTrailing
        )
    }
    
    // MARK: - Title and Price Section
    private var titlePriceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(listing.title)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(Theme.Colors.text)
            
            HStack(alignment: .bottom, spacing: 8) {
                Text("$\(String(format: "%.2f", listing.price))")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(Theme.Colors.primary)
                
                if listing.price > 0 {
                    Text("per day")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Theme.Colors.secondaryText)
                }
                
                Spacer()
                
                if "listing" == "rental" {
                    Label("For Rent", systemImage: "clock.arrow.circlepath")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Theme.Colors.primary)
                        .cornerRadius(20)
                } else {
                    Label("For Sale", systemImage: "tag.fill")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Theme.Colors.accent)
                        .cornerRadius(20)
                }
            }
        }
        .opacity(animateContent ? 1 : 0)
        .offset(y: animateContent ? 0 : 20)
        .animation(.easeOut(duration: 0.3).delay(0.1), value: animateContent)
    }
    
    // MARK: - Quick Stats
    private var quickStatsSection: some View {
        HStack(spacing: 20) {
            StatItem(icon: "eye", value: "\(listing.views)", label: "Views")
            StatItem(icon: "heart", value: "0", label: "Likes")
            if "listing" == "rental" {
                StatItem(icon: "clock", value: "\(listing.timesBorrowed)", label: "Rented")
            }
            if let rating = listing.rating {
                StatItem(icon: "star.fill", value: String(format: "%.1f", rating), label: "Rating")
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
        .opacity(animateContent ? 1 : 0)
        .offset(y: animateContent ? 0 : 20)
        .animation(.easeOut(duration: 0.3).delay(0.2), value: animateContent)
    }
    
    // MARK: - Seller Info
    private var sellerInfoSection: some View {
        Button(action: { showingSellerProfile = true }) {
            HStack(spacing: 12) {
                BrrowAsyncImage(url: viewModel.seller?.profilePicture ?? "") { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Image(systemName: "person.crop.circle.fill")
                        .font(.system(size: 50))
                        .foregroundColor(Theme.Colors.secondary)
                }
                .frame(width: 60, height: 60)
                .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(viewModel.seller?.username ?? "Loading...")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(Theme.Colors.text)
                        
                        if viewModel.seller?.verified == true {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 16))
                                .foregroundColor(Theme.Colors.primary)
                        }
                    }
                    
                    HStack(spacing: 12) {
                        if let rating = viewModel.seller?.listerRating {
                            HStack(spacing: 4) {
                                Image(systemName: "star.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(.orange)
                                Text(String(format: "%.1f", rating))
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(Theme.Colors.secondaryText)
                            }
                        }
                        
                        Text("Member since \(viewModel.seller?.createdAt ?? "")")
                            .font(.system(size: 14))
                            .foregroundColor(Theme.Colors.secondaryText)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 16))
                    .foregroundColor(Theme.Colors.secondaryText)
            }
            .padding()
            .background(Color.gray.opacity(0.05))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
        .opacity(animateContent ? 1 : 0)
        .offset(y: animateContent ? 0 : 20)
        .animation(.easeOut(duration: 0.3).delay(0.3), value: animateContent)
    }
    
    // MARK: - Description
    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Description")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(Theme.Colors.text)
            
            Text(listing.description)
                .font(.system(size: 16))
                .foregroundColor(Theme.Colors.secondaryText)
                .lineSpacing(4)
            
            // Tags removed - not available in current Listing model
        }
        .opacity(animateContent ? 1 : 0)
        .offset(y: animateContent ? 0 : 20)
        .animation(.easeOut(duration: 0.3).delay(0.4), value: animateContent)
    }
    
    // MARK: - Specifications
    private var specificationsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Specifications")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(Theme.Colors.text)
            
            VStack(spacing: 12) {
                ForEach(Array(listing.specifications.enumerated()), id: \.element.key) { index, spec in
                    HStack {
                        Text(spec.key.replacingOccurrences(of: "_", with: " ").capitalized)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Theme.Colors.secondaryText)
                        
                        Spacer()
                        
                        Text(spec.value)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Theme.Colors.text)
                    }
                    
                    if index < listing.specifications.count - 1 {
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
            HStack {
                Image(systemName: "location")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(Theme.Colors.primary)
                
                Text(listing.locationString)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(Theme.Colors.text)
                
                Spacer()
            }
            
            // Map preview would go here
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.1))
                .frame(height: 150)
                .overlay(
                    Text("Map View")
                        .foregroundColor(Theme.Colors.secondaryText)
                )
        }
    }
    
    // MARK: - Similar Items
    private var similarItemsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Similar Items")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(Theme.Colors.text)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(viewModel.similarListings) { similar in
                        SimilarItemCard(listing: similar)
                    }
                }
            }
        }
    }
    
    // MARK: - Bottom Action Bar
    private var bottomActionBar: some View {
        HStack(spacing: 12) {
            Button(action: { showingInquiry = true }) {
                HStack {
                    Image(systemName: "message.fill")
                        .font(.system(size: 18, weight: .medium))
                    Text("Send Inquiry")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Theme.Colors.primary)
                .cornerRadius(25)
            }
            
            if "listing" == "rental" {
                Button(action: { showingBorrowOptions = true }) {
                    HStack {
                        Image(systemName: "calendar.badge.plus")
                            .font(.system(size: 18, weight: .medium))
                        Text("Rent Now")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Theme.Colors.accent)
                    .cornerRadius(25)
                }
            } else {
                Button(action: { /* Buy action */ }) {
                    HStack {
                        Image(systemName: "cart.fill")
                            .font(.system(size: 18, weight: .medium))
                        Text("Buy Now")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Theme.Colors.accent)
                    .cornerRadius(25)
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 16)
        .background(
            Color.white
                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: -5)
        )
    }
    
    // MARK: - Helper Methods
    private func sendInquiry(message: String) {
        Task {
            do {
                _ = try await viewModel.sendInquiry(message: message)
                // Success - the viewModel will post notification to navigate to chat
                await MainActor.run {
                    showingInquiry = false
                    inquiryMessage = ""
                }
            } catch {
                print("Failed to send inquiry: \(error)")
                await MainActor.run {
                    errorMessage = "Failed to send inquiry. Please try again."
                    showingErrorAlert = true
                }
            }
        }
    }
}

// MARK: - Supporting Views
struct StatItem: View {
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(Theme.Colors.primary)
            
            Text(value)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(Theme.Colors.text)
            
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(Theme.Colors.secondaryText)
        }
        .frame(maxWidth: .infinity)
    }
}

// SimilarItemCard moved to ProfessionalListingDetailView to avoid duplication

// MARK: - Inquiry View
struct FullScreenInquiryView: View {
    let listing: Listing
    @Binding var message: String
    let onSend: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isMessageFocused: Bool
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Listing preview
                HStack(spacing: 12) {
                    BrrowAsyncImage(url: listing.imageUrls.first ?? "") { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                    }
                    .frame(width: 80, height: 80)
                    .cornerRadius(12)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(listing.title)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Theme.Colors.text)
                            .lineLimit(2)
                        
                        Text("$\(String(format: "%.2f", listing.price))")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(Theme.Colors.primary)
                    }
                    
                    Spacer()
                }
                .padding()
                .background(Color.gray.opacity(0.05))
                .cornerRadius(12)
                
                // Quick responses
                VStack(alignment: .leading, spacing: 12) {
                    Text("Quick Responses")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Theme.Colors.text)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach([
                                "Is this still available?",
                                "What's the condition?",
                                "Can I see more photos?",
                                "Is the price negotiable?",
                                "When can I pick it up?"
                            ], id: \.self) { quickResponse in
                                Button(action: {
                                    message = quickResponse
                                }) {
                                    Text(quickResponse)
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(Theme.Colors.primary)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(
                                            RoundedRectangle(cornerRadius: 20)
                                                .stroke(Theme.Colors.primary, lineWidth: 1)
                                        )
                                }
                            }
                        }
                    }
                }
                
                // Message input
                VStack(alignment: .leading, spacing: 8) {
                    Text("Your Message")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Theme.Colors.text)
                    
                    TextEditor(text: $message)
                        .font(.system(size: 16))
                        .padding(12)
                        .background(Color.gray.opacity(0.05))
                        .cornerRadius(12)
                        .frame(minHeight: 120)
                        .focused($isMessageFocused)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Send Inquiry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Send") {
                        if !message.isEmpty {
                            onSend(message)
                            dismiss()
                        }
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .disabled(message.isEmpty)
                }
            }
        }
        .onAppear {
            isMessageFocused = true
        }
    }
}

// Helper Flow Layout
struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(
            in: proposal.replacingUnspecifiedDimensions().width,
            subviews: subviews,
            spacing: spacing
        )
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(
            in: bounds.width,
            subviews: subviews,
            spacing: spacing
        )
        for row in result.rows {
            for (frameIndex, index) in row.indices.enumerated() {
                // Ensure we have a corresponding frame
                guard frameIndex < row.frames.count else { continue }
                let frame = row.frames[frameIndex]
                let position = CGPoint(
                    x: bounds.minX + frame.minX,
                    y: bounds.minY + frame.minY
                )
                subviews[index].place(at: position, proposal: ProposedViewSize(frame.size))
            }
        }
    }
    
    struct FlowResult {
        var size: CGSize = .zero
        var rows: [Row] = []
        
        struct Row {
            var indices: Range<Int>
            var frames: [CGRect] = []
        }
        
        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var rowHeight: CGFloat = 0
            var rowStart = 0
            
            for (index, subview) in subviews.enumerated() {
                let dimensions = subview.dimensions(in: ProposedViewSize(width: nil, height: nil))
                
                if x + dimensions.width > maxWidth && index > rowStart {
                    // Finish current row
                    finalizeRow(rowStart: rowStart, rowEnd: index, y: y, rowHeight: rowHeight)
                    
                    // Start new row
                    x = 0
                    y += rowHeight + spacing
                    rowHeight = 0
                    rowStart = index
                }
                
                // Add frame to current row
                let frame = CGRect(x: x, y: y, width: dimensions.width, height: dimensions.height)
                
                if rows.isEmpty || rows.last!.indices.upperBound <= index {
                    rows.append(Row(indices: rowStart..<index + 1, frames: [frame]))
                } else {
                    rows[rows.count - 1].frames.append(frame)
                }
                
                x += dimensions.width + spacing
                rowHeight = max(rowHeight, dimensions.height)
                size.width = max(size.width, x - spacing)
            }
            
            // Finalize last row
            if rowStart < subviews.count {
                finalizeRow(rowStart: rowStart, rowEnd: subviews.count, y: y, rowHeight: rowHeight)
            }
            
            size.height = y + rowHeight
        }
        
        mutating func finalizeRow(rowStart: Int, rowEnd: Int, y: CGFloat, rowHeight: CGFloat) {
            if rowStart < rowEnd {
                rows.append(Row(indices: rowStart..<rowEnd, frames: []))
            }
        }
    }
}