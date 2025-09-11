//
//  ReportListingView.swift
//  Brrow
//
//  Report inappropriate listings
//

import SwiftUI

struct ReportListingView: View {
    let listing: Listing
    @Environment(\.dismiss) private var dismiss
    @State private var selectedReason = ""
    @State private var additionalDetails = ""
    @State private var isLoading = false
    @State private var showingSuccess = false
    
    let reportReasons = [
        "Inappropriate content",
        "Misleading information",
        "Suspected scam",
        "Prohibited item",
        "Pricing concerns",
        "Safety concerns",
        "Duplicate listing",
        "Other"
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Info text
                    Text("Help us maintain a safe marketplace by reporting listings that violate our community guidelines.")
                        .font(.system(size: 14))
                        .foregroundColor(Theme.Colors.secondaryText)
                        .padding(.horizontal, 16)
                        .padding(.top, 20)
                    
                    // Listing info
                    HStack(spacing: 12) {
                        if let firstImage = listing.imageUrls.first {
                            ListingImageView(
                                imageURLs: [firstImage],
                                aspectRatio: .fill,
                                cornerRadius: 8
                            )
                            .frame(width: 60, height: 60)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(listing.title)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Theme.Colors.text)
                                .lineLimit(2)
                            
                            Text("Listed by \(listing.ownerUsername ?? "Unknown")")
                                .font(.system(size: 12))
                                .foregroundColor(Theme.Colors.secondaryText)
                        }
                        
                        Spacer()
                    }
                    .padding(12)
                    .background(Theme.Colors.secondaryBackground)
                    .cornerRadius(8)
                    .padding(.horizontal, 16)
                    
                    // Report reasons
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Select a reason")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Theme.Colors.text)
                        
                        ForEach(reportReasons, id: \.self) { reason in
                            ReportReasonRow(
                                reason: reason,
                                isSelected: selectedReason == reason,
                                action: { selectedReason = reason }
                            )
                        }
                    }
                    .padding(.horizontal, 16)
                    
                    // Additional details
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Additional details (optional)")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Theme.Colors.secondaryText)
                        
                        TextEditor(text: $additionalDetails)
                            .frame(minHeight: 100)
                            .padding(8)
                            .background(Theme.Colors.secondaryBackground)
                            .cornerRadius(8)
                        
                        Text("\(additionalDetails.count)/500")
                            .font(.system(size: 12))
                            .foregroundColor(Theme.Colors.secondaryText)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                    .padding(.horizontal, 16)
                    
                    // Submit button
                    Button(action: { submitReport() }) {
                        HStack {
                            Text("Submit Report")
                                .font(.system(size: 18, weight: .semibold))
                            
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            }
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Theme.Colors.accent)
                        .cornerRadius(12)
                        .opacity(selectedReason.isEmpty || isLoading ? 0.6 : 1)
                    }
                    .disabled(selectedReason.isEmpty || isLoading || additionalDetails.count > 500)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle("Report Listing")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Report Submitted", isPresented: $showingSuccess) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Thank you for helping keep our community safe. We'll review this report within 24 hours.")
            }
        }
    }
    
    private func submitReport() {
        isLoading = true
        
        Task {
            do {
                let baseURL = await APIEndpointManager.shared.getBestEndpoint()
                let url = URL(string: "\(baseURL)/report_listing.php")!
                
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.addValue("application/json", forHTTPHeaderField: "Content-Type")
                
                if let token = await AuthManager.shared.authToken {
                    request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                }
                
                let body: [String: Any] = [
                    "listing_id": listing.listingId,
                    "reason": selectedReason,
                    "details": additionalDetails
                ]
                
                request.httpBody = try JSONSerialization.data(withJSONObject: body)
                
                let (_, _) = try await URLSession.shared.data(for: request)
                
                await MainActor.run {
                    isLoading = false
                    showingSuccess = true
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                }
            }
        }
    }
}

struct ReportReasonRow: View {
    let reason: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20))
                    .foregroundColor(isSelected ? Theme.Colors.primary : Theme.Colors.secondary)
                
                Text(reason)
                    .font(.system(size: 14))
                    .foregroundColor(Theme.Colors.text)
                
                Spacer()
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(isSelected ? Theme.Colors.primary.opacity(0.05) : Theme.Colors.secondaryBackground)
            .cornerRadius(8)
        }
    }
}