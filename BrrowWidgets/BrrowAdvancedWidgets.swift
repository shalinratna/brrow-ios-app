//
//  BrrowAdvancedWidgets.swift
//  BrrowWidgets
//
//  8 Advanced widget types with professional theme
//

import WidgetKit
import SwiftUI
import Charts


// MARK: - 1. Quick Stats Widget (Small/Medium)
struct QuickStatsWidget: View {
    let data: WidgetData
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        switch family {
        case .systemSmall:
            SmallQuickStats(data: data)
        case .systemMedium:
            MediumQuickStats(data: data)
        default:
            SmallQuickStats(data: data)
        }
    }
}

struct SmallQuickStats: View {
    let data: WidgetData
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "cube.box.fill")
                    .font(.system(size: 24))
                    .foregroundColor(Color(hex: "2ABF5A"))
                
                Spacer()
                
                Text("ACTIVE")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(Color(hex: "2ABF5A"))
            }
            
            Text("\(data.activeListings)")
                .font(.system(size: 42, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
            
            HStack(spacing: 4) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 12))
                    .foregroundColor(.green)
                
                Text("+3 this week")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .conditionalContainerBackgroundClear()
    }
}

struct MediumQuickStats: View {
    let data: WidgetData
    
    var body: some View {
        HStack(spacing: 0) {
            // Main stat
            VStack(alignment: .leading, spacing: 8) {
                Label("Active Listings", systemImage: "cube.box.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color(hex: "2ABF5A"))
                
                Text("\(data.activeListings)")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                
                HStack {
                    StatChip(value: "$\(Int(data.todaysEarnings))", label: "Today")
                    StatChip(value: "\(data.nearbyItems)", label: "Nearby")
                    StatChip(value: "\(data.unreadMessages)", label: "Msgs")
                }
            }
            .padding()
            
            Spacer()
            
            // Mini chart
            VStack {
                Text("7 Day Trend")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
                
                MiniChartView()
                    .frame(width: 100, height: 60)
            }
            .padding()
        }
        .conditionalContainerBackgroundClear()
    }
}

// MARK: - 2. Earnings Tracker Widget (Medium/Large)
struct EarningsWidget: View {
    let earnings: EarningsData
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        Group {
            if family == .systemMedium {
                MediumEarningsView(earnings: earnings)
            } else {
                LargeEarningsView(earnings: earnings)
            }
        }
        .conditionalContainerBackgroundClear()
    }
}

struct MediumEarningsView: View {
    let earnings: EarningsData
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 12) {
                Label("Earnings", systemImage: "dollarsign.circle.fill")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Color(hex: "2ABF5A"))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("$\(earnings.todayAmount, specifier: "%.2f")")
                        .font(.system(size: 32, weight: .bold))
                    
                    Text("Today")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                
                HStack(spacing: 16) {
                    EarningsStat(label: "Week", value: "$\(Int(earnings.weekAmount))")
                    EarningsStat(label: "Month", value: "$\(Int(earnings.monthAmount))")
                }
            }
            .padding()
            
            Spacer()
            
            // Progress Circle
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 8)
                
                Circle()
                    .trim(from: 0, to: earnings.goalProgress)
                    .stroke(Color(hex: "2ABF5A"), lineWidth: 8)
                    .rotationEffect(.degrees(-90))
                
                VStack(spacing: 2) {
                    Text("\(Int(earnings.goalProgress * 100))%")
                        .font(.system(size: 20, weight: .bold))
                    Text("of goal")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
            }
            .frame(width: 80, height: 80)
            .padding()
        }
    }
}

// MARK: - 3. Active Rentals Widget (Small/Medium/Large)
struct ActiveRentalsWidget: View {
    let rentals: [ActiveRental]
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        ZStack {
            ContainerRelativeShape()
                .fill(Color(.systemBackground))
            
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Label("Active Rentals", systemImage: "clock.fill")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(Color(hex: "2ABF5A"))
                    
                    Spacer()
                    
                    if !rentals.isEmpty {
                        Text("\(rentals.count)")
                            .font(.system(size: 14, weight: .medium))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color(hex: "2ABF5A").opacity(0.2))
                            .cornerRadius(8)
                    }
                }
                
                if rentals.isEmpty {
                    Spacer()
                    
                    VStack(spacing: 8) {
                        Image(systemName: "clock.badge.checkmark")
                            .font(.system(size: 32))
                            .foregroundColor(.gray.opacity(0.5))
                        
                        Text("No active rentals")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    
                    Spacer()
                } else {
                    ForEach(rentals.prefix(family == .systemSmall ? 1 : 3)) { rental in
                        RentalRow(rental: rental, compact: family == .systemSmall)
                    }
                }
            }
            .padding()
        }
    }
}

// MARK: - 4. Nearby Items Map Widget (Medium/Large)
struct NearbyMapWidget: View {
    let items: [NearbyItem]
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        ZStack {
            // Map placeholder background
            Image("map_placeholder")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .overlay(Color.black.opacity(0.3))
            
            VStack {
                HStack {
                    Label("\(items.count) Nearby", systemImage: "location.fill")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .padding(8)
                        .background(Color.black.opacity(0.5))
                        .cornerRadius(8)
                    
                    Spacer()
                }
                
                Spacer()
                
                if family == .systemLarge {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(items.prefix(5)) { item in
                                NearbyItemCard(item: item)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .padding()
        }
    }
}

// MARK: - 5. Messages & Activity Widget (Medium/Large)
struct ActivityWidget: View {
    let activities: [Activity]
    let unreadCount: Int
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Label("Activity", systemImage: "bell.fill")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Color(hex: "2ABF5A"))
                
                Spacer()
                
                if unreadCount > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "envelope.badge.fill")
                        Text("\(unreadCount)")
                    }
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.red)
                    .cornerRadius(12)
                }
            }
            .padding()
            
            Divider()
            
            // Activities
            if activities.isEmpty {
                Spacer()
                
                Image(systemName: "bell.slash")
                    .font(.system(size: 32))
                    .foregroundColor(.gray.opacity(0.5))
                
                Text("No recent activity")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                
                Spacer()
            } else {
                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(activities.prefix(family == .systemMedium ? 2 : 5)) { activity in
                            ActivityRow(activity: activity)
                        }
                    }
                    .padding()
                }
            }
        }
        .background(Color(.systemBackground))
    }
}

// MARK: - 6. Achievements Progress Widget (Small/Medium)
struct AchievementsWidget: View {
    let achievementData: AchievementWidgetData
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.purple.opacity(0.1), Color.blue.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            if family == .systemSmall {
                SmallAchievementView(data: achievementData)
            } else {
                MediumAchievementView(data: achievementData)
            }
        }
    }
}

struct SmallAchievementView: View {
    let data: AchievementWidgetData
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "trophy.fill")
                .font(.system(size: 32))
                .foregroundColor(.orange)
            
            Text("Level \(data.currentLevel)")
                .font(.system(size: 20, weight: .bold))
            
            ProgressView(value: data.levelProgress)
                .tint(Color(hex: "2ABF5A"))
            
            Text("\(data.totalPoints) pts")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
        }
        .padding()
    }
}

struct LargeEarningsView: View {
    let earnings: EarningsData
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Label("Earnings Overview", systemImage: "dollarsign.circle.fill")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Color(hex: "2ABF5A"))
                
                Spacer()
                
                // Goal Progress
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 6)
                        .frame(width: 60, height: 60)
                    
                    Circle()
                        .trim(from: 0, to: earnings.goalProgress)
                        .stroke(Color(hex: "2ABF5A"), lineWidth: 6)
                        .rotationEffect(.degrees(-90))
                        .frame(width: 60, height: 60)
                    
                    Text("\(Int(earnings.goalProgress * 100))%")
                        .font(.system(size: 16, weight: .bold))
                }
            }
            
            // Earnings Grid
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                VStack(spacing: 4) {
                    Text("Today")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    Text("$\(earnings.todayAmount, specifier: "%.2f")")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(Color(hex: "2ABF5A"))
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.gray.opacity(0.05))
                .cornerRadius(8)
                
                VStack(spacing: 4) {
                    Text("Week")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    Text("$\(Int(earnings.weekAmount))")
                        .font(.system(size: 18, weight: .bold))
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.gray.opacity(0.05))
                .cornerRadius(8)
                
                VStack(spacing: 4) {
                    Text("Month")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    Text("$\(Int(earnings.monthAmount))")
                        .font(.system(size: 18, weight: .bold))
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.gray.opacity(0.05))
                .cornerRadius(8)
            }
            
            // Chart Placeholder
            VStack(alignment: .leading, spacing: 8) {
                Text("30 Day Trend")
                    .font(.system(size: 14, weight: .semibold))
                
                // Simple line chart placeholder
                GeometryReader { geometry in
                    Path { path in
                        let points: [CGFloat] = [0.2, 0.3, 0.5, 0.4, 0.6, 0.8, 0.7, 0.9, 0.85, 0.95]
                        let width = geometry.size.width
                        let height = geometry.size.height
                        
                        for (index, point) in points.enumerated() {
                            let x = width * CGFloat(index) / CGFloat(points.count - 1)
                            let y = height * (1 - point)
                            
                            if index == 0 {
                                path.move(to: CGPoint(x: x, y: y))
                            } else {
                                path.addLine(to: CGPoint(x: x, y: y))
                            }
                        }
                    }
                    .stroke(Color(hex: "2ABF5A"), lineWidth: 2)
                }
                .frame(height: 100)
                .background(Color.gray.opacity(0.05))
                .cornerRadius(8)
            }
            
            Spacer()
        }
        .padding()
    }
}

// MARK: - 7. Savings Calculator Widget (Medium)
struct SavingsWidget: View {
    let savings: SavingsData
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 12) {
                Label("Saved", systemImage: "leaf.fill")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.green)
                
                Text("$\(savings.totalSaved, specifier: "%.0f")")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                
                Text("vs buying new")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                
                HStack(spacing: 4) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 12))
                    Text("+\(savings.percentageSaved)% this month")
                        .font(.system(size: 12))
                }
                .foregroundColor(.green)
            }
            .padding()
            
            Spacer()
            
            // Eco impact
            VStack(spacing: 8) {
                Image(systemName: "leaf.circle.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.green)
                
                Text("\(savings.itemsSaved)")
                    .font(.system(size: 24, weight: .bold))
                
                Text("items saved\nfrom landfill")
                    .font(.system(size: 10))
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
            }
            .padding()
        }
        .background(Color(.systemBackground))
    }
}

// MARK: - 8. Community Impact Widget (Large)
struct CommunityWidget: View {
    let community: CommunityData
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading) {
                    Text("Community Impact")
                        .font(.system(size: 20, weight: .bold))
                    
                    Text("Your neighborhood sharing stats")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "person.3.fill")
                    .font(.system(size: 24))
                    .foregroundColor(Color(hex: "2ABF5A"))
            }
            
            // Stats Grid
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                CommunityStatCard(
                    icon: "person.2.fill",
                    value: "\(community.neighborsHelped)",
                    label: "Neighbors Helped",
                    color: .blue
                )
                
                CommunityStatCard(
                    icon: "hands.clap.fill",
                    value: "\(community.itemsShared)",
                    label: "Items Shared",
                    color: .green
                )
                
                CommunityStatCard(
                    icon: "star.fill",
                    value: String(format: "%.1f", community.averageRating),
                    label: "Avg Rating",
                    color: .orange
                )
                
                CommunityStatCard(
                    icon: "dollarsign.circle.fill",
                    value: "$\(Int(community.moneySavedCommunity))",
                    label: "Community Saved",
                    color: Color(hex: "2ABF5A")
                )
            }
            
            // Top items
            VStack(alignment: .leading, spacing: 8) {
                Text("Popular in your area")
                    .font(.system(size: 14, weight: .semibold))
                
                HStack {
                    ForEach(community.topCategories, id: \.self) { category in
                        CategoryChip(category: category)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
    }
}

// MARK: - Supporting Views
struct StatChip: View {
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 14, weight: .bold))
            Text(label)
                .font(.system(size: 10))
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(6)
    }
}

struct MiniChartView: View {
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                let points = [0.2, 0.4, 0.3, 0.6, 0.5, 0.8, 0.7]
                
                for (index, point) in points.enumerated() {
                    let x = geometry.size.width * CGFloat(index) / CGFloat(points.count - 1)
                    let y = geometry.size.height * (1 - point)
                    
                    if index == 0 {
                        path.move(to: CGPoint(x: x, y: y))
                    } else {
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                }
            }
            .stroke(Color(hex: "2ABF5A"), lineWidth: 2)
        }
    }
}

struct RentalRow: View {
    let rental: ActiveRental
    let compact: Bool
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: rental.icon)
                .font(.system(size: compact ? 14 : 16))
                .foregroundColor(Color(hex: "2ABF5A"))
                .frame(width: compact ? 20 : 30)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(rental.itemName)
                    .font(.system(size: compact ? 12 : 14, weight: .medium))
                    .lineLimit(1)
                
                if !compact {
                    Text(rental.renterName)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(rental.timeRemaining)
                    .font(.system(size: compact ? 10 : 12, weight: .medium))
                    .foregroundColor(rental.isOverdue ? .red : .secondary)
                
                if !compact {
                    Text("$\(rental.earnings, specifier: "%.0f")")
                        .font(.system(size: 12))
                        .foregroundColor(Color(hex: "2ABF5A"))
                }
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 10)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
    }
}

struct NearbyItemCard: View {
    let item: NearbyItem
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: item.icon)
                .font(.system(size: 24))
                .foregroundColor(.white)
            
            Text(item.name)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white)
                .lineLimit(1)
            
            Text(item.distance)
                .font(.system(size: 10))
                .foregroundColor(.white.opacity(0.8))
        }
        .frame(width: 80)
        .padding(.vertical, 12)
        .background(Color.white.opacity(0.2))
        .cornerRadius(12)
    }
}

struct ActivityRow: View {
    let activity: Activity
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: activity.icon)
                .font(.system(size: 16))
                .foregroundColor(activity.color)
                .frame(width: 30, height: 30)
                .background(activity.color.opacity(0.1))
                .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(activity.title)
                    .font(.system(size: 14, weight: .medium))
                    .lineLimit(1)
                
                Text(activity.time)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

struct EarningsStat: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(.system(size: 16, weight: .bold))
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
        }
    }
}

struct MediumAchievementView: View {
    let data: AchievementWidgetData
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 12) {
                Label("Achievements", systemImage: "trophy.fill")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.orange)
                
                HStack(spacing: 16) {
                    VStack(alignment: .leading) {
                        Text("Level \(data.currentLevel)")
                            .font(.system(size: 24, weight: .bold))
                        
                        ProgressView(value: data.levelProgress)
                            .frame(width: 100)
                            .tint(Color(hex: "2ABF5A"))
                    }
                    
                    VStack {
                        Text("\(data.totalPoints)")
                            .font(.system(size: 20, weight: .bold))
                        Text("points")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                }
                
                HStack {
                    ForEach(data.recentBadges, id: \.self) { badge in
                        Image(systemName: badge)
                            .font(.system(size: 20))
                            .foregroundColor(.orange)
                    }
                }
            }
            .padding()
            
            Spacer()
            
            // Next achievement preview
            if let next = data.nextAchievement {
                VStack {
                    Image(systemName: next.icon)
                        .font(.system(size: 30))
                        .foregroundColor(.gray)
                    
                    Text(next.name)
                        .font(.system(size: 12))
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                    
                    Text("\(next.progress)%")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(Color(hex: "2ABF5A"))
                }
                .padding()
                .frame(maxWidth: 100)
            }
        }
    }
}

struct CommunityStatCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
            
            Text(value)
                .font(.system(size: 20, weight: .bold))
            
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
}

struct CategoryChip: View {
    let category: String
    
    var body: some View {
        Text(category)
            .font(.system(size: 12))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color(hex: "2ABF5A").opacity(0.1))
            .foregroundColor(Color(hex: "2ABF5A"))
            .cornerRadius(6)
    }
}

// MARK: - Data Models
struct EarningsData {
    let todayAmount: Double
    let weekAmount: Double
    let monthAmount: Double
    let goalProgress: Double
}

struct ActiveRental: Identifiable {
    let id = UUID()
    let itemName: String
    let renterName: String
    let timeRemaining: String
    let earnings: Double
    let icon: String
    let isOverdue: Bool
}

struct NearbyItem: Identifiable {
    let id = UUID()
    let name: String
    let distance: String
    let icon: String
}

struct Activity: Identifiable {
    let id = UUID()
    let title: String
    let time: String
    let icon: String
    let color: Color
}

struct AchievementWidgetData {
    let currentLevel: Int
    let levelProgress: Double
    let totalPoints: Int
    let recentBadges: [String]
    let nextAchievement: NextAchievement?
}

struct NextAchievement {
    let name: String
    let icon: String
    let progress: Int
}

struct SavingsData {
    let totalSaved: Double
    let percentageSaved: Int
    let itemsSaved: Int
}

struct CommunityData {
    let neighborsHelped: Int
    let itemsShared: Int
    let averageRating: Double
    let moneySavedCommunity: Double
    let topCategories: [String]
}

