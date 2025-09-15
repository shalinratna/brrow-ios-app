//
//  BrrowWidgets.swift
//  Brrow
//
//  iOS Widgets for Home Screen, Lock Screen & StandBy
//

import SwiftUI
import WidgetKit

// MARK: - Widget Bundle
// Note: This should be moved to a separate Widget Extension target
// For now, commenting out @main to avoid build conflicts
// @main
struct BrrowWidgetBundle: WidgetBundle {
    var body: some Widget {
        BrrowEarningsWidget()
        BrrowNearbyWidget()
        BrrowKarmaWidget()
        BrrowActivityWidget()
    }
}

// MARK: - Earnings Widget
struct BrrowEarningsWidget: Widget {
    let kind: String = "BrrowEarningsWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: EarningsProvider()) { entry in
            EarningsWidgetView(entry: entry)
        }
        .configurationDisplayName("Earnings")
        .description("Track your Brrow earnings at a glance")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryRectangular, .accessoryInline])
    }
}

struct EarningsProvider: TimelineProvider {
    func placeholder(in context: Context) -> EarningsEntry {
        EarningsEntry(date: Date(), totalEarnings: 1250.00, todayEarnings: 45.00, availableBalance: 234.50)
    }
    
    func getSnapshot(in context: Context, completion: @escaping (EarningsEntry) -> ()) {
        let entry = EarningsEntry(date: Date(), totalEarnings: 1250.00, todayEarnings: 45.00, availableBalance: 234.50)
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<EarningsEntry>) -> ()) {
        // In real app, fetch from API
        let entry = EarningsEntry(date: Date(), totalEarnings: 1250.00, todayEarnings: 45.00, availableBalance: 234.50)
        let timeline = Timeline(entries: [entry], policy: .atEnd)
        completion(timeline)
    }
}

struct EarningsEntry: TimelineEntry {
    let date: Date
    let totalEarnings: Double
    let todayEarnings: Double
    let availableBalance: Double
}

struct EarningsWidgetView: View {
    var entry: EarningsProvider.Entry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        switch family {
        case .systemSmall:
            smallEarningsWidget
        case .systemMedium:
            mediumEarningsWidget
        case .accessoryRectangular:
            lockScreenEarningsWidget
        case .accessoryInline:
            inlineEarningsWidget
        default:
            smallEarningsWidget
        }
    }
    
    private var smallEarningsWidget: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "dollarsign.circle.fill")
                    .foregroundColor(Color(hex: "#2ABF5A"))
                Spacer()
                Text("Brrow")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .leading, spacing: 4) {
                Text("$\(entry.totalEarnings, specifier: "%.0f")")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Total Earned")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack {
                    Text("+$\(entry.todayEarnings, specifier: "%.0f")")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(Color(hex: "#2ABF5A"))
                    Text("today")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .containerBackground(.ultraThinMaterial, for: .widget)
        .widgetURL(URL(string: "brrow://earnings"))
    }
    
    private var mediumEarningsWidget: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "dollarsign.circle.fill")
                        .foregroundColor(Color(hex: "#2ABF5A"))
                    Text("Earnings")
                        .font(.headline)
                        .fontWeight(.semibold)
                    Spacer()
                }
                
                HStack {
                    VStack(alignment: .leading) {
                        Text("$\(entry.totalEarnings, specifier: "%.0f")")
                            .font(.title2)
                            .fontWeight(.bold)
                        Text("Total")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing) {
                        Text("$\(entry.availableBalance, specifier: "%.0f")")
                            .font(.title3)
                            .fontWeight(.semibold)
                        Text("Available")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                HStack {
                    Image(systemName: "arrow.up.right")
                        .font(.caption)
                        .foregroundColor(Color(hex: "#2ABF5A"))
                    Text("+$\(entry.todayEarnings, specifier: "%.0f") today")
                        .font(.caption)
                        .foregroundColor(Color(hex: "#2ABF5A"))
                    Spacer()
                }
            }
        }
        .padding()
        .containerBackground(.ultraThinMaterial, for: .widget)
        .widgetURL(URL(string: "brrow://earnings"))
    }
    
    private var lockScreenEarningsWidget: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Brrow Earnings")
                    .font(.caption)
                    .fontWeight(.medium)
                
                Text("$\(entry.totalEarnings, specifier: "%.0f")")
                    .font(.title3)
                    .fontWeight(.bold)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("+$\(entry.todayEarnings, specifier: "%.0f")")
                    .font(.caption)
                    .fontWeight(.medium)
                Text("today")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .containerBackground(.clear, for: .widget)
        .widgetURL(URL(string: "brrow://earnings"))
    }
    
    private var inlineEarningsWidget: some View {
        Text("Brrow: $\(entry.totalEarnings, specifier: "%.0f") (+$\(entry.todayEarnings, specifier: "%.0f") today)")
            .containerBackground(.clear, for: .widget)
            .widgetURL(URL(string: "brrow://earnings"))
    }
}

// MARK: - Nearby Items Widget
struct BrrowNearbyWidget: Widget {
    let kind: String = "BrrowNearbyWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: NearbyProvider()) { entry in
            NearbyWidgetView(entry: entry)
        }
        .configurationDisplayName("Nearby Items")
        .description("See what's available to borrow nearby")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}

struct NearbyProvider: TimelineProvider {
    func placeholder(in context: Context) -> NearbyEntry {
        NearbyEntry(date: Date(), items: mockNearbyItems)
    }
    
    func getSnapshot(in context: Context, completion: @escaping (NearbyEntry) -> ()) {
        let entry = NearbyEntry(date: Date(), items: mockNearbyItems)
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<NearbyEntry>) -> ()) {
        let entry = NearbyEntry(date: Date(), items: mockNearbyItems)
        let timeline = Timeline(entries: [entry], policy: .atEnd)
        completion(timeline)
    }
}

struct NearbyEntry: TimelineEntry {
    let date: Date
    let items: [NearbyItem]
}

struct NearbyItem {
    let title: String
    let price: String
    let distance: String
    let imageUrl: String?
}

let mockNearbyItems = [
    NearbyItem(title: "Mountain Bike", price: "FREE", distance: "0.3 mi", imageUrl: nil),
    NearbyItem(title: "Power Drill", price: "$15/day", distance: "0.5 mi", imageUrl: nil),
    NearbyItem(title: "Camera", price: "$25/day", distance: "0.8 mi", imageUrl: nil),
    NearbyItem(title: "Ladder", price: "$10/day", distance: "1.2 mi", imageUrl: nil)
]

struct NearbyWidgetView: View {
    var entry: NearbyProvider.Entry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "location.circle.fill")
                    .foregroundColor(Color(hex: "#2ABF5A"))
                Text("Nearby to Borrow")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: family == .systemLarge ? 2 : 1), spacing: 8) {
                ForEach(Array(entry.items.prefix(family == .systemLarge ? 4 : 2).enumerated()), id: \.offset) { index, item in
                    HStack(spacing: 8) {
                        Rectangle()
                            .fill(Color(hex: "#A8E6B0").opacity(0.3))
                            .frame(width: 40, height: 40)
                            .cornerRadius(8)
                            .overlay(
                                Image(systemName: "cube.box")
                                    .foregroundColor(Color(hex: "#2ABF5A"))
                            )
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.title)
                                .font(.caption)
                                .fontWeight(.medium)
                                .lineLimit(1)
                            
                            HStack {
                                Text(item.price)
                                    .font(.caption2)
                                    .fontWeight(.semibold)
                                    .foregroundColor(item.price == "FREE" ? Color(hex: "#2ABF5A") : .primary)
                                
                                Spacer()
                                
                                Text(item.distance)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Spacer()
                    }
                }
            }
            
            Spacer()
        }
        .padding()
        .containerBackground(.ultraThinMaterial, for: .widget)
        .widgetURL(URL(string: "brrow://discover"))
    }
}

// MARK: - Karma Credits Widget
struct BrrowKarmaWidget: Widget {
    let kind: String = "BrrowKarmaWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: KarmaProvider()) { entry in
            KarmaWidgetView(entry: entry)
        }
        .configurationDisplayName("Karma Credits")
        .description("Track your community karma points")
        .supportedFamilies([.systemSmall, .accessoryCircular])
    }
}

struct KarmaProvider: TimelineProvider {
    func placeholder(in context: Context) -> KarmaEntry {
        KarmaEntry(date: Date(), karmaPoints: 1250, todayPoints: 45, level: "Gold Neighbor")
    }
    
    func getSnapshot(in context: Context, completion: @escaping (KarmaEntry) -> ()) {
        let entry = KarmaEntry(date: Date(), karmaPoints: 1250, todayPoints: 45, level: "Gold Neighbor")
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<KarmaEntry>) -> ()) {
        let entry = KarmaEntry(date: Date(), karmaPoints: 1250, todayPoints: 45, level: "Gold Neighbor")
        let timeline = Timeline(entries: [entry], policy: .atEnd)
        completion(timeline)
    }
}

struct KarmaEntry: TimelineEntry {
    let date: Date
    let karmaPoints: Int
    let todayPoints: Int
    let level: String
}

struct KarmaWidgetView: View {
    var entry: KarmaProvider.Entry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        switch family {
        case .systemSmall:
            smallKarmaWidget
        case .accessoryCircular:
            circularKarmaWidget
        default:
            smallKarmaWidget
        }
    }
    
    private var smallKarmaWidget: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "star.circle.fill")
                    .foregroundColor(.orange)
                Spacer()
                Text("Karma")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .leading, spacing: 4) {
                Text("\(entry.karmaPoints)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.orange)
                
                Text(entry.level)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                
                HStack {
                    Text("+\(entry.todayPoints)")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(.orange)
                    Text("today")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .containerBackground(.ultraThinMaterial, for: .widget)
        .widgetURL(URL(string: "brrow://profile"))
    }
    
    private var circularKarmaWidget: some View {
        ZStack {
            Circle()
                .stroke(Color.orange.opacity(0.3), lineWidth: 4)
            
            Circle()
                .trim(from: 0, to: 0.7) // 70% progress to next level
                .stroke(Color.orange, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .rotationEffect(.degrees(-90))
            
            VStack(spacing: 1) {
                Text("\(entry.karmaPoints)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.orange)
                
                Image(systemName: "star.fill")
                    .font(.caption2)
                    .foregroundColor(.orange)
            }
        }
        .containerBackground(.clear, for: .widget)
        .widgetURL(URL(string: "brrow://profile"))
    }
}

// MARK: - Activity Widget
struct BrrowActivityWidget: Widget {
    let kind: String = "BrrowActivityWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ActivityProvider()) { entry in
            ActivityWidgetView(entry: entry)
        }
        .configurationDisplayName("Recent Activity")
        .description("Stay updated with your Brrow activity")
        .supportedFamilies([.systemMedium])
    }
}

struct ActivityProvider: TimelineProvider {
    func placeholder(in context: Context) -> ActivityEntry {
        ActivityEntry(date: Date(), activities: mockActivities)
    }
    
    func getSnapshot(in context: Context, completion: @escaping (ActivityEntry) -> ()) {
        let entry = ActivityEntry(date: Date(), activities: mockActivities)
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<ActivityEntry>) -> ()) {
        let entry = ActivityEntry(date: Date(), activities: mockActivities)
        let timeline = Timeline(entries: [entry], policy: .atEnd)
        completion(timeline)
    }
}

struct ActivityEntry: TimelineEntry {
    let date: Date
    let activities: [RecentActivity]
}

struct RecentActivity: Codable {
    let icon: String
    let title: String
    let subtitle: String
    let time: String
}

let mockActivities = [
    RecentActivity(icon: "message.fill", title: "New message", subtitle: "Sarah asked about your bike", time: "2m"),
    RecentActivity(icon: "dollarsign.circle.fill", title: "Payment received", subtitle: "$25 from Mike", time: "1h"),
    RecentActivity(icon: "heart.fill", title: "Item favorited", subtitle: "Camera lens saved by 3 people", time: "3h")
]

struct ActivityWidgetView: View {
    var entry: ActivityProvider.Entry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "bell.circle.fill")
                    .foregroundColor(Color(hex: "#2ABF5A"))
                Text("Recent Activity")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            VStack(spacing: 8) {
                ForEach(Array(entry.activities.prefix(3).enumerated()), id: \.offset) { index, activity in
                    HStack(spacing: 10) {
                        Image(systemName: activity.icon)
                            .font(.caption)
                            .foregroundColor(Color(hex: "#2ABF5A"))
                            .frame(width: 20)
                        
                        VStack(alignment: .leading, spacing: 1) {
                            Text(activity.title)
                                .font(.caption)
                                .fontWeight(.medium)
                            
                            Text(activity.subtitle)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                        
                        Spacer()
                        
                        Text(activity.time)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
        }
        .padding()
        .containerBackground(.ultraThinMaterial, for: .widget)
        .widgetURL(URL(string: "brrow://notifications"))
    }
}

