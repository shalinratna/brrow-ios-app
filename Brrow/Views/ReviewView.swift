import SwiftUI

struct ReviewView: View {
    let targetUser: ReviewUser
    let listingId: String?
    let transactionId: String?
    
    @StateObject private var reviewService = ReviewService.shared
    @State private var rating: Int = 5
    @State private var comment: String = ""
    @State private var reviewType: String = "GENERAL"
    @State private var isSubmitting = false
    @State private var showingSuccess = false
    @State private var errorMessage: String?
    
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // User Info Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Review User")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        HStack(spacing: 16) {
                            AsyncImage(url: URL(string: targetUser.profilePictureUrl ?? "")) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            } placeholder: {
                                Circle()
                                    .fill(Color.gray.opacity(0.3))
                            }
                            .frame(width: 60, height: 60)
                            .clipShape(Circle())
                            
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(targetUser.username)
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    
                                    if targetUser.isVerified {
                                        Image(systemName: "checkmark.seal.fill")
                                            .foregroundColor(.blue)
                                            .font(.caption)
                                    }
                                }
                                
                                if let avgRating = targetUser.averageRating,
                                   let totalRatings = targetUser.totalRatings {
                                    HStack(spacing: 4) {
                                        HStack(spacing: 2) {
                                            ForEach(1...5, id: \.self) { star in
                                                Image(systemName: "star.fill")
                                                    .foregroundColor(Double(star) <= avgRating ? .yellow : .gray.opacity(0.3))
                                                    .font(.caption)
                                            }
                                        }
                                        Text("\(String(format: "%.1f", avgRating)) (\(totalRatings))")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            
                            Spacer()
                        }
                    }
                    
                    Divider()
                    
                    // Rating Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Your Rating")
                            .font(.headline)
                        
                        HStack(spacing: 8) {
                            ForEach(1...5, id: \.self) { star in
                                Button(action: {
                                    rating = star
                                }) {
                                    Image(systemName: star <= rating ? "star.fill" : "star")
                                        .foregroundColor(star <= rating ? .yellow : .gray)
                                        .font(.title2)
                                }
                            }
                            
                            Spacer()
                            
                            Text("\(rating) star\(rating == 1 ? "" : "s")")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        // Rating description
                        Text(ratingDescription)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // Review Type Selection
                    if listingId != nil {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Review Type")
                                .font(.headline)
                            
                            Picker("Review Type", selection: $reviewType) {
                                Text("General").tag("GENERAL")
                                Text("As Buyer").tag("BUYER")
                                Text("As Seller").tag("SELLER")
                            }
                            .pickerStyle(SegmentedPickerStyle())
                        }
                    }
                    
                    // Comment Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Comment (Optional)")
                            .font(.headline)
                        
                        TextEditor(text: $comment)
                            .frame(minHeight: 100)
                            .padding(8)
                            .background(Color(UIColor.systemGray6))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                        
                        Text("\(comment.count)/500")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                    
                    // Error Message
                    if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(.horizontal)
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Leave Review")
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Submit") {
                    submitReview()
                }
                .disabled(isSubmitting || comment.count > 500)
            )
        }
        .alert("Review Submitted", isPresented: $showingSuccess) {
            Button("OK") {
                presentationMode.wrappedValue.dismiss()
            }
        } message: {
            Text("Thank you for your feedback!")
        }
    }
    
    private var ratingDescription: String {
        switch rating {
        case 1: return "Poor"
        case 2: return "Fair"
        case 3: return "Good"
        case 4: return "Very Good"
        case 5: return "Excellent"
        default: return ""
        }
    }
    
    private func submitReview() {
        guard !isSubmitting else { return }
        
        isSubmitting = true
        errorMessage = nil
        
        Task {
            do {
                let trimmedComment = comment.trimmingCharacters(in: .whitespacesAndNewlines)
                let finalComment = trimmedComment.isEmpty ? nil : trimmedComment
                
                _ = try await reviewService.createReview(
                    targetId: targetUser.id,
                    rating: rating,
                    comment: finalComment,
                    reviewType: reviewType,
                    listingId: listingId,
                    transactionId: transactionId
                )
                
                await MainActor.run {
                    isSubmitting = false
                    showingSuccess = true
                }
            } catch {
                await MainActor.run {
                    isSubmitting = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}

// MARK: - Reviews List View
struct ReviewsListView: View {
    let targetUserId: String
    let listingId: String?
    
    @StateObject private var reviewService = ReviewService.shared
    @State private var reviews: [Review] = []
    @State private var reviewStats: ReviewStats?
    @State private var isLoading = false
    @State private var selectedFilter = "all"
    
    let filterOptions = [
        ("all", "All Reviews"),
        ("as_buyer", "As Buyer"),
        ("as_seller", "As Seller")
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // Stats Header
            if let stats = reviewStats {
                VStack(spacing: 16) {
                    HStack {
                        VStack(alignment: .leading) {
                            HStack(spacing: 8) {
                                Text(String(format: "%.1f", stats.averageRating))
                                    .font(.title)
                                    .fontWeight(.bold)
                                
                                HStack(spacing: 2) {
                                    ForEach(1...5, id: \.self) { star in
                                        Image(systemName: "star.fill")
                                            .foregroundColor(Double(star) <= stats.averageRating ? .yellow : .gray.opacity(0.3))
                                            .font(.caption)
                                    }
                                }
                            }
                            
                            Text("\(stats.totalReviews) review\(stats.totalReviews == 1 ? "" : "s")")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        // Rating breakdown if available
                        if let breakdown = stats.ratingBreakdown {
                            VStack(alignment: .trailing, spacing: 2) {
                                ForEach((1...5).reversed(), id: \.self) { rating in
                                    let count = breakdown[String(rating)] ?? 0
                                    HStack(spacing: 4) {
                                        Text("\(rating)")
                                            .font(.caption2)
                                        
                                        RatingBar(
                                            count: count,
                                            total: stats.totalReviews,
                                            color: .yellow
                                        )
                                        
                                        Text("\(count)")
                                            .font(.caption2)
                                            .frame(width: 20, alignment: .trailing)
                                    }
                                }
                            }
                            .font(.caption2)
                        }
                    }
                    .padding()
                    .background(Color(UIColor.systemGray6))
                    .cornerRadius(12)
                }
                .padding(.horizontal)
            }
            
            // Filter Options
            if listingId == nil {
                Picker("Filter", selection: $selectedFilter) {
                    ForEach(filterOptions, id: \.0) { option in
                        Text(option.1).tag(option.0)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                .onChange(of: selectedFilter) { _ in
                    loadReviews()
                }
            }
            
            // Reviews List
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if reviews.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "star.circle")
                        .font(.system(size: 50))
                        .foregroundColor(.gray.opacity(0.5))
                    
                    Text("No reviews yet")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text("Be the first to leave a review!")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(reviews) { review in
                    ReviewRowView(review: review)
                        .listRowSeparator(.hidden)
                        .padding(.vertical, 4)
                }
                .listStyle(PlainListStyle())
            }
        }
        .onAppear {
            loadReviews()
        }
    }
    
    private func loadReviews() {
        isLoading = true
        
        Task {
            do {
                let result: (reviews: [Review], stats: ReviewStats)
                
                if let listingId = listingId {
                    result = try await reviewService.fetchListingReviews(listingId: listingId)
                } else {
                    result = try await reviewService.fetchUserReviews(
                        userId: targetUserId,
                        type: selectedFilter
                    )
                }
                
                await MainActor.run {
                    self.reviews = result.reviews
                    self.reviewStats = result.stats
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.reviews = []
                    self.reviewStats = nil
                    self.isLoading = false
                }
            }
        }
    }
}

// MARK: - Review Row View
struct ReviewRowView: View {
    let review: Review
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Author info and rating
            HStack(spacing: 12) {
                AsyncImage(url: URL(string: review.author?.profilePictureUrl ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                }
                .frame(width: 40, height: 40)
                .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(review.author?.username ?? "Anonymous")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        if review.author?.isVerified == true {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundColor(.blue)
                                .font(.caption2)
                        }
                        
                        Spacer()
                        
                        Text(review.createdAt, style: .relative)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack(spacing: 4) {
                        ForEach(1...5, id: \.self) { star in
                            Image(systemName: "star.fill")
                                .foregroundColor(star <= review.rating ? .yellow : .gray.opacity(0.3))
                                .font(.caption)
                        }
                        
                        if review.reviewType != .general {
                            Text("• \(review.reviewType.rawValue.capitalized)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            
            // Comment
            if let comment = review.comment, !comment.isEmpty {
                Text(comment)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .padding(.leading, 52) // Align with username
            }
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

// MARK: - Rating Bar Component
struct RatingBar: View {
    let count: Int
    let total: Int
    let color: Color
    
    var percentage: Double {
        total > 0 ? Double(count) / Double(total) : 0
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                
                Rectangle()
                    .fill(color)
                    .frame(width: geometry.size.width * percentage)
            }
        }
        .frame(height: 6)
        .cornerRadius(3)
    }
}

#Preview {
    ReviewView(
        targetUser: ReviewUser(
            id: "1",
            apiId: "1",
            username: "john_doe",
            profilePictureUrl: nil,
            isVerified: true,
            averageRating: 4.5,
            totalRatings: 23
        ),
        listingId: "listing1",
        transactionId: nil
    )
}