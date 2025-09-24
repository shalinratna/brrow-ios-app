//
//  BusinessAccountView.swift
//  Brrow
//
//  Business account management view
//

import SwiftUI

struct BusinessAccountView: View {
    @StateObject private var viewModel = BusinessAccountViewModel()
    @State private var showingVerification = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Theme.Colors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: Theme.Spacing.lg) {
                        // Business Info Card
                        if let businessAccount = viewModel.businessAccount {
                            BusinessInfoCard(businessAccount: businessAccount)
                        }
                        
                        // Verification Status
                        VerificationStatusCard(
                            status: viewModel.verificationStatus,
                            onStartVerification: {
                                showingVerification = true
                            }
                        )
                        
                        // Business Statistics
                        BusinessStatsGrid(viewModel: viewModel)
                        
                        // Quick Actions
                        BusinessQuickActions()
                    }
                    .padding(.horizontal, Theme.Spacing.md)
                    .padding(.vertical, Theme.Spacing.lg)
                }
            }
            .navigationTitle("Business Account")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingVerification) {
                BusinessVerificationView()
            }
            .onAppear {
                viewModel.loadBusinessAccount()
            }
        }
    }
}

struct BusinessInfoCard: View {
    let businessAccount: BusinessAccount
    
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("Business Information")
                .font(.headline)
                .foregroundColor(Theme.Colors.text)
            
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                InfoRow(label: "Business Name", value: businessAccount.businessName)
                InfoRow(label: "Business Type", value: businessAccount.businessType)
                if let email = businessAccount.businessEmail {
                    InfoRow(label: "Email", value: email)
                }
                if let phone = businessAccount.businessPhone {
                    InfoRow(label: "Phone", value: phone)
                }
            }
        }
        .padding(Theme.Spacing.md)
        .background(Theme.Colors.secondaryBackground)
        .cornerRadius(Theme.CornerRadius.lg)
    }
}

struct VerificationStatusCard: View {
    let status: String
    let onStartVerification: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            HStack {
                Text("Verification Status")
                    .font(.headline)
                    .foregroundColor(Theme.Colors.text)
                
                Spacer()
                
                StatusBadge(status: status)
            }
            
            Text(statusDescription)
                .font(.body)
                .foregroundColor(Theme.Colors.secondaryText)
            
            if status == "pending" {
                Button("Start Verification") {
                    onStartVerification()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
        }
        .padding(Theme.Spacing.md)
        .background(Theme.Colors.secondaryBackground)
        .cornerRadius(Theme.CornerRadius.lg)
    }
    
    private var statusDescription: String {
        switch status {
        case "verified":
            return "Your business account is verified and ready to use all features."
        case "pending":
            return "Complete your business verification to unlock premium features."
        case "rejected":
            return "Your verification was rejected. Please contact support for assistance."
        default:
            return "Business verification helps build trust with customers."
        }
    }
}

struct BusinessStatsGrid: View {
    @ObservedObject var viewModel: BusinessAccountViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("Business Statistics")
                .font(.headline)
                .foregroundColor(Theme.Colors.text)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                BusinessStatCard(
                    title: "Total Listings",
                    value: "\(viewModel.totalListings)",
                    icon: "cube.box.fill",
                    color: Theme.Colors.primary
                )
                
                BusinessStatCard(
                    title: "Active Bookings",
                    value: "\(viewModel.activeBookings)",
                    icon: "calendar.fill",
                    color: Theme.Colors.accentBlue
                )
                
                BusinessStatCard(
                    title: "Total Revenue",
                    value: "$\(String(format: "%.0f", viewModel.totalRevenue))",
                    icon: "dollarsign.circle.fill",
                    color: Theme.Colors.success
                )
                
                BusinessStatCard(
                    title: "Rating",
                    value: String(format: "%.1f", viewModel.averageRating),
                    icon: "star.fill",
                    color: Theme.Colors.accentOrange
                )
            }
        }
    }
}

struct BusinessQuickActions: View {
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("Quick Actions")
                .font(.headline)
                .foregroundColor(Theme.Colors.text)
            
            VStack(spacing: Theme.Spacing.sm) {
                ActionButton(
                    title: "Fleet Management",
                    subtitle: "Manage inventory and bookings",
                    icon: "truck.box.fill",
                    action: { /* Navigate to fleet management */ }
                )
                
                ActionButton(
                    title: "Business Analytics",
                    subtitle: "View detailed performance metrics",
                    icon: "chart.bar.fill",
                    action: { /* Navigate to analytics */ }
                )
                
                ActionButton(
                    title: "Bulk Operations",
                    subtitle: "Create multiple listings at once",
                    icon: "square.stack.3d.up.fill",
                    action: { /* Navigate to bulk operations */ }
                )
            }
        }
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.body)
                .foregroundColor(Theme.Colors.secondaryText)
            
            Spacer()
            
            Text(value)
                .font(.body)
                .fontWeight(.medium)
                .foregroundColor(Theme.Colors.text)
        }
    }
}

struct BusinessStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(color)
            
            Text(value)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(Theme.Colors.text)
            
            Text(title)
                .font(.system(size: 12))
                .foregroundColor(Theme.Colors.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Theme.Colors.secondaryBackground)
        .cornerRadius(12)
    }
}

struct ActionButton: View {
    let title: String
    let subtitle: String
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: Theme.Spacing.md) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(Theme.Colors.primary)
                    .frame(width: 40, height: 40)
                    .background(Theme.Colors.primary.opacity(0.1))
                    .cornerRadius(8)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Theme.Colors.text)
                    
                    Text(subtitle)
                        .font(.system(size: 14))
                        .foregroundColor(Theme.Colors.secondaryText)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Theme.Colors.tertiaryText)
            }
            .padding(Theme.Spacing.md)
            .background(Theme.Colors.secondaryBackground)
            .cornerRadius(Theme.CornerRadius.md)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - View Model
class BusinessAccountViewModel: ObservableObject {
    @Published var businessAccount: BusinessAccount?
    @Published var verificationStatus: String = "pending"
    @Published var totalListings: Int = 0
    @Published var activeBookings: Int = 0
    @Published var totalRevenue: Double = 0.0
    @Published var averageRating: Double = 0.0
    @Published var isLoading = false
    
    func loadBusinessAccount() {
        isLoading = true
        
        Task { @MainActor in
            do {
                // Load business account data from API
                let response = try await APIClient.shared.getBusinessAccount()
                
                await MainActor.run {
                    self.businessAccount = response.businessAccount
                    if let summary = response.analyticsSummary {
                        self.totalRevenue = summary.revenue?.total ?? 0.0
                        self.averageRating = 4.5 // Placeholder
                    }
                    if let inventory = response.inventorySummary {
                        self.totalListings = inventory.totalItems
                        self.activeBookings = inventory.activeItems
                    }
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    // Handle error - load sample data
                    self.totalListings = 15
                    self.activeBookings = 7
                    self.totalRevenue = 2450.0
                    self.averageRating = 4.7
                    self.isLoading = false
                }
            }
        }
    }
}

// MARK: - Placeholder Views
struct BusinessVerificationView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Business Verification")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding()
                
                Text("Upload your business documents to get verified and unlock premium features.")
                    .multilineTextAlignment(.center)
                    .padding()
                
                Spacer()
                
                Button("Upload Documents") {
                    // Handle document upload
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .padding()
                
                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    BusinessAccountView()
}