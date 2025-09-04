//
//  AchievementsView.swift
//  Brrow
//
//  Achievements and badges view
//

import SwiftUI

struct AchievementsView: View {
    @StateObject private var achievementManager = AchievementManager.shared
    @State private var selectedCategory: String = "All"
    @State private var showOnlyUnlocked = false
    @State private var confettiCounter = 0
    @State private var showingAchievementDetail: AchievementData?
    @State private var animateHeader = false
    @State private var scrollOffset: CGFloat = 0
    @State private var selectedDifficulty: String = "All"
    @State private var searchText = ""
    
    @Environment(\.dismiss) private var dismiss
    
    private let gridColumns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    // Filter achievements based on category, difficulty, and search
    private var filteredAchievements: [AchievementData] {
        achievementManager.achievements.filter { achievement in
            let categoryMatch = selectedCategory == "All" || achievement.category == selectedCategory
            let difficultyMatch = selectedDifficulty == "All" || achievement.difficulty == selectedDifficulty
            let unlockedMatch = !showOnlyUnlocked || achievement.isUnlocked
            let searchMatch = searchText.isEmpty || 
                             achievement.displayName.localizedCaseInsensitiveContains(searchText) ||
                             achievement.displayDescription.localizedCaseInsensitiveContains(searchText)
            
            return categoryMatch && difficultyMatch && unlockedMatch && searchMatch
        }
    }
    
    var body: some View {
        ZStack {
            // Animated gradient background
            AchievementsAnimatedGradientBackground()
            
            VStack(spacing: 0) {
                // Custom header with no native back button
                headerView
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Level progress card
                        levelProgressCard
                            .padding(.horizontal)
                        
                        // Stats overview
                        statsOverview
                            .padding(.horizontal)
                        
                        // Category filters
                        categoryFilters
                        
                        // Difficulty filters
                        difficultyFilters
                            .padding(.horizontal)
                        
                        // Search bar
                        searchBar
                            .padding(.horizontal)
                        
                        // Achievement grid
                        achievementGrid
                            .padding(.horizontal)
                    }
                    .padding(.bottom, 32)
                    .background(
                        GeometryReader { geometry in
                            Color.clear
                                .preference(
                                    key: AchievementsScrollOffsetPreferenceKey.self,
                                    value: geometry.frame(in: .named("scroll")).origin.y
                                )
                        }
                    )
                }
                .coordinateSpace(name: "scroll")
                .onPreferenceChange(AchievementsScrollOffsetPreferenceKey.self) { value in
                    scrollOffset = value
                }
            }
        }
        .ignoresSafeArea(.all, edges: .top)
        .onAppear {
            achievementManager.fetchAchievements()
            withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
                animateHeader = true
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .achievementUnlocked)) { notification in
            // Trigger celebration animation
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                confettiCounter += 1
            }
            HapticManager.notification(type: .success)
        }
        .sheet(item: $showingAchievementDetail) { achievement in
            AchievementDetailView(achievement: achievement)
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        ZStack {
            // Gradient background that changes with scroll
            LinearGradient(
                colors: [
                    Color(hex: "#2ABF5A").opacity(scrollOffset > -50 ? 0.9 : 1),
                    Color(hex: "#1E8E3E").opacity(scrollOffset > -50 ? 0.9 : 1)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            VStack(spacing: 0) {
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.white.opacity(0.8))
                            .background(Circle().fill(Color.black.opacity(0.2)))
                    }
                    
                    Spacer()
                    
                    Button(action: { showOnlyUnlocked.toggle() }) {
                        HStack(spacing: 6) {
                            Image(systemName: showOnlyUnlocked ? "eye.fill" : "eye.slash.fill")
                            Text(showOnlyUnlocked ? "Unlocked" : "All")
                                .font(.caption)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(Color.white.opacity(0.2)))
                        .foregroundColor(.white)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 60)
                
                VStack(spacing: 8) {
                    Text("Achievements")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .scaleEffect(animateHeader ? 1 : 0.8)
                        .opacity(animateHeader ? 1 : 0)
                    
                    if let stats = achievementManager.stats {
                        Text("\(stats.totalUnlocked) unlocked")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                .padding(.bottom, 20)
            }
        }
        .frame(height: 180)
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
    
    // MARK: - Level Progress Card
    private var levelProgressCard: some View {
        Group {
            if let level = achievementManager.userLevel {
                VStack(spacing: 16) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Level \(level.current)")
                                .font(.title2)
                                .fontWeight(.bold)
                            Text(level.title)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            HStack(spacing: 4) {
                                Image(systemName: "star.fill")
                                    .foregroundColor(.yellow)
                                Text("\(level.points)")
                                    .fontWeight(.semibold)
                            }
                            Text("\(level.pointsToNext) to next")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Animated progress bar
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 12)
                            
                            RoundedRectangle(cornerRadius: 8)
                                .fill(
                                    LinearGradient(
                                        colors: [Color(hex: "#2ABF5A"), Color(hex: "#1E8E3E")],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: geometry.size.width * (Double(level.progressPercentage) / 100), height: 12)
                                .animation(.spring(response: 0.5, dampingFraction: 0.7), value: level.progressPercentage)
                            
                            // Shimmer effect
                            Rectangle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color.clear, Color.white.opacity(0.3), Color.clear],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: 60)
                                .offset(x: animateHeader ? geometry.size.width : -60)
                                .animation(
                                    Animation.linear(duration: 2)
                                        .repeatForever(autoreverses: false)
                                        .delay(1),
                                    value: animateHeader
                                )
                                .mask(
                                    RoundedRectangle(cornerRadius: 8)
                                        .frame(width: geometry.size.width * (Double(level.progressPercentage) / 100), height: 12)
                                )
                        }
                    }
                    .frame(height: 12)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white)
                        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 2)
                )
            }
        }
    }
    
    // MARK: - Stats Overview
    private var statsOverview: some View {
        Group {
            if let stats = achievementManager.stats {
                HStack(spacing: 12) {
                    statCard(
                        title: "Unlocked",
                        value: "\(stats.totalUnlocked)",
                        icon: "chart.pie.fill",
                        color: .blue
                    )
                    
                    statCard(
                        title: "Points",
                        value: "\(achievementManager.userLevel?.lifetimePoints ?? 0)",
                        icon: "star.fill",
                        color: .yellow
                    )
                    
                    statCard(
                        title: "Rank",
                        value: "#\(achievementManager.userLevel?.rank ?? 0)",
                        icon: "trophy.fill",
                        color: .orange
                    )
                }
            }
        }
    }
    
    private func statCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
    }
    
    // MARK: - Category Filters
    private var categoryFilters: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                categoryPill("All", icon: "square.grid.2x2.fill", isSelected: selectedCategory == "All")
                
                ForEach(achievementManager.categories) { category in
                    categoryPill(
                        category.name,
                        icon: category.icon,
                        color: Color(hex: category.color),
                        isSelected: selectedCategory == category.name
                    )
                }
            }
            .padding(.horizontal)
        }
    }
    
    private func categoryPill(_ name: String, icon: String, color: Color = .gray, isSelected: Bool) -> some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedCategory = name
            }
        }) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                Text(name)
                    .font(.system(size: 14, weight: .medium))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(isSelected ? color : Color.gray.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(isSelected ? color : Color.clear, lineWidth: 2)
                    )
            )
            .foregroundColor(isSelected ? .white : .primary)
            .scaleEffect(isSelected ? 1.05 : 1)
        }
    }
    
    // MARK: - Difficulty Filters
    private var difficultyFilters: some View {
        HStack(spacing: 8) {
            ForEach(["All", "easy", "medium", "hard", "legendary"], id: \.self) { difficulty in
                difficultyChip(difficulty)
            }
        }
    }
    
    private func difficultyChip(_ difficulty: String) -> some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedDifficulty = difficulty
            }
        }) {
            Text(difficulty.capitalized)
                .font(.caption)
                .fontWeight(.medium)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 15)
                        .fill(selectedDifficulty == difficulty ? difficultyColor(difficulty) : Color.gray.opacity(0.1))
                )
                .foregroundColor(selectedDifficulty == difficulty ? .white : .primary)
        }
    }
    
    private func difficultyColor(_ difficulty: String) -> Color {
        switch difficulty.lowercased() {
        case "easy": return .green
        case "medium": return .orange
        case "hard": return .red
        case "legendary": return .purple
        default: return .gray
        }
    }
    
    // MARK: - Search Bar
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("Search achievements...", text: $searchText)
                .textFieldStyle(PlainTextFieldStyle())
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.1))
        )
    }
    
    // MARK: - Achievement Grid
    private var achievementGrid: some View {
        LazyVGrid(columns: gridColumns, spacing: 16) {
            ForEach(filteredAchievements) { achievement in
                AchievementCard(achievement: achievement)
                    .onTapGesture {
                        showingAchievementDetail = achievement
                        HapticManager.impact(style: .light)
                    }
            }
        }
    }
}

// MARK: - Achievement Card
struct AchievementCard: View {
    let achievement: AchievementData
    @State private var isPressed = false
    @State private var showUnlockAnimation = false
    
    var body: some View {
        VStack(spacing: 12) {
            // Icon with unlock status
            ZStack {
                Circle()
                    .fill(
                        achievement.isUnlocked
                            ? LinearGradient(
                                colors: [Color(hex: achievement.categoryColor), Color(hex: achievement.categoryColor).opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                              )
                            : LinearGradient(
                                colors: [Color.gray.opacity(0.2), Color.gray.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                              )
                    )
                    .frame(width: 60, height: 60)
                
                Image(systemName: achievement.icon)
                    .font(.title2)
                    .foregroundColor(achievement.isUnlocked ? .white : .gray)
                    .scaleEffect(showUnlockAnimation ? 1.2 : 1)
                
                if !achievement.isUnlocked && achievement.progress.percentage > 0 {
                    Circle()
                        .trim(from: 0, to: CGFloat(achievement.progress.percentage) / 100)
                        .stroke(
                            Color(hex: achievement.categoryColor),
                            style: StrokeStyle(lineWidth: 3, lineCap: .round)
                        )
                        .frame(width: 58, height: 58)
                        .rotationEffect(.degrees(-90))
                }
            }
            
            VStack(spacing: 4) {
                Text(achievement.displayName)
                    .font(.system(size: 14, weight: .semibold))
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                
                if achievement.isUnlocked || !achievement.isSecret {
                    Text(achievement.displayDescription)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                }
                
                // Points and difficulty
                HStack(spacing: 8) {
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.yellow)
                        Text("\(achievement.points)")
                            .font(.caption2)
                            .fontWeight(.medium)
                    }
                    
                    Circle()
                        .fill(achievement.difficultyColor)
                        .frame(width: 6, height: 6)
                    
                    if !achievement.isUnlocked && achievement.progress.percentage > 0 {
                        Text("\(achievement.progress.percentage)%")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(
                    color: achievement.isUnlocked ? Color(hex: achievement.categoryColor).opacity(0.2) : .black.opacity(0.05),
                    radius: achievement.isUnlocked ? 8 : 5,
                    x: 0,
                    y: 2
                )
        )
        .scaleEffect(isPressed ? 0.95 : 1)
        .opacity(achievement.isUnlocked ? 1 : 0.8)
        .onAppear {
            if achievement.isUnlocked && showUnlockAnimation == false {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.1)) {
                    showUnlockAnimation = true
                }
            }
        }
    }
}

// MARK: - Animated Gradient Background
struct AchievementsAnimatedGradientBackground: View {
    @State private var animateGradient = false
    
    var body: some View {
        LinearGradient(
            colors: [
                Color(hex: "#F5F5F5"),
                Color(hex: "#FFFFFF"),
                Color(hex: "#F0F0F0")
            ],
            startPoint: animateGradient ? .topLeading : .bottomLeading,
            endPoint: animateGradient ? .bottomTrailing : .topTrailing
        )
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.linear(duration: 15).repeatForever(autoreverses: true)) {
                animateGradient.toggle()
            }
        }
    }
}

// MARK: - Scroll Offset Preference Key
struct AchievementsScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

#Preview {
    AchievementsView()
}