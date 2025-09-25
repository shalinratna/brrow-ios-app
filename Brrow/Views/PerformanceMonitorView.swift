//
//  PerformanceMonitorView.swift
//  Brrow
//
//  Real-time performance monitoring for predictive loading system
//

import SwiftUI

struct PerformanceMonitorView: View {
    @StateObject private var predictiveLoader = PredictiveLoadingManager.shared
    @StateObject private var cacheManager = AggressiveCacheManager.shared
    @State private var showingDetails = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Performance Overview Cards
                    performanceOverviewCards

                    // Cache Performance Charts
                    cachePerformanceCharts

                    // Predictive Loading Status
                    predictiveLoadingStatus

                    // Background Sync Progress
                    backgroundSyncProgress

                    // Performance Metrics Details
                    if showingDetails {
                        performanceDetailsSection
                    }

                    // Action Buttons
                    actionButtonsSection
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
            .navigationTitle("⚡ Performance Monitor")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Details") {
                        withAnimation(.spring()) {
                            showingDetails.toggle()
                        }
                    }
                }
            }
        }
    }

    // MARK: - Performance Overview Cards

    private var performanceOverviewCards: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 16) {
            // Cache Hit Rate Card
            PerformanceCard(
                title: "Cache Hit Rate",
                value: String(format: "%.1f%%", cacheManager.getPerformanceMetrics()["image_cache_hit_rate"] as? Double ?? 0 * 100),
                icon: "speedometer",
                color: .green,
                subtitle: "Image Cache"
            )

            // API Cache Hit Rate Card
            PerformanceCard(
                title: "API Cache Rate",
                value: String(format: "%.1f%%", cacheManager.getPerformanceMetrics()["api_cache_hit_rate"] as? Double ?? 0 * 100),
                icon: "server.rack",
                color: .blue,
                subtitle: "API Responses"
            )

            // Predictive Loading Card
            PerformanceCard(
                title: "Predictive Loading",
                value: predictiveLoader.isPredictiveLoading ? "Active" : "Idle",
                icon: "brain.head.profile",
                color: predictiveLoader.isPredictiveLoading ? .orange : .gray,
                subtitle: "Intelligence"
            )

            // Background Sync Card
            PerformanceCard(
                title: "Background Sync",
                value: String(format: "%.0f%%", predictiveLoader.backgroundSyncProgress * 100),
                icon: "arrow.triangle.2.circlepath",
                color: .purple,
                subtitle: "Data Sync"
            )
        }
    }

    // MARK: - Cache Performance Charts

    private var cachePerformanceCharts: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Cache Performance")
                .font(.headline)
                .foregroundColor(Theme.Colors.text)

            // Image Cache Usage
            VStack(alignment: .leading, spacing: 8) {
                Text("Image Cache Usage")
                    .font(.subheadline)
                    .foregroundColor(Theme.Colors.secondaryText)

                ProgressView(
                    value: Double(cacheManager.getPerformanceMetrics()["image_cache_count"] as? Int ?? 0),
                    total: 500
                ) {
                    HStack {
                        Text("Images Cached")
                        Spacer()
                        Text("\(cacheManager.getPerformanceMetrics()["image_cache_count"] as? Int ?? 0)/500")
                    }
                    .font(.caption)
                }
                .tint(.blue)
            }

            // API Cache Usage
            VStack(alignment: .leading, spacing: 8) {
                Text("API Cache Usage")
                    .font(.subheadline)
                    .foregroundColor(Theme.Colors.secondaryText)

                ProgressView(
                    value: Double(cacheManager.getPerformanceMetrics()["api_cache_count"] as? Int ?? 0),
                    total: 1000
                ) {
                    HStack {
                        Text("API Responses Cached")
                        Spacer()
                        Text("\(cacheManager.getPerformanceMetrics()["api_cache_count"] as? Int ?? 0)/1000")
                    }
                    .font(.caption)
                }
                .tint(.green)
            }
        }
        .padding(16)
        .background(Theme.Colors.surface)
        .cornerRadius(12)
    }

    // MARK: - Predictive Loading Status

    private var predictiveLoadingStatus: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("🚀 Predictive Loading System")
                .font(.headline)
                .foregroundColor(Theme.Colors.text)

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Status")
                        .font(.caption)
                        .foregroundColor(Theme.Colors.secondaryText)

                    HStack(spacing: 8) {
                        Circle()
                            .fill(predictiveLoader.isPredictiveLoading ? Color.orange : Color.gray)
                            .frame(width: 8, height: 8)
                        Text(predictiveLoader.isPredictiveLoading ? "Loading" : "Ready")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("Intelligence Level")
                        .font(.caption)
                        .foregroundColor(Theme.Colors.secondaryText)

                    Text("🧠 High")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.green)
                }
            }

            // Recent Predictions
            if !predictiveLoader.getPerformanceMetrics().isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Recent Predictions")
                        .font(.caption)
                        .foregroundColor(Theme.Colors.secondaryText)

                    LazyVStack(alignment: .leading, spacing: 4) {
                        PredictionRow(icon: "person.circle", text: "User profiles pre-loaded", time: "2m ago", success: true)
                        PredictionRow(icon: "photo.stack", text: "Listing images cached", time: "3m ago", success: true)
                        PredictionRow(icon: "message", text: "Conversations synced", time: "5m ago", success: true)
                    }
                }
            }
        }
        .padding(16)
        .background(Theme.Colors.surface)
        .cornerRadius(12)
    }

    // MARK: - Background Sync Progress

    private var backgroundSyncProgress: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("🔄 Background Sync")
                .font(.headline)
                .foregroundColor(Theme.Colors.text)

            ProgressView(
                value: predictiveLoader.backgroundSyncProgress
            ) {
                HStack {
                    Text("Syncing user data...")
                        .font(.subheadline)
                    Spacer()
                    Text(String(format: "%.0f%%", predictiveLoader.backgroundSyncProgress * 100))
                        .font(.caption)
                        .fontWeight(.medium)
                }
            }
            .tint(.purple)

            if predictiveLoader.backgroundSyncProgress > 0 && predictiveLoader.backgroundSyncProgress < 1 {
                Text("Syncing profile, favorites, messages, and notifications...")
                    .font(.caption)
                    .foregroundColor(Theme.Colors.secondaryText)
            } else if predictiveLoader.backgroundSyncProgress == 1 {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.caption)
                    Text("Sync completed successfully")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }
        }
        .padding(16)
        .background(Theme.Colors.surface)
        .cornerRadius(12)
    }

    // MARK: - Performance Details

    private var performanceDetailsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("📊 Detailed Metrics")
                .font(.headline)
                .foregroundColor(Theme.Colors.text)

            // Predictive Loading Metrics
            MetricsGroup(
                title: "Predictive Loading",
                metrics: predictiveLoader.getPerformanceMetrics()
            )

            // Cache Metrics
            MetricsGroup(
                title: "Cache Performance",
                metrics: cacheManager.getPerformanceMetrics()
            )
        }
        .padding(16)
        .background(Theme.Colors.surface)
        .cornerRadius(12)
    }

    // MARK: - Action Buttons

    private var actionButtonsSection: some View {
        VStack(spacing: 12) {
            // Clear Caches Button
            Button(action: {
                cacheManager.clearAllCaches()
                predictiveLoader.clearAllCaches()
            }) {
                HStack {
                    Image(systemName: "trash")
                    Text("Clear All Caches")
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.red.opacity(0.1))
                .foregroundColor(.red)
                .cornerRadius(8)
            }

            // Force Background Sync Button
            Button(action: {
                Task {
                    await predictiveLoader.startBackgroundSync()
                }
            }) {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("Force Background Sync")
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Theme.Colors.primary.opacity(0.1))
                .foregroundColor(Theme.Colors.primary)
                .cornerRadius(8)
            }
        }
        .padding(.horizontal, 16)
    }
}

// MARK: - Supporting Views

struct PerformanceCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title3)
                Spacer()
            }

            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(Theme.Colors.text)

            Text(title)
                .font(.caption)
                .foregroundColor(Theme.Colors.secondaryText)

            Text(subtitle)
                .font(.caption2)
                .foregroundColor(color)
        }
        .padding(16)
        .background(Theme.Colors.surface)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

struct PredictionRow: View {
    let icon: String
    let text: String
    let time: String
    let success: Bool

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(success ? .green : .red)
                .font(.caption)
                .frame(width: 16)

            Text(text)
                .font(.caption)
                .foregroundColor(Theme.Colors.text)

            Spacer()

            Text(time)
                .font(.caption2)
                .foregroundColor(Theme.Colors.secondaryText)
        }
    }
}

struct MetricsGroup: View {
    let title: String
    let metrics: [String: Any]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(Theme.Colors.text)

            ForEach(Array(metrics.keys.sorted()), id: \.self) { key in
                HStack {
                    Text(key.replacingOccurrences(of: "_", with: " ").capitalized)
                        .font(.caption)
                        .foregroundColor(Theme.Colors.secondaryText)

                    Spacer()

                    Text("\(metrics[key] ?? "N/A")")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(Theme.Colors.text)
                }
            }
        }
        .padding(12)
        .background(Theme.Colors.background)
        .cornerRadius(8)
    }
}

// MARK: - Preview

#Preview {
    PerformanceMonitorView()
}