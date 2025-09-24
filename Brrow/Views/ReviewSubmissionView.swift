//
//  ReviewSubmissionView.swift
//  Brrow
//
//  Complete review submission interface with ratings and feedback
//

import SwiftUI
import PhotosUI

struct ReviewSubmissionView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = ReviewSubmissionViewModel()

    let reviewee: UserInfo
    let listing: ListingInfo?
    let transaction: TransactionInfo?
    let reviewType: ReviewType

    @State private var rating: Int = 5
    @State private var title = ""
    @State private var content = ""
    @State private var isAnonymous = false
    @State private var selectedCriteria: [String: Int] = [:]
    @State private var selectedImages: [PhotosPickerItem] = []
    @State private var attachmentImages: [UIImage] = []
    @State private var isSubmitting = false
    @State private var showingSuccessAlert = false
    @State private var errorMessage: String?

    private var criteria: [ReviewCriteria] {
        switch reviewType {
        case .seller:
            return ReviewCriteria.sellerCriteria
        case .buyer:
            return ReviewCriteria.buyerCriteria
        default:
            return []
        }
    }

    private var isFormValid: Bool {
        rating > 0 && content.count >= 10
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header Info
                    headerSection

                    // Rating Section
                    ratingSection

                    // Criteria Rating (if applicable)
                    if !criteria.isEmpty {
                        criteriaSection
                    }

                    // Review Title
                    titleSection

                    // Review Content
                    contentSection

                    // Photo Attachments
                    photoSection

                    // Options
                    optionsSection

                    // Submit Button
                    submitButton
                }
                .padding()
            }
            .navigationTitle("Write Review")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
            .alert("Review Submitted", isPresented: $showingSuccessAlert) {
                Button("OK") { dismiss() }
            } message: {
                Text("Your review has been submitted successfully and will be visible after moderation.")
            }
            .alert("Error", isPresented: .constant(errorMessage != nil)) {
                Button("OK") { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }

    private var headerSection: some View {
        VStack(spacing: 12) {
            // Profile image placeholder
            Circle()
                .fill(Color.blue.opacity(0.1))
                .frame(width: 60, height: 60)
                .overlay(
                    Text(reviewee.displayName.prefix(1).uppercased())
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                )

            VStack(spacing: 4) {
                Text("Review \(reviewee.displayName)")
                    .font(.headline)

                if let listing = listing {
                    Text(listing.title)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    private var ratingSection: some View {
        VStack(spacing: 12) {
            Text("Overall Rating")
                .font(.headline)

            HStack(spacing: 8) {
                ForEach(1...5, id: \.self) { star in
                    Button {
                        rating = star
                    } label: {
                        Image(systemName: star <= rating ? "star.fill" : "star")
                            .font(.title2)
                            .foregroundColor(star <= rating ? .yellow : .gray)
                    }
                }
            }

            Text(ratingDescription)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }

    private var criteriaSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Rate Specific Areas")
                .font(.headline)

            ForEach(criteria) { criterion in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(criterion.name)
                            .font(.subheadline)
                            .fontWeight(.medium)

                        Spacer()

                        if !criterion.isRequired {
                            Text("Optional")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    HStack(spacing: 4) {
                        ForEach(1...criterion.maxRating, id: \.self) { star in
                            Button {
                                selectedCriteria[criterion.id] = star
                            } label: {
                                Image(systemName: star <= (selectedCriteria[criterion.id] ?? 0) ? "star.fill" : "star")
                                    .font(.subheadline)
                                    .foregroundColor(star <= (selectedCriteria[criterion.id] ?? 0) ? .yellow : .gray)
                            }
                        }

                        Spacer()
                    }

                    Text(criterion.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 8)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }

    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Review Title (Optional)")
                .font(.headline)

            TextField("Summarize your experience...", text: $title)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .textInputAutocapitalization(.sentences)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }

    private var contentSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Your Review")
                    .font(.headline)

                Spacer()

                Text("\(content.count)/500")
                    .font(.caption)
                    .foregroundColor(content.count > 500 ? .red : .secondary)
            }

            TextEditor(text: $content)
                .frame(minHeight: 100)
                .padding(8)
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .textInputAutocapitalization(.sentences)
                .onChange(of: content) { oldValue, newValue in
                    if newValue.count > 500 {
                        content = String(newValue.prefix(500))
                    }
                }

            Text("Minimum 10 characters required")
                .font(.caption)
                .foregroundColor(content.count >= 10 ? .green : .secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }

    private var photoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Add Photos (Optional)")
                .font(.headline)

            PhotosPicker(
                selection: $selectedImages,
                maxSelectionCount: 5,
                matching: .images
            ) {
                HStack {
                    Image(systemName: "photo.badge.plus")
                    Text("Add Photos")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue.opacity(0.1))
                .foregroundColor(.blue)
                .cornerRadius(8)
            }
            .onChange(of: selectedImages) { oldValue, newValue in
                loadImages()
            }

            if !attachmentImages.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(attachmentImages.indices, id: \.self) { index in
                            ZStack(alignment: .topTrailing) {
                                Image(uiImage: attachmentImages[index])
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 80, height: 80)
                                    .clipped()
                                    .cornerRadius(8)

                                Button {
                                    attachmentImages.remove(at: index)
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.red)
                                        .background(Color.white, in: Circle())
                                }
                                .offset(x: 5, y: -5)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }

    private var optionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Toggle("Submit anonymously", isOn: $isAnonymous)

            Text("When anonymous, your name will be hidden from other users but visible to moderators.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }

    private var submitButton: some View {
        Button {
            submitReview()
        } label: {
            HStack {
                if isSubmitting {
                    ProgressView()
                        .scaleEffect(0.8)
                }
                Text(isSubmitting ? "Submitting..." : "Submit Review")
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(isFormValid && !isSubmitting ? Color.blue : Color.gray)
            .foregroundColor(.white)
            .cornerRadius(12)
        }
        .disabled(!isFormValid || isSubmitting)
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

    private func loadImages() {
        Task {
            var images: [UIImage] = []

            for item in selectedImages {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    images.append(image)
                }
            }

            await MainActor.run {
                attachmentImages = images
            }
        }
    }

    private func submitReview() {
        guard isFormValid else { return }

        isSubmitting = true

        Task {
            do {
                let attachmentUploads: [ReviewAttachmentUpload] = attachmentImages.compactMap { image in
                    guard let imageData = image.jpegData(compressionQuality: 0.8) else { return nil }
                    return ReviewAttachmentUpload(
                        fileData: imageData.base64EncodedString(),
                        fileName: "review_image_\(UUID().uuidString).jpg",
                        fileType: .image
                    )
                }

                let request = CreateReviewRequest(
                    revieweeId: reviewee.id,
                    listingId: listing?.id,
                    transactionId: transaction?.id,
                    rating: rating,
                    title: title.isEmpty ? nil : title,
                    content: content,
                    reviewType: reviewType,
                    isAnonymous: isAnonymous,
                    criteriaRatings: selectedCriteria.isEmpty ? nil : selectedCriteria,
                    attachments: attachmentUploads.isEmpty ? nil : attachmentUploads
                )

                try await viewModel.submitReview(request)

                await MainActor.run {
                    isSubmitting = false
                    showingSuccessAlert = true
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

// MARK: - Preview

struct ReviewSubmissionView_Previews: PreviewProvider {
    static var previews: some View {
        ReviewSubmissionView(
            reviewee: UserInfo(
                id: "1",
                username: "johndoe",
                profilePictureUrl: nil,
                averageRating: nil,
                bio: nil,
                totalRatings: nil,
                isVerified: nil,
                createdAt: nil
            ),
            listing: ListingInfo(
                id: "1",
                title: "Professional Camera",
                imageUrl: nil,
                price: 25.0
            ),
            transaction: nil,
            reviewType: .seller
        )
    }
}