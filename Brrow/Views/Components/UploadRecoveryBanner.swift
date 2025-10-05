//
//  UploadRecoveryBanner.swift
//  Brrow
//
//  UI banner to show upload recovery status
//

import SwiftUI

struct UploadRecoveryBanner: View {

    @StateObject private var persistence = UploadQueuePersistence.shared
    @State private var showBanner = false
    @State private var bannerMessage = ""
    @State private var bannerType: BannerType = .info

    enum BannerType {
        case info
        case success
        case warning
        case error

        var color: Color {
            switch self {
            case .info: return .blue
            case .success: return .green
            case .warning: return .orange
            case .error: return .red
            }
        }

        var icon: String {
            switch self {
            case .info: return "arrow.clockwise.circle.fill"
            case .success: return "checkmark.circle.fill"
            case .warning: return "exclamationmark.triangle.fill"
            case .error: return "xmark.circle.fill"
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            if showBanner {
                HStack(spacing: 12) {
                    Image(systemName: bannerType.icon)
                        .foregroundColor(bannerType.color)
                        .font(.title3)

                    Text(bannerMessage)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)

                    Spacer()

                    Button(action: {
                        withAnimation {
                            showBanner = false
                        }
                    }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                }
                .padding()
                .background(bannerType.color.opacity(0.1))
                .cornerRadius(12)
                .padding(.horizontal)
                .padding(.top, 8)
                .transition(.move(edge: .top).combined(with: .opacity))
            }

            // Show restoring progress
            if persistence.isRestoring {
                HStack(spacing: 12) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())

                    Text("Resuming \(persistence.pendingUploads.count) pending uploads...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Spacer()
                }
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(12)
                .padding(.horizontal)
                .padding(.top, 8)
            }
        }
        .onAppear {
            setupNotifications()
        }
        .onReceive(NotificationCenter.default.publisher(for: .showUploadResumeAlert)) { notification in
            handleResumeAlert(notification)
        }
    }

    private func setupNotifications() {
        // Check for pending uploads on appear
        let stats = persistence.getQueueStatistics()
        if stats.shouldRetry > 0 {
            showInfoBanner(message: "Found \(stats.shouldRetry) pending upload\(stats.shouldRetry > 1 ? "s" : "") from previous session")
        }
    }

    private func handleResumeAlert(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let message = userInfo["message"] as? String,
              let successCount = userInfo["successCount"] as? Int,
              let failureCount = userInfo["failureCount"] as? Int else {
            return
        }

        if failureCount == 0 {
            showSuccessBanner(message: message)
        } else if successCount > 0 {
            showWarningBanner(message: message)
        } else {
            showErrorBanner(message: message)
        }
    }

    private func showInfoBanner(message: String) {
        bannerMessage = message
        bannerType = .info
        withAnimation {
            showBanner = true
        }

        // Auto-hide after 5 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            withAnimation {
                showBanner = false
            }
        }
    }

    private func showSuccessBanner(message: String) {
        bannerMessage = message
        bannerType = .success
        withAnimation {
            showBanner = true
        }

        // Auto-hide after 4 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
            withAnimation {
                showBanner = false
            }
        }
    }

    private func showWarningBanner(message: String) {
        bannerMessage = message
        bannerType = .warning
        withAnimation {
            showBanner = true
        }

        // Auto-hide after 6 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 6) {
            withAnimation {
                showBanner = false
            }
        }
    }

    private func showErrorBanner(message: String) {
        bannerMessage = message
        bannerType = .error
        withAnimation {
            showBanner = true
        }

        // Auto-hide after 6 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 6) {
            withAnimation {
                showBanner = false
            }
        }
    }
}

// MARK: - Usage in Main App

extension View {
    /// Add upload recovery banner to any view
    func withUploadRecoveryBanner() -> some View {
        VStack(spacing: 0) {
            UploadRecoveryBanner()
            self
        }
    }
}

// MARK: - Preview

struct UploadRecoveryBanner_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            UploadRecoveryBanner()
            Spacer()
        }
    }
}
