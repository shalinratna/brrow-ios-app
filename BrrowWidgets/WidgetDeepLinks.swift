//
//  WidgetDeepLinks.swift
//  BrrowWidgets
//
//  Deep linking support for widgets
//

import SwiftUI
import WidgetKit

// MARK: - Deep Link URLs
enum WidgetDeepLink {
    static let listings = URL(string: "brrowapp://listings")!
    static let messages = URL(string: "brrowapp://messages")!
    static let earnings = URL(string: "brrowapp://earnings")!
    static let nearby = URL(string: "brrowapp://nearby")!
    static let createListing = URL(string: "brrowapp://create-listing")!
}

// MARK: - Enhanced Widget Views with Deep Links
extension SmallWidgetView {
    var deepLinkedBody: some View {
        self
            .widgetURL(WidgetDeepLink.listings)
    }
}

extension MediumWidgetView {
    func deepLinkedBody(_ data: WidgetData) -> some View {
        ZStack {
            self
                .widgetURL(WidgetDeepLink.listings) // Default tap

            // Specific tap areas
            HStack {
                // Left side - opens listings
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture { } // Handled by widgetURL

                Spacer()

                // Right side - opens messages if there are unread
                if data.unreadMessages > 0 {
                    Link(destination: WidgetDeepLink.messages) {
                        Color.clear
                            .frame(width: 100)
                            .contentShape(Rectangle())
                    }
                }
            }
        }
    }
}

// MARK: - Deep Link Handler
// Note: The actual handler should be implemented in the main app target
// This is just documentation for how to handle the URLs in BrrowApp.swift:
/*
func handleWidgetDeepLink(_ url: URL) {
    guard let host = url.host else { return }
    
    switch host {
    case "listings":
        // Navigate to listings tab
        TabSelectionManager.shared.selectedTab = .marketplace
        
    case "messages":
        // Navigate to messages tab
        TabSelectionManager.shared.selectedTab = .messages
        
    case "earnings":
        // Navigate to profile then earnings
        TabSelectionManager.shared.selectedTab = .profile
        // Post notification to open earnings
        NotificationCenter.default.post(name: .openEarnings, object: nil)
        
    case "nearby":
        // Navigate to marketplace with location filter
        TabSelectionManager.shared.selectedTab = .marketplace
        NotificationCenter.default.post(name: .filterNearby, object: nil)
        
    case "create-listing":
        // Open create listing modal
        NotificationCenter.default.post(name: .createNewListing, object: nil)
        
    default:
        break
    }
}
*/

// MARK: - Notification Names
extension Notification.Name {
    static let openEarnings = Notification.Name("openEarnings")
    static let filterNearby = Notification.Name("filterNearby")
    static let createNewListing = Notification.Name("createNewListing")
}

// MARK: - Interactive Widgets (iOS 17+)
@available(iOS 17.0, *)
struct InteractiveWidgetButton: View {
    let title: String
    let systemImage: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(hex: "2ABF5A"))
                .cornerRadius(8)
        }
    }
}

// MARK: - Widget Configuration with Deep Links
extension BrrowWidget {
    var enhancedBody: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: BrrowProvider()) { entry in
            BrrowWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Brrow Stats")
        .description("Keep track of your listings and activity")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
        #if swift(>=5.9)
        .contentMarginsDisabled() // iOS 17+ for edge-to-edge content
        #endif
    }
}

