//
//  GarageSalesView.swift
//  Brrow
//
//  Created by Shalin Ratna on 7/16/25.
//

import SwiftUI
import Combine

struct GarageSalesView: View {
    @StateObject private var viewModel = GarageSalesViewModel()
    @State private var showingCreateGarageSale = false
    @State private var cancellables = Set<AnyCancellable>()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                headerSection
                
                // Content
                if viewModel.isLoading && viewModel.garageSales.isEmpty {
                    loadingView
                } else if viewModel.garageSales.isEmpty {
                    emptyStateView
                } else {
                    garageSalesList
                }
            }
            .background(Theme.Colors.background)
            .navigationBarHidden(true)
            .sheet(isPresented: $showingCreateGarageSale) {
                ModernCreateGarageSaleView()
            }
            .onAppear {
                viewModel.loadGarageSales()
                trackScreenView("garage_sales")
            }
            .refreshable {
                viewModel.refreshGarageSales()
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        HStack {
            Text("Garage Sales")
                .font(Theme.Typography.title)
                .fontWeight(.bold)
                .foregroundColor(Theme.Colors.text)
            
            Spacer()
            
            Button(action: {
                showingCreateGarageSale = true
            }) {
                Image(systemName: "plus.circle.fill")
                    .font(.headline)
                    .foregroundColor(Theme.Colors.primary)
            }
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.top, Theme.Spacing.md)
    }
    
    // MARK: - Garage Sales List
    private var garageSalesList: some View {
        ScrollView {
            LazyVStack(spacing: Theme.Spacing.md) {
                ForEach(viewModel.garageSales, id: \.id) { garageSale in
                    NavigationLink(destination: GarageSaleDetailView(sale: garageSale)) {
                        GarageSaleCard(garageSale: garageSale)
                    }
                    .buttonStyle(PlainButtonStyle())
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
            
            Text("Loading garage sales...")
                .font(Theme.Typography.callout)
                .foregroundColor(Theme.Colors.secondaryText)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Empty State View
    private var emptyStateView: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Image(systemName: "storefront")
                .font(.system(size: 60))
                .foregroundColor(Theme.Colors.secondaryText)
            
            Text("No Garage Sales")
                .font(Theme.Typography.headline)
                .fontWeight(.semibold)
                .foregroundColor(Theme.Colors.text)
            
            Text("Create the first garage sale in your neighborhood!")
                .font(Theme.Typography.body)
                .foregroundColor(Theme.Colors.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Theme.Spacing.xxl)
            
            Button(action: {
                showingCreateGarageSale = true
            }) {
                Text("Create Garage Sale")
            }
            .primaryButtonStyle()
            .padding(.horizontal, Theme.Spacing.xxl)
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
        
        APIClient.shared.trackAnalytics(event: event)
            .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
            .store(in: &cancellables)
    }
}

// MARK: - Garage Sale Card
struct GarageSaleCard: View {
    let garageSale: GarageSale
    
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            // Image
            AsyncImage(url: URL(string: garageSale.photos.first?.url ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .foregroundColor(Theme.Colors.divider)
                    .overlay(
                        Image(systemName: "storefront")
                            .font(.title)
                            .foregroundColor(Theme.Colors.secondaryText)
                    )
            }
            .frame(height: 150)
            .clipped()
            
            // Content
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text(garageSale.title)
                    .font(Theme.Typography.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(Theme.Colors.text)
                    .lineLimit(2)
                
                Text(garageSale.description ?? "")
                    .font(Theme.Typography.body)
                    .foregroundColor(Theme.Colors.secondaryText)
                    .lineLimit(3)
                
                HStack {
                    Image(systemName: "location.fill")
                        .foregroundColor(Theme.Colors.primary)
                    
                    Text(garageSale.address ?? garageSale.location)
                        .font(Theme.Typography.callout)
                        .foregroundColor(Theme.Colors.secondaryText)
                    
                    Spacer()
                }
                
                HStack {
                    Image(systemName: "calendar")
                        .foregroundColor(Theme.Colors.primary)
                    
                    Text(garageSale.startDate)
                        .font(Theme.Typography.callout)
                        .foregroundColor(Theme.Colors.text)
                    
                    Spacer()
                    
                    Text("\(garageSale.rsvpCount) attending")
                        .font(Theme.Typography.caption)
                        .foregroundColor(Theme.Colors.secondaryText)
                }
            }
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.bottom, Theme.Spacing.md)
        }
        .cardStyle()
    }
}


// MARK: - Placeholder Views
// GarageSaleDetailView is defined in GarageSaleComponents.swift

struct GarageSalesView_Previews: PreviewProvider {
    static var previews: some View {
        GarageSalesView()
    }
}
