//
//  SeeksView.swift
//  Brrow
//
//  Created by Shalin Ratna on 7/16/25.
//

import SwiftUI
import Combine

struct SeeksView: View {
    @StateObject private var viewModel = SeeksViewModel()
    @State private var showingCreateSeek = false
    @State private var cancellables = Set<AnyCancellable>()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                headerSection
                
                // Content
                if viewModel.isLoading && viewModel.seeks.isEmpty {
                    loadingView
                } else if viewModel.seeks.isEmpty {
                    emptyStateView
                } else {
                    seeksList
                }
            }
            .background(Theme.Colors.background)
            .navigationBarHidden(true)
            .sheet(isPresented: $showingCreateSeek) {
                CreateSeekView()
            }
            .onAppear {
                viewModel.loadSeeks()
                trackScreenView("seeks")
            }
            .refreshable {
                viewModel.refreshSeeks()
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        HStack {
            Text("Seeks")
                .font(Theme.Typography.title)
                .fontWeight(.bold)
                .foregroundColor(Theme.Colors.text)
            
            Spacer()
            
            Button(action: {
                showingCreateSeek = true
            }) {
                Image(systemName: "plus.circle.fill")
                    .font(.headline)
                    .foregroundColor(Theme.Colors.primary)
            }
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.top, Theme.Spacing.md)
    }
    
    // MARK: - Seeks List
    private var seeksList: some View {
        ScrollView {
            LazyVStack(spacing: Theme.Spacing.md) {
                ForEach(viewModel.seeks, id: \.id) { seek in
                    NavigationLink(destination: SeekDetailView(seek: seek)) {
                        SeekCard(seek: seek)
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
            
            Text("Loading seeks...")
                .font(Theme.Typography.callout)
                .foregroundColor(Theme.Colors.secondaryText)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Empty State View
    private var emptyStateView: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(Theme.Colors.secondaryText)
            
            Text("No Active Seeks")
                .font(Theme.Typography.headline)
                .fontWeight(.semibold)
                .foregroundColor(Theme.Colors.text)
            
            Text("Post a seek to let others know what you're looking for!")
                .font(Theme.Typography.body)
                .foregroundColor(Theme.Colors.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Theme.Spacing.xxl)
            
            Button(action: {
                showingCreateSeek = true
            }) {
                Text("Create First Seek")
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

// MARK: - Seek Card
struct SeekCard: View {
    let seek: Seek
    
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            HStack {
                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    Text(seek.title)
                        .font(Theme.Typography.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(Theme.Colors.text)
                        .lineLimit(2)
                    
                    Text(seek.category)
                        .font(Theme.Typography.caption)
                        .foregroundColor(Theme.Colors.primary)
                        .padding(.horizontal, Theme.Spacing.sm)
                        .padding(.vertical, Theme.Spacing.xs)
                        .background(Theme.Colors.primary.opacity(0.1))
                        .cornerRadius(Theme.CornerRadius.sm)
                }
                
                Spacer()
                
                VStack {
                    urgencyBadge
                    
                    if (seek.matchCount ?? 0) > 0 {
                        Text("\(seek.matchCount ?? 0) matches")
                            .font(Theme.Typography.caption)
                            .foregroundColor(Theme.Colors.success)
                    }
                }
            }
            
            Text(seek.description)
                .font(Theme.Typography.body)
                .foregroundColor(Theme.Colors.secondaryText)
                .lineLimit(3)
            
            HStack {
                Image(systemName: "location.fill")
                    .foregroundColor(Theme.Colors.primary)
                
                Text(seek.location)
                    .font(Theme.Typography.callout)
                    .foregroundColor(Theme.Colors.secondaryText)
                
                Spacer()
                
                if let maxBudget = seek.maxBudget {
                    Text("Up to $\(String(format: "%.0f", maxBudget))")
                        .font(Theme.Typography.callout)
                        .foregroundColor(Theme.Colors.success)
                }
            }
            
            HStack {
                Text("Within \(String(format: "%.1f", seek.maxDistance)) km")
                    .font(Theme.Typography.caption)
                    .foregroundColor(Theme.Colors.secondaryText)
                
                Spacer()
                
                Text(timeAgo(seek.createdAt))
                    .font(Theme.Typography.caption)
                    .foregroundColor(Theme.Colors.secondaryText)
            }
        }
        .padding(Theme.Spacing.md)
        .cardStyle()
    }
    
    private var urgencyBadge: some View {
        Text(seek.urgency.capitalized)
            .font(Theme.Typography.caption)
            .foregroundColor(.white)
            .padding(.horizontal, Theme.Spacing.sm)
            .padding(.vertical, Theme.Spacing.xs)
            .background(urgencyColor)
            .cornerRadius(Theme.CornerRadius.sm)
    }
    
    private var urgencyColor: Color {
        switch seek.urgency.lowercased() {
        case "high":
            return Theme.Colors.error
        case "medium":
            return Theme.Colors.warning
        default:
            return Theme.Colors.info
        }
    }
    
    private func timeAgo(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: dateString) else { return "Recently" }
        
        let now = Date()
        let components = Calendar.current.dateComponents([.day, .hour, .minute], from: date, to: now)
        
        if let days = components.day, days > 0 {
            return "\(days)d ago"
        } else if let hours = components.hour, hours > 0 {
            return "\(hours)h ago"
        } else if let minutes = components.minute, minutes > 0 {
            return "\(minutes)m ago"
        } else {
            return "Just now"
        }
    }
}

// MARK: - Seeks View Model
class SeeksViewModel: ObservableObject {
    @Published var seeks: [Seek] = []
    @Published var isLoading = false
    @Published var errorMessage = ""
    
    private var cancellables = Set<AnyCancellable>()
    
    func loadSeeks() {
        isLoading = true
        errorMessage = ""
        
        Task {
            do {
                let fetchedSeeks = try await APIClient.shared.fetchSeeks()
                await MainActor.run {
                    self.seeks = fetchedSeeks
                    self.isLoading = false
                    PersistenceController.shared.saveSeeks(fetchedSeeks)
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    self.errorMessage = error.localizedDescription
                    self.loadCachedSeeks()
                }
            }
        }
    }
    
    func refreshSeeks() {
        loadSeeks()
    }
    
    private func loadCachedSeeks() {
        let cachedSeeks = PersistenceController.shared.fetchSeeks()
        let seeks = cachedSeeks.compactMap { entity -> Seek? in
            guard let imagesData = entity.images,
                  let images = try? JSONDecoder().decode([String].self, from: imagesData),
                  let tagsData = entity.tags,
                  let tags = try? JSONDecoder().decode([String].self, from: tagsData) else {
                return nil
            }
            
            return Seek(
                id: entity.id,
                userId: entity.userId,
                title: entity.title,
                description: entity.seekDescription,
                category: entity.category,
                location: entity.location,
                latitude: entity.latitude,
                longitude: entity.longitude,
                maxDistance: entity.maxDistance,
                minBudget: entity.minBudget,
                maxBudget: entity.maxBudget,
                urgency: entity.urgency,
                status: entity.status,
                createdAt: ISO8601DateFormatter().string(from: entity.createdAt),
                expiresAt: entity.expiresAt != nil ? ISO8601DateFormatter().string(from: entity.expiresAt!) : nil,
                images: images,
                tags: tags,
                matchCount: Int(entity.matchCount)
            )
        }
        
        self.seeks = seeks
    }
}

// MARK: - Placeholder Views
struct SeekDetailView: View {
    let seek: Seek
    
    var body: some View {
        Text("Seek Detail - \(seek.title)")
            .navigationTitle("Seek")
    }
}

// CreateSeekView moved to standalone file

struct SeeksView_Previews: PreviewProvider {
    static var previews: some View {
        SeeksView()
    }
}
