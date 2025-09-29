//
//  AdvancedWidgetBundle.swift
//  BrrowWidgets
//
//  Bundle for all 8 advanced widget types
//

import WidgetKit
import SwiftUI

// MARK: - Advanced Widget Bundle
// @main - Commented out to avoid conflicts, use BrrowWidgets as main bundle
struct BrrowAdvancedWidgetBundle: WidgetBundle {
    var body: some Widget {
        // Basic stats widget
        BrrowWidget()
        
        // Quick stats widget
        QuickStatsWidgetConfiguration()
        
        // Earnings tracker widget
        EarningsWidgetConfiguration()
        
        // Active rentals widget
        ActiveRentalsWidgetConfiguration()
        
        // Nearby items map widget
        NearbyMapWidgetConfiguration()
        
        // Messages & activity widget
        ActivityWidgetConfiguration()
        
        // Achievements progress widget
        AchievementsWidgetConfiguration()
        
        // Savings calculator widget
        SavingsWidgetConfiguration()
        
        // Community impact widget
        CommunityWidgetConfiguration()
    }
}

// MARK: - 1. Quick Stats Widget Configuration
struct QuickStatsWidgetConfiguration: Widget {
    let kind: String = "QuickStatsWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: BrrowProvider()) { entry in
            QuickStatsWidget(data: entry.widgetData)
        }
        .configurationDisplayName("Quick Stats")
        .description("View your active listings at a glance")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - 2. Earnings Widget Configuration
struct EarningsWidgetConfiguration: Widget {
    let kind: String = "EarningsWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: EarningsProvider()) { entry in
            EarningsWidget(earnings: entry.earningsData)
        }
        .configurationDisplayName("Earnings Tracker")
        .description("Track your daily, weekly, and monthly earnings")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}

// MARK: - 3. Active Rentals Widget Configuration
struct ActiveRentalsWidgetConfiguration: Widget {
    let kind: String = "ActiveRentalsWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: RentalsProvider()) { entry in
            ActiveRentalsWidget(rentals: entry.rentals)
        }
        .configurationDisplayName("Active Rentals")
        .description("Monitor your active rentals and due dates")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// MARK: - 4. Nearby Map Widget Configuration
struct NearbyMapWidgetConfiguration: Widget {
    let kind: String = "NearbyMapWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: NearbyProvider()) { entry in
            NearbyMapWidget(items: entry.items)
        }
        .configurationDisplayName("Nearby Items")
        .description("See items available near you")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}

// MARK: - 5. Activity Widget Configuration
struct ActivityWidgetConfiguration: Widget {
    let kind: String = "ActivityWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ActivityProvider()) { entry in
            ActivityWidget(activities: entry.activities, unreadCount: entry.unreadCount)
        }
        .configurationDisplayName("Messages & Activity")
        .description("Stay updated with messages and recent activity")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}

// MARK: - 6. Achievements Widget Configuration
struct AchievementsWidgetConfiguration: Widget {
    let kind: String = "AchievementsWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: AchievementsProvider()) { entry in
            AchievementsWidget(achievementData: entry.achievementData)
        }
        .configurationDisplayName("Achievements")
        .description("Track your progress and achievements")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - 7. Savings Widget Configuration
struct SavingsWidgetConfiguration: Widget {
    let kind: String = "SavingsWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SavingsProvider()) { entry in
            SavingsWidget(savings: entry.savingsData)
        }
        .configurationDisplayName("Savings Calculator")
        .description("See how much you've saved by renting")
        .supportedFamilies([.systemMedium])
    }
}

// MARK: - 8. Community Widget Configuration
struct CommunityWidgetConfiguration: Widget {
    let kind: String = "CommunityWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CommunityProvider()) { entry in
            CommunityWidget(community: entry.communityData)
        }
        .configurationDisplayName("Community Impact")
        .description("Your impact on the community")
        .supportedFamilies([.systemLarge])
    }
}

// MARK: - Timeline Entries
struct EarningsEntry: TimelineEntry {
    let date: Date
    let earningsData: EarningsData
}

struct RentalsEntry: TimelineEntry {
    let date: Date
    let rentals: [ActiveRental]
}

struct NearbyEntry: TimelineEntry {
    let date: Date
    let items: [NearbyItem]
}

struct ActivityEntry: TimelineEntry {
    let date: Date
    let activities: [Activity]
    let unreadCount: Int
}

struct AchievementsEntry: TimelineEntry {
    let date: Date
    let achievementData: AchievementWidgetData
}

struct SavingsEntry: TimelineEntry {
    let date: Date
    let savingsData: SavingsData
}

struct CommunityEntry: TimelineEntry {
    let date: Date
    let communityData: CommunityData
}

// MARK: - Specialized Providers
struct EarningsProvider: TimelineProvider {
    private let appGroupIdentifier = "group.com.brrowapp.widgets"
    
    func placeholder(in context: Context) -> EarningsEntry {
        EarningsEntry(date: Date(), earningsData: EarningsData(
            todayAmount: 0,
            weekAmount: 0,
            monthAmount: 0,
            goalProgress: 0
        ))
    }
    
    func getSnapshot(in context: Context, completion: @escaping (EarningsEntry) -> ()) {
        let entry = EarningsEntry(date: Date(), earningsData: fetchEarningsData())
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let currentDate = Date()
        let earningsData = fetchEarningsData()
        let entry = EarningsEntry(date: currentDate, earningsData: earningsData)
        
        let timeline = Timeline(entries: [entry], policy: .after(
            Calendar.current.date(byAdding: .hour, value: 1, to: currentDate)!
        ))
        completion(timeline)
    }
    
    private func fetchEarningsData() -> EarningsData {
        guard let defaults = UserDefaults(suiteName: appGroupIdentifier) else {
            return EarningsData(todayAmount: 0, weekAmount: 0, monthAmount: 0, goalProgress: 0)
        }
        
        return EarningsData(
            todayAmount: defaults.double(forKey: "widget.earnings.today"),
            weekAmount: defaults.double(forKey: "widget.earnings.week"),
            monthAmount: defaults.double(forKey: "widget.earnings.month"),
            goalProgress: defaults.double(forKey: "widget.earnings.goalProgress")
        )
    }
}

struct RentalsProvider: TimelineProvider {
    private let appGroupIdentifier = "group.com.brrowapp.widgets"
    
    func placeholder(in context: Context) -> RentalsEntry {
        RentalsEntry(date: Date(), rentals: [])
    }
    
    func getSnapshot(in context: Context, completion: @escaping (RentalsEntry) -> ()) {
        let entry = RentalsEntry(date: Date(), rentals: fetchRentals())
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let currentDate = Date()
        let rentals = fetchRentals()
        let entry = RentalsEntry(date: currentDate, rentals: rentals)
        
        let timeline = Timeline(entries: [entry], policy: .after(
            Calendar.current.date(byAdding: .minute, value: 30, to: currentDate)!
        ))
        completion(timeline)
    }
    
    private func fetchRentals() -> [ActiveRental] {
        // In production, fetch from shared storage
        return [
            ActiveRental(
                itemName: "Power Drill",
                renterName: "John D.",
                timeRemaining: "2 hours",
                earnings: 15.00,
                icon: "hammer.fill",
                isOverdue: false
            ),
            ActiveRental(
                itemName: "Ladder",
                renterName: "Sarah M.",
                timeRemaining: "1 day",
                earnings: 25.00,
                icon: "arrow.up.to.line",
                isOverdue: false
            )
        ]
    }
}

struct NearbyProvider: TimelineProvider {
    private let appGroupIdentifier = "group.com.brrowapp.widgets"
    
    func placeholder(in context: Context) -> NearbyEntry {
        NearbyEntry(date: Date(), items: [])
    }
    
    func getSnapshot(in context: Context, completion: @escaping (NearbyEntry) -> ()) {
        let entry = NearbyEntry(date: Date(), items: fetchNearbyItems())
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let currentDate = Date()
        let items = fetchNearbyItems()
        let entry = NearbyEntry(date: currentDate, items: items)
        
        let timeline = Timeline(entries: [entry], policy: .after(
            Calendar.current.date(byAdding: .hour, value: 2, to: currentDate)!
        ))
        completion(timeline)
    }
    
    private func fetchNearbyItems() -> [NearbyItem] {
        return [
            NearbyItem(name: "Bike", distance: "0.5 mi", icon: "bicycle"),
            NearbyItem(name: "Camera", distance: "0.8 mi", icon: "camera.fill"),
            NearbyItem(name: "Tent", distance: "1.2 mi", icon: "tent.fill")
        ]
    }
}

struct ActivityProvider: TimelineProvider {
    private let appGroupIdentifier = "group.com.brrowapp.widgets"
    
    func placeholder(in context: Context) -> ActivityEntry {
        ActivityEntry(date: Date(), activities: [], unreadCount: 0)
    }
    
    func getSnapshot(in context: Context, completion: @escaping (ActivityEntry) -> ()) {
        let entry = ActivityEntry(date: Date(), activities: fetchActivities(), unreadCount: fetchUnreadCount())
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let currentDate = Date()
        let activities = fetchActivities()
        let unreadCount = fetchUnreadCount()
        let entry = ActivityEntry(date: currentDate, activities: activities, unreadCount: unreadCount)
        
        let timeline = Timeline(entries: [entry], policy: .after(
            Calendar.current.date(byAdding: .minute, value: 15, to: currentDate)!
        ))
        completion(timeline)
    }
    
    private func fetchActivities() -> [Activity] {
        return [
            Activity(title: "New rental request", time: "5 min ago", icon: "bell.fill", color: .blue),
            Activity(title: "Payment received", time: "1 hour ago", icon: "dollarsign.circle.fill", color: .green),
            Activity(title: "Review posted", time: "2 hours ago", icon: "star.fill", color: .orange)
        ]
    }
    
    private func fetchUnreadCount() -> Int {
        guard let defaults = UserDefaults(suiteName: appGroupIdentifier) else { return 0 }
        return defaults.integer(forKey: "widget.unreadMessages")
    }
}

struct AchievementsProvider: TimelineProvider {
    private let appGroupIdentifier = "group.com.brrowapp.widgets"
    
    func placeholder(in context: Context) -> AchievementsEntry {
        AchievementsEntry(date: Date(), achievementData: AchievementWidgetData(
            currentLevel: 1,
            levelProgress: 0,
            totalPoints: 0,
            recentBadges: [],
            nextAchievement: nil
        ))
    }
    
    func getSnapshot(in context: Context, completion: @escaping (AchievementsEntry) -> ()) {
        let entry = AchievementsEntry(date: Date(), achievementData: fetchAchievementData())
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let currentDate = Date()
        let achievementData = fetchAchievementData()
        let entry = AchievementsEntry(date: currentDate, achievementData: achievementData)
        
        let timeline = Timeline(entries: [entry], policy: .after(
            Calendar.current.date(byAdding: .hour, value: 4, to: currentDate)!
        ))
        completion(timeline)
    }
    
    private func fetchAchievementData() -> AchievementWidgetData {
        return AchievementWidgetData(
            currentLevel: 5,
            levelProgress: 0.65,
            totalPoints: 1250,
            recentBadges: ["star.fill", "trophy.fill", "rosette"],
            nextAchievement: NextAchievement(name: "Power Lender", icon: "bolt.fill", progress: 75)
        )
    }
}

struct SavingsProvider: TimelineProvider {
    private let appGroupIdentifier = "group.com.brrowapp.widgets"
    
    func placeholder(in context: Context) -> SavingsEntry {
        SavingsEntry(date: Date(), savingsData: SavingsData(
            totalSaved: 0,
            percentageSaved: 0,
            itemsSaved: 0
        ))
    }
    
    func getSnapshot(in context: Context, completion: @escaping (SavingsEntry) -> ()) {
        let entry = SavingsEntry(date: Date(), savingsData: fetchSavingsData())
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let currentDate = Date()
        let savingsData = fetchSavingsData()
        let entry = SavingsEntry(date: currentDate, savingsData: savingsData)
        
        let timeline = Timeline(entries: [entry], policy: .after(
            Calendar.current.date(byAdding: .hour, value: 6, to: currentDate)!
        ))
        completion(timeline)
    }
    
    private func fetchSavingsData() -> SavingsData {
        return SavingsData(
            totalSaved: 450.00,
            percentageSaved: 15,
            itemsSaved: 12
        )
    }
}

struct CommunityProvider: TimelineProvider {
    private let appGroupIdentifier = "group.com.brrowapp.widgets"
    
    func placeholder(in context: Context) -> CommunityEntry {
        CommunityEntry(date: Date(), communityData: CommunityData(
            neighborsHelped: 0,
            itemsShared: 0,
            averageRating: 0,
            moneySavedCommunity: 0,
            topCategories: []
        ))
    }
    
    func getSnapshot(in context: Context, completion: @escaping (CommunityEntry) -> ()) {
        let entry = CommunityEntry(date: Date(), communityData: fetchCommunityData())
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let currentDate = Date()
        let communityData = fetchCommunityData()
        let entry = CommunityEntry(date: currentDate, communityData: communityData)
        
        let timeline = Timeline(entries: [entry], policy: .after(
            Calendar.current.date(byAdding: .day, value: 1, to: currentDate)!
        ))
        completion(timeline)
    }
    
    private func fetchCommunityData() -> CommunityData {
        return CommunityData(
            neighborsHelped: 23,
            itemsShared: 45,
            averageRating: 4.8,
            moneySavedCommunity: 2850.00,
            topCategories: ["Tools", "Sports", "Garden"]
        )
    }
}