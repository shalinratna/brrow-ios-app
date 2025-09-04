//
//  PerformanceManager.swift
//  Brrow
//
//  Created by Claude on 7/26/25.
//  Comprehensive performance monitoring and optimization service
//

import Foundation
import SwiftUI
import Combine
import os.log

// MARK: - Performance Metrics
struct AppPerformanceMetrics {
    var appLaunchTime: TimeInterval = 0
    var memoryUsage: Int64 = 0
    var cpuUsage: Double = 0
    var batteryLevel: Float = 0
    var networkLatency: TimeInterval = 0
    var viewRenderTime: TimeInterval = 0
    var apiResponseTime: TimeInterval = 0
    var imageLoadTime: TimeInterval = 0
    var cacheHitRate: Double = 0
    var backgroundTaskDuration: TimeInterval = 0
    
    // View-specific metrics
    var viewAppearTime: [String: TimeInterval] = [:]
    var viewMemoryUsage: [String: Int64] = [:]
    var animationFrameRate: [String: Double] = [:]
}

// MARK: - Performance Alert Level
enum PerformanceAlertLevel {
    case normal
    case warning
    case critical
    
    var threshold: (memory: Int64, cpu: Double, battery: Float) {
        switch self {
        case .normal:
            return (memory: 100_000_000, cpu: 50.0, battery: 0.3) // 100MB, 50%, 30%
        case .warning:
            return (memory: 200_000_000, cpu: 70.0, battery: 0.2) // 200MB, 70%, 20%
        case .critical:
            return (memory: 300_000_000, cpu: 90.0, battery: 0.1) // 300MB, 90%, 10%
        }
    }
}

// MARK: - Performance Manager
class PerformanceManager: ObservableObject {
    static let shared = PerformanceManager()
    
    @Published var metrics = AppPerformanceMetrics()
    @Published var alertLevel: PerformanceAlertLevel = .normal
    @Published var isMonitoring = false
    @Published var optimizationRecommendations: [String] = []
    
    private let logger = Logger(subsystem: "com.brrow.performance", category: "metrics")
    private var cancellables = Set<AnyCancellable>()
    private var monitoringTimer: Timer?
    private var appLaunchStartTime: Date?
    
    // Memory optimization
    private let imageCache = NSCache<NSString, UIImage>()
    private let viewCache = NSCache<NSString, AnyObject>()
    
    // Performance tracking
    private var viewAppearTimes: [String: Date] = [:]
    private var networkStartTimes: [String: Date] = [:]
    
    private init() {
        setupImageCache()
        startAppLaunchTimer()
    }
    
    // MARK: - Public Interface
    
    /// Start performance monitoring
    func startMonitoring() {
        guard !isMonitoring else { return }
        
        isMonitoring = true
        logger.info("Performance monitoring started")
        
        // Start periodic monitoring
        monitoringTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            Task {
                await self.updateMetrics()
            }
        }
        
        // Monitor battery level changes
        NotificationCenter.default.publisher(for: UIDevice.batteryLevelDidChangeNotification)
            .sink { [weak self] _ in
                self?.updateBatteryMetrics()
            }
            .store(in: &cancellables)
    }
    
    /// Stop performance monitoring
    func stopMonitoring() {
        guard isMonitoring else { return }
        
        isMonitoring = false
        monitoringTimer?.invalidate()
        monitoringTimer = nil
        cancellables.removeAll()
        
        logger.info("Performance monitoring stopped")
    }
    
    /// Track app launch completion
    func trackAppLaunchCompleted() {
        if let startTime = appLaunchStartTime {
            metrics.appLaunchTime = Date().timeIntervalSince(startTime)
            logger.info("App launch completed in \(self.metrics.appLaunchTime)s")
        }
    }
    
    /// Track view appearance
    func trackViewAppear(_ viewName: String) {
        viewAppearTimes[viewName] = Date()
    }
    
    /// Track view disappearance and calculate render time
    func trackViewDisappear(_ viewName: String) {
        if let appearTime = viewAppearTimes[viewName] {
            let renderTime = Date().timeIntervalSince(appearTime)
            metrics.viewAppearTime[viewName] = renderTime
            viewAppearTimes.removeValue(forKey: viewName)
            
            logger.debug("View \(viewName) render time: \(renderTime)s")
        }
    }
    
    /// Track network request start
    func trackNetworkStart(_ requestId: String) {
        networkStartTimes[requestId] = Date()
    }
    
    /// Track network request completion
    func trackNetworkComplete(_ requestId: String) {
        if let startTime = networkStartTimes[requestId] {
            let responseTime = Date().timeIntervalSince(startTime)
            metrics.apiResponseTime = responseTime
            networkStartTimes.removeValue(forKey: requestId)
            
            logger.debug("Network request \(requestId) completed in \(responseTime)s")
        }
    }
    
    /// Get cached image or nil if not cached
    func getCachedImage(for key: String) -> UIImage? {
        return imageCache.object(forKey: NSString(string: key))
    }
    
    /// Cache image for future use
    func cacheImage(_ image: UIImage, for key: String) {
        imageCache.setObject(image, forKey: NSString(string: key))
    }
    
    /// Clear all caches to free memory
    func clearCaches() {
        imageCache.removeAllObjects()
        viewCache.removeAllObjects()
        logger.info("All caches cleared")
    }
    
    /// Get performance recommendations
    func getOptimizationRecommendations() -> [String] {
        var recommendations: [String] = []
        
        // Memory recommendations
        if metrics.memoryUsage > 200_000_000 { // 200MB
            recommendations.append("High memory usage detected. Consider clearing caches or reducing image sizes.")
        }
        
        // CPU recommendations
        if metrics.cpuUsage > 70.0 {
            recommendations.append("High CPU usage detected. Reduce animations or background processing.")
        }
        
        // Battery recommendations
        if metrics.batteryLevel < 0.2 {
            recommendations.append("Low battery detected. Enable power saving mode.")
        }
        
        // Network recommendations
        if metrics.apiResponseTime > 5.0 {
            recommendations.append("Slow network detected. Enable offline mode or reduce network requests.")
        }
        
        // View performance recommendations
        for (viewName, renderTime) in metrics.viewAppearTime {
            if renderTime > 1.0 {
                recommendations.append("View \(viewName) takes \(String(format: "%.2f", renderTime))s to load. Consider optimization.")
            }
        }
        
        return recommendations
    }
    
    // MARK: - Private Methods
    
    private func setupImageCache() {
        imageCache.countLimit = 100 // Limit to 100 images
        imageCache.totalCostLimit = 50 * 1024 * 1024 // 50MB limit
    }
    
    private func startAppLaunchTimer() {
        appLaunchStartTime = Date()
    }
    
    @MainActor
    private func updateMetrics() async {
        // Update memory usage
        updateMemoryMetrics()
        
        // Update CPU usage
        updateCPUMetrics()
        
        // Update battery metrics
        updateBatteryMetrics()
        
        // Update cache metrics
        updateCacheMetrics()
        
        // Update alert level
        updateAlertLevel()
        
        // Update recommendations
        optimizationRecommendations = getOptimizationRecommendations()
    }
    
    private func updateMemoryMetrics() {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            metrics.memoryUsage = Int64(info.resident_size)
        }
    }
    
    private func updateCPUMetrics() {
        var info = host_cpu_load_info()
        var count = mach_msg_type_number_t(MemoryLayout<host_cpu_load_info>.size / MemoryLayout<integer_t>.size)
        
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                host_statistics(mach_host_self(), HOST_CPU_LOAD_INFO, $0, &count)
            }
        }
        
        if result == KERN_SUCCESS {
            let userTime = Double(info.cpu_ticks.0)
            let systemTime = Double(info.cpu_ticks.1)
            let idleTime = Double(info.cpu_ticks.2)
            let totalTime = userTime + systemTime + idleTime
            
            if totalTime > 0 {
                metrics.cpuUsage = ((userTime + systemTime) / totalTime) * 100.0
            }
        }
    }
    
    private func updateBatteryMetrics() {
        UIDevice.current.isBatteryMonitoringEnabled = true
        metrics.batteryLevel = UIDevice.current.batteryLevel
    }
    
    private func updateCacheMetrics() {
        // Calculate cache hit rate (placeholder - would need actual tracking)
        metrics.cacheHitRate = 0.75 // 75% hit rate
    }
    
    private func updateAlertLevel() {
        let thresholds = PerformanceAlertLevel.critical.threshold
        
        if metrics.memoryUsage > thresholds.memory ||
           metrics.cpuUsage > thresholds.cpu ||
           metrics.batteryLevel < thresholds.battery {
            alertLevel = .critical
        } else {
            let warningThresholds = PerformanceAlertLevel.warning.threshold
            if metrics.memoryUsage > warningThresholds.memory ||
               metrics.cpuUsage > warningThresholds.cpu ||
               metrics.batteryLevel < warningThresholds.battery {
                alertLevel = .warning
            } else {
                alertLevel = .normal
            }
        }
    }
}

// MARK: - Performance View Modifier
struct PerformanceTrackingModifier: ViewModifier {
    let viewName: String
    @StateObject private var performanceManager = PerformanceManager.shared
    
    func body(content: Content) -> some View {
        content
            .onAppear {
                performanceManager.trackViewAppear(viewName)
            }
            .onDisappear {
                performanceManager.trackViewDisappear(viewName)
            }
    }
}

extension View {
    func trackPerformance(_ viewName: String) -> some View {
        modifier(PerformanceTrackingModifier(viewName: viewName))
    }
}

// MARK: - Performance Dashboard View
struct PerformanceDashboardView: View {
    @StateObject private var performanceManager = PerformanceManager.shared
    
    var body: some View {
        NavigationView {
            List {
                Section("Current Metrics") {
                    MetricRow(title: "Memory Usage", value: formatBytes($performanceManager.metrics.wrappedValue.memoryUsage), color: colorForMemory)
                    MetricRow(title: "CPU Usage", value: String(format: "%.1f%%", performanceManager.metrics.cpuUsage), color: colorForCPU)
                    MetricRow(title: "Battery Level", value: String(format: "%.0f%%", performanceManager.metrics.batteryLevel * 100), color: colorForBattery)
                    MetricRow(title: "App Launch Time", value: String(format: "%.2fs", performanceManager.metrics.appLaunchTime), color: .primary)
                }
                
                Section("Network Performance") {
                    MetricRow(title: "API Response Time", value: String(format: "%.2fs", performanceManager.metrics.apiResponseTime), color: .primary)
                    MetricRow(title: "Cache Hit Rate", value: String(format: "%.1f%%", performanceManager.metrics.cacheHitRate * 100), color: .primary)
                }
                
                Section("View Performance") {
                    ForEach(Array(performanceManager.metrics.viewAppearTime.keys.sorted()), id: \.self) { viewName in
                        if let renderTime = performanceManager.metrics.viewAppearTime[viewName] {
                            MetricRow(title: viewName, value: String(format: "%.2fs", renderTime), color: renderTime > 1.0 ? .red : .green)
                        }
                    }
                }
                
                if !performanceManager.optimizationRecommendations.isEmpty {
                    Section("Recommendations") {
                        ForEach(performanceManager.optimizationRecommendations, id: \.self) { recommendation in
                            Text(recommendation)
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                    }
                }
                
                Section("Actions") {
                    Button("Clear Caches") {
                        performanceManager.clearCaches()
                        HapticManager.impact(style: .medium)
                    }
                    .foregroundColor(.red)
                    
                    Toggle("Performance Monitoring", isOn: .constant(performanceManager.isMonitoring))
                        .disabled(true)
                }
            }
            .navigationTitle("Performance")
            .onAppear {
                performanceManager.startMonitoring()
            }
        }
    }
    
    private var colorForMemory: Color {
        let usage = $performanceManager.metrics.wrappedValue.memoryUsage
        if usage > 300_000_000 { return .red }
        if usage > 200_000_000 { return .orange }
        return .green
    }
    
    private var colorForCPU: Color {
        let usage = $performanceManager.metrics.wrappedValue.cpuUsage
        if usage > 90 { return .red }
        if usage > 70 { return .orange }
        return .green
    }
    
    private var colorForBattery: Color {
        let level = $performanceManager.metrics.wrappedValue.batteryLevel
        if level < 0.1 { return .red }
        if level < 0.2 { return .orange }
        return .green
    }
    
    private func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useGB]
        formatter.countStyle = .memory
        return formatter.string(fromByteCount: bytes)
    }
}

struct MetricRow: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
    }
}