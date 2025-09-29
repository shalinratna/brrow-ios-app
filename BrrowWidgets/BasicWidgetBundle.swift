//
//  BasicWidgetBundle.swift
//  BrrowWidgets
//
//  Basic widget bundle with minimal dependencies
//

import WidgetKit
import SwiftUI

@main
struct BrrowBasicWidgets: WidgetBundle {
    var body: some Widget {
        BrrowBasicWidget()
    }
}

struct BrrowBasicWidget: Widget {
    let kind: String = "BrrowBasicWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: BasicProvider()) { entry in
            BasicWidgetView(entry: entry)
        }
        .configurationDisplayName("Brrow")
        .description("Your Brrow app")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct BasicEntry: TimelineEntry {
    let date: Date
    let title: String = "Brrow"
    let subtitle: String = "P2P Marketplace"
}

struct BasicProvider: TimelineProvider {
    func placeholder(in context: Context) -> BasicEntry {
        BasicEntry(date: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (BasicEntry) -> ()) {
        let entry = BasicEntry(date: Date())
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let entry = BasicEntry(date: Date())
        let timeline = Timeline(entries: [entry], policy: .atEnd)
        completion(timeline)
    }
}

struct BasicWidgetView: View {
    var entry: BasicProvider.Entry

    var body: some View {
        VStack(spacing: 8) {
            Text(entry.title)
                .font(.headline)
                .foregroundColor(.primary)

            Text(entry.subtitle)
                .font(.caption)
                .foregroundColor(.secondary)

            Text("📦")
                .font(.largeTitle)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .basicWidgetBackground()
    }
}

extension View {
    @ViewBuilder
    func basicWidgetBackground() -> some View {
        if #available(iOS 17.0, *) {
            self.containerBackground(.fill.tertiary, for: .widget)
        } else {
            self.background(Color(.systemBackground))
        }
    }
}