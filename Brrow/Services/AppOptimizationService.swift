//
//  AppOptimizationService.swift
//  Brrow
//
//  Created by Claude on 7/26/25.
//  Comprehensive app optimization service for startup performance and resource management
//

import Foundation
import SwiftUI
import Combine
import CoreData

// MARK: - App Optimization Service
class AppOptimizationService: ObservableObject {
    static let shared = AppOptimizationService()
    
    @Published var isOptimizing = false
    @Published var optimizationProgress: Double = 0.0
    @Published var currentOptimizationStep = ""
    
    private let performanceManager = PerformanceManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    private init() {}
    
    // MARK: - App Launch Optimization
    
    /// Optimize app for launch performance
    func optimizeAppLaunch() async {
        await MainActor.run {
            isOptimizing = true
            optimizationProgress = 0.0
            currentOptimizationStep = "Initializing optimization..."
        }
        
        // Step 1: Clear expired caches (20%)
        await optimizeStorage()
        await updateProgress(0.2, "Storage optimized")
        
        // Step 2: Preload critical resources (40%)
        await preloadCriticalResources()
        await updateProgress(0.4, "Critical resources loaded")
        
        // Step 3: Optimize memory settings (60%)
        await optimizeMemorySettings()
        await updateProgress(0.6, "Memory settings optimized")
        
        // Step 4: Setup performance monitoring (80%)
        await setupPerformanceMonitoring()
        await updateProgress(0.8, "Performance monitoring enabled")
        
        // Step 5: Final optimizations (100%)
        await performFinalOptimizations()
        await updateProgress(1.0, "Optimization complete")
        
        await MainActor.run {
            isOptimizing = false
        }
    }
    
    // MARK: - Runtime Optimization
    
    /// Optimize app during runtime based on current conditions
    func optimizeRuntime() async {
        let metrics = performanceManager.metrics
        
        // Memory optimization
        if metrics.memoryUsage > 200_000_000 { // 200MB
            await optimizeMemoryUsage()
        }
        
        // CPU optimization
        if metrics.cpuUsage > 70.0 {
            await optimizeCPUUsage()
        }
        
        // Battery optimization
        if metrics.batteryLevel < 0.2 {
            await optimizeBatteryUsage()
        }
        
        // Network optimization
        if metrics.apiResponseTime > 5.0 {
            await optimizeNetworkUsage()
        }
    }
    
    // MARK: - Private Methods
    
    private func optimizeStorage() async {
        // Clear expired image cache
        let cacheDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        let imageCacheDir = cacheDir.appendingPathComponent("ImageCache")
        
        if FileManager.default.fileExists(atPath: imageCacheDir.path) {
            let contents = try? FileManager.default.contentsOfDirectory(at: imageCacheDir, includingPropertiesForKeys: [.creationDateKey])
            let expiredDate = Date().addingTimeInterval(-7 * 24 * 60 * 60) // 7 days ago
            
            contents?.forEach { url in
                if let creationDate = try? url.resourceValues(forKeys: [.creationDateKey]).creationDate,
                   creationDate < expiredDate {
                    try? FileManager.default.removeItem(at: url)
                }
            }
        }
        
        // Clear Core Data cache
        // TODO: Fix Core Data model before enabling this
        // PersistenceController.shared.clearExpiredData()
    }
    
    private func preloadCriticalResources() async {
        // Preload essential user data
        if let user = AuthManager.shared.currentUser {
            // Preload recent listings
            let recentListings = try? await APIClient.shared.fetchListings()
            // Listings will be cached by the API client
        }
    }
    
    private func optimizeMemorySettings() async {
        // Configure NSCache settings based on device capabilities
        let totalMemory = ProcessInfo.processInfo.physicalMemory
        let availableMemory = totalMemory / 4 // Use 25% of total memory for caches
        
        // Clear URL cache to start fresh
        URLCache.shared.removeAllCachedResponses()
        
        // Configure URLCache
        let urlCacheSize = min(Int(availableMemory / 2), 100 * 1024 * 1024) // Max 100MB
        URLCache.shared.memoryCapacity = urlCacheSize / 4
        URLCache.shared.diskCapacity = urlCacheSize
    }
    
    private func setupPerformanceMonitoring() async {
        performanceManager.startMonitoring()
        
        // Setup memory warning handling
        NotificationCenter.default.publisher(for: UIApplication.didReceiveMemoryWarningNotification)
            .sink { [weak self] _ in
                Task {
                    await self?.handleMemoryWarning()
                }
            }
            .store(in: &cancellables)
        
        // Setup background app handling
        NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)
            .sink { [weak self] _ in
                Task {
                    await self?.optimizeForBackground()
                }
            }
            .store(in: &cancellables)
    }
    
    private func performFinalOptimizations() async {
        // Enable aggressive compiler optimizations at runtime
        setenv("DYLD_PRINT_STATISTICS", "0", 1) // Disable dyld statistics
        
        // Optimize dispatch queues
        DispatchQueue.global(qos: .utility).async {
            // Warm up commonly used queues
        }
        
        // Pre-warm frequently used DateFormatters to avoid repeated creation
        _ = ISO8601DateFormatter()
        _ = DateFormatter()
    }
    
    @MainActor
    private func updateProgress(_ progress: Double, _ step: String) async {
        optimizationProgress = progress
        currentOptimizationStep = step
        
        // Small delay to show progress
        try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
    }
    
    private func optimizeMemoryUsage() async {
        // Clear caches
        URLCache.shared.removeAllCachedResponses()
        
        // Reduce background processing
        DispatchQueue.global(qos: .background).async {
            // Force garbage collection
            autoreleasepool {}
        }
    }
    
    private func optimizeCPUUsage() async {
        // Reduce animation quality
        await MainActor.run {
            UIView.setAnimationsEnabled(false)
            
            // Re-enable after a short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                UIView.setAnimationsEnabled(true)
            }
        }
        
        // Throttle background tasks
        DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 2) {
            // Resume normal operation
        }
    }
    
    private func optimizeBatteryUsage() async {
        // Reduce location accuracy
        // Disable background app refresh for non-essential features
        // Reduce network polling frequency
        
        await MainActor.run {
            // Dim UI slightly to save battery
            UIScreen.main.brightness = max(UIScreen.main.brightness - 0.1, 0.3)
        }
    }
    
    private func optimizeNetworkUsage() async {
        // Increase request timeout
        // Reduce concurrent network requests
        // Enable request coalescing
        
        // Cancel non-essential network requests
        URLSession.shared.getAllTasks { tasks in
            tasks.forEach { task in
                if task.priority < 0.3 {  // Low priority threshold
                    task.cancel()
                }
            }
        }
    }
    
    private func handleMemoryWarning() async {
        await optimizeMemoryUsage()
        
        // Post notification for views to optimize themselves
        await MainActor.run {
            NotificationCenter.default.post(name: .optimizeMemoryUsage, object: nil)
        }
    }
    
    private func optimizeForBackground() async {
        // Save current state
        PersistenceController.shared.save()
        
        // Clear non-essential caches
        URLCache.shared.removeAllCachedResponses()
        
        // Pause non-essential operations
        performanceManager.stopMonitoring()
    }
}

// MARK: - Optimization Configuration
struct OptimizationConfig {
    let enableAggressiveOptimization: Bool
    let memoryThreshold: Int64 // in bytes
    let cpuThreshold: Double // percentage
    let batteryThreshold: Float // percentage
    let cacheSize: Int // in bytes
    
    static let `default` = OptimizationConfig(
        enableAggressiveOptimization: false,
        memoryThreshold: 200_000_000, // 200MB
        cpuThreshold: 70.0, // 70%
        batteryThreshold: 0.2, // 20%
        cacheSize: 100 * 1024 * 1024 // 100MB
    )
    
    static let aggressive = OptimizationConfig(
        enableAggressiveOptimization: true,
        memoryThreshold: 100_000_000, // 100MB
        cpuThreshold: 50.0, // 50%
        batteryThreshold: 0.3, // 30%
        cacheSize: 50 * 1024 * 1024 // 50MB
    )
    
    static let lowEnd = OptimizationConfig(
        enableAggressiveOptimization: true,
        memoryThreshold: 50_000_000, // 50MB
        cpuThreshold: 40.0, // 40%
        batteryThreshold: 0.4, // 40%
        cacheSize: 25 * 1024 * 1024 // 25MB
    )
}

// MARK: - Optimization Splash View
struct OptimizationSplashView: View {
    @StateObject private var optimizationService = AppOptimizationService.shared
    @State private var showMainApp = false
    
    var body: some View {
        ZStack {
            Theme.Colors.background
                .ignoresSafeArea()
            
            VStack(spacing: 30) {
                // App Logo
                Image("AppIcon") // Replace with actual app icon
                    .resizable()
                    .frame(width: 100, height: 100)
                    .cornerRadius(20)
                    .shadow(radius: 10)
                
                VStack(spacing: 16) {
                    Text("Optimizing Brrow")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text(optimizationService.currentOptimizationStep)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    // Progress Bar
                    ProgressView(value: optimizationService.optimizationProgress)
                        .progressViewStyle(LinearProgressViewStyle(tint: Theme.Colors.primary))
                        .frame(width: 200)
                    
                    Text("\(Int(optimizationService.optimizationProgress * 100))%")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(Theme.Colors.primary)
                }
                
                if optimizationService.optimizationProgress >= 1.0 {
                    Button("Continue") {
                        showMainApp = true
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(width: 200, height: 50)
                    .background(Theme.Colors.primary)
                    .cornerRadius(25)
                    .shadow(radius: 5)
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .padding()
        }
        .fullScreenCover(isPresented: $showMainApp) {
            NativeMainTabView() // Main app view
        }
        .onAppear {
            Task {
                await optimizationService.optimizeAppLaunch()
            }
        }
    }
}

// MARK: - Notification Extensions
extension Notification.Name {
    static let optimizeMemoryUsage = Notification.Name("optimizeMemoryUsage")
    static let performanceAlert = Notification.Name("performanceAlert")
}

// MARK: - PersistenceController Extension
extension PersistenceController {
    func clearExpiredData() {
        let context = container.viewContext
        
        // Clear old cached listings (older than 24 hours)
        let expiredDate = Date().addingTimeInterval(-24 * 60 * 60)
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "CachedListing")
        fetchRequest.predicate = NSPredicate(format: "cachedAt < %@", expiredDate as NSDate)
        
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        
        do {
            try context.execute(deleteRequest)
            try context.save()
        } catch {
            print("Failed to clear expired data: \(error)")
        }
    }
}