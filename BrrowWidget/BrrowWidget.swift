import WidgetKit
import SwiftUI

// MARK: - Widget Timeline Provider
struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> BrrowEntry {
        BrrowEntry(date: Date(), listings: sampleListings, earnings: "$0")
    }

    func getSnapshot(in context: Context, completion: @escaping (BrrowEntry) -> ()) {
        let entry = BrrowEntry(date: Date(), listings: sampleListings, earnings: "$0")
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        var entries: [BrrowEntry] = []
        
        // Fetch data from shared container
        let sharedDefaults = UserDefaults(suiteName: "group.com.brrow.app")
        let activeListings = sharedDefaults?.integer(forKey: "activeListings") ?? 0
        let todayEarnings = sharedDefaults?.string(forKey: "todayEarnings") ?? "$0"
        let savedListings = sharedDefaults?.data(forKey: "recentListings") ?? Data()
        
        // Decode listings
        var listings: [WidgetListing] = []
        if let decoded = try? JSONDecoder().decode([WidgetListing].self, from: savedListings) {
            listings = decoded
        } else {
            listings = sampleListings
        }
        
        // Generate a timeline entry
        let currentDate = Date()
        let entry = BrrowEntry(
            date: currentDate,
            listings: listings,
            earnings: todayEarnings,
            activeCount: activeListings
        )
        entries.append(entry)

        // Refresh every 30 minutes
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: currentDate)!
        let timeline = Timeline(entries: entries, policy: .after(nextUpdate))
        completion(timeline)
    }
}

// MARK: - Widget Entry
struct BrrowEntry: TimelineEntry {
    let date: Date
    let listings: [WidgetListing]
    let earnings: String
    let activeCount: Int = 0
}

// MARK: - Widget Listing Model
struct WidgetListing: Codable {
    let id: Int
    let title: String
    let price: Double
    let imageUrl: String?
    let views: Int
}

// MARK: - Widget Views
struct BrrowWidgetEntryView : View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        case .systemLarge:
            LargeWidgetView(entry: entry)
        default:
            SmallWidgetView(entry: entry)
        }
    }
}

// MARK: - Small Widget
struct SmallWidgetView: View {
    let entry: BrrowEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack {
                Image(systemName: "cube.box.fill")
                    .foregroundColor(.white)
                    .font(.title3)
                Text("Brrow")
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
            }
            
            Spacer()
            
            // Stats
            VStack(alignment: .leading, spacing: 4) {
                Text("\(entry.activeCount)")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                Text("Active Listings")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
            }
            
            // Earnings
            HStack {
                Text(entry.earnings)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                Text("today")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
            }
        }
        .padding()
        .containerBackground(
            LinearGradient(
                colors: [Color(hex: "#2ABF5A"), Color(hex: "#1ea34a")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            for: .widget
        )
    }
}

// MARK: - Medium Widget
struct MediumWidgetView: View {
    let entry: BrrowEntry
    
    var body: some View {
        HStack {
            // Left Stats
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack {
                    Image(systemName: "cube.box.fill")
                        .foregroundColor(.white)
                        .font(.title2)
                    Text("Brrow")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                // Active Listings
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(entry.activeCount)")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    Text("Active Listings")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }
                
                // Earnings
                HStack {
                    Text(entry.earnings)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    Text("today")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Recent Listings
            if !entry.listings.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Recent")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                    
                    ForEach(entry.listings.prefix(2), id: \.id) { listing in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(listing.title)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.white)
                                    .lineLimit(1)
                                Text("$\(listing.price, specifier: "%.0f")")
                                    .font(.caption2)
                                    .foregroundColor(.white.opacity(0.8))
                            }
                            Spacer()
                            Text("\(listing.views)")
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.8))
                            Image(systemName: "eye")
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding()
        .containerBackground(
            LinearGradient(
                colors: [Color(hex: "#2ABF5A"), Color(hex: "#1ea34a")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            for: .widget
        )
    }
}

// MARK: - Large Widget
struct LargeWidgetView: View {
    let entry: BrrowEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Image(systemName: "cube.box.fill")
                    .foregroundColor(.white)
                    .font(.title)
                Text("Brrow")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                Spacer()
                
                Link(destination: URL(string: "brrow://home")!) {
                    Image(systemName: "arrow.up.right.circle.fill")
                        .foregroundColor(.white.opacity(0.8))
                        .font(.title3)
                }
            }
            
            // Stats Row
            HStack(spacing: 20) {
                StatCard(
                    value: "\(entry.activeCount)",
                    label: "Active",
                    icon: "cube.box",
                    color: .white.opacity(0.2)
                )
                
                StatCard(
                    value: entry.earnings,
                    label: "Today",
                    icon: "dollarsign.circle",
                    color: .white.opacity(0.2)
                )
            }
            
            // Recent Listings
            if !entry.listings.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Recent Listings")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    ForEach(entry.listings.prefix(4), id: \.id) { listing in
                        ListingRow(listing: listing)
                    }
                }
            }
            
            Spacer()
        }
        .padding()
        .containerBackground(
            LinearGradient(
                colors: [Color(hex: "#2ABF5A"), Color(hex: "#1ea34a")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            for: .widget
        )
    }
}

// MARK: - Helper Views
struct StatCard: View {
    let value: String
    let label: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.white)
                .font(.title3)
            
            VStack(alignment: .leading) {
                Text(value)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                Text(label)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(color)
        .cornerRadius(8)
    }
}

struct ListingRow: View {
    let listing: WidgetListing
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(listing.title)
                    .font(.footnote)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .lineLimit(1)
                HStack(spacing: 4) {
                    Text("$\(listing.price, specifier: "%.0f")")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                    Text("•")
                        .foregroundColor(.white.opacity(0.6))
                    Text("\(listing.views) views")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            Spacer()
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color.white.opacity(0.1))
        .cornerRadius(8)
    }
}

// MARK: - Widget Configuration
@main
struct BrrowWidget: Widget {
    let kind: String = "BrrowWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            BrrowWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Brrow Dashboard")
        .description("Track your listings and earnings")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// MARK: - Sample Data
let sampleListings = [
    WidgetListing(id: 1, title: "Electric Drill", price: 25, imageUrl: nil, views: 45),
    WidgetListing(id: 2, title: "Camping Tent", price: 35, imageUrl: nil, views: 32),
    WidgetListing(id: 3, title: "Pressure Washer", price: 40, imageUrl: nil, views: 28),
    WidgetListing(id: 4, title: "Ladder", price: 20, imageUrl: nil, views: 19)
]

// MARK: - Extensions
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