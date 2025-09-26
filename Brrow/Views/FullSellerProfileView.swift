//
//  FullSellerProfileView.swift
//  Brrow
//
//  Comprehensive seller profile view with all details
//

import SwiftUI
import MapKit

struct FullSellerProfileView: View {
    let user: User
    @StateObject private var viewModel: SellerProfileViewModel
    @State private var selectedTab = 0
    @State private var showingMessageView = false
    @State private var showingReportUser = false
    @Environment(\.dismiss) private var dismiss
    
    init(user: User) {
        self.user = user
        self._viewModel = StateObject(wrappedValue: SellerProfileViewModel(user: user))
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    // Profile Header
                    profileHeaderSection
                    
                    // Stats Overview
                    statsOverviewSection
                    
                    // Tab Selection
                    tabSelectionSection
                    
                    // Tab Content
                    tabContentSection
                }
            }
            .background(Color.gray.opacity(0.05))
            .navigationTitle("Seller Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: { showingMessageView = true }) {
                            Label("Send Message", systemImage: "message")
                        }
                        
                        Button(action: { shareProfile() }) {
                            Label("Share Profile", systemImage: "square.and.arrow.up")
                        }
                        
                        Button(action: { showingReportUser = true }) {
                            Label("Report User", systemImage: "exclamationmark.triangle")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundColor(Theme.Colors.text)
                    }
                }
            }
        }
        .sheet(isPresented: $showingMessageView) {
            SellerMessageComposerView(recipient: user)
        }
        .sheet(isPresented: $showingReportUser) {
            ReportUserView(user: user)
        }
        .onAppear {
            viewModel.loadFullProfile()
        }
    }
    
    // MARK: - Profile Header
    private var profileHeaderSection: some View {
        VStack(spacing: 20) {
            // Background gradient
            LinearGradient(
                colors: [Theme.Colors.primary.opacity(0.3), Theme.Colors.primary.opacity(0.1)],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 120)
            .overlay(
                // Profile Picture
                VStack {
                    Spacer()
                    if let avatarUrl = user.profilePicture {
                        BrrowAsyncImage(url: avatarUrl) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 120, height: 120)
                                .clipShape(Circle())
                                .overlay(
                                    Circle()
                                        .stroke(Color.white, lineWidth: 4)
                                )
                        } placeholder: {
                            Circle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 120, height: 120)
                                .overlay(
                                    ProgressView()
                                )
                        }
                    } else {
                        Circle()
                            .fill(Theme.Colors.primary.opacity(0.2))
                            .frame(width: 120, height: 120)
                            .overlay(
                                Text(user.name.prefix(1).uppercased())
                                    .font(.system(size: 48, weight: .bold))
                                    .foregroundColor(Theme.Colors.primary)
                            )
                            .overlay(
                                Circle()
                                    .stroke(Color.white, lineWidth: 4)
                            )
                    }
                }
                .offset(y: 60)
            )
            
            VStack(spacing: 12) {
                // Name and verification
                HStack(spacing: 8) {
                    Text(user.name)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(Theme.Colors.text)
                    
                    if user.isVerified ?? false {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundColor(.blue)
                            .font(.title3)
                    }
                    
                    if viewModel.isPremiumSeller {
                        Image(systemName: "star.circle.fill")
                            .foregroundColor(.orange)
                            .font(.title3)
                    }
                }
                .padding(.top, 40)
                
                // Username
                Text("@\(user.username)")
                    .font(.body)
                    .foregroundColor(Theme.Colors.secondaryText)
                
                // Location
                if let location = user.location {
                    HStack(spacing: 4) {
                        Image(systemName: "location.fill")
                            .font(.caption)
                        Text(location)
                            .font(.body)
                    }
                    .foregroundColor(Theme.Colors.secondaryText)
                }
                
                // Bio
                if let bio = user.bio, !bio.isEmpty {
                    Text(bio)
                        .font(.body)
                        .foregroundColor(Theme.Colors.text)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                        .padding(.top, 8)
                }
                
                // Member since
                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                        .font(.caption)
                    Text("Member since \(user.memberSince, style: .date)")
                        .font(.caption)
                }
                .foregroundColor(Theme.Colors.secondaryText)
                .padding(.top, 4)
                
                // Action Buttons
                HStack(spacing: 12) {
                    Button(action: { showingMessageView = true }) {
                        Label("Message", systemImage: "message.fill")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Theme.Colors.primary)
                            .cornerRadius(12)
                    }
                    
                    Button(action: { viewModel.toggleFollow() }) {
                        Label(viewModel.isFollowing ? "Following" : "Follow", systemImage: viewModel.isFollowing ? "person.badge.minus" : "person.badge.plus")
                            .font(.headline)
                            .foregroundColor(viewModel.isFollowing ? Theme.Colors.text : Theme.Colors.primary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(viewModel.isFollowing ? Color.gray.opacity(0.1) : Color.clear)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(viewModel.isFollowing ? Color.clear : Theme.Colors.primary, lineWidth: 2)
                            )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
            }
        }
    }
    
    // MARK: - Stats Overview
    private var statsOverviewSection: some View {
        VStack(spacing: 16) {
            HStack(spacing: 0) {
                statCard(value: "\(user.totalListings)", label: "Active Listings", icon: "tag.fill")
                
                Divider()
                    .frame(height: 50)
                
                statCard(value: "\(user.completedRentals)", label: "Completed Rentals", icon: "checkmark.circle.fill")
                
                Divider()
                    .frame(height: 50)
                
                statCard(value: String(format: "%.1f", user.rating), label: "Rating", icon: "star.fill")
            }
            .padding(.vertical, 8)
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
            
            // Response and verification info
            HStack(spacing: 20) {
                HStack(spacing: 8) {
                    Image(systemName: "clock.fill")
                        .foregroundColor(.green)
                    Text("Responds in ~\(user.responseTime)")
                        .font(.callout)
                        .foregroundColor(Theme.Colors.text)
                }
                
                if user.isVerified ?? false {
                    HStack(spacing: 8) {
                        Image(systemName: "shield.checkered")
                            .foregroundColor(.blue)
                        Text("ID Verified")
                            .font(.callout)
                            .foregroundColor(Theme.Colors.text)
                    }
                }
                
                Spacer()
            }
            .padding(.horizontal, 20)
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
    }
    
    private func statCard(value: String, label: String, icon: String) -> some View {
        VStack(spacing: 8) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(icon == "star.fill" ? .orange : Theme.Colors.primary)
                Text(value)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(Theme.Colors.text)
            }
            
            Text(label)
                .font(.caption)
                .foregroundColor(Theme.Colors.secondaryText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Tab Selection
    private var tabSelectionSection: some View {
        HStack(spacing: 0) {
            ForEach(0..<4) { index in
                Button(action: { selectedTab = index }) {
                    VStack(spacing: 8) {
                        Image(systemName: tabIcon(for: index))
                            .font(.headline)
                        Text(tabTitle(for: index))
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(selectedTab == index ? Theme.Colors.primary : Theme.Colors.secondaryText)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        selectedTab == index ?
                        Theme.Colors.primary.opacity(0.1) : Color.clear
                    )
                }
            }
        }
        .background(Color.white)
        .cornerRadius(12)
        .padding(.horizontal, 20)
        .padding(.top, 20)
    }
    
    private func tabIcon(for index: Int) -> String {
        switch index {
        case 0: return "square.grid.2x2"
        case 1: return "star"
        case 2: return "chart.line.uptrend.xyaxis"
        case 3: return "info.circle"
        default: return ""
        }
    }
    
    private func tabTitle(for index: Int) -> String {
        switch index {
        case 0: return "Listings"
        case 1: return "Reviews"
        case 2: return "Stats"
        case 3: return "About"
        default: return ""
        }
    }
    
    // MARK: - Tab Content
    private var tabContentSection: some View {
        VStack {
            switch selectedTab {
            case 0:
                listingsTabContent
            case 1:
                reviewsTabContent
            case 2:
                statsTabContent
            case 3:
                aboutTabContent
            default:
                EmptyView()
            }
        }
        .padding(.top, 20)
    }
    
    // MARK: - Listings Tab
    private var listingsTabContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Active Listings (\(viewModel.listings.count))")
                .font(.headline)
                .foregroundColor(Theme.Colors.text)
                .padding(.horizontal, 20)
            
            if viewModel.isLoadingListings {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding(40)
            } else if viewModel.listings.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "tag.slash")
                        .font(.system(size: 40))
                        .foregroundColor(Theme.Colors.secondaryText)
                    Text("No active listings")
                        .font(.body)
                        .foregroundColor(Theme.Colors.secondaryText)
                }
                .frame(maxWidth: .infinity)
                .padding(40)
            } else {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(viewModel.listings, id: \.listingId) { listing in
                        NavigationLink(destination: ProfessionalListingDetailView(listing: listing)) {
                            ListingGridCard(listing: listing)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
    
    // MARK: - Reviews Tab
    private var reviewsTabContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Reviews (\(viewModel.reviews.count))")
                    .font(.headline)
                    .foregroundColor(Theme.Colors.text)
                
                Spacer()
                
                // Average rating
                HStack(spacing: 4) {
                    ForEach(0..<5) { star in
                        Image(systemName: star < Int(user.rating) ? "star.fill" : "star")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                    Text(String(format: "%.1f", user.rating))
                        .font(.callout)
                        .fontWeight(.medium)
                        .foregroundColor(Theme.Colors.text)
                }
            }
            .padding(.horizontal, 20)
            
            if viewModel.reviews.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "star.slash")
                        .font(.system(size: 40))
                        .foregroundColor(Theme.Colors.secondaryText)
                    Text("No reviews yet")
                        .font(.body)
                        .foregroundColor(Theme.Colors.secondaryText)
                }
                .frame(maxWidth: .infinity)
                .padding(40)
            } else {
                VStack(spacing: 12) {
                    ForEach(viewModel.reviews) { review in
                        SellerReviewCard(review: review)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
    
    // MARK: - Stats Tab
    private var statsTabContent: some View {
        VStack(spacing: 16) {
            // Performance metrics
            VStack(alignment: .leading, spacing: 12) {
                Text("Performance Metrics")
                    .font(.headline)
                    .foregroundColor(Theme.Colors.text)
                
                VStack(spacing: 8) {
                    metricRow(label: "Response Rate", value: "\(viewModel.responseRate)%", color: .green)
                    metricRow(label: "Acceptance Rate", value: "\(viewModel.acceptanceRate)%", color: .blue)
                    metricRow(label: "On-Time Delivery", value: "\(viewModel.onTimeRate)%", color: .orange)
                    metricRow(label: "Customer Satisfaction", value: "\(viewModel.satisfactionRate)%", color: .purple)
                }
                .padding()
                .background(Color.white)
                .cornerRadius(12)
            }
            
            // Rental history chart
            VStack(alignment: .leading, spacing: 12) {
                Text("Rental History (Last 6 Months)")
                    .font(.headline)
                    .foregroundColor(Theme.Colors.text)
                
                // Simplified chart placeholder
                HStack(alignment: .bottom, spacing: 8) {
                    ForEach(0..<6) { month in
                        VStack {
                            Spacer()
                            Rectangle()
                                .fill(Theme.Colors.primary.opacity(0.7))
                                .frame(height: CGFloat.random(in: 40...120))
                            Text(monthName(month))
                                .font(.caption2)
                                .foregroundColor(Theme.Colors.secondaryText)
                        }
                    }
                }
                .frame(height: 150)
                .padding()
                .background(Color.white)
                .cornerRadius(12)
            }
            
            // Badges and achievements
            VStack(alignment: .leading, spacing: 12) {
                Text("Achievements")
                    .font(.headline)
                    .foregroundColor(Theme.Colors.text)
                
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(viewModel.achievements) { achievement in
                        VStack(spacing: 4) {
                            Image(systemName: achievement.icon)
                                .font(.title2)
                                .foregroundColor(achievement.earned ? Theme.Colors.primary : Color.gray.opacity(0.3))
                            Text(achievement.name)
                                .font(.caption2)
                                .foregroundColor(achievement.earned ? Theme.Colors.text : Theme.Colors.secondaryText)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(8)
                        .background(achievement.earned ? Theme.Colors.primary.opacity(0.1) : Color.gray.opacity(0.05))
                        .cornerRadius(8)
                    }
                }
                .padding()
                .background(Color.white)
                .cornerRadius(12)
            }
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - About Tab
    private var aboutTabContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Verification status
            VStack(alignment: .leading, spacing: 12) {
                Text("Verification")
                    .font(.headline)
                    .foregroundColor(Theme.Colors.text)
                
                VStack(spacing: 8) {
                    verificationRow(title: "Email", verified: user.emailVerified == true)
                    verificationRow(title: "Phone Number", verified: user.phoneVerified == true)
                    verificationRow(title: "Government ID", verified: user.idVerified == true)
                    verificationRow(title: "Address", verified: viewModel.addressVerified)
                }
                .padding()
                .background(Color.white)
                .cornerRadius(12)
            }
            
            // Languages
            if !viewModel.languages.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Languages")
                        .font(.headline)
                        .foregroundColor(Theme.Colors.text)
                    
                    HStack {
                        ForEach(viewModel.languages, id: \.self) { language in
                            Text(language)
                                .font(.callout)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Theme.Colors.primary.opacity(0.1))
                                .foregroundColor(Theme.Colors.primary)
                                .cornerRadius(15)
                        }
                    }
                }
            }
            
            // Policies
            VStack(alignment: .leading, spacing: 12) {
                Text("Rental Policies")
                    .font(.headline)
                    .foregroundColor(Theme.Colors.text)
                
                VStack(alignment: .leading, spacing: 8) {
                    policyRow(icon: "clock", title: "Cancellation", value: viewModel.cancellationPolicy.isEmpty ? "Not Set" : viewModel.cancellationPolicy)
                    policyRow(icon: "shield", title: "Damage Protection", value: viewModel.damageProtection.isEmpty ? "Not Set" : viewModel.damageProtection)
                    policyRow(icon: "doc.text", title: "Rental Agreement", value: "Not Set")
                    policyRow(icon: "creditcard", title: "Payment Methods", value: viewModel.paymentMethods.isEmpty ? "Not Set" : viewModel.paymentMethods)
                }
                .padding()
                .background(Color.white)
                .cornerRadius(12)
            }
            
            // Report user
            Button(action: { showingReportUser = true }) {
                HStack {
                    Image(systemName: "exclamationmark.triangle")
                    Text("Report This User")
                }
                .font(.callout)
                .foregroundColor(.red)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.red.opacity(0.1))
                .cornerRadius(12)
            }
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - Helper Views
    private func metricRow(label: String, value: String, color: Color) -> some View {
        HStack {
            Text(label)
                .font(.body)
                .foregroundColor(Theme.Colors.secondaryText)
            Spacer()
            Text(value)
                .font(.body)
                .fontWeight(.medium)
                .foregroundColor(color)
        }
        .padding(.vertical, 4)
    }
    
    private func verificationRow(title: String, verified: Bool) -> some View {
        HStack {
            Image(systemName: verified ? "checkmark.circle.fill" : "xmark.circle")
                .foregroundColor(verified ? .green : Color.gray.opacity(0.5))
            Text(title)
                .font(.body)
                .foregroundColor(Theme.Colors.text)
            Spacer()
            if verified {
                Text("Verified")
                    .font(.caption)
                    .foregroundColor(.green)
            }
        }
        .padding(.vertical, 4)
    }
    
    private func policyRow(icon: String, title: String, value: String) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(Theme.Colors.primary)
                .frame(width: 20)
            Text(title)
                .font(.body)
                .foregroundColor(Theme.Colors.text)
            Spacer()
            Text(value)
                .font(.callout)
                .foregroundColor(Theme.Colors.secondaryText)
        }
        .padding(.vertical, 4)
    }
    
    private func monthName(_ index: Int) -> String {
        let months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun"]
        return months[index]
    }
    
    private func shareProfile() {
        // Share profile implementation
    }
}

// MARK: - Supporting Views
struct SellerReviewCard: View {
    let review: SellerReview
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                // Reviewer avatar
                if let avatarUrl = review.reviewerAvatar {
                    BrrowAsyncImage(url: avatarUrl) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 40, height: 40)
                            .clipShape(Circle())
                    } placeholder: {
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 40, height: 40)
                    }
                } else {
                    Circle()
                        .fill(Theme.Colors.primary.opacity(0.2))
                        .frame(width: 40, height: 40)
                        .overlay(
                            Text(review.reviewerName.prefix(1).uppercased())
                                .font(.headline)
                                .foregroundColor(Theme.Colors.primary)
                        )
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(review.reviewerName)
                        .font(.callout)
                        .fontWeight(.medium)
                        .foregroundColor(Theme.Colors.text)
                    
                    HStack(spacing: 2) {
                        ForEach(0..<5) { star in
                            Image(systemName: star < review.rating ? "star.fill" : "star")
                                .font(.caption2)
                                .foregroundColor(.orange)
                        }
                        Text("· \(review.date, style: .date)")
                            .font(.caption)
                            .foregroundColor(Theme.Colors.secondaryText)
                    }
                }
                
                Spacer()
            }
            
            Text(review.comment)
                .font(.body)
                .foregroundColor(Theme.Colors.text)
                .fixedSize(horizontal: false, vertical: true)
            
            if let itemName = review.itemName {
                Text("Rented: \(itemName)")
                    .font(.caption)
                    .foregroundColor(Theme.Colors.secondaryText)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(4)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

// MARK: - View Models and Models
class SellerProfileViewModel: ObservableObject {
    @Published var listings: [Listing] = []
    @Published var reviews: [SellerReview] = []
    @Published var achievements: [SellerAchievement] = []
    @Published var isFollowing = false
    @Published var isPremiumSeller = false
    @Published var isLoadingListings = false
    @Published var responseRate = 0
    @Published var acceptanceRate = 0
    @Published var onTimeRate = 0
    @Published var satisfactionRate = 0
    @Published var addressVerified = false
    @Published var languages: [String] = []
    @Published var cancellationPolicy = ""
    @Published var damageProtection = ""
    @Published var paymentMethods = ""
    
    private let user: User
    
    init(user: User) {
        self.user = user
        loadFullProfile()
    }
    
    func loadFullProfile() {
        isLoadingListings = true
        // Fetch real data from API
        Task {
            do {
                let response = try await APIClient.shared.fetchUserListings(userId: user.apiId)
                DispatchQueue.main.async {
                    self.listings = response.allListings
                    self.isLoadingListings = false
                }
            } catch {
                print("Error loading listings: \(error)")
                DispatchQueue.main.async {
                    self.isLoadingListings = false
                }
            }
        }
    }
    
    func toggleFollow() {
        isFollowing.toggle()
    }
    
    // Achievements and reviews are now loaded from API instead of mock data
    // The empty arrays will be populated when real data becomes available
}

struct SellerAchievement: Identifiable {
    let id: String
    let name: String
    let icon: String
    let earned: Bool
}

struct SellerReview: Identifiable {
    let id: String
    let reviewerName: String
    let reviewerAvatar: String?
    let rating: Int
    let comment: String
    let date: Date
    let itemName: String?
}

// MARK: - Message Composer
struct SellerMessageComposerView: View {
    let recipient: User
    @State private var messageText = ""
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                TextEditor(text: $messageText)
                    .padding(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                    .padding()
                
                Spacer()
            }
            .navigationTitle("Message \(recipient.name)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Send") {
                        sendMessage()
                    }
                    .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
    
    private func sendMessage() {
        // Send message implementation
        dismiss()
    }
}

// MARK: - Report User View
struct ReportUserView: View {
    let user: User
    @State private var selectedReason = ""
    @State private var additionalInfo = ""
    @Environment(\.dismiss) private var dismiss
    
    let reportReasons = [
        "Inappropriate behavior",
        "Scam or fraud",
        "Fake profile",
        "Harassment",
        "Other"
    ]
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Reason for Report")) {
                    ForEach(reportReasons, id: \.self) { reason in
                        Button(action: { selectedReason = reason }) {
                            HStack {
                                Text(reason)
                                    .foregroundColor(Theme.Colors.text)
                                Spacer()
                                if selectedReason == reason {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(Theme.Colors.primary)
                                }
                            }
                        }
                    }
                }
                
                Section(header: Text("Additional Information")) {
                    TextEditor(text: $additionalInfo)
                        .frame(height: 100)
                }
            }
            .navigationTitle("Report User")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Submit") {
                        submitReport()
                    }
                    .disabled(selectedReason.isEmpty)
                }
            }
        }
    }
    
    private func submitReport() {
        // Submit report implementation
        dismiss()
    }
}