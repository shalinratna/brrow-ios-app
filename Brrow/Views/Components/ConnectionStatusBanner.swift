//
//  ConnectionStatusBanner.swift
//  Brrow
//
//  Non-intrusive banner showing connection status
//  Appears when connection is lost or poor
//

import SwiftUI

struct ConnectionStatusBanner: View {
    @ObservedObject var networkManager = NetworkManager.shared
    @State private var isDismissed = false

    var body: some View {
        VStack(spacing: 0) {
            if shouldShowBanner {
                HStack(spacing: 12) {
                    // Icon
                    Image(systemName: iconName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)

                    // Message
                    Text(networkManager.connectionQuality.message)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                        .lineLimit(1)

                    Spacer()

                    // Dismiss button (only for poor connection, not disconnected)
                    if networkManager.connectionQuality == .poor {
                        Button(action: {
                            withAnimation(.spring(response: 0.3)) {
                                isDismissed = true
                            }
                        }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white.opacity(0.8))
                                .padding(6)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(backgroundColor)
                .transition(.move(edge: .top).combined(with: .opacity))
                .onTapGesture {
                    // Allow tapping banner to dismiss if connection is poor
                    if networkManager.connectionQuality == .poor {
                        withAnimation(.spring(response: 0.3)) {
                            isDismissed = true
                        }
                    }
                }
            }
        }
        .onChange(of: networkManager.connectionQuality) { newQuality in
            // Reset dismissed state when connection quality changes
            if newQuality.shouldShowBanner && isDismissed {
                isDismissed = false
            }

            // Auto-dismiss when connection is good
            if newQuality == .good {
                isDismissed = false
            }
        }
    }

    private var shouldShowBanner: Bool {
        return networkManager.connectionQuality.shouldShowBanner && !isDismissed
    }

    private var backgroundColor: Color {
        switch networkManager.connectionQuality {
        case .disconnected:
            return .red
        case .poor:
            return .orange
        case .good:
            return .clear
        }
    }

    private var iconName: String {
        switch networkManager.connectionQuality {
        case .disconnected:
            return "wifi.slash"
        case .poor:
            return "wifi.exclamationmark"
        case .good:
            return ""
        }
    }
}

// MARK: - View Extension for Easy Integration
extension View {
    /// Adds a connection status banner to the top of the view
    func connectionStatusBanner() -> some View {
        ZStack(alignment: .top) {
            self

            ConnectionStatusBanner()
                .zIndex(999) // Ensure banner appears above other content
        }
    }
}

// MARK: - Preview
struct ConnectionStatusBanner_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            ConnectionStatusBanner()

            Spacer()

            Text("Main Content")
                .font(.title)
        }
    }
}
