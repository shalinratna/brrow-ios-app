//
//  DataRefreshManager.swift
//  Brrow
//
//  Manages real-time data updates and cache invalidation
//

import Foundation
import Combine
import Network
import SwiftUI

// MARK: - Refresh Policy
enum RefreshPolicy {
    case always           // Always fetch fresh data
    case onAppear        // Refresh when view appears
    case interval(TimeInterval)  // Refresh at intervals
    case manual          // Only refresh on pull-to-refresh
    case smart           // Smart refresh based on staleness
    
    var shouldRefresh: Bool {
        switch self {
        case .always:
            return true
        case .onAppear:
            return true
        case .interval(let interval):
            return Date().timeIntervalSince(DataRefreshManager.shared.lastRefreshTime) > interval
        case .manual:
            return false
        case .smart:
            // Smart logic: refresh if data is older than 5 minutes or network changed
            return Date().timeIntervalSince(DataRefreshManager.shared.lastRefreshTime) > 300
        }
    }
}

// MARK: - Data Refresh Manager
class DataRefreshManager: ObservableObject {
    static let shared = DataRefreshManager()
    
    // Published properties for UI updates
    @Published var isRefreshing = false
    @Published var lastRefreshTime = Date()
    @Published var networkStatus: NWPath.Status = .satisfied
    
    // Refresh timers
    private var refreshTimers: [String: Timer] = [:]
    private var cancellables = Set<AnyCancellable>()
    
    // Network monitor
    private let monitor = NWPathMonitor()
    private let monitorQueue = DispatchQueue(label: "com.brrow.networkmonitor")
    
    // Cache manager
    private let cacheManager = CacheManager.shared
    
    private init() {
        setupNetworkMonitoring()
        setupAutoRefresh()
    }
    
    // MARK: - Network Monitoring
    
    private func setupNetworkMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.networkStatus = path.status
                
                // Clear cache when network becomes available after being offline
                if path.status == .satisfied && self?.networkStatus != .satisfied {
                    self?.refreshAllData()
                }
            }
        }
        monitor.start(queue: monitorQueue)
    }
    
    // MARK: - Auto Refresh
    
    private func setupAutoRefresh() {
        // Refresh featured listings every 5 minutes
        startAutoRefresh(for: "featured_listings", interval: 300)
        
        // Refresh marketplace every 2 minutes
        startAutoRefresh(for: "marketplace", interval: 120)
        
        // Refresh user data every 10 minutes
        startAutoRefresh(for: "user_data", interval: 600)
    }
    
    func startAutoRefresh(for key: String, interval: TimeInterval) {
        stopAutoRefresh(for: key)
        
        let timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.refreshData(for: key)
        }
        
        refreshTimers[key] = timer
    }
    
    func stopAutoRefresh(for key: String) {
        refreshTimers[key]?.invalidate()
        refreshTimers[key] = nil
    }
    
    // MARK: - Data Refresh
    
    @MainActor
    func refreshAllData() {
        Task {
            isRefreshing = true
            
            // Clear all cache for fresh data
            cacheManager.clearAll()
            
            // Refresh all data types in parallel
            await withTaskGroup(of: Void.self) { group in
                group.addTask { await self.refreshListings() }
                group.addTask { await self.refreshGarageSales() }
                group.addTask { await self.refreshSeeks() }
                group.addTask { await self.refreshUserData() }
            }
            
            lastRefreshTime = Date()
            isRefreshing = false
            
            print("✅ All data refreshed at \(lastRefreshTime)")
        }
    }
    
    @MainActor
    func refreshData(for key: String) {
        Task {
            switch key {
            case "featured_listings":
                await refreshFeaturedListings()
            case "marketplace":
                await refreshListings()
            case "user_data":
                await refreshUserData()
            default:
                break
            }
        }
    }
    
    // MARK: - Specific Refresh Methods
    
    @MainActor
    private func refreshListings() async {
        do {
            // Clear listing cache
            cacheManager.clearCache(matching: "listings_")
            
            // Fetch fresh data
            let _ = try await APIClient.shared.fetchListings()
            
            print("📦 Listings refreshed")
        } catch {
            print("Failed to refresh listings: \(error)")
        }
    }
    
    @MainActor
    private func refreshFeaturedListings() async {
        do {
            // Clear featured cache
            cacheManager.clearCache(matching: "featured_")
            
            // Fetch fresh featured items
            let _ = try await APIClient.shared.fetchFeaturedListings()
            
            print("⭐ Featured listings refreshed")
        } catch {
            print("Failed to refresh featured listings: \(error)")
        }
    }
    
    @MainActor
    private func refreshGarageSales() async {
        do {
            // Clear garage sale cache
            cacheManager.clearCache(matching: "garage_sales_")
            
            // Fetch fresh garage sales
            let _ = try await APIClient.shared.fetchGarageSales()
            
            print("🏠 Garage sales refreshed")
        } catch {
            print("Failed to refresh garage sales: \(error)")
        }
    }
    
    @MainActor
    private func refreshSeeks() async {
        do {
            // Clear seeks cache
            cacheManager.clearCache(matching: "seeks_")
            
            // Fetch fresh seeks
            let _ = try await APIClient.shared.fetchSeeks()
            
            print("🔍 Seeks refreshed")
        } catch {
            print("Failed to refresh seeks: \(error)")
        }
    }
    
    @MainActor
    private func refreshUserData() async {
        guard AuthManager.shared.isAuthenticated else { return }
        
        do {
            // Clear user cache
            cacheManager.clearCache(matching: "user_")
            cacheManager.clearCache(matching: "profile_")
            
            // Fetch fresh user data  
            let _ = try await APIClient.shared.fetchProfile()
            
            print("👤 User data refreshed")
        } catch {
            print("Failed to refresh user data: \(error)")
        }
    }
    
    // MARK: - Smart Refresh
    
    func shouldRefreshData(for key: String, policy: RefreshPolicy = .smart) -> Bool {
        switch policy {
        case .always:
            return true
            
        case .onAppear:
            return true
            
        case .interval(let interval):
            let lastRefresh = UserDefaults.standard.object(forKey: "lastRefresh_\(key)") as? Date ?? Date.distantPast
            return Date().timeIntervalSince(lastRefresh) > interval
            
        case .manual:
            return false
            
        case .smart:
            // Check network status
            guard networkStatus == .satisfied else { return false }
            
            // Check last refresh time for this key
            let lastRefresh = UserDefaults.standard.object(forKey: "lastRefresh_\(key)") as? Date ?? Date.distantPast
            let staleness = Date().timeIntervalSince(lastRefresh)
            
            // Different staleness thresholds for different data types
            let threshold: TimeInterval
            switch key {
            case "featured_listings":
                threshold = 300 // 5 minutes
            case "marketplace", "listings":
                threshold = 120 // 2 minutes
            case "user_profile", "user_data":
                threshold = 600 // 10 minutes
            case "garage_sales":
                threshold = 180 // 3 minutes
            default:
                threshold = 300 // Default 5 minutes
            }
            
            return staleness > threshold
        }
    }
    
    func markDataRefreshed(for key: String) {
        UserDefaults.standard.set(Date(), forKey: "lastRefresh_\(key)")
    }
    
    // MARK: - WebSocket Support (Future)
    
    func connectToRealTimeUpdates() {
        // Future: Connect to WebSocket for real-time updates
        // This would provide instant updates for:
        // - New listings
        // - Price changes
        // - Availability changes
        // - New messages
        // - New reviews
    }
}

// MARK: - View Modifier for Auto Refresh
struct AutoRefresh: ViewModifier {
    let key: String
    let policy: RefreshPolicy
    @StateObject private var refreshManager = DataRefreshManager.shared
    
    func body(content: Content) -> some View {
        content
            .onAppear {
                if refreshManager.shouldRefreshData(for: key, policy: policy) {
                    Task {
                        await refreshManager.refreshData(for: key)
                    }
                }
            }
            .refreshable {
                await refreshManager.refreshData(for: key)
            }
    }
}

extension View {
    func autoRefresh(key: String, policy: RefreshPolicy = .smart) -> some View {
        modifier(AutoRefresh(key: key, policy: policy))
    }
}

// MARK: - Cache Extension
extension CacheManager {
    func clearCache(matching prefix: String) {
        // For now, just clear all cache
        // In production, implement selective clearing
        clearAll()
    }
}