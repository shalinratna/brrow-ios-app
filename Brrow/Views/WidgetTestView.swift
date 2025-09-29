//
//  WidgetTestView.swift
//  Brrow
//
//  UI for running comprehensive widget integration tests
//

import SwiftUI
import WidgetKit

struct WidgetTestView: View {
    @StateObject private var testRunner = WidgetIntegrationTest()
    @State private var showingDetailedResults = false

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                headerSection

                if testRunner.isRunning {
                    runningSection
                } else {
                    resultsSection
                }

                Spacer()

                actionButtons
            }
            .padding()
            .navigationTitle("Widget Tests")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var headerSection: some View {
        VStack(spacing: 10) {
            Image(systemName: "waveform.badge.plus")
                .font(.system(size: 50))
                .foregroundColor(.blue)

            Text("Widget Integration Test")
                .font(.title2)
                .fontWeight(.bold)

            Text("Comprehensive testing of widget data flow and integration")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }

    private var runningSection: some View {
        VStack(spacing: 15) {
            ProgressView()
                .scaleEffect(1.5)

            Text("Running Tests...")
                .font(.headline)

            Text("This may take a few moments")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(30)
        .background(Color.orange.opacity(0.1))
        .cornerRadius(12)
    }

    private var resultsSection: some View {
        VStack(spacing: 15) {
            if !testRunner.testResults.isEmpty {
                overallStatusCard

                testResultsList
            } else {
                emptyStateView
            }
        }
    }

    private var overallStatusCard: some View {
        HStack {
            Text(testRunner.overallStatus.emoji)
                .font(.title)

            VStack(alignment: .leading) {
                Text("Overall Status")
                    .font(.headline)

                Text(testRunner.overallStatus == .passed ? "All Tests Passed" : "Some Tests Failed")
                    .font(.subheadline)
                    .foregroundColor(testRunner.overallStatus == .passed ? .green : .red)
            }

            Spacer()

            VStack {
                Text("\(testRunner.testResults.filter { $0.status == .passed }.count)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.green)
                Text("Passed")
                    .font(.caption)
            }

            VStack {
                Text("\(testRunner.testResults.filter { $0.status == .failed }.count)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.red)
                Text("Failed")
                    .font(.caption)
            }
        }
        .padding()
        .background(testRunner.overallStatus == .passed ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
        .cornerRadius(12)
    }

    private var testResultsList: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(testRunner.testResults.indices, id: \.self) { index in
                    let result = testRunner.testResults[index]
                    TestResultRow(result: result)
                }
            }
        }
        .frame(maxHeight: 300)
    }

    private var emptyStateView: some View {
        VStack(spacing: 15) {
            Image(systemName: "testtube.2")
                .font(.system(size: 40))
                .foregroundColor(.gray)

            Text("No tests run yet")
                .font(.headline)
                .foregroundColor(.secondary)

            Text("Tap 'Run Tests' to start comprehensive widget testing")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(30)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }

    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button(action: runTests) {
                HStack {
                    Image(systemName: "play.circle.fill")
                    Text("Run Comprehensive Tests")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(testRunner.isRunning ? Color.gray : Color.blue)
                .cornerRadius(12)
            }
            .disabled(testRunner.isRunning)

            HStack(spacing: 12) {
                Button("Refresh Widgets") {
                    WidgetCenter.shared.reloadAllTimelines()
                }
                .font(.subheadline)
                .foregroundColor(.blue)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)

                Button("Show Widget Data") {
                    showingDetailedResults = true
                }
                .font(.subheadline)
                .foregroundColor(.green)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Color.green.opacity(0.1))
                .cornerRadius(8)
            }
        }
        .sheet(isPresented: $showingDetailedResults) {
            WidgetDataDetailView()
        }
    }

    private func runTests() {
        Task {
            await testRunner.runComprehensiveTest()
        }
    }
}

struct TestResultRow: View {
    let result: WidgetIntegrationTest.TestResult

    var body: some View {
        HStack {
            Text(result.status.emoji)
                .font(.title3)

            VStack(alignment: .leading, spacing: 2) {
                Text(result.testName)
                    .font(.headline)
                    .foregroundColor(.primary)

                Text(result.details)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }

            Spacer()

            Text(result.timestamp, style: .time)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
    }
}

struct WidgetDataDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var widgetData = WidgetDataManager.shared.getWidgetData()

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    dataCard("Active Listings", value: "\(widgetData.activeListings)", icon: "list.bullet")
                    dataCard("Unread Messages", value: "\(widgetData.unreadMessages)", icon: "message.badge")
                    dataCard("Today's Earnings", value: "$\(String(format: "%.2f", widgetData.todaysEarnings))", icon: "dollarsign.circle")
                    dataCard("Nearby Items", value: "\(widgetData.nearbyItems)", icon: "location.circle")

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "clock.badge")
                                .foregroundColor(.blue)
                            Text("Recent Activity")
                                .font(.headline)
                        }

                        Text(widgetData.recentActivity)
                            .font(.body)
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "calendar")
                                .foregroundColor(.green)
                            Text("Last Updated")
                                .font(.headline)
                        }

                        Text(widgetData.lastUpdated, style: .date)
                            .font(.body)
                        Text(widgetData.lastUpdated, style: .time)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
            }
            .navigationTitle("Current Widget Data")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Refresh") {
                        widgetData = WidgetDataManager.shared.getWidgetData()
                    }
                }
            }
        }
    }

    private func dataCard(_ title: String, value: String, icon: String) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 30)

            VStack(alignment: .leading) {
                Text(title)
                    .font(.headline)
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
            }

            Spacer()
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

#Preview {
    WidgetTestView()
}