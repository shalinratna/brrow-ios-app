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

    // Load user's posts
    func loadPosts() {
        guard !isLoading else { return }

        isLoading = true
        errorMessage = nil
        currentPage = 0

        Task {
            do {
                let response = try await apiClient.fetchUserPosts(limit: pageLimit, offset: 0)

                await MainActor.run {
                    self.posts = response.posts
                    self.hasMore = response.hasMore
                    self.isLoading = false
                    print("[MyPosts] Loaded \(response.posts.count) posts")
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

    // Load more posts (pagination)
    func loadMorePosts() {
        guard !isLoadingMore, hasMore else { return }

        isLoadingMore = true
        let nextOffset = (currentPage + 1) * pageLimit

        Task {
            do {
                let response = try await apiClient.fetchUserPosts(limit: pageLimit, offset: nextOffset)

                await MainActor.run {
                    self.posts.append(contentsOf: response.posts)
                    self.hasMore = response.hasMore
                    self.currentPage += 1
                    self.isLoadingMore = false
                    print("[MyPosts] Loaded \(response.posts.count) more posts (page \(self.currentPage))")
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to load more posts: \(error.localizedDescription)"
                    self.isLoadingMore = false
                    print("[MyPosts] Error loading more posts: \(error)")
                }
            }
        }
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
