//
//  SimplifiedListingDetailViewFixed.swift
//  Brrow
//
//  Fixed version with simplified expressions
//

import SwiftUI

struct SimplifiedListingDetailView: View {
    @StateObject private var viewModel: ListingDetailViewModel
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.dismiss) private var dismiss
    
    // State variables
    @State private var showingBorrowFlow = false
    @State private var showingOfferFlow = false
    @State private var showingMakeOffer = false
    @State private var showingMessageComposer = false
    @State private var isFavorited = false
    @State private var selectedImageIndex = 0
    @State private var showingFullScreenImage = false
    @State private var showingReportSheet = false
    @State private var showingSellerProfile = false
    @State private var showingEditView = false
    @State private var showingShareSheet = false
    @State private var showingDeleteAlert = false
    
    init(listing: Listing) {
        _viewModel = StateObject(wrappedValue: ListingDetailViewModel(listing: listing))
    }
    
    private var isOwner: Bool {
        guard let currentUser = authManager.currentUser else { return false }
        return viewModel.listing.userId == String(currentUser.id)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                imageCarousel
                mainContent
            }
        }
        .navigationBarHidden(true)
        .overlay(
            navigationBar,
            alignment: .top
        )
        .overlay(
            bottomBar,
            alignment: .bottom
        )
        .sheet(isPresented: $showingBorrowFlow) {
            BorrowFlowView(listing: viewModel.listing)
        }
        .sheet(isPresented: $showingSellerProfile) {
            if let seller = viewModel.seller {
                FullSellerProfileView(user: seller)
            }
        }
        .sheet(isPresented: $showingEditView) {
            EnhancedEditListingView(listing: viewModel.listing)
                .environmentObject(authManager)
        }
        .alert("Delete Listing", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteListing()
            }
        } message: {
            Text("Are you sure you want to delete this listing? This action cannot be undone.")
        }
        .onAppear {
            viewModel.loadListingDetails()
        }
    }
    
    private var navigationBar: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(Theme.Colors.text)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(Theme.Colors.background.opacity(0.9)))
            }
            
            Spacer()
            
            HStack(spacing: 12) {
                Button(action: shareItem) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(Theme.Colors.text)
                        .frame(width: 44, height: 44)
                        .background(Circle().fill(Theme.Colors.background.opacity(0.9)))
                }
                
                Button(action: toggleFavorite) {
                    Image(systemName: isFavorited ? "heart.fill" : "heart")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(isFavorited ? .red : Theme.Colors.text)
                        .frame(width: 44, height: 44)
                        .background(Circle().fill(Theme.Colors.background.opacity(0.9)))
                }
            }
        }
        .padding(.horizontal)
        .padding(.top, 50)
    }
    
    private var imageCarousel: some View {
        TabView(selection: $selectedImageIndex) {
            ForEach(Array(viewModel.listing.imageUrls.enumerated()), id: \.offset) { index, imageUrl in
                BrrowAsyncImage(url: imageUrl)
                    .frame(height: 400)
                    .clipped()
                    .tag(index)
            }
        }
        .tabViewStyle(PageTabViewStyle())
        .frame(height: 400)
        .overlay(
            imageIndicator,
            alignment: .bottom
        )
    }
    
    private var imageIndicator: some View {
        HStack(spacing: 8) {
            ForEach(0..<viewModel.listing.imageUrls.count, id: \.self) { index in
                Circle()
                    .fill(selectedImageIndex == index ? Color.white : Color.white.opacity(0.5))
                    .frame(width: 8, height: 8)
            }
        }
        .padding(.bottom, 20)
    }
    
    private var mainContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Title and price
            VStack(alignment: .leading, spacing: 8) {
                Text(viewModel.listing.title)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(Theme.Colors.text)
                
                HStack {
                    Text(viewModel.listing.priceDisplay)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(Theme.Colors.primary)
                    
                    if viewModel.listing.isNegotiable {
                        Text("• Negotiable")
                            .font(.system(size: 14))
                            .foregroundColor(Theme.Colors.secondaryText)
                    }
                }
            }
            .padding(.horizontal)
            
            // Location
            HStack {
                Image(systemName: "location")
                    .font(.system(size: 14))
                    .foregroundColor(Theme.Colors.secondaryText)
                
                Text(viewModel.listing.locationString)
                    .font(.system(size: 14))
                    .foregroundColor(Theme.Colors.secondaryText)
            }
            .padding(.horizontal)
            
            Divider()
            
            // Description
            VStack(alignment: .leading, spacing: 8) {
                Text("Description")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Theme.Colors.text)
                
                Text(viewModel.listing.description)
                    .font(.system(size: 14))
                    .foregroundColor(Theme.Colors.text)
                    .lineSpacing(4)
            }
            .padding(.horizontal)
            
            // Owner info
            if !isOwner {
                Divider()
                
                Button(action: { showingSellerProfile = true }) {
                    HStack {
                        // Profile picture
                        if let profilePic = viewModel.listing.ownerProfilePicture {
                            BrrowAsyncImage(url: profilePic)
                                .frame(width: 50, height: 50)
                                .clipShape(Circle())
                        } else {
                            Circle()
                                .fill(Theme.Colors.secondaryBackground)
                                .frame(width: 50, height: 50)
                                .overlay(
                                    Image(systemName: "person.fill")
                                        .foregroundColor(Theme.Colors.secondaryText)
                                )
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(viewModel.listing.ownerUsername ?? "User")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(Theme.Colors.text)
                            
                            if let rating = viewModel.listing.ownerRating {
                                HStack(spacing: 4) {
                                    Image(systemName: "star.fill")
                                        .font(.system(size: 12))
                                        .foregroundColor(.yellow)
                                    
                                    Text(String(format: "%.1f", rating))
                                        .font(.system(size: 14))
                                        .foregroundColor(Theme.Colors.secondaryText)
                                }
                            }
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14))
                            .foregroundColor(Theme.Colors.secondaryText)
                    }
                    .padding(.horizontal)
                }
            }
            
            // Add some bottom padding for the action bar
            Color.clear.frame(height: 100)
        }
        .padding(.top, 20)
    }
    
    private var bottomBar: some View {
        HStack(spacing: 12) {
            if isOwner {
                Button(action: { showingEditView = true }) {
                    HStack {
                        Image(systemName: "pencil")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Edit")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Theme.Colors.primary)
                    .cornerRadius(25)
                }
                
                Button(action: { showingDeleteAlert = true }) {
                    HStack {
                        Image(systemName: "trash")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Delete")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.red)
                    .cornerRadius(25)
                }
            } else {
                // Message button
                Button(action: {
                    showingMessageComposer = true
                }) {
                    Image(systemName: "message")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(Theme.Colors.primary)
                        .frame(width: 50, height: 50)
                        .background(Theme.Colors.primary.opacity(0.15))
                        .cornerRadius(25)
                }

                // Main action button based on listing type
                if viewModel.listing.type == "rental" {
                    Button(action: { showingBorrowFlow = true }) {
                        HStack {
                            Image(systemName: "calendar")
                                .font(.system(size: 18, weight: .semibold))

                            Text("Request to Rent")
                                .font(.system(size: 18, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Theme.Colors.primary)
                        .cornerRadius(25)
                    }
                } else {
                    // For sale items - show Make Offer or Buy Now
                    HStack(spacing: 12) {
                        // Make Offer button
                        Button(action: { showingMakeOffer = true }) {
                            HStack {
                                Image(systemName: "tag")
                                    .font(.system(size: 16, weight: .semibold))

                                Text("Make Offer")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            .foregroundColor(Theme.Colors.primary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Theme.Colors.primary.opacity(0.15))
                            .cornerRadius(25)
                        }

                        // Buy Now button
                        Button(action: { showingBorrowFlow = true }) {
                            HStack {
                                Image(systemName: "cart")
                                    .font(.system(size: 16, weight: .semibold))

                                Text("Buy Now")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Theme.Colors.primary)
                            .cornerRadius(25)
                        }
                    }
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(
            Rectangle()
                .fill(Theme.Colors.background)
                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: -5)
                .ignoresSafeArea()
        )
    }
    
    private func toggleFavorite() {
        isFavorited.toggle()
        Task {
            await viewModel.toggleFavorite()
        }
    }
    
    private func shareItem() {
        // Share functionality
        let url = URL(string: "https://brrowapp.com/listing/\(viewModel.listing.id)")!
        let activityController = UIActivityViewController(
            activityItems: [viewModel.listing.title, url],
            applicationActivities: nil
        )
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            rootViewController.present(activityController, animated: true)
        }
    }
    
    private func deleteListing() {
        Task {
            await viewModel.deleteListing()
            // Navigate back after successful deletion
            DispatchQueue.main.async {
                dismiss()
            }
        }
    }
}