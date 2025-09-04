//
//  WidgetProvider.swift
//  BrrowWidgets
//
//  Enhanced provider that fetches real data
//

import WidgetKit
import SwiftUI

struct EnhancedProvider: TimelineProvider {
    private let appGroupIdentifier = "group.com.brrowapp.widgets"
    
    private var sharedDefaults: UserDefaults? {
        return UserDefaults(suiteName: appGroupIdentifier)
    }
    
    func placeholder(in context: Context) -> BrrowEntry {
        BrrowEntry(date: Date(), widgetData: WidgetData.placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (BrrowEntry) -> ()) {
        // For quick preview, use cached data
        let widgetData = fetchCachedData()
        let entry = BrrowEntry(date: Date(), widgetData: widgetData)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        var entries: [BrrowEntry] = []
        let currentDate = Date()
        
        // Fetch fresh data
        let widgetData = fetchCachedData()
        
        // Create timeline entries for the next 4 hours, updating every hour
        for hourOffset in 0 ..< 4 {
            let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate)!
            let entry = BrrowEntry(date: entryDate, widgetData: widgetData)
            entries.append(entry)
        }

        // Set the timeline to refresh after 4 hours
        let timeline = Timeline(entries: entries, policy: .after(Calendar.current.date(byAdding: .hour, value: 4, to: currentDate)!))
        completion(timeline)
    }
    
    private func fetchCachedData() -> WidgetData {
        guard let defaults = sharedDefaults else {
            return WidgetData.placeholder
        }
        
        // Keys matching WidgetDataManager
        let activeListings = defaults.integer(forKey: "widget.activeListings")
        let unreadMessages = defaults.integer(forKey: "widget.unreadMessages")
        let todaysEarnings = defaults.double(forKey: "widget.todaysEarnings")
        let nearbyItems = defaults.integer(forKey: "widget.nearbyItems")
        let recentActivity = defaults.string(forKey: "widget.recentActivity") ?? "Open app for updates"
        
        return WidgetData(
            activeListings: activeListings,
            unreadMessages: unreadMessages,
            todaysEarnings: todaysEarnings,
            nearbyItems: nearbyItems,
            recentActivity: recentActivity
        )
    }
}