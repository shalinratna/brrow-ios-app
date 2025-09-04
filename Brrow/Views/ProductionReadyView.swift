//
//  ProductionReadyView.swift
//  Brrow
//
//  Production-Ready App Demo
//

import SwiftUI

struct ProductionReadyView: View {
    @EnvironmentObject var authManager: AuthManager
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            Text("Brrow Production Status")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top, 40)
            
            // Status indicators
            VStack(alignment: .leading, spacing: 16) {
                StatusRow(title: "Native Tab Bar", status: .completed)
                StatusRow(title: "Professional UI Design", status: .completed)
                StatusRow(title: "Real Authentication (brrowapp.com API)", status: .completed)
                StatusRow(title: "Login/Signup Flow", status: .completed)
                StatusRow(title: "API Integration", status: .active)
                StatusRow(title: "Core Data Offline Support", status: .ready)
                StatusRow(title: "Push Notifications", status: .ready)
                StatusRow(title: "Stripe Payments", status: .ready)
            }
            .padding()
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(12)
            .padding(.horizontal)
            
            // User info
            if let user = authManager.currentUser {
                VStack(spacing: 8) {
                    Text("Logged in as:")
                        .foregroundColor(.secondary)
                    Text(user.username)
                        .font(.title2)
                        .fontWeight(.semibold)
                    Text(user.email)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(12)
                .padding(.horizontal)
            }
            
            Spacer()
            
            // Key features
            VStack(spacing: 12) {
                Text("Production Features")
                    .font(.headline)
                
                Text("✅ Native iOS Tab Bar")
                Text("✅ Professional Login/Signup")
                Text("✅ Real API Integration")
                Text("✅ Secure Authentication")
                Text("✅ Modern UI Design")
            }
            .padding()
            .background(Theme.Colors.primary.opacity(0.1))
            .cornerRadius(12)
            .padding(.horizontal)
            
            Spacer()
        }
    }
}

struct StatusRow: View {
    let title: String
    let status: Status
    
    enum Status {
        case completed, active, ready
        
        var color: Color {
            switch self {
            case .completed: return .green
            case .active: return .orange
            case .ready: return .blue
            }
        }
        
        var icon: String {
            switch self {
            case .completed: return "checkmark.circle.fill"
            case .active: return "circle.inset.filled"
            case .ready: return "circle"
            }
        }
    }
    
    var body: some View {
        HStack {
            Image(systemName: status.icon)
                .foregroundColor(status.color)
            Text(title)
                .foregroundColor(.primary)
            Spacer()
        }
    }
}

#Preview {
    ProductionReadyView()
        .environmentObject(AuthManager.shared)
}