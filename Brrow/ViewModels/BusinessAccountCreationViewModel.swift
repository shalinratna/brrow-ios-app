//
//  BusinessAccountCreationViewModel.swift
//  Brrow
//
//  View model for creating business accounts
//

import SwiftUI
import Combine

class BusinessAccountCreationViewModel: ObservableObject {
    // Business Information
    @Published var businessName = ""
    @Published var businessType = ""
    @Published var taxId = ""
    @Published var businessAddress = ""
    @Published var businessPhone = ""
    @Published var website = ""
    
    // Verification
    @Published var businessLicenseUploaded = false
    @Published var taxDocumentUploaded = false
    @Published var insuranceUploaded = false
    @Published var businessLicenseUrl = ""
    @Published var taxDocumentUrl = ""
    @Published var insuranceUrl = ""
    
    // Payment Setup
    @Published var stripeConnected = false
    @Published var stripeAccountId = ""
    @Published var paymentSchedule: PaymentSchedule = .daily
    @Published var addBankAccount = false
    
    // UI State
    @Published var hasAgreedToTerms = false
    @Published var isLoading = false
    @Published var showError = false
    @Published var errorMessage = ""
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Validation
    func isBusinessInfoValid() -> Bool {
        return !businessName.isEmpty &&
               !businessType.isEmpty &&
               !businessAddress.isEmpty &&
               !businessPhone.isEmpty &&
               businessPhone.count >= 10
    }
    
    func isVerificationValid() -> Bool {
        // At minimum, business license is required
        return businessLicenseUploaded
    }
    
    func isPaymentSetupValid() -> Bool {
        // Stripe connection is required
        return stripeConnected
    }
    
    // MARK: - Document Upload
    func uploadBusinessLicense() {
        // Simulate upload for now
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.businessLicenseUploaded = true
            self.businessLicenseUrl = "https://brrow-backend-nodejs-production.up.railway.app/uploads/business/license_\(UUID().uuidString).pdf"
        }
    }
    
    func uploadTaxDocument() {
        // Simulate upload for now
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.taxDocumentUploaded = true
            self.taxDocumentUrl = "https://brrow-backend-nodejs-production.up.railway.app/uploads/business/tax_\(UUID().uuidString).pdf"
        }
    }
    
    func uploadInsurance() {
        // Simulate upload for now
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.insuranceUploaded = true
            self.insuranceUrl = "https://brrow-backend-nodejs-production.up.railway.app/uploads/business/insurance_\(UUID().uuidString).pdf"
        }
    }
    
    // MARK: - Stripe Connection
    func connectStripe() {
        // In production, this would open Stripe Connect OAuth flow
        // For now, simulate connection
        isLoading = true
        
        Task {
            do {
                // Simulate API call
                try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
                
                await MainActor.run {
                    self.stripeConnected = true
                    self.stripeAccountId = "acct_\(UUID().uuidString.prefix(16))"
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to connect Stripe account"
                    self.showError = true
                    self.isLoading = false
                }
            }
        }
    }
    
    // MARK: - Create Business Account
    func createBusinessAccount() async throws -> BusinessAccount {
        // Validate all steps
        guard isBusinessInfoValid() else {
            throw BusinessAccountError.invalidBusinessInfo
        }
        
        guard isVerificationValid() else {
            throw BusinessAccountError.verificationRequired
        }
        
        guard isPaymentSetupValid() else {
            throw BusinessAccountError.paymentSetupRequired
        }
        
        guard hasAgreedToTerms else {
            throw BusinessAccountError.termsNotAccepted
        }
        
        // Create request
        let request = CreateBusinessAccountRequest(
            businessName: businessName,
            businessType: businessType,
            taxId: taxId.isEmpty ? nil : taxId,
            businessAddress: businessAddress,
            businessPhone: businessPhone,
            website: website.isEmpty ? nil : website,
            businessLicenseUrl: businessLicenseUrl,
            taxDocumentUrl: taxDocumentUrl.isEmpty ? nil : taxDocumentUrl,
            insuranceUrl: insuranceUrl.isEmpty ? nil : insuranceUrl,
            stripeAccountId: stripeAccountId,
            paymentSchedule: paymentSchedule.rawValue,
            bankAccountAdded: addBankAccount
        )
        
        // Make API call
        return try await APIClient.shared.createBusinessAccount(request)
    }
}

// MARK: - Business Account Error
enum BusinessAccountError: LocalizedError {
    case invalidBusinessInfo
    case verificationRequired
    case paymentSetupRequired
    case termsNotAccepted
    case creationFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidBusinessInfo:
            return "Please complete all required business information"
        case .verificationRequired:
            return "Please upload required verification documents"
        case .paymentSetupRequired:
            return "Please complete payment setup with Stripe"
        case .termsNotAccepted:
            return "Please agree to the business terms and conditions"
        case .creationFailed(let message):
            return message
        }
    }
}

// MARK: - API Models
struct CreateBusinessAccountRequest: Codable {
    let businessName: String
    let businessType: String
    let taxId: String?
    let businessAddress: String
    let businessPhone: String
    let website: String?
    let businessLicenseUrl: String
    let taxDocumentUrl: String?
    let insuranceUrl: String?
    let stripeAccountId: String
    let paymentSchedule: String
    let bankAccountAdded: Bool
    
    enum CodingKeys: String, CodingKey {
        case businessName = "business_name"
        case businessType = "business_type"
        case taxId = "tax_id"
        case businessAddress = "business_address"
        case businessPhone = "business_phone"
        case website
        case businessLicenseUrl = "business_license_url"
        case taxDocumentUrl = "tax_document_url"
        case insuranceUrl = "insurance_url"
        case stripeAccountId = "stripe_account_id"
        case paymentSchedule = "payment_schedule"
        case bankAccountAdded = "bank_account_added"
    }
}

// BusinessAccount is already defined in BusinessModels.swift