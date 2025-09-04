//
//  LocationPermissionView.swift
//  Brrow
//
//  Location permission request UI
//

import SwiftUI
import CoreLocation

struct LocationPermissionView: View {
    @StateObject private var locationService = LocationService.shared
    @Environment(\.dismiss) private var dismiss
    let onPermissionGranted: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .font(.title3)
                        .foregroundColor(.secondary)
                        .padding(10)
                        .background(Circle().fill(Color(.systemGray5)))
                }
                
                Spacer()
            }
            .padding()
            
            Spacer()
            
            // Content
            VStack(spacing: 24) {
                // Icon
                ZStack {
                    Circle()
                        .fill(Theme.Colors.primary.opacity(0.1))
                        .frame(width: 120, height: 120)
                    
                    Image(systemName: "location.fill")
                        .font(.system(size: 50))
                        .foregroundColor(Theme.Colors.primary)
                }
                
                // Title
                Text("Enable Location Services")
                    .font(.title.bold())
                    .multilineTextAlignment(.center)
                
                // Description
                Text("Brrow needs your location to:\n• Auto-fill your address when creating listings\n• Show items near you\n• Connect you with neighbors")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                // Status indicator
                HStack {
                    Image(systemName: statusIcon)
                        .foregroundColor(statusColor)
                    
                    Text(statusText)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(RoundedRectangle(cornerRadius: 20).fill(Color(.systemGray6)))
            }
            
            Spacer()
            
            // Action buttons
            VStack(spacing: 12) {
                Button(action: requestPermission) {
                    HStack {
                        Image(systemName: "location.fill")
                        Text(buttonText)
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(buttonColor)
                    )
                }
                .disabled(locationService.authorizationStatus == .authorizedAlways || 
                         locationService.authorizationStatus == .authorizedWhenInUse)
                
                if locationService.authorizationStatus == .notDetermined {
                    Button(action: { dismiss() }) {
                        Text("Not Now")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
        }
        .background(Color(.systemBackground))
        .onReceive(locationService.$authorizationStatus) { status in
            if status == .authorizedAlways || status == .authorizedWhenInUse {
                // Permission granted - dismiss after a short delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    onPermissionGranted()
                    dismiss()
                }
            }
        }
    }
    
    private var statusIcon: String {
        switch locationService.authorizationStatus {
        case .notDetermined:
            return "questionmark.circle"
        case .restricted, .denied:
            return "xmark.circle"
        case .authorizedAlways, .authorizedWhenInUse:
            return "checkmark.circle"
        @unknown default:
            return "questionmark.circle"
        }
    }
    
    private var statusColor: Color {
        switch locationService.authorizationStatus {
        case .notDetermined:
            return .orange
        case .restricted, .denied:
            return .red
        case .authorizedAlways, .authorizedWhenInUse:
            return .green
        @unknown default:
            return .gray
        }
    }
    
    private var statusText: String {
        switch locationService.authorizationStatus {
        case .notDetermined:
            return "Location permission not set"
        case .restricted:
            return "Location access restricted"
        case .denied:
            return "Location access denied"
        case .authorizedAlways:
            return "Location access enabled"
        case .authorizedWhenInUse:
            return "Location access enabled"
        @unknown default:
            return "Unknown status"
        }
    }
    
    private var buttonText: String {
        switch locationService.authorizationStatus {
        case .notDetermined:
            return "Enable Location"
        case .restricted, .denied:
            return "Open Settings"
        case .authorizedAlways, .authorizedWhenInUse:
            return "Location Enabled"
        @unknown default:
            return "Enable Location"
        }
    }
    
    private var buttonColor: Color {
        switch locationService.authorizationStatus {
        case .notDetermined:
            return Theme.Colors.primary
        case .restricted, .denied:
            return .blue
        case .authorizedAlways, .authorizedWhenInUse:
            return .green
        @unknown default:
            return Theme.Colors.primary
        }
    }
    
    private func requestPermission() {
        switch locationService.authorizationStatus {
        case .notDetermined:
            locationService.requestLocationPermission()
        case .restricted, .denied:
            // Open settings
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
        default:
            break
        }
    }
}

// MARK: - Preview
struct LocationPermissionView_Previews: PreviewProvider {
    static var previews: some View {
        LocationPermissionView {
            print("Permission granted")
        }
    }
}