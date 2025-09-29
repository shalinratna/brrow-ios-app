//
//  SimpleWidgetBundle.swift
//  BrrowWidgets
//
//  Simplified widget bundle for basic functionality
//

import WidgetKit
import SwiftUI

// @main - Disabled, using BasicWidgetBundle
struct BrrowSimpleWidgets: WidgetBundle {
    var body: some Widget {
        BrrowSimpleWidget()
    }
}

struct BrrowSimpleWidget: Widget {
    let kind: String = "BrrowSimpleWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SimpleProvider()) { entry in
            SimpleWidgetView(entry: entry)
        }
        .configurationDisplayName("Brrow")
        .description("Your Brrow stats")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let message: String
}

struct SimpleProvider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), message: "Brrow")
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date(), message: "Brrow Stats")
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let entry = SimpleEntry(date: Date(), message: "Brrow Stats")
        let timeline = Timeline(entries: [entry], policy: .atEnd)
        completion(timeline)
    }
}

struct SimpleWidgetView: View {
    var entry: SimpleProvider.Entry

    var body: some View {
        VStack {
            Text("Brrow")
                .font(.headline)
            Text(entry.message)
                .font(.caption)
        }
        .padding()
        .widgetBackground()
    }
}

extension View {
    @ViewBuilder
    func widgetBackground() -> some View {
        if #available(iOS 17.0, *) {
            self.containerBackground(.fill.tertiary, for: .widget)
        } else {
            self.background(Color(.systemBackground))
        }
    }
}