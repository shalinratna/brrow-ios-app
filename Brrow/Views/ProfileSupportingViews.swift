import SwiftUI

// MARK: - Transaction Row
struct TransactionRow: View {
    let transaction: Transaction
    let listing: Listing?
    let otherUser: User?
    
    init(transaction: Transaction, listing: Listing? = nil, otherUser: User? = nil) {
        self.transaction = transaction
        self.listing = listing
        self.otherUser = otherUser
    }
    
    var body: some View {
        HStack {
            Image(systemName: "arrow.triangle.2.circlepath")
                .font(.title3)
                .foregroundColor(.blue)
                .frame(width: 40, height: 40)
                .background(Color(.systemGray6))
                .clipShape(Circle())
            
            VStack(alignment: .leading) {
                Text(listing?.title ?? "Transaction #\(transaction.id)")
                    .font(.subheadline.bold())
                
                Text(otherUser?.username ?? "User")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing) {
                Text("$\(Int(transaction.totalCost))")
                    .font(.subheadline.bold())
                    .foregroundColor(Theme.Colors.primary)
                
                Text(formatDate(transaction.createdAt))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
}

// MARK: - Profile Review Card
struct ProfileSupportingReviewCard: View {
    let review: ProfileReview
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                if let imageUrl = review.reviewerImage {
                    AsyncImage(url: URL(string: imageUrl)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Image(systemName: "person.fill")
                            .foregroundColor(.gray)
                    }
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())
                } else {
                    Image(systemName: "person.circle.fill")
                        .font(.largeTitle)
                        .foregroundColor(.gray)
                        .frame(width: 40, height: 40)
                }
                
                VStack(alignment: .leading) {
                    Text(review.reviewerName)
                        .font(.subheadline.bold())
                    
                    HStack(spacing: 2) {
                        ForEach(0..<5) { index in
                            Image(systemName: index < review.rating ? "star.fill" : "star")
                                .font(.caption2)
                                .foregroundColor(.orange)
                        }
                    }
                }
                
                Spacer()
                
                Text(formatDate(review.date))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(review.comment)
                .font(.subheadline)
                .foregroundColor(.primary)
            
            Label(review.listingTitle, systemImage: "cube.box")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Review Summary Card
struct ReviewSummaryCard: View {
    let rating: Double
    let totalReviews: Int
    let distribution: [Int: Int]
    
    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 20) {
                // Overall rating
                VStack(spacing: 8) {
                    Text(String(format: "%.1f", rating))
                        .font(.system(size: 48, weight: .bold))
                    
                    HStack(spacing: 2) {
                        ForEach(0..<5) { index in
                            Image(systemName: index < Int(rating.rounded()) ? "star.fill" : "star")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                    }
                    
                    Text("\(totalReviews) reviews")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Divider()
                    .frame(height: 80)
                
                // Distribution bars
                VStack(alignment: .leading, spacing: 4) {
                    ForEach((1...5).reversed(), id: \.self) { stars in
                        HStack(spacing: 8) {
                            Text("\(stars)")
                                .font(.caption.bold())
                                .frame(width: 15)
                            
                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(Color(.systemGray5))
                                        .frame(height: 8)
                                    
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(Color.orange)
                                        .frame(
                                            width: geometry.size.width * CGFloat(distribution[stars] ?? 0) / CGFloat(totalReviews),
                                            height: 8
                                        )
                                }
                            }
                            .frame(height: 8)
                            
                            Text("\(distribution[stars] ?? 0)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .frame(width: 30, alignment: .trailing)
                        }
                    }
                }
            }
            .padding()
        }
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGray6))
        )
    }
}

// MARK: - Review Model
// ProfileReview is defined in ProfileViewModel.swift