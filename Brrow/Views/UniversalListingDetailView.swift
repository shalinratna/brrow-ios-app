//
//  UniversalListingDetailView.swift
//  Brrow
//
//  Universal listing detail view that adapts based on ownership and context
//

import SwiftUI

struct UniversalListingDetailView: View {
    let listing: Listing
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.dismiss) private var dismiss
    @State private var showingEditView = false
    @State private var showingPromoteView = false
    @State private var showingDeleteConfirmation = false
    @State private var showingMessageComposer = false
    @State private var showingReportView = false
    @State private var showingRentalOptions = false
    @State private var showingCalculator = false
    @State private var isProcessing = false
    @State private var errorMessage: String?
    @State private var isActive = true
    @State private var isRefreshingUserData = false
    
    private var isOwner: Bool {
        guard let currentUser = authManager.currentUser else { return false }

        // Check if current user owns this listing using multiple comparison methods
        let isOwnerByUserId = listing.userId == currentUser.id
        let isOwnerByApiId = listing.user?.apiId == currentUser.apiId

        // Additional checks for API ID variations
        let isOwnerByCurrentApiId = listing.userId == currentUser.apiId
        let isOwnerByListingApiId = currentUser.id == listing.user?.apiId

        // Debug logging to help identify ownership detection issues
        print("🔍 Ownership Check:")
        print("  Current User ID: \(currentUser.id)")
        print("  Current User ApiId: \(currentUser.apiId ?? "nil")")
        print("  Current User Username: \(currentUser.username)")
        print("  Listing User ID: \(listing.userId)")
        print("  Listing User ApiId: \(listing.user?.apiId ?? "nil")")
        print("  Listing User Username: \(listing.user?.username ?? "nil")")
        print("  IsOwner by UserId: \(isOwnerByUserId)")
        print("  IsOwner by ApiId: \(isOwnerByApiId)")
        print("  IsOwner by CurrentApiId: \(isOwnerByCurrentApiId)")
        print("  IsOwner by ListingApiId: \(isOwnerByListingApiId)")

        let isOwner = isOwnerByUserId || isOwnerByApiId || isOwnerByCurrentApiId || isOwnerByListingApiId
        print("  🎯 Final IsOwner Result: \(isOwner)")

        return isOwner
    }
    
    var body: some View {
        NavigationView {
            Group {
                if isOwner {
                    // Owner view - show existing ProfessionalListingDetailView
                    ProfessionalListingDetailView(listing: listing)
                        .environmentObject(authManager)
                } else {
                    // Visitor view - show existing FullScreenListingDetailView
                    FullScreenListingDetailView(listing: listing)
                        .environmentObject(authManager)
                }
            }
            .onAppear {
                print("🔶 UniversalListingDetailView appeared with listing: \(listing.title) (ID: \(listing.listingId))")
                print("🔶 IsOwner: \(isOwner)")
                print("🔶 Will show: \(isOwner ? "ProfessionalListingDetailView" : "FullScreenListingDetailView")")

                // Force refresh user profile to ensure we have latest data after any username changes
                Task {
                    isRefreshingUserData = true
                    await authManager.refreshUserProfile()
                    // Small delay to ensure state updates are processed
                    try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
                    isRefreshingUserData = false
                    print("🔄 User data refreshed - rechecking ownership")
                    print("🔄 Updated IsOwner: \(isOwner)")
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Theme.Colors.text)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: shareListing) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Theme.Colors.primary)
                    }
                }
            }
        }
    }
    
    // MARK: - Actions
    
    private func shareListing() {
        let shareText = "Check out \(listing.title) on Brrow for $\(Int(listing.price))/day!"
        let shareURL = URL(string: "https://brrowapp.com/listing/\(listing.listingId)")!
        
        let activityVC = UIActivityViewController(
            activityItems: [shareText, shareURL],
            applicationActivities: nil
        )
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            rootViewController.present(activityVC, animated: true)
        }
    }
}