//
//  OffersView.swift
//  Brrow
//
//  Created by Shalin Ratna on 7/17/25.
//

import SwiftUI
import Combine

struct OffersView: View {
    @StateObject private var viewModel = OffersViewModel()
    @State private var selectedTab = 0
    @State private var showingCreateOffer = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                headerSection
                
                // Tab Selection
                tabSelectionSection
                
                // Content
                contentSection
            }
            .background(Theme.Colors.background)
            .navigationBarHidden(true)
            .sheet(isPresented: $showingCreateOffer) {
                CreateOfferView()
            }
            .onAppear {
                viewModel.fetchOffers()
                trackScreenView("offers")
            }
            .refreshable {
                viewModel.fetchOffers()
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        HStack {
            Text("Offers")
                .font(Theme.Typography.title)
                .fontWeight(.bold)
                .foregroundColor(Theme.Colors.text)
            
            Spacer()
            
            Button(action: {
                showingCreateOffer = true
            }) {
                Image(systemName: "plus.circle.fill")
                    .font(.headline)
                    .foregroundColor(Theme.Colors.primary)
            }
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.top, Theme.Spacing.md)
    }
    
    // MARK: - Tab Selection Section
    private var tabSelectionSection: some View {
        HStack {
            TabButton(
                title: "Received",
                isSelected: selectedTab == 0,
                badgeCount: viewModel.receivedOffers.count
            ) {
                selectedTab = 0
            }
            
            TabButton(
                title: "Sent",
                isSelected: selectedTab == 1,
                badgeCount: viewModel.sentOffers.count
            ) {
                selectedTab = 1
            }
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.top, Theme.Spacing.md)
    }
    
    // MARK: - Content Section
    private var contentSection: some View {
        Group {
            if viewModel.isLoading && viewModel.receivedOffers.isEmpty && viewModel.sentOffers.isEmpty {
                loadingView
            } else if (selectedTab == 0 && viewModel.receivedOffers.isEmpty) || (selectedTab == 1 && viewModel.sentOffers.isEmpty) {
                emptyStateView
            } else {
                offersList
            }
        }
    }
    
    // MARK: - Offers List
    private var offersList: some View {
        ScrollView {
            LazyVStack(spacing: Theme.Spacing.md) {
                ForEach(selectedTab == 0 ? viewModel.receivedOffers : viewModel.sentOffers, id: \.id) { offer in
                    OfferCard(offer: offer, isReceived: selectedTab == 0, 
                             onAccept: { viewModel.acceptOffer(offer) },
                             onReject: { viewModel.rejectOffer(offer) })
                }
            }
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.top, Theme.Spacing.md)
        }
    }
    
    // MARK: - Loading View
    private var loadingView: some View {
        VStack(spacing: Theme.Spacing.md) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: Theme.Colors.primary))
                .scaleEffect(1.5)
            
            Text("Loading offers...")
                .font(Theme.Typography.callout)
                .foregroundColor(Theme.Colors.secondaryText)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Empty State View
    private var emptyStateView: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Image(systemName: selectedTab == 0 ? "tray.fill" : "paperplane.fill")
                .font(.system(size: 60))
                .foregroundColor(Theme.Colors.secondaryText)
            
            Text(selectedTab == 0 ? "No Offers Received" : "No Offers Sent")
                .font(Theme.Typography.headline)
                .fontWeight(.semibold)
                .foregroundColor(Theme.Colors.text)
            
            Text(selectedTab == 0 ? "When someone makes an offer on your listings, they'll appear here." : "Your sent offers will appear here.")
                .font(Theme.Typography.body)
                .foregroundColor(Theme.Colors.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Theme.Spacing.xxl)
            
            if selectedTab == 1 {
                Button(action: {
                    showingCreateOffer = true
                }) {
                    Text("Make an Offer")
                }
                .primaryButtonStyle()
                .padding(.horizontal, Theme.Spacing.xxl)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func trackScreenView(_ screenName: String) {
        let event = AnalyticsEvent(
            eventName: "screen_view",
            eventType: "navigation",
            userId: AuthManager.shared.currentUser?.apiId,
            sessionId: AuthManager.shared.sessionId,
            timestamp: ISO8601DateFormatter().string(from: Date()),
            metadata: [
                "screen_name": screenName,
                "platform": "ios"
            ]
        )
        
        Task {
            try? await APIClient.shared.trackAnalytics(event: event)
        }
    }
}

// MARK: - Tab Button
struct TabButton: View {
    let title: String
    let isSelected: Bool
    let badgeCount: Int
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(Theme.Typography.callout)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? Theme.Colors.primary : Theme.Colors.secondaryText)
                
                if badgeCount > 0 {
                    Text("\(badgeCount)")
                        .font(Theme.Typography.caption)
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Theme.Colors.primary)
                        .cornerRadius(8)
                }
            }
            .padding(.vertical, Theme.Spacing.sm)
            .padding(.horizontal, Theme.Spacing.md)
            .background(isSelected ? Theme.Colors.primary.opacity(0.1) : Color.clear)
            .cornerRadius(Theme.CornerRadius.sm)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Offer Card
struct OfferCard: View {
    let offer: Offer
    let isReceived: Bool
    let onAccept: () -> Void
    let onReject: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            // Header
            HStack {
                Text(isReceived ? "From: \(offer.senderName)" : "To: \(offer.recipientName)")
                    .font(Theme.Typography.callout)
                    .fontWeight(.medium)
                    .foregroundColor(Theme.Colors.text)
                
                Spacer()
                
                Text(offer.status.rawValue.capitalized)
                    .font(Theme.Typography.caption)
                    .foregroundColor(statusColor)
                    .padding(.horizontal, Theme.Spacing.sm)
                    .padding(.vertical, Theme.Spacing.xs)
                    .background(statusColor.opacity(0.1))
                    .cornerRadius(Theme.CornerRadius.sm)
            }
            
            // Listing Info
            Text(offer.listingTitle)
                .font(Theme.Typography.headline)
                .fontWeight(.semibold)
                .foregroundColor(Theme.Colors.text)
            
            // Offer Details
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                HStack {
                    Text("Offer Price:")
                        .font(Theme.Typography.callout)
                        .foregroundColor(Theme.Colors.secondaryText)
                    
                    Spacer()
                    
                    Text("$\(offer.price, specifier: "%.2f")")
                        .font(Theme.Typography.callout)
                        .fontWeight(.semibold)
                        .foregroundColor(Theme.Colors.primary)
                }
                
                if let duration = offer.duration {
                    HStack {
                        Text("Duration:")
                            .font(Theme.Typography.callout)
                            .foregroundColor(Theme.Colors.secondaryText)
                        
                        Spacer()
                        
                        Text("\(duration) days")
                            .font(Theme.Typography.callout)
                            .foregroundColor(Theme.Colors.text)
                    }
                }
                
                if let message = offer.message, !message.isEmpty {
                    Text("Message:")
                        .font(Theme.Typography.callout)
                        .foregroundColor(Theme.Colors.secondaryText)
                    
                    Text(message)
                        .font(Theme.Typography.body)
                        .foregroundColor(Theme.Colors.text)
                        .padding(Theme.Spacing.sm)
                        .background(Theme.Colors.background)
                        .cornerRadius(Theme.CornerRadius.sm)
                }
            }
            
            // Action Buttons (only for received offers)
            if isReceived && offer.status == .pending {
                HStack {
                    Button(action: onReject) {
                        Text("Decline")
                            .font(Theme.Typography.callout)
                            .fontWeight(.medium)
                            .foregroundColor(Theme.Colors.error)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Theme.Spacing.sm)
                            .background(Theme.Colors.error.opacity(0.1))
                            .cornerRadius(Theme.CornerRadius.sm)
                    }
                    
                    Button(action: onAccept) {
                        Text("Accept")
                            .font(Theme.Typography.callout)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Theme.Spacing.sm)
                            .background(Theme.Colors.success)
                            .cornerRadius(Theme.CornerRadius.sm)
                    }
                }
            }
            
            // Timestamp
            HStack {
                Spacer()
                Text(offer.createdAt, style: .relative)
                    .font(Theme.Typography.caption)
                    .foregroundColor(Theme.Colors.secondaryText)
            }
        }
        .padding(Theme.Spacing.md)
        .cardStyle()
    }
    
    private var statusColor: Color {
        switch offer.status {
        case .pending:
            return Theme.Colors.warning
        case .accepted:
            return Theme.Colors.success
        case .rejected:
            return Theme.Colors.error
        case .expired:
            return Theme.Colors.secondaryText
        case .cancelled:
            return Theme.Colors.secondaryText
        }
    }
}

// MARK: - Create Offer View
struct CreateOfferView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var viewModel = CreateOfferViewModel()
    
    @State private var selectedListing: Listing?
    @State private var offerAmount: String = ""
    @State private var duration: String = ""
    @State private var message: String = ""
    @State private var showingListingPicker = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                    // Header
                    VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                        Text("Make an Offer")
                            .font(Theme.Typography.headline)
                            .fontWeight(.bold)
                            .foregroundColor(Theme.Colors.text)
                        
                        Text("Submit an offer to borrow an item")
                            .font(Theme.Typography.body)
                            .foregroundColor(Theme.Colors.secondaryText)
                    }
                    .padding(.horizontal, Theme.Spacing.md)
                    
                    // Listing Selection
                    VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                        Text("Select Listing")
                            .font(Theme.Typography.callout)
                            .fontWeight(.medium)
                            .foregroundColor(Theme.Colors.text)
                        
                        Button(action: {
                            showingListingPicker = true
                        }) {
                            HStack {
                                if let listing = selectedListing {
                                    AsyncImage(url: URL(string: listing.images.first ?? "")) { image in
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                    } placeholder: {
                                        Rectangle()
                                            .fill(Theme.Colors.background)
                                    }
                                    .frame(width: 50, height: 50)
                                    .cornerRadius(Theme.CornerRadius.sm)
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(listing.title)
                                            .font(Theme.Typography.callout)
                                            .fontWeight(.medium)
                                            .foregroundColor(Theme.Colors.text)
                                        
                                        Text("$\(listing.price, specifier: "%.2f")")
                                            .font(Theme.Typography.caption)
                                            .foregroundColor(Theme.Colors.primary)
                                    }
                                } else {
                                    Text("Select a listing to make an offer")
                                        .font(Theme.Typography.callout)
                                        .foregroundColor(Theme.Colors.secondaryText)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(Theme.Colors.secondaryText)
                            }
                            .padding(Theme.Spacing.md)
                            .background(Theme.Colors.surface)
                            .cornerRadius(Theme.CornerRadius.md)
                        }
                    }
                    .padding(.horizontal, Theme.Spacing.md)
                    
                    // Offer Amount
                    VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                        Text("Offer Amount")
                            .font(Theme.Typography.callout)
                            .fontWeight(.medium)
                            .foregroundColor(Theme.Colors.text)
                        
                        HStack {
                            Text("$")
                                .font(Theme.Typography.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(Theme.Colors.text)
                            
                            TextField("0.00", text: $offerAmount)
                                .keyboardType(.decimalPad)
                                .font(Theme.Typography.body)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                    }
                    .padding(.horizontal, Theme.Spacing.md)
                    
                    // Duration
                    VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                        Text("Duration (days)")
                            .font(Theme.Typography.callout)
                            .fontWeight(.medium)
                            .foregroundColor(Theme.Colors.text)
                        
                        TextField("Number of days", text: $duration)
                            .keyboardType(.numberPad)
                            .font(Theme.Typography.body)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    .padding(.horizontal, Theme.Spacing.md)
                    
                    // Message
                    VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                        Text("Message (Optional)")
                            .font(Theme.Typography.callout)
                            .fontWeight(.medium)
                            .foregroundColor(Theme.Colors.text)
                        
                        TextField("Add a message to your offer...", text: $message, axis: .vertical)
                            .lineLimit(3...6)
                            .font(Theme.Typography.body)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    .padding(.horizontal, Theme.Spacing.md)
                    
                    // Submit Button
                    Button(action: submitOffer) {
                        HStack {
                            if viewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            }
                            
                            Text("Send Offer")
                                .font(Theme.Typography.callout)
                                .fontWeight(.medium)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Theme.Spacing.md)
                        .background(canSubmit ? Theme.Colors.primary : Theme.Colors.secondaryText)
                        .foregroundColor(.white)
                        .cornerRadius(Theme.CornerRadius.md)
                    }
                    .disabled(!canSubmit || viewModel.isLoading)
                    .padding(.horizontal, Theme.Spacing.md)
                    
                    Spacer()
                }
                .padding(.vertical, Theme.Spacing.lg)
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingListingPicker) {
                ListingPickerView(selectedListing: $selectedListing)
            }
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") {
                    viewModel.errorMessage = nil
                }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
    }
    
    private var canSubmit: Bool {
        guard let _ = selectedListing,
              let amount = Double(offerAmount),
              let days = Int(duration),
              amount > 0,
              days > 0 else {
            return false
        }
        return true
    }
    
    private func submitOffer() {
        guard let listing = selectedListing,
              let amount = Double(offerAmount),
              let days = Int(duration) else {
            return
        }
        
        let offerRequest = CreateOfferRequest(
            listingId: String(listing.id),
            amount: amount,
            message: message.isEmpty ? "" : message
        )
        
        Task {
            await viewModel.createOffer(offerRequest)
            if viewModel.errorMessage == nil {
                DispatchQueue.main.async {
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }
    }
}

// MARK: - Create Offer View Model
class CreateOfferViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    func createOffer(_ request: CreateOfferRequest) async {
        DispatchQueue.main.async {
            self.isLoading = true
            self.errorMessage = nil
        }
        
        do {
            _ = try await APIClient.shared.createOffer(request)
            DispatchQueue.main.async {
                self.isLoading = false
            }
        } catch {
            DispatchQueue.main.async {
                self.isLoading = false
                self.errorMessage = error.localizedDescription
            }
        }
    }
}

// MARK: - Listing Picker View
struct ListingPickerView: View {
    @Binding var selectedListing: Listing?
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var viewModel = ListingPickerViewModel()
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: Theme.Spacing.sm) {
                    ForEach(viewModel.listings, id: \.listingId) { listing in
                        listingRow(listing)
                    }
                }
                .padding()
            }
            .navigationTitle("Select Listing")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
        .onAppear {
            viewModel.fetchListings()
        }
    }
    
    private func listingRow(_ listing: Listing) -> some View {
        Button(action: {
            selectedListing = listing
            presentationMode.wrappedValue.dismiss()
        }) {
            HStack {
                AsyncImage(url: URL(string: listing.images.first ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Theme.Colors.background)
                }
                .cornerRadius(Theme.CornerRadius.sm)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(listing.title)
                        .font(Theme.Typography.callout)
                        .fontWeight(.medium)
                        .foregroundColor(Theme.Colors.text)
                    
                    Text("$\(listing.price, specifier: "%.2f")")
                        .font(Theme.Typography.caption)
                        .foregroundColor(Theme.Colors.primary)
                    
                    Text(listing.location.address)
                        .font(Theme.Typography.caption)
                        .foregroundColor(Theme.Colors.secondaryText)
                }
                
                Spacer()
                
                if selectedListing?.id == listing.id {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(Theme.Colors.primary)
                }
            }
            .padding(Theme.Spacing.md)
            .background(selectedListing?.id == listing.id ? Theme.Colors.primary.opacity(0.1) : Theme.Colors.surface)
            .cornerRadius(Theme.CornerRadius.md)
        }
    }
}

// MARK: - Listing Picker View Model
class ListingPickerViewModel: ObservableObject {
    @Published var listings: [Listing] = []
    @Published var isLoading = false
    
    func fetchListings() {
        isLoading = true
        
        Task {
            do {
                let fetchedListings = try await APIClient.shared.fetchListings()
                DispatchQueue.main.async {
                    self.listings = fetchedListings
                    self.isLoading = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.listings = []
                    self.isLoading = false
                }
            }
        }
    }
}

struct OffersView_Previews: PreviewProvider {
    static var previews: some View {
        OffersView()
    }
}