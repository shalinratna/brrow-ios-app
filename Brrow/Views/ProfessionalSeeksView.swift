//
//  ProfessionalSeeksView.swift
//  Brrow
//
//  Professional seeks view matching the green/white theme
//

import SwiftUI

struct ProfessionalSeeksView: View {
    @StateObject private var viewModel = SeeksViewModel()
    @State private var showingCreateSeek = false
    @State private var selectedCategory: String? = nil
    @State private var searchText = ""
    @State private var animateContent = false
    
    var body: some View {
        ZStack {
            // Clean background
            Theme.Colors.background
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Professional Header
                professionalHeader
                    .padding(.horizontal, Theme.Spacing.md)
                    .padding(.top, 10)
                    .background(Theme.Colors.background)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        // Search Bar
                        searchSection
                            .padding(.horizontal, Theme.Spacing.md)
                            .padding(.top, Theme.Spacing.md)
                        
                        // Category Pills
                        categorySection
                            .padding(.top, Theme.Spacing.lg)
                        
                        // Stats Cards
                        if !viewModel.isLoading {
                            statsSection
                                .padding(.horizontal, Theme.Spacing.md)
                                .padding(.top, Theme.Spacing.lg)
                        }
                        
                        // Seeks List
                        seeksSection
                            .padding(.horizontal, Theme.Spacing.md)
                            .padding(.top, Theme.Spacing.lg)
                        
                        // Bottom padding
                        Color.clear.frame(height: 100)
                    }
                }
                .refreshable {
                    viewModel.refreshSeeks()
                }
            }
            
            // Floating Action Button
            floatingActionButton
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showingCreateSeek) {
            ModernCreateSeekView()
        }
        .onAppear {
            viewModel.loadSeeks()
            withAnimation {
                animateContent = true
            }
        }
    }
    
    // MARK: - Professional Header
    private var professionalHeader: some View {
        HStack {
            Text("seeks".localizedString)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(Theme.Colors.text)
            
            Spacer()
            
            // My Seeks button
            Button(action: { /* Show user's seeks */ }) {
                HStack(spacing: 6) {
                    Image(systemName: "person.circle")
                        .font(.system(size: 16, weight: .medium))
                    Text("my_seeks".localizedString)
                        .font(.system(size: 15, weight: .medium))
                }
                .foregroundColor(Theme.Colors.primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Theme.Colors.primary.opacity(0.1))
                .cornerRadius(20)
            }
        }
    }
    
    // MARK: - Search Section
    private var searchSection: some View {
        HStack(spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Theme.Colors.secondaryText)
                
                TextField("search_seeks".localizedString, text: $searchText)
                    .font(.system(size: 16))
                    .foregroundColor(Theme.Colors.text)
                    .onSubmit {
                        // Implement search
                    }
                
                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                        // Clear search
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(Theme.Colors.secondaryText)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Theme.Colors.secondaryBackground)
            .cornerRadius(12)
        }
        .opacity(animateContent ? 1 : 0)
        .offset(y: animateContent ? 0 : 20)
        .animation(.easeOut(duration: 0.4), value: animateContent)
    }
    
    // MARK: - Category Section
    private var categorySection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                SeekCategoryPill(
                    title: "all".localizedString,
                    icon: "square.grid.2x2",
                    isSelected: selectedCategory == nil,
                    action: {
                        selectedCategory = nil
                        // Filter by all
                    }
                )
                
                ForEach(ProfessionalSeekCategory.allCases, id: \.self) { category in
                    SeekCategoryPill(
                        title: category.title,
                        icon: category.icon,
                        isSelected: selectedCategory == category.rawValue,
                        action: {
                            selectedCategory = category.rawValue
                            // Filter by category
                        }
                    )
                }
            }
            .padding(.horizontal, Theme.Spacing.md)
        }
        .opacity(animateContent ? 1 : 0)
        .offset(y: animateContent ? 0 : 20)
        .animation(.easeOut(duration: 0.4).delay(0.1), value: animateContent)
    }
    
    // MARK: - Stats Section
    private var statsSection: some View {
        HStack(spacing: 12) {
            ProfessionalSeekStatCard(
                title: "active_seeks".localizedString,
                value: "\(viewModel.seeks.filter { $0.isActive }.count)",
                icon: "magnifyingglass.circle.fill",
                color: Theme.Colors.primary
            )
            
            ProfessionalSeekStatCard(
                title: "with_matches".localizedString,
                value: "\(viewModel.seeks.filter { $0.hasMatches }.count)",
                icon: "checkmark.circle.fill",
                color: Theme.Colors.success
            )
            
            ProfessionalSeekStatCard(
                title: "urgent".localizedString,
                value: "\(viewModel.seeks.filter { $0.urgency == "high" }.count)",
                icon: "exclamationmark.circle.fill",
                color: Theme.Colors.error
            )
        }
        .opacity(animateContent ? 1 : 0)
        .scaleEffect(animateContent ? 1 : 0.9)
        .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.2), value: animateContent)
    }
    
    // MARK: - Seeks Section
    private var seeksSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section header
            HStack {
                Text("community_seeks".localizedString)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(Theme.Colors.text)
                
                Spacer()
                
                // Sort menu
                Menu {
                    Button("newest_first".localizedString) { /* Sort by newest */ }
                    Button("highest_budget".localizedString) { /* Sort by budget */ }
                    Button("most_urgent".localizedString) { /* Sort by urgency */ }
                    Button("nearest".localizedString) { /* Sort by distance */ }
                } label: {
                    HStack(spacing: 6) {
                        Text("sort".localizedString)
                            .font(.system(size: 14, weight: .medium))
                        Image(systemName: "chevron.down")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundColor(Theme.Colors.primary)
                }
            }
            
            // List
            if viewModel.isLoading && viewModel.seeks.isEmpty {
                ProfessionalSeeksLoadingView()
            } else if viewModel.seeks.isEmpty {
                EmptyStateView(
                    title: "no_seeks_found".localizedString,
                    message: "be_first_to_post".localizedString,
                    systemImage: "magnifyingglass"
                )
                .frame(height: 300)
            } else {
                LazyVStack(spacing: 16) {
                    ForEach(Array(viewModel.seeks.enumerated()), id: \.element.id) { index, seek in
                        NavigationLink(destination: SeekDetailView(seek: seek)) {
                            ProfessionalSeekCard(seek: seek)
                                .opacity(animateContent ? 1 : 0)
                                .scaleEffect(animateContent ? 1 : 0.9)
                                .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(Double(index) * 0.05 + 0.3), value: animateContent)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
        }
    }
    
    // MARK: - Floating Action Button
    private var floatingActionButton: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                
                Button(action: {
                    showingCreateSeek = true
                }) {
                    ZStack {
                        Circle()
                            .fill(Theme.Colors.primary)
                            .frame(width: 60, height: 60)
                            .shadow(color: Theme.Colors.primary.opacity(0.3), radius: 8, x: 0, y: 4)
                        
                        Image(systemName: "magnifyingglass.circle")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                .scaleEffect(animateContent ? 1 : 0)
                .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.5), value: animateContent)
            }
            .padding(.trailing, 20)
            .padding(.bottom, 30)
        }
    }
}

// MARK: - Professional Seek Card
struct ProfessionalSeekCard: View {
    let seek: Seek
    
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            // Header with title and urgency
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(seek.title)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(Theme.Colors.text)
                        .lineLimit(2)
                    
                    Text(seek.category.localizedString)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Theme.Colors.primary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Theme.Colors.primary.opacity(0.1))
                        .cornerRadius(12)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    UrgencyBadge(urgency: seek.urgency)
                    
                    if seek.matchCount > 0 {
                        Text("\(seek.matchCount) matches")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Theme.Colors.success)
                    }
                }
            }
            
            // Description
            Text(seek.description)
                .font(.system(size: 15))
                .foregroundColor(Theme.Colors.secondaryText)
                .lineLimit(3)
            
            // Location and budget
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "location.fill")
                        .font(.system(size: 12))
                        .foregroundColor(Theme.Colors.primary)
                    
                    Text(seek.location)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Theme.Colors.text)
                }
                
                Spacer()
                
                if let maxBudget = seek.maxBudget, maxBudget > 0 {
                    Text("Up to $\(String(format: "%.0f", maxBudget))")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Theme.Colors.success)
                }
            }
            
            // Footer with distance and time
            HStack {
                Text("Within \(String(format: "%.1f", seek.maxDistance)) km")
                    .font(.system(size: 12))
                    .foregroundColor(Theme.Colors.secondaryText)
                
                Spacer()
                
                Text(timeAgo(seek.createdAt))
                    .font(.system(size: 12))
                    .foregroundColor(Theme.Colors.secondaryText)
            }
        }
        .padding(Theme.Spacing.md)
        .background(Theme.Colors.cardBackground)
        .cornerRadius(Theme.CornerRadius.lg)
        .shadow(color: Theme.Shadows.card, radius: Theme.Shadows.cardRadius, x: 0, y: 2)
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

// MARK: - Urgency Badge
struct UrgencyBadge: View {
    let urgency: String
    
    var body: some View {
        Text(urgency.capitalized)
            .font(.system(size: 11, weight: .bold))
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(urgencyColor)
            .cornerRadius(8)
    }
    
    private var urgencyColor: Color {
        switch urgency.lowercased() {
        case "high":
            return Theme.Colors.error
        case "medium":
            return Theme.Colors.accentOrange
        default:
            return Theme.Colors.primary
        }
    }
}

// MARK: - Seek Category Pill
struct SeekCategoryPill: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                
                Text(title)
                    .font(.system(size: 15, weight: .medium))
            }
            .foregroundColor(isSelected ? .white : Theme.Colors.text)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                isSelected ? Theme.Colors.primary : Theme.Colors.secondaryBackground
            )
            .cornerRadius(20)
            .scaleEffect(isSelected ? 1.05 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        }
    }
}

// MARK: - Professional Seek Stat Card
struct ProfessionalSeekStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(color)
            
            Text(value)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(Theme.Colors.text)
            
            Text(title)
                .font(.system(size: 12))
                .foregroundColor(Theme.Colors.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Theme.Colors.secondaryBackground)
        .cornerRadius(12)
    }
}

// MARK: - Professional Seeks Loading View
struct ProfessionalSeeksLoadingView: View {
    var body: some View {
        VStack(spacing: 16) {
            ForEach(0..<3) { _ in
                ProfessionalSeekShimmerCard()
            }
        }
    }
}

// MARK: - Professional Seek Shimmer Card
struct ProfessionalSeekShimmerCard: View {
    @State private var isAnimating = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Rectangle()
                        .fill(Theme.Colors.secondary.opacity(0.2))
                        .frame(height: 20)
                    
                    Rectangle()
                        .fill(Theme.Colors.secondary.opacity(0.2))
                        .frame(width: 80, height: 16)
                }
                
                Spacer()
                
                Rectangle()
                    .fill(Theme.Colors.secondary.opacity(0.2))
                    .frame(width: 60, height: 24)
            }
            
            Rectangle()
                .fill(Theme.Colors.secondary.opacity(0.2))
                .frame(height: 40)
            
            HStack {
                Rectangle()
                    .fill(Theme.Colors.secondary.opacity(0.2))
                    .frame(width: 120, height: 16)
                
                Spacer()
                
                Rectangle()
                    .fill(Theme.Colors.secondary.opacity(0.2))
                    .frame(width: 80, height: 16)
            }
        }
        .padding(Theme.Spacing.md)
        .background(Theme.Colors.cardBackground)
        .cornerRadius(Theme.CornerRadius.lg)
        .overlay(
            LinearGradient(
                colors: [.clear, Theme.Colors.secondary.opacity(0.3), .clear],
                startPoint: .leading,
                endPoint: .trailing
            )
            .rotationEffect(.degrees(30))
            .offset(x: isAnimating ? 300 : -300)
            .animation(.linear(duration: 1.5).repeatForever(autoreverses: false), value: isAnimating)
        )
        .mask(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.lg)
        )
        .onAppear {
            isAnimating = true
        }
    }
}

// MARK: - Seek Categories
enum ProfessionalSeekCategory: String, CaseIterable {
    case electronics = "electronics"
    case furniture = "furniture"
    case tools = "tools"
    case sports = "sports"
    case books = "books"
    case clothing = "clothing"
    case vehicles = "vehicles"
    case home = "home"
    case other = "other"
    
    var title: String { rawValue.localizedString }
    
    var icon: String {
        switch self {
        case .electronics: return "tv"
        case .furniture: return "sofa"
        case .tools: return "wrench"
        case .sports: return "sportscourt"
        case .books: return "book"
        case .clothing: return "tshirt"
        case .vehicles: return "car"
        case .home: return "house"
        case .other: return "square.grid.2x2"
        }
    }
}

#Preview {
    ProfessionalSeeksView()
}