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
                // Use fetchMyListings instead of non-existent fetchUserPosts
                let response = try await apiClient.fetchMyListings(status: "all")

                await MainActor.run {
                    // Convert listings to UserPost format
                    self.posts = response.allListings.map { listing in
                        UserPost(
                            id: listing.id,
                            title: listing.title,
                            description: listing.description,
                            price: listing.price,
                            postType: "listing",
                            status: listing.availabilityStatus.rawValue,
                            imageUrl: listing.firstImageUrl,
                            createdAt: listing.createdAt,
                            viewCount: listing.viewCount,
                            favoriteCount: listing.favoriteCount
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

    // Delete post
    func deletePost(_ post: UserPost) {
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

                await MainActor.run {
                    // Remove from local array
                    self.posts.removeAll { $0.id == post.id }
                    print("[MyPosts] Deleted post: \(post.id)")
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to delete post: \(error.localizedDescription)"
                    print("[MyPosts] Error deleting post: \(error)")
                }
            }
        }
    }

    // Refresh posts
    func refresh() {
        loadPosts()
    }
}
