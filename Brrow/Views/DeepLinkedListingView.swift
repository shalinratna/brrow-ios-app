//
//  DeepLinkedListingView.swift
//  Brrow
//
//  Handles deep linked listings by loading the listing data
//

import SwiftUI

// Response wrapper for listing detail
private struct DeepLinkListingResponse: Codable {
    let listing: Listing
}

struct DeepLinkedListingView: View {
    let listingId: String
    @Environment(\.dismiss) private var dismiss
    @State private var listing: Listing?
    @State private var isLoading = true
    @State private var errorMessage: String?
    
    var body: some View {
        Group {
            if isLoading {
                ZStack {
                    Color(.systemBackground)
                        .ignoresSafeArea()
                    
                    VStack(spacing: 20) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                            .scaleEffect(1.2)
                        
                        Text("Loading listing...")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                }
            } else if let listing = listing {
                FullScreenListingDetailView(listing: listing)
            } else {
                // Error state
                ZStack {
                    Color(.systemBackground)
                        .ignoresSafeArea()
                    
                    VStack(spacing: 20) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 60))
                            .foregroundColor(Theme.Colors.accent)
                        
                        Text("Listing Not Found")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(Theme.Colors.text)
                        
                        Text(errorMessage ?? "The listing you're looking for could not be found.")
                            .font(.body)
                            .foregroundColor(Theme.Colors.secondaryText)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                        
                        Button(action: { dismiss() }) {
                            Text("Go Back")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(width: 120, height: 44)
                                .background(Theme.Colors.primary)
                                .cornerRadius(8)
                        }
                        .padding(.top, 20)
                    }
                }
            }
        }
        .onAppear {
            loadListing()
        }
    }
    
    private func loadListing() {
        Task {
            do {
                let url = URL(string: "\(APIClient.shared.baseURL)/get_listing.php?listing_id=\(listingId)")!
                
                var request = URLRequest(url: url)
                request.httpMethod = "GET"
                request.addValue("application/json", forHTTPHeaderField: "Content-Type")
                
                if let token = await AuthManager.shared.authToken {
                    request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                }
                
                let (data, _) = try await URLSession.shared.data(for: request)
                let response = try JSONDecoder().decode(APIResponse<DeepLinkListingResponse>.self, from: data)
                
                await MainActor.run {
                    if response.success, let listingData = response.data {
                        self.listing = listingData.listing
                    } else {
                        self.errorMessage = response.message ?? "Failed to load listing"
                    }
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to load listing: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }
}

