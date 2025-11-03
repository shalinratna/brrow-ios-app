//
//  MyPostsViewModel.swift
//  Brrow
//
//  ViewModel for managing user's posts (listings, seeks, garage sales)
//

import Foundation
import SwiftUI

@MainActor
class MyPostsViewModel: ObservableObject {
    @Published var posts: [UserPost] = []
    @Published var isLoading = false
    @Published var isLoadingMore = false
    @Published var errorMessage: String?

    private let apiClient = APIClient.shared
    private var currentPage = 0
    private let pageLimit = 20
    private var hasMore = true

    // Load user's posts (using my-listings endpoint)
    func loadPosts() {
        guard !isLoading else { return }

        isLoading = true
        errorMessage = nil
        currentPage = 0

        Task {
            do {
                // Use fetchUserListings to get authenticated user's listings
                let response = try await apiClient.fetchUserListings(status: "all")

                await MainActor.run {
                    // Convert listings to UserPost format
                    self.posts = response.allListings.map { listing in
                        UserPost(
                            id: listing.id,
                            title: listing.title,
                            content: listing.description,
                            imageUrl: listing.firstImageUrl,
                            createdAt: listing.createdAt,
                            updatedAt: listing.createdAt,  // Use createdAt as fallback for updatedAt
                            postType: "listing",
                            status: listing.availabilityStatus.rawValue,
                            price: listing.price,
                            category: listing.category?.name,  // Extract name from CategoryModel
                            thumbnail: listing.firstImageUrl,
                            urgency: nil,
                            editRestrictions: nil,
                            canEdit: true
                        )
                    }
                    self.hasMore = false // My listings API doesn't paginate
                    self.isLoading = false
                    print("[MyPosts] Loaded \(self.posts.count) listings")
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to load posts: \(error.localizedDescription)"
                    self.isLoading = false
                    print("[MyPosts] Error loading posts: \(error)")
                }
            }
        }
    }

    // Load more posts (pagination) - disabled for my-listings endpoint
    func loadMorePosts() {
        // My listings endpoint doesn't support pagination yet
        // All listings are loaded at once
        print("[MyPosts] Pagination not supported for my-listings endpoint")
    }

    // Get count for specific filter
    func getCount(for filter: PostFilter) -> Int {
        switch filter {
        case .all:
            return posts.count
        case .listings:
            return posts.filter { $0.postType == "listing" }.count
        case .seeks:
            return posts.filter { $0.postType == "seek" }.count
        case .garageSales:
            return posts.filter { $0.postType == "garage_sale" }.count
        }
    }

    // Delete post with optimistic UI update
    func deletePost(_ post: UserPost) {
        // Store backup for rollback if delete fails
        let deletedPost = post
        let deletedIndex = posts.firstIndex(where: { $0.id == post.id })

        // Optimistic UI update - remove immediately for instant feedback
        posts.removeAll { $0.id == post.id }
        print("[MyPosts] Optimistically removed post: \(post.id)")

        // Perform actual delete in background
        Task {
            do {
                // Call appropriate delete API based on post type
                switch post.postType {
                case "listing":
                    try await apiClient.deleteListing(listingId: post.id)
                case "garage_sale":
                    try await apiClient.deleteGarageSale(saleId: post.id)
                case "seek":
                    try await apiClient.deleteSeek(seekId: post.id)
                default:
                    print("[MyPosts] Unknown post type: \(post.postType)")
                    throw BrrowAPIError.validationError("Unknown post type")
                }

                // Success - notify marketplace to refresh
                NotificationCenter.default.post(name: .listingDidDelete, object: nil, userInfo: ["listingId": post.id])
                print("[MyPosts] Successfully deleted post: \(post.id)")

            } catch {
                await MainActor.run {
                    // Rollback - restore the deleted post
                    if let index = deletedIndex {
                        self.posts.insert(deletedPost, at: min(index, self.posts.count))
                    } else {
                        self.posts.append(deletedPost)
                    }

                    // Check if error is due to active transactions/offers
                    let errorDesc = error.localizedDescription.lowercased()
                    if errorDesc.contains("active transaction") || errorDesc.contains("pending") || errorDesc.contains("offer") {
                        self.errorMessage = """
                        Unable to delete listing - Active offers or transactions in progress

                        This listing has pending sales or rentals with money being held. To delete this listing:

                        1. Cancel or complete all pending offers
                        2. Wait for active rentals to be returned
                        3. Resolve any transactions with held funds

                        Check your Offers tab to manage pending transactions.
                        """
                    } else {
                        self.errorMessage = "Failed to delete post: \(error.localizedDescription)"
                    }

                    print("[MyPosts] Error deleting post, rolled back: \(error)")
                }
            }
        }
    }

    // Refresh posts
    func refresh() {
        loadPosts()
    }
}
