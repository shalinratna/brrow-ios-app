//
//  TabSelectionManager.swift
//  Brrow
//
//  Manages tab selection across the app
//

import SwiftUI

class TabSelectionManager: ObservableObject {
    @Published var selectedTab: Int = 0
    @Published var shouldFocusMarketplaceSearch = false
    
    static let shared = TabSelectionManager()
    
    private init() {}
    
    func switchToMarketplace() {
        selectedTab = 1
    }
    
    func switchToMarketplaceWithSearch() {
        selectedTab = 1
        // Trigger search focus after a slight delay to ensure tab switch completes
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.shouldFocusMarketplaceSearch = true
        }
    }
    
    func switchToHome() {
        selectedTab = 0
    }
    
    func switchToMessages() {
        print("🔀 [TabSelectionManager] switchToMessages() called - changing from tab \(selectedTab) to tab 3")
        selectedTab = 3
        print("✅ [TabSelectionManager] selectedTab is now: \(selectedTab)")
    }
    
    func switchToProfile() {
        selectedTab = 4
    }
    
    func resetSearchFocus() {
        shouldFocusMarketplaceSearch = false
    }
}