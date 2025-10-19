//
//  IDmeVerificationView.swift
//  Brrow
//
//  ID.me Identity Verification UI
//

import SwiftUI

struct IDmeVerificationView: View {
    @StateObject private var idmeService = IDmeService.shared
    @State private var showingVerificationOptions = false
    @State private var selectedScopes = IDmeConfig.defaultScopes
    @State private var alertMessage = ""
    @State private var showingAlert = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                Theme.Colors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 32) {
                        // Header Section
                        headerSection
                        
                        // Current Status
                        statusSection
                        
                        // Verification Options
                        if !idmeService.isVerified {
                            verificationOptionsSection
                        }
                        
                        // User Profile (if verified)
                        if let profile = idmeService.userProfile {
                            profileSection(profile: profile)
                        }
                        
                        // Benefits Section
                        benefitsSection
                        
                        Spacer(minLength: 100)
                    }
                    .padding()
                }
            }
            .navigationTitle("Identity Verification")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert("Verification Result", isPresented: $showingAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 16) {
            // ID.me Logo placeholder
            Circle()
                .fill(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 80, height: 80)
                .overlay(
                    Text("ID.me")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                )
            
            VStack(spacing: 8) {
                Text("Secure Identity Verification")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(Theme.Colors.text)
                
                Text("Verify your identity to unlock additional features and build trust in the Brrow community")
                    .font(.body)
                    .foregroundColor(Theme.Colors.secondaryText)
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    // MARK: - Status Section
    private var statusSection: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: idmeService.isVerified ? "checkmark.shield.fill" : "exclamationmark.shield")
                    .font(.title2)
                    .foregroundColor(idmeService.isVerified ? .green : .orange)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(idmeService.isVerified ? "Identity Verified" : "Not Verified")
                        .font(.headline)
                        .foregroundColor(Theme.Colors.text)
                    
                    Text(idmeService.isVerified ? 
                         "Your identity has been successfully verified" : 
                         "Complete verification to access premium features")
                        .font(.caption)
                        .foregroundColor(Theme.Colors.secondaryText)
                }
                
                Spacer()
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(idmeService.isVerified ? Color.green.opacity(0.1) : Color.orange.opacity(0.1))
            )
        }
    }
    
    // MARK: - Verification Options Section
    private var verificationOptionsSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Verification Options")
                .font(.headline)
                .foregroundColor(Theme.Colors.text)
            
            VStack(spacing: 16) {
                // Basic Identity - Primary option
                VerificationOptionCard(
                    title: "Basic Identity Verification",
                    description: "Verify your government-issued ID to build trust and unlock premium features",
                    icon: "person.crop.circle.fill.badge.checkmark",
                    isSelected: true,
                    action: { selectedScopes = IDmeConfig.defaultScopes }
                )
            }
            
            // Verify Button
            Button(action: startVerification) {
                HStack {
                    if idmeService.isVerifying {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "checkmark.shield.fill")
                            .font(.title3)
                    }
                    
                    Text(idmeService.isVerifying ? "Verifying..." : "Start Verification")
                        .font(.headline)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(idmeService.isVerifying ? Color.gray : Theme.Colors.primary)
                )
            }
            .disabled(idmeService.isVerifying)
        }
    }
    
    // MARK: - Profile Section
    private func profileSection(profile: IDmeUserProfile) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Verified Information")
                .font(.headline)
                .foregroundColor(Theme.Colors.text)
            
            VStack(spacing: 12) {
                if let firstName = profile.attributes.firstName,
                   let lastName = profile.attributes.lastName {
                    ProfileInfoRow(label: "Name", value: "\(firstName) \(lastName)")
                }
                
                if let email = profile.attributes.email {
                    ProfileInfoRow(label: "Email", value: email)
                }
                
                if let phone = profile.attributes.phone {
                    ProfileInfoRow(label: "Phone", value: phone)
                }
                
                if let birthDate = profile.attributes.birthDate {
                    ProfileInfoRow(label: "Birth Date", value: birthDate)
                }
                
                if let zip = profile.attributes.zip {
                    ProfileInfoRow(label: "ZIP Code", value: zip)
                }
                
                if let level = profile.attributes.verificationLevel {
                    ProfileInfoRow(label: "Verification Level", value: level)
                }
                
                if let groups = profile.attributes.groups, !groups.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Verified Groups")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(Theme.Colors.secondaryText)
                        
                        ForEach(groups, id: \.self) { group in
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                    .font(.caption)
                                
                                Text(group.capitalized)
                                    .font(.body)
                                    .foregroundColor(Theme.Colors.text)
                                
                                Spacer()
                            }
                        }
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Theme.Colors.secondaryBackground)
            )
        }
    }
    
    // MARK: - Benefits Section
    private var benefitsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Verification Benefits")
                .font(.headline)
                .foregroundColor(Theme.Colors.text)
            
            VStack(spacing: 12) {
                IDmeBenefitRow(
                    icon: "shield.checkered",
                    title: "Enhanced Trust",
                    description: "Build trust with verified identity badge"
                )
                
                IDmeBenefitRow(
                    icon: "star.circle.fill",
                    title: "Priority Support",
                    description: "Get priority customer support"
                )
                
                IDmeBenefitRow(
                    icon: "creditcard.fill",
                    title: "Higher Limits",
                    description: "Access higher transaction limits"
                )
                
                IDmeBenefitRow(
                    icon: "percent",
                    title: "Special Discounts",
                    description: "Unlock exclusive discounts and offers"
                )
            }
        }
    }
    
    // MARK: - Actions
    private func startVerification() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first,
              let rootViewController = window.rootViewController else {
            return
        }
        
        let presentingVC = rootViewController.presentedViewController ?? rootViewController

        idmeService.startVerification(from: presentingVC, scopes: selectedScopes) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let profile):
                    alertMessage = "Verification successful! Your identity has been verified."
                    // Update user profile in backend
                    updateUserVerificationStatus(profile: profile)
                case .failure(let error):
                    alertMessage = "Verification failed: \(error.localizedDescription)"
                }
                showingAlert = true
            }
        }
    }
    
    private func updateUserVerificationStatus(profile: IDmeUserProfile) {
        Task {
            do {
                // Update user verification status via API
                _ = try await APIClient.shared.updateUserVerificationStatus(
                    isVerified: profile.attributes.verified,
                    verificationLevel: profile.attributes.verificationLevel,
                    verificationProvider: "id.me"
                )
            } catch {
                print("Failed to update verification status: \(error)")
            }
        }
    }
}

// MARK: - Supporting Views
struct VerificationOptionCard: View {
    let title: String
    let description: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(isSelected ? Theme.Colors.primary : Theme.Colors.secondary)
                
                VStack(spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(Theme.Colors.text)
                        .multilineTextAlignment(.center)
                    
                    Text(description)
                        .font(.caption)
                        .foregroundColor(Theme.Colors.secondaryText)
                        .multilineTextAlignment(.center)
                        .lineLimit(3)
                }
            }
            .frame(height: 120)
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Theme.Colors.primary.opacity(0.1) : Theme.Colors.secondaryBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Theme.Colors.primary : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ProfileInfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(Theme.Colors.secondaryText)
            
            Spacer()
            
            Text(value)
                .font(.body)
                .foregroundColor(Theme.Colors.text)
        }
    }
}

struct IDmeBenefitRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(Theme.Colors.primary)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(Theme.Colors.text)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(Theme.Colors.secondaryText)
            }
            
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Theme.Colors.secondaryBackground)
        )
    }
}

// MARK: - Preview
struct IDmeVerificationView_Previews: PreviewProvider {
    static var previews: some View {
        IDmeVerificationView()
    }
}