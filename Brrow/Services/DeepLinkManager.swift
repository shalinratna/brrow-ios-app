//
//  DeepLinkManager.swift
//  Brrow
//
//  Handles deep linking, universal links, and sharing functionality
//

import SwiftUI
import UIKit

// MARK: - Deep Link Types
enum DeepLinkDestination {
    case listing(id: Int)
    case profile(userId: String)
    case garageSale(id: Int)
    case seek(id: Int)
    case chat(conversationId: Int)
    case category(name: String)
    
    var path: String {
        switch self {
        case .listing(let id):
            return "/listing/\(id)"
        case .profile(let userId):
            return "/profile/\(userId)"
        case .garageSale(let id):
            return "/garage-sale/\(id)"
        case .seek(let id):
            return "/seek/\(id)"
        case .chat(let conversationId):
            return "/chat/\(conversationId)"
        case .category(let name):
            return "/category/\(name.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? name)"
        }
    }
    
    var webURL: URL? {
        let baseURL = "https://brrowapp.com"
        return URL(string: baseURL + path)
    }
    
    var appURL: URL? {
        let scheme = "brrow://"
        return URL(string: scheme + path.dropFirst())
    }
}

// MARK: - Deep Link Manager
class DeepLinkManager: ObservableObject {
    static let shared = DeepLinkManager()
    
    @Published var pendingDeepLink: DeepLinkDestination?
    @Published var shouldHandleDeepLink = false
    
    private init() {}
    
    // MARK: - Handle URL
    func handleURL(_ url: URL) -> Bool {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
            return false
        }
        
        // Handle different URL schemes
        if components.scheme == "brrow" {
            return handleAppScheme(components)
        } else if components.scheme == "https" || components.scheme == "http" {
            return handleWebScheme(components)
        }
        
        return false
    }
    
    private func handleAppScheme(_ components: URLComponents) -> Bool {
        guard let path = components.path.isEmpty ? components.host : components.path else {
            return false
        }
        
        return parsePath(path)
    }
    
    private func handleWebScheme(_ components: URLComponents) -> Bool {
        guard components.host?.contains("brrowapp.com") == true,
              let path = components.path.isEmpty ? nil : components.path else {
            return false
        }
        
        return parsePath(path)
    }
    
    private func parsePath(_ path: String) -> Bool {
        let pathComponents = path.split(separator: "/").map(String.init)
        
        guard !pathComponents.isEmpty else { return false }
        
        switch pathComponents[0] {
        case "listing", "item", "rental":
            if pathComponents.count > 1, let id = Int(pathComponents[1]) {
                pendingDeepLink = .listing(id: id)
                shouldHandleDeepLink = true
                return true
            }
            
        case "profile", "user":
            if pathComponents.count > 1 {
                pendingDeepLink = .profile(userId: pathComponents[1])
                shouldHandleDeepLink = true
                return true
            }
            
        case "garage-sale", "sale":
            if pathComponents.count > 1, let id = Int(pathComponents[1]) {
                pendingDeepLink = .garageSale(id: id)
                shouldHandleDeepLink = true
                return true
            }
            
        case "seek", "request":
            if pathComponents.count > 1, let id = Int(pathComponents[1]) {
                pendingDeepLink = .seek(id: id)
                shouldHandleDeepLink = true
                return true
            }
            
        case "chat", "message":
            if pathComponents.count > 1, let id = Int(pathComponents[1]) {
                pendingDeepLink = .chat(conversationId: id)
                shouldHandleDeepLink = true
                return true
            }
            
        case "category":
            if pathComponents.count > 1 {
                pendingDeepLink = .category(name: pathComponents[1])
                shouldHandleDeepLink = true
                return true
            }
            
        default:
            break
        }
        
        return false
    }
    
    // MARK: - Navigation
    func navigate(to destination: DeepLinkDestination, in navigationPath: Binding<NavigationPath>) {
        switch destination {
        case .listing(let id):
            // Navigate to listing detail
            navigationPath.wrappedValue.append(ListingNavigationDestination(listingId: id))
            
        case .profile(let userId):
            // Navigate to profile
            navigationPath.wrappedValue.append(ProfileNavigationDestination(userId: userId))
            
        case .garageSale(let id):
            // Navigate to garage sale
            navigationPath.wrappedValue.append(GarageSaleNavigationDestination(saleId: id))
            
        case .seek(let id):
            // Navigate to seek detail
            navigationPath.wrappedValue.append(SeekNavigationDestination(seekId: id))
            
        case .chat(let conversationId):
            // Navigate to chat
            navigationPath.wrappedValue.append(ChatNavigationDestination(conversationId: conversationId))
            
        case .category(let name):
            // Navigate to category
            navigationPath.wrappedValue.append(CategoryNavigationDestination(categoryName: name))
        }
        
        // Clear pending deep link
        pendingDeepLink = nil
        shouldHandleDeepLink = false
    }
    
    // MARK: - Share Generation
    func generateShareContent(for destination: DeepLinkDestination) -> ShareContent {
        let webURL = destination.webURL
        let appURL = destination.appURL
        
        var title = "Check this out on Brrow!"
        var message = ""
        
        switch destination {
        case .listing:
            title = "Check out this listing on Brrow!"
            message = "I found this great item available for rent on Brrow."
            
        case .profile:
            title = "Check out this profile on Brrow!"
            message = "View this user's listings and reviews on Brrow."
            
        case .garageSale:
            title = "Garage Sale on Brrow!"
            message = "Don't miss this garage sale happening in your area."
            
        case .seek:
            title = "Someone is looking for this on Brrow!"
            message = "Can you help fulfill this request?"
            
        case .chat:
            title = "Message on Brrow"
            message = "Continue our conversation on Brrow."
            
        case .category(let name):
            title = "Browse \(name) on Brrow!"
            message = "Check out items available in \(name) category."
        }
        
        return ShareContent(
            title: title,
            message: message,
            webURL: webURL,
            appURL: appURL
        )
    }
}

// MARK: - Share Content
struct ShareContent {
    let title: String
    let message: String
    let webURL: URL?
    let appURL: URL?
    
    var activityItems: [Any] {
        var items: [Any] = ["\(title)\n\(message)"]
        
        if let webURL = webURL {
            items.append(webURL)
        }
        
        return items
    }
}

// MARK: - Navigation Destinations
struct ListingNavigationDestination: Hashable {
    let listingId: Int
}

struct ProfileNavigationDestination: Hashable {
    let userId: String
}

struct GarageSaleNavigationDestination: Hashable {
    let saleId: Int
}

struct SeekNavigationDestination: Hashable {
    let seekId: Int
}

struct ChatNavigationDestination: Hashable {
    let conversationId: Int
}

struct CategoryNavigationDestination: Hashable {
    let categoryName: String
}

// MARK: - Share Sheet View
struct BrrowShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    let applicationActivities: [UIActivity]? = nil
    @Binding var isPresented: Bool
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: applicationActivities
        )
        
        controller.completionWithItemsHandler = { _, _, _, _ in
            isPresented = false
        }
        
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Deep Link View Modifier
struct DeepLinkHandler: ViewModifier {
    @ObservedObject var deepLinkManager = DeepLinkManager.shared
    @Binding var navigationPath: NavigationPath
    
    func body(content: Content) -> some View {
        content
            .onOpenURL { url in
                _ = deepLinkManager.handleURL(url)
            }
            .onChange(of: deepLinkManager.shouldHandleDeepLink) { shouldHandle in
                if shouldHandle, let destination = deepLinkManager.pendingDeepLink {
                    deepLinkManager.navigate(to: destination, in: $navigationPath)
                }
            }
    }
}

extension View {
    func handleDeepLinks(navigationPath: Binding<NavigationPath>) -> some View {
        modifier(DeepLinkHandler(navigationPath: navigationPath))
    }
}