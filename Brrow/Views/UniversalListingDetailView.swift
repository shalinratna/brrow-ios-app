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
    
    private var isOwner: Bool {
        guard let currentUser = authManager.currentUser else { return false }
        // Check if current user owns this listing using multiple comparison methods
        let isOwnerByUserId = listing.userId == currentUser.id
        let isOwnerByApiId = listing.user?.apiId == currentUser.apiId

        // Debug logging to help identify ownership detection issues
        print("🔍 Ownership Check:")
        print("  Current User ID: \(currentUser.id)")
        print("  Current User ApiId: \(currentUser.apiId)")
        print("  Listing User ID: \(listing.userId)")
        print("  Listing User ApiId: \(listing.user?.apiId ?? "nil")")
        print("  IsOwner by UserId: \(isOwnerByUserId)")
        print("  IsOwner by ApiId: \(isOwnerByApiId)")

        return isOwnerByUserId || isOwnerByApiId
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