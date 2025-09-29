//
//  BrrowWidget.swift
//  BrrowWidgets
//
//  Widget implementation for Brrow app
//

import WidgetKit
import SwiftUI

// MARK: - Widget Entry
struct BrrowEntry: TimelineEntry {
    let date: Date
    let widgetData: WidgetData
}

// MARK: - Timeline Provider
struct BrrowProvider: TimelineProvider {
    typealias Entry = BrrowEntry
    
    func placeholder(in context: Context) -> BrrowEntry {
        BrrowEntry(date: Date(), widgetData: WidgetData.placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (BrrowEntry) -> ()) {
        let entry = BrrowEntry(date: Date(), widgetData: WidgetData.placeholder)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<BrrowEntry>) -> ()) {
        var entries: [BrrowEntry] = []

        // Generate a timeline consisting of five entries an hour apart, starting from the current date
        let currentDate = Date()
        for hourOffset in 0 ..< 5 {
            let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate)!
            
            // Fetch real data from your app here
            let widgetData = fetchWidgetData()
            let entry = BrrowEntry(date: entryDate, widgetData: widgetData)
            entries.append(entry)
        }

        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
    
    private func fetchWidgetData() -> WidgetData {
        // Access shared UserDefaults with app group
        let appGroupIdentifier = "group.com.brrowapp.widgets"
        guard let defaults = UserDefaults(suiteName: appGroupIdentifier) else {
            return WidgetData.placeholder
        }
        
        // Fetch real data from shared storage
        let activeListings = defaults.integer(forKey: "widget.activeListings")
        let unreadMessages = defaults.integer(forKey: "widget.unreadMessages")
        let todaysEarnings = defaults.double(forKey: "widget.todaysEarnings")
        let nearbyItems = defaults.integer(forKey: "widget.nearbyItems")
        let recentActivity = defaults.string(forKey: "widget.recentActivity") ?? "Open app for updates"
        
        // Return placeholder if no data exists
        if activeListings == 0 && unreadMessages == 0 && todaysEarnings == 0 {
            return WidgetData.placeholder
        }
        
        return WidgetData(
            activeListings: activeListings,
            unreadMessages: unreadMessages,
            todaysEarnings: todaysEarnings,
            nearbyItems: nearbyItems,
            recentActivity: recentActivity
        )
    }
}

// MARK: - Widget Data Model
struct WidgetData {
    let activeListings: Int
    let unreadMessages: Int
    let todaysEarnings: Double
    let nearbyItems: Int
    let recentActivity: String
    
    static let placeholder = WidgetData(
        activeListings: 0,
        unreadMessages: 0,
        todaysEarnings: 0,
        nearbyItems: 0,
        recentActivity: "Loading..."
    )
}

// MARK: - Widget Views
struct BrrowWidgetEntryView : View {
    var entry: BrrowProvider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(data: entry.widgetData)
        case .systemMedium:
            MediumWidgetView(data: entry.widgetData)
        case .systemLarge:
            LargeWidgetView(data: entry.widgetData)
        case .systemExtraLarge:
            LargeWidgetView(data: entry.widgetData)
        case .accessoryCircular:
            CircularWidgetView(data: entry.widgetData)
        case .accessoryRectangular:
            RectangularWidgetView(data: entry.widgetData)
        case .accessoryInline:
            InlineWidgetView(data: entry.widgetData)
        @unknown default:
            SmallWidgetView(data: entry.widgetData)
        }
    }
}

// MARK: - Small Widget
struct SmallWidgetView: View {
    let data: WidgetData
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image("AppIcon")
                    .resizable()
                    .frame(width: 30, height: 30)
                    .cornerRadius(6)
                
                Spacer()
                
                if data.unreadMessages > 0 {
                    ZStack {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 20, height: 20)
                        
                        Text("\(data.unreadMessages)")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("\(data.activeListings)")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(Color(hex: "2ABF5A"))
                
                Text("Active Listings")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            HStack {
                Image(systemName: "location.fill")
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "2ABF5A"))
                
                Text("\(data.nearbyItems) nearby")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .conditionalContainerBackground()
    }
}

// MARK: - Medium Widget
struct MediumWidgetView: View {
    let data: WidgetData
    
    var body: some View {
        HStack(spacing: 16) {
            // Left side - Stats
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image("AppIcon")
                        .resizable()
                        .frame(width: 40, height: 40)
                        .cornerRadius(8)
                    
                    VStack(alignment: .leading) {
                        Text("Brrow")
                            .font(.system(size: 16, weight: .bold))
                        Text("Borrow, don't buy")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                HStack(spacing: 20) {
                    StatItem(value: "\(data.activeListings)", label: "Listings", icon: "cube.box.fill")
                    StatItem(value: "$\(String(format: "%.0f", data.todaysEarnings))", label: "Today", icon: "dollarsign.circle.fill")
                    StatItem(value: "\(data.nearbyItems)", label: "Nearby", icon: "location.fill")
                }
            }
            
            Divider()
            
            // Right side - Activity
            VStack(alignment: .leading, spacing: 8) {
                Label("Recent Activity", systemImage: "bell.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color(hex: "2ABF5A"))
                
                Text(data.recentActivity)
                    .font(.system(size: 13))
                    .lineLimit(2)
                    .foregroundColor(.primary)
                
                Spacer()
                
                if data.unreadMessages > 0 {
                    Label("\(data.unreadMessages) unread messages", systemImage: "envelope.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .conditionalContainerBackground()
    }
}

// MARK: - Large Widget
struct LargeWidgetView: View {
    let data: WidgetData
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Image("AppIcon")
                    .resizable()
                    .frame(width: 50, height: 50)
                    .cornerRadius(10)
                
                VStack(alignment: .leading) {
                    Text("Brrow")
                        .font(.system(size: 20, weight: .bold))
                    Text("Your rental marketplace")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if data.unreadMessages > 0 {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.red)
                            .frame(width: 50, height: 30)
                        
                        HStack(spacing: 4) {
                            Image(systemName: "envelope.fill")
                                .font(.system(size: 12))
                            Text("\(data.unreadMessages)")
                                .font(.system(size: 14, weight: .bold))
                        }
                        .foregroundColor(.white)
                    }
                }
            }
            
            // Stats Grid
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                LargeStatCard(title: "Active Listings", value: "\(data.activeListings)", icon: "cube.box.fill", color: Color(hex: "2ABF5A"))
                LargeStatCard(title: "Today's Earnings", value: "$\(String(format: "%.0f", data.todaysEarnings))", icon: "dollarsign.circle.fill", color: .orange)
                LargeStatCard(title: "Nearby Items", value: "\(data.nearbyItems)", icon: "location.fill", color: .blue)
                LargeStatCard(title: "Messages", value: "\(data.unreadMessages)", icon: "envelope.fill", color: .red)
            }
            
            Divider()
            
            // Recent Activity
            VStack(alignment: .leading, spacing: 8) {
                Label("Recent Activity", systemImage: "clock.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color(hex: "2ABF5A"))
                
                Text(data.recentActivity)
                    .font(.system(size: 14))
                    .foregroundColor(.primary)
                    .lineLimit(2)
            }
            
            Spacer()
        }
        .padding()
        .conditionalContainerBackground()
    }
}

// MARK: - Lock Screen Widgets
struct CircularWidgetView: View {
    let data: WidgetData
    
    var body: some View {
        ZStack {
            AccessoryWidgetBackground()
            VStack {
                Text("\(data.activeListings)")
                    .font(.system(size: 22, weight: .bold))
                Text("Items")
                    .font(.system(size: 10))
            }
        }
        .conditionalContainerBackgroundFill()
    }
}

struct RectangularWidgetView: View {
    let data: WidgetData
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Label("Brrow", systemImage: "cube.box.fill")
                .font(.system(size: 14, weight: .semibold))
            
            Text("\(data.activeListings) listings • $\(String(format: "%.0f", data.todaysEarnings)) today")
                .font(.system(size: 12))
        }
        .conditionalContainerBackgroundFill()
    }
}

struct InlineWidgetView: View {
    let data: WidgetData
    
    var body: some View {
        Label("\(data.activeListings) listings • \(data.unreadMessages) msgs", systemImage: "cube.box.fill")
            .conditionalContainerBackgroundClear()
    }
}

// MARK: - Helper Views
struct StatItem: View {
    let value: String
    let label: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(Color(hex: "2ABF5A"))
            
            Text(value)
                .font(.system(size: 16, weight: .bold))
            
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
        }
    }
}

struct LargeStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(color)
                
                Spacer()
            }
            
            Text(value)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.primary)
            
            Text(title)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

// MARK: - Widget Configuration
struct BrrowWidget: Widget {
    let kind: String = "BrrowWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: BrrowProvider()) { entry in
            BrrowWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Brrow Stats")
        .description("Keep track of your listings and activity")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge, .accessoryCircular, .accessoryRectangular, .accessoryInline])
    }
}

// MARK: - Widget Bundle
// @main - Disabled, using SimpleWidgetBundle
struct BrrowWidgets: WidgetBundle {
    var body: some Widget {
        BrrowWidget()
    }
}

// MARK: - Preview
struct BrrowWidget_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            BrrowWidgetEntryView(entry: BrrowEntry(
                date: Date(),
                widgetData: WidgetData(
                    activeListings: 12,
                    unreadMessages: 3,
                    todaysEarnings: 45.50,
                    nearbyItems: 8,
                    recentActivity: "New rental request for Drill"
                )
            ))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
            .previewDisplayName("Small")
            
            BrrowWidgetEntryView(entry: BrrowEntry(
                date: Date(),
                widgetData: WidgetData(
                    activeListings: 12,
                    unreadMessages: 3,
                    todaysEarnings: 45.50,
                    nearbyItems: 8,
                    recentActivity: "New rental request for Drill"
                )
            ))
            .previewContext(WidgetPreviewContext(family: .systemMedium))
            .previewDisplayName("Medium")
            
            BrrowWidgetEntryView(entry: BrrowEntry(
                date: Date(),
                widgetData: WidgetData(
                    activeListings: 12,
                    unreadMessages: 3,
                    todaysEarnings: 45.50,
                    nearbyItems: 8,
                    recentActivity: "New rental request for Drill"
                )
            ))
            .previewContext(WidgetPreviewContext(family: .systemLarge))
            .previewDisplayName("Large")
        }
    }
}

// MARK: - View Extension for conditional modifiers
extension View {
    @ViewBuilder
    func conditionalContainerBackground() -> some View {
        if #available(iOS 17.0, *) {
            self.conditionalContainerBackground()
        } else {
            self.background(Color(.systemBackground))
        }
    }

    @ViewBuilder
    func conditionalContainerBackgroundClear() -> some View {
        if #available(iOS 17.0, *) {
            self.conditionalContainerBackgroundClear()
        } else {
            self
        }
    }

    @ViewBuilder
    func conditionalContainerBackgroundFill() -> some View {
        if #available(iOS 17.0, *) {
            self.conditionalContainerBackgroundFill()
        } else {
            self.background(Color(.systemBackground))
        }
    }
}

// MARK: - Color Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}