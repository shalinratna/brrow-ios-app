//
//  AddressConflictAlertView.swift
//  Brrow
//
//  Handles address conflict warnings and reporting
//

import SwiftUI

struct AddressConflictAlertView: View {
    let conflictData: AddressConflictData
    @Binding var isPresented: Bool
    @State private var showReportSheet = false
    @State private var reportMessage = ""
    @State private var contactEmail = ""
    @State private var contactPhone = ""
    @State private var isReporting = false
    @State private var reportSuccess = false
    @State private var reportError: String?
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.orange)
                
                Text("Address Conflict Detected")
                    .font(.title2.bold())
                    .foregroundColor(Theme.Colors.text)
                
                Text(conflictData.isOwnSale ? 
                     "You already have a garage sale at this address" :
                     "Another garage sale exists at this address")
                    .font(.subheadline)
                    .foregroundColor(Theme.Colors.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .padding(.top, 30)
            .padding(.bottom, 20)
            
            // Conflict Details
            VStack(alignment: .leading, spacing: 16) {
                DetailRow(
                    icon: "house.fill",
                    title: "Address",
                    value: conflictData.address
                )
                
                DetailRow(
                    icon: "tag.fill",
                    title: "Existing Sale",
                    value: conflictData.existingSaleTitle
                )
                
                DetailRow(
                    icon: "calendar",
                    title: "Sale Date",
                    value: formatDate(conflictData.saleDate)
                )
            }
            .padding(.horizontal)
            .padding(.vertical, 20)
            .background(Theme.Colors.secondaryBackground)
            
            // Message
            if !conflictData.isOwnSale {
                Text("If this is your address and you didn't authorize this sale, you can report it to our team.")
                    .font(.footnote)
                    .foregroundColor(Theme.Colors.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .padding(.vertical, 20)
            }
            
            // Actions
            VStack(spacing: 12) {
                if !conflictData.isOwnSale {
                    Button(action: { showReportSheet = true }) {
                        HStack {
                            Image(systemName: "flag.fill")
                            Text("Report Unauthorized Use")
                        }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.red)
                        .cornerRadius(12)
                    }
                }
                
                Button(action: { isPresented = false }) {
                    Text("Understood")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Theme.Colors.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Theme.Colors.primary, lineWidth: 2)
                        )
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 30)
        }
        .background(Theme.Colors.background)
        .cornerRadius(20)
        .shadow(radius: 20)
        .padding(20)
        .sheet(isPresented: $showReportSheet) {
            ReportAddressConflictView(
                conflictData: conflictData,
                reportMessage: $reportMessage,
                contactEmail: $contactEmail,
                contactPhone: $contactPhone,
                isReporting: $isReporting,
                onReport: reportConflict,
                onDismiss: { showReportSheet = false }
            )
        }
        .alert("Report Submitted", isPresented: $reportSuccess) {
            Button("OK") {
                isPresented = false
            }
        } message: {
            Text("Thank you for reporting this issue. Our team will review it and contact you within 24-48 hours if needed.")
        }
        .alert("Error", isPresented: .constant(reportError != nil)) {
            Button("OK") {
                reportError = nil
            }
        } message: {
            Text(reportError ?? "Failed to submit report")
        }
    }
    
    private func reportConflict() {
        isReporting = true
        
        Task {
            do {
                let request = ReportAddressConflictRequest(
                    garageSaleId: conflictData.garageSaleId,
                    address: conflictData.address,
                    message: reportMessage,
                    contactEmail: contactEmail,
                    contactPhone: contactPhone
                )
                
                try await APIClient.shared.reportAddressConflict(request)
                
                await MainActor.run {
                    isReporting = false
                    showReportSheet = false
                    reportSuccess = true
                }
            } catch {
                await MainActor.run {
                    isReporting = false
                    reportError = error.localizedDescription
                }
            }
        }
    }
    
    private func formatDate(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let date = formatter.date(from: dateString) else { return dateString }
        
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

struct ReportAddressConflictView: View {
    let conflictData: AddressConflictData
    @Binding var reportMessage: String
    @Binding var contactEmail: String
    @Binding var contactPhone: String
    @Binding var isReporting: Bool
    let onReport: () -> Void
    let onDismiss: () -> Void
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Reporting Unauthorized Use")
                            .font(.headline)
                        Text("Please provide details about why this garage sale is unauthorized at your address.")
                            .font(.caption)
                            .foregroundColor(Theme.Colors.secondaryText)
                    }
                }
                
                Section("Your Message") {
                    TextEditor(text: $reportMessage)
                        .frame(minHeight: 120)
                        .placeholder(when: reportMessage.isEmpty) {
                            Text("Explain why this sale is unauthorized...")
                                .foregroundColor(Theme.Colors.tertiaryText)
                        }
                }
                
                Section("Contact Information") {
                    TextField("Email Address", text: $contactEmail)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                    
                    TextField("Phone Number (Optional)", text: $contactPhone)
                        .keyboardType(.phonePad)
                }
                
                Section {
                    Text("Our team will review this report and take appropriate action. We may contact you for additional information if needed.")
                        .font(.caption)
                        .foregroundColor(Theme.Colors.secondaryText)
                }
            }
            .navigationTitle("Report Issue")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        onDismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Submit") {
                        onReport()
                    }
                    .disabled(reportMessage.isEmpty || contactEmail.isEmpty || isReporting)
                }
            }
            .disabled(isReporting)
            .overlay {
                if isReporting {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                    
                    ProgressView("Submitting Report...")
                        .padding()
                        .background(Theme.Colors.cardBackground)
                        .cornerRadius(12)
                        .shadow(radius: 10)
                }
            }
        }
    }
}

struct DetailRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(Theme.Colors.primary)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(Theme.Colors.secondaryText)
                Text(value)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Theme.Colors.text)
            }
            
            Spacer()
        }
    }
}

// MARK: - Data Models

struct AddressConflictData {
    let garageSaleId: Int
    let address: String
    let existingSaleTitle: String
    let saleDate: String
    let isOwnSale: Bool
}

// Response structure from API
struct AddressConflictResponse: Codable {
    let success: Bool
    let message: String
    let errorCode: String?
    let data: ConflictDetails?
    
    struct ConflictDetails: Codable {
        let conflictType: String
        let existingSale: ExistingSale
        let canReport: Bool
        let reportMessage: String
        
        struct ExistingSale: Codable {
            let id: Int
            let title: String
            let saleDate: String
            let address: String
            let isOwnSale: Bool
            
            enum CodingKeys: String, CodingKey {
                case id, title, address
                case saleDate = "sale_date"
                case isOwnSale = "is_own_sale"
            }
        }
        
        enum CodingKeys: String, CodingKey {
            case conflictType = "conflict_type"
            case existingSale = "existing_sale"
            case canReport = "can_report"
            case reportMessage = "report_message"
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case success, message, data
        case errorCode = "error_code"
    }
}

struct ReportAddressConflictRequest: Codable {
    let garageSaleId: Int
    let address: String
    let message: String
    let contactEmail: String
    let contactPhone: String
    
    enum CodingKeys: String, CodingKey {
        case garageSaleId = "garage_sale_id"
        case address, message
        case contactEmail = "contact_email"
        case contactPhone = "contact_phone"
    }
}

