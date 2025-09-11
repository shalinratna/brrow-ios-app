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
        // Check if current user owns this listing
        return listing.userId == currentUser.id
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