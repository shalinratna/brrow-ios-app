import SwiftUI
import Charts
import PhotosUI

struct SocialMediaProfileView: View {
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var viewModel = ModernProfileViewModel()
    @State private var selectedTab = 0
    @State private var showSettings = false
    @State private var showEditProfile = false
    @State private var animateIn = false
    @State private var pulseAnimation = false
    @State private var gradientAngle = 0.0
    @State private var selectedListing: Listing?
    @State private var showCreateListing = false
    @State private var showShareSheet = false
    @State private var listingToShare: Listing?
    @State private var showEditListing = false
    @State private var listingToEdit: Listing?
    
    let profileTabs = ["Listings", "Reviews", "About", "Activity"]
    let gradientColors = [
        [Color(#colorLiteral(red: 0.9568627451, green: 0.2588235294, blue: 0.8588235294, alpha: 1)), Color(#colorLiteral(red: 0.4156862745, green: 0.7098039216, blue: 0.9294117647, alpha: 1))],
        [Color(#colorLiteral(red: 0.9803921569, green: 0.3921568627, blue: 0.3921568627, alpha: 1)), Color(#colorLiteral(red: 0.9607843137, green: 0.7058823529, blue: 0.2, alpha: 1))],
        [Color(#colorLiteral(red: 0.2039215686, green: 0.7803921569, blue: 0.3490196078, alpha: 1)), Color(#colorLiteral(red: 0.3647058824, green: 0.8549019608, blue: 0.7725490196, alpha: 1))],
        [Color(#colorLiteral(red: 0.5843137255, green: 0.4274509804, blue: 0.9411764706, alpha: 1)), Color(#colorLiteral(red: 0.9098039216, green: 0.5098039216, blue: 0.9647058824, alpha: 1))]
    ]
    @State private var currentGradientIndex = 0
    
    var body: some View {
        NavigationView {
            ZStack {
                // Animated gradient background
                animatedBackground
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        // Instagram-style header
                        profileHeader
                            .padding(.top, 60)
                        
                        // Stats bar
                        statsBar
                            .padding(.vertical, 20)
                        
                        // Bio section
                        bioSection
                            .padding(.horizontal, 20)
                            .padding(.bottom, 20)
                        
                        // Action buttons
                        actionButtons
                            .padding(.horizontal, 20)
                            .padding(.bottom, 20)
                        
                        // Tab selector
                        tabSelector
                        
                        // Content based on selected tab
                        tabContent
                            .padding(.top, 20)
                    }
                    .padding(.bottom, 100)
                }
                
                // Floating action button
                floatingActionButton
            }
            .navigationBarHidden(true)
            .onAppear {
                startAnimations()
                viewModel.loadUserData()
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
            .sheet(isPresented: $showEditProfile) {
                if let user = authManager.currentUser {
                    EditProfileView(user: user)
                }
            }
            .sheet(isPresented: $showCreateListing) {
                ModernCreateListingView()
            }
            .sheet(item: $selectedListing) { listing in
                NavigationView {
                    ListingDetailView(listing: listing)
                }
            }
            .sheet(item: $listingToEdit) { listing in
                EditListingView(listing: listing)
                    .environmentObject(AuthManager.shared)
            }
            .sheet(isPresented: $showShareSheet) {
                if let listing = listingToShare {
                    ShareSheet(activityItems: [createShareText(for: listing)])
                }
            }
        }
    }
    
    // MARK: - Animated Background
    private var animatedBackground: some View {
        ZStack {
            // Dynamic gradient
            LinearGradient(
                colors: gradientColors[currentGradientIndex],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            .onAppear {
                Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
                    withAnimation(.easeInOut(duration: 2.0)) {
                        currentGradientIndex = (currentGradientIndex + 1) % gradientColors.count
                    }
                }
            }
            
            // Floating orbs
            ForEach(0..<6) { index in
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.white.opacity(0.3),
                                Color.white.opacity(0.1),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 50
                        )
                    )
                    .frame(width: CGFloat.random(in: 50...150))
                    .blur(radius: 10)
                    .offset(
                        x: animateIn ? CGFloat.random(in: -200...200) : 0,
                        y: animateIn ? CGFloat.random(in: -400...400) : 0
                    )
                    .animation(
                        .easeInOut(duration: Double.random(in: 10...20))
                        .repeatForever(autoreverses: true)
                        .delay(Double(index) * 0.5),
                        value: animateIn
                    )
            }
            
            // Glass overlay
            Rectangle()
                .fill(.ultraThinMaterial)
                .opacity(0.3)
                .ignoresSafeArea()
        }
    }
    
    // MARK: - Profile Header
    private var profileHeader: some View {
        VStack(spacing: 16) {
            HStack {
                // Username
                Text("@\(viewModel.user?.username ?? "username")")
                    .font(.title2.bold())
                    .foregroundColor(.white)
                
                Spacer()
                
                // Top buttons
                HStack(spacing: 16) {
                    Button(action: { showCreateListing = true }) {
                        Image(systemName: "plus.square")
                            .font(.title2)
                            .foregroundColor(.white)
                    }
                    
                    Button(action: { showSettings = true }) {
                        Image(systemName: "line.3.horizontal")
                            .font(.title2)
                            .foregroundColor(.white)
                    }
                }
            }
            .padding(.horizontal, 20)
            
            // Profile picture with ring animation
            ZStack {
                // Animated ring
                Circle()
                    .stroke(
                        AngularGradient(
                            colors: [.pink, .purple, .blue, .cyan, .green, .yellow, .orange, .red, .pink],
                            center: .center,
                            angle: .degrees(gradientAngle)
                        ),
                        lineWidth: 4
                    )
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(gradientAngle))
                
                // Profile image
                if let avatarUrl = viewModel.user?.profilePicture {
                    AsyncImage(url: URL(string: avatarUrl)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 100))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .frame(width: 110, height: 110)
                    .clipShape(Circle())
                } else {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 110))
                        .foregroundColor(.white.opacity(0.8))
                }
                
                // Online indicator
                Circle()
                    .fill(Color.green)
                    .frame(width: 24, height: 24)
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: 3)
                    )
                    .offset(x: 40, y: 40)
                    .scaleEffect(pulseAnimation ? 1.2 : 1.0)
            }
            
            // Name
            Text(viewModel.user?.username ?? "Your Name")
                .font(.title.bold())
                .foregroundColor(.white)
                .opacity(animateIn ? 1 : 0)
                .offset(y: animateIn ? 0 : 20)
                .animation(.spring(response: 0.6).delay(0.2), value: animateIn)
        }
    }
    
    // MARK: - Stats Bar
    private var statsBar: some View {
        HStack(spacing: 0) {
            ProfileStatItem(
                value: "\(viewModel.userListings.count)",
                label: "Listings",
                color: .orange
            )
            
            Divider()
                .frame(height: 40)
                .background(Color.white.opacity(0.3))
            
            ProfileStatItem(
                value: String(format: "%.1f", viewModel.rating),
                label: "Rating",
                color: .yellow,
                icon: "star.fill"
            )
            
            Divider()
                .frame(height: 40)
                .background(Color.white.opacity(0.3))
            
            ProfileStatItem(
                value: "\(viewModel.totalRentals)",
                label: "Rentals",
                color: .green
            )
            
            Divider()
                .frame(height: 40)
                .background(Color.white.opacity(0.3))
            
            ProfileStatItem(
                value: "$\(viewModel.totalEarnings)",
                label: "Earned",
                color: .purple
            )
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.1), radius: 10)
        )
        .padding(.horizontal, 20)
        .opacity(animateIn ? 1 : 0)
        .scaleEffect(animateIn ? 1 : 0.8)
        .animation(.spring(response: 0.6).delay(0.3), value: animateIn)
    }
    
    // MARK: - Bio Section
    private var bioSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Bio text
            if let bio = viewModel.user?.bio, !bio.isEmpty {
                Text(bio)
                    .font(.body)
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.leading)
            }
            
            // Location
            HStack {
                Image(systemName: "location.fill")
                    .font(.caption)
                Text("San Francisco, CA")
                    .font(.subheadline)
            }
            .foregroundColor(.white.opacity(0.8))
            
            // Member since
            HStack {
                Image(systemName: "calendar")
                    .font(.caption)
                Text("Member since \(formatMemberSince())")
                    .font(.subheadline)
            }
            .foregroundColor(.white.opacity(0.8))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .opacity(animateIn ? 1 : 0)
        .offset(y: animateIn ? 0 : 20)
        .animation(.spring(response: 0.6).delay(0.4), value: animateIn)
    }
    
    // MARK: - Action Buttons
    private var actionButtons: some View {
        HStack(spacing: 12) {
            Button(action: { showEditProfile = true }) {
                Label("Edit Profile", systemImage: "square.and.pencil")
                    .font(.subheadline.bold())
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.2))
                    )
            }
            
            Button(action: { shareProfile() }) {
                Label("Share", systemImage: "square.and.arrow.up")
                    .font(.subheadline.bold())
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.2))
                    )
            }
        }
        .opacity(animateIn ? 1 : 0)
        .scaleEffect(animateIn ? 1 : 0.8)
        .animation(.spring(response: 0.6).delay(0.5), value: animateIn)
    }
    
    // MARK: - Tab Selector
    private var tabSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 30) {
                ForEach(0..<profileTabs.count, id: \.self) { index in
                    VStack(spacing: 8) {
                        Text(profileTabs[index])
                            .font(.headline)
                            .foregroundColor(selectedTab == index ? .white : .white.opacity(0.7))
                        
                        Rectangle()
                            .fill(Color.white)
                            .frame(height: 3)
                            .opacity(selectedTab == index ? 1 : 0)
                            .animation(.spring(response: 0.3), value: selectedTab)
                    }
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3)) {
                            selectedTab = index
                        }
                        HapticManager.impact(style: .light)
                    }
                }
            }
            .padding(.horizontal, 20)
        }
        .padding(.vertical, 16)
        .background(
            Rectangle()
                .fill(.ultraThinMaterial)
                .opacity(0.5)
        )
    }
    
    // MARK: - Tab Content
    private var tabContent: some View {
        Group {
            switch selectedTab {
            case 0: // Listings
                listingsGrid
            case 1: // Reviews
                reviewsSection
            case 2: // About
                aboutSection
            case 3: // Activity
                activitySection
            default:
                EmptyView()
            }
        }
        .transition(.asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        ))
    }
    
    // MARK: - Listings Grid (Instagram Style)
    private var listingsGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 2),
            GridItem(.flexible(), spacing: 2),
            GridItem(.flexible(), spacing: 2)
        ], spacing: 2) {
            ForEach(viewModel.userListings) { listing in
                ListingGridItem(listing: listing) {
                    selectedListing = listing
                } onEdit: {
                    listingToEdit = listing
                } onShare: {
                    listingToShare = listing
                    showShareSheet = true
                }
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.horizontal, 2)
    }
    
    // MARK: - Reviews Section
    private var reviewsSection: some View {
        VStack(spacing: 16) {
            ForEach(0..<3) { index in
                ProfileReviewCard(index: index)
                    .padding(.horizontal, 20)
                    .transition(.asymmetric(
                        insertion: .slide.combined(with: .opacity),
                        removal: .scale.combined(with: .opacity)
                    ))
            }
        }
    }
    
    // MARK: - About Section
    private var aboutSection: some View {
        VStack(spacing: 20) {
            // Verification badges
            VStack(alignment: .leading, spacing: 16) {
                Text("Verifications")
                    .font(.headline)
                    .foregroundColor(.white)
                
                HStack(spacing: 16) {
                    VerificationBadge(icon: "checkmark.shield.fill", title: "ID Verified", color: .green)
                    VerificationBadge(icon: "envelope.fill", title: "Email", color: .blue)
                    VerificationBadge(icon: "phone.fill", title: "Phone", color: .orange)
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
            )
            
            // Response time
            HStack {
                Image(systemName: "clock.fill")
                    .foregroundColor(.yellow)
                Text("Usually responds within 1 hour")
                    .font(.subheadline)
                    .foregroundColor(.white)
                Spacer()
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
            )
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - Activity Section
    private var activitySection: some View {
        VStack(spacing: 16) {
            // Activity chart
            ActivityChart()
                .frame(height: 200)
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.ultraThinMaterial)
                )
            
            // Recent activity
            VStack(alignment: .leading, spacing: 16) {
                Text("Recent Activity")
                    .font(.headline)
                    .foregroundColor(.white)
                
                ForEach(0..<5) { index in
                    ActivityItem(index: index)
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
            )
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - Floating Action Button
    private var floatingActionButton: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                
                Button(action: { showCreateListing = true }) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.pink, Color.purple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 60, height: 60)
                            .shadow(color: .purple.opacity(0.3), radius: 10, y: 5)
                        
                        Image(systemName: "plus")
                            .font(.title2.bold())
                            .foregroundColor(.white)
                            .rotationEffect(.degrees(showCreateListing ? 45 : 0))
                    }
                }
                .scaleEffect(pulseAnimation ? 1.1 : 1.0)
                .padding(20)
            }
        }
    }
    
    // MARK: - Helper Functions
    private func startAnimations() {
        withAnimation(.easeOut(duration: 0.8)) {
            animateIn = true
        }
        
        withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
            gradientAngle = 360
        }
        
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
            pulseAnimation = true
        }
    }
    
    private func formatMemberSince() -> String {
        guard let createdAtString = viewModel.user?.createdAt else { return "Unknown" }
        
        let isoFormatter = ISO8601DateFormatter()
        if let date = isoFormatter.date(from: createdAtString) {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMMM yyyy"
            return formatter.string(from: date)
        }
        return "Unknown"
    }
    
    private func shareProfile() {
        // Share profile functionality
        HapticManager.impact(style: .medium)
    }
    
    private func createShareText(for listing: Listing) -> String {
        return "Check out \(listing.title) on Brrow for $\(Int(listing.price))\("listing" == "rental" ? "/day" : "")! Download the app to rent or buy from your neighbors."
    }
}

// MARK: - Supporting Views

struct ProfileStatItem: View {
    let value: String
    let label: String
    let color: Color
    var icon: String? = nil
    
    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.caption)
                        .foregroundColor(color)
                }
                Text(value)
                    .font(.title3.bold())
                    .foregroundColor(.white)
            }
            
            Text(label)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
    }
}

struct ListingGridItem: View {
    let listing: Listing
    let onTap: () -> Void
    let onEdit: () -> Void
    let onShare: () -> Void
    
    @State private var showMenu = false
    @State private var isPressed = false
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            // Main image
            if let imageUrl = listing.imageUrls.first {
                AsyncImage(url: URL(string: imageUrl)) { image in
                    image
                        .resizable()
                        .aspectRatio(1, contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .overlay(
                            ProgressView()
                                .tint(.white)
                        )
                }
                .frame(width: UIScreen.main.bounds.width / 3 - 4, height: UIScreen.main.bounds.width / 3 - 4)
                .clipped()
                .overlay(
                    LinearGradient(
                        colors: [Color.clear, Color.black.opacity(0.3)],
                        startPoint: .center,
                        endPoint: .bottom
                    )
                )
            }
            
            // Price badge
            VStack {
                Spacer()
                HStack {
                    Text("$\(Int(listing.price))")
                        .font(.caption.bold())
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color.black.opacity(0.6))
                        )
                    Spacer()
                }
                .padding(8)
            }
            
            // Menu button
            Button(action: { showMenu = true }) {
                Image(systemName: "ellipsis")
                    .font(.caption)
                    .foregroundColor(.white)
                    .padding(8)
                    .background(
                        Circle()
                            .fill(Color.black.opacity(0.6))
                    )
            }
            .padding(8)
        }
        .onTapGesture {
            onTap()
        }
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .onLongPressGesture(minimumDuration: 0.1, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.spring(response: 0.3)) {
                isPressed = pressing
            }
        }, perform: {})
        .confirmationDialog("Listing Options", isPresented: $showMenu) {
            Button("View Details") { onTap() }
            Button("Edit Listing") { onEdit() }
            Button("Share") { onShare() }
            Button("Cancel", role: .cancel) { }
        }
    }
}

struct ProfileReviewCard: View {
    let index: Int
    
    var body: some View {
        HStack(spacing: 16) {
            // Reviewer avatar
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color.blue, Color.purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 50, height: 50)
                .overlay(
                    Text("JD")
                        .font(.headline)
                        .foregroundColor(.white)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("John Doe")
                        .font(.subheadline.bold())
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    HStack(spacing: 2) {
                        ForEach(0..<5) { star in
                            Image(systemName: star < 4 ? "star.fill" : "star")
                                .font(.caption2)
                                .foregroundColor(.yellow)
                        }
                    }
                }
                
                Text("Great experience! The item was exactly as described and communication was excellent.")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
                    .lineLimit(2)
                
                Text("2 days ago")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.6))
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
    }
}

struct VerificationBadge: View {
    let icon: String
    let title: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.1))
        )
    }
}

struct ActivityChart: View {
    var body: some View {
        Chart {
            ForEach(0..<7, id: \.self) { day in
                BarMark(
                    x: .value("Day", ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"][day]),
                    y: .value("Activity", Double.random(in: 2...10))
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.purple, Color.pink],
                        startPoint: .bottom,
                        endPoint: .top
                    )
                )
                .cornerRadius(4)
            }
        }
        .chartXAxis {
            AxisMarks { value in
                AxisValueLabel()
                    .foregroundStyle(Color.white.opacity(0.7))
            }
        }
        .chartYAxis {
            AxisMarks { value in
                AxisValueLabel()
                    .foregroundStyle(Color.white.opacity(0.7))
            }
        }
    }
}

struct ActivityItem: View {
    let index: Int
    let activities = [
        ("Listed", "MacBook Pro 16\"", "2 hours ago", "cube.box.fill", Color.blue),
        ("Rented", "Canon EOS R5", "5 hours ago", "camera.fill", Color.green),
        ("Reviewed", "Power Drill", "1 day ago", "star.fill", Color.yellow),
        ("Messaged", "Gaming Chair inquiry", "2 days ago", "message.fill", Color.purple),
        ("Listed", "iPhone 13 Pro", "3 days ago", "cube.box.fill", Color.blue)
    ]
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: activities[index].3)
                .font(.body)
                .foregroundColor(activities[index].4)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(activities[index].0)
                        .font(.subheadline.bold())
                        .foregroundColor(.white)
                    Text(activities[index].1)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                }
                
                Text(activities[index].2)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
    }
}

// ShareSheet removed - using implementation from ProfessionalListingDetailView

// Preview
struct SocialMediaProfileView_Previews: PreviewProvider {
    static var previews: some View {
        SocialMediaProfileView()
            .environmentObject(AuthManager.shared)
    }
}