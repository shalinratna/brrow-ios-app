//
//  BrrowWidgetsLiveActivity.swift
//  BrrowWidgets
//
//  Created by Shalin Ratna on 7/25/25.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct BrrowWidgetsAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct BrrowWidgetsLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: BrrowWidgetsAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "brrow://"))
            .keylineTint(Color.red)
        }
    }
}

extension BrrowWidgetsAttributes {
    fileprivate static var preview: BrrowWidgetsAttributes {
        BrrowWidgetsAttributes(name: "World")
    }
}

extension BrrowWidgetsAttributes.ContentState {
    fileprivate static var smiley: BrrowWidgetsAttributes.ContentState {
        BrrowWidgetsAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: BrrowWidgetsAttributes.ContentState {
         BrrowWidgetsAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: BrrowWidgetsAttributes.preview) {
   BrrowWidgetsLiveActivity()
} contentStates: {
    BrrowWidgetsAttributes.ContentState.smiley
    BrrowWidgetsAttributes.ContentState.starEyes
}
