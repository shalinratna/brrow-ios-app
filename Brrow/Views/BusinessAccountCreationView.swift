//
//  BusinessAccountCreationView.swift
//  Brrow
//
//  Create a business account for personal users
//

import SwiftUI

struct BusinessAccountCreationView: View {
    @Binding var showingAccountTypeSelection: Bool
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var viewModel = BusinessAccountCreationViewModel()
    @Environment(\.dismiss) private var dismiss
    
    @State private var currentStep = 0
    @State private var showSuccessView = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Theme.Colors.background
                    .ignoresSafeArea()
                
                if showSuccessView {
                    successView
                } else {
                    ScrollView {
                        VStack(spacing: 0) {
                            // Progress Indicator
                            ProgressBar(currentStep: currentStep, totalSteps: 4)
                                .padding(.horizontal, Theme.Spacing.md)
                                .padding(.vertical, Theme.Spacing.lg)
                            
                            // Step Content
                            TabView(selection: $currentStep) {
                                // Step 1: Business Information
                                BusinessInfoStep(viewModel: viewModel)
                                    .tag(0)
                                
                                // Step 2: Business Verification
                                BusinessVerificationStep(viewModel: viewModel)
                                    .tag(1)
                                
                                // Step 3: Payment Setup
                                PaymentSetupStep(viewModel: viewModel)
                                    .tag(2)
                                
                                // Step 4: Review & Confirm
                                ReviewConfirmStep(viewModel: viewModel)
                                    .tag(3)
                            }
                            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                            .frame(minHeight: UIScreen.main.bounds.height * 0.6)
                            
                            // Navigation Buttons
                            navigationButtons
                                .padding(.horizontal, Theme.Spacing.md)
                                .padding(.vertical, Theme.Spacing.lg)
                        }
                    }
                }
            }
            .navigationTitle("Create Business Account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(Theme.Colors.primary)
                }
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK") { }
            } message: {
                Text(viewModel.errorMessage)
            }
        }
    }
    
    // MARK: - Navigation Buttons
    private var navigationButtons: some View {
        HStack(spacing: Theme.Spacing.md) {
            if currentStep > 0 {
                Button(action: previousStep) {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Theme.Colors.primary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Theme.Colors.primary, lineWidth: 2)
                    )
                }
            }
            
            Button(action: nextStep) {
                HStack {
                    if viewModel.isLoading {
                        ProgressView()
                            .tint(.white)
                            .scaleEffect(0.8)
                    } else {
                        Text(currentStep == 3 ? "Create Account" : "Continue")
                        if currentStep < 3 {
                            Image(systemName: "chevron.right")
                        }
                    }
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(canProceed() ? Theme.Colors.primary : Color.gray)
                )
                .disabled(!canProceed() || viewModel.isLoading)
            }
        }
    }
    
    // MARK: - Success View
    private var successView: some View {
        VStack(spacing: Theme.Spacing.xl) {
            Spacer()
            
            // Success Icon
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.green)
                .scaleEffect(1.2)
                .animation(.spring(response: 0.5, dampingFraction: 0.6), value: showSuccessView)
            
            VStack(spacing: Theme.Spacing.md) {
                Text("Business Account Created!")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(Theme.Colors.text)
                
                Text("Your business account is now active. You can start listing items as a business.")
                    .font(.body)
                    .foregroundColor(Theme.Colors.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Theme.Spacing.xl)
            }
            
            Spacer()
            
            Button(action: {
                dismiss()
            }) {
                Text("Get Started")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Theme.Colors.primary)
                    .cornerRadius(12)
            }
            .padding(.horizontal, Theme.Spacing.xl)
            .padding(.bottom, Theme.Spacing.xl)
        }
    }
    
    // MARK: - Helper Methods
    private func canProceed() -> Bool {
        switch currentStep {
        case 0:
            return viewModel.isBusinessInfoValid()
        case 1:
            return viewModel.isVerificationValid()
        case 2:
            return viewModel.isPaymentSetupValid()
        case 3:
            return viewModel.hasAgreedToTerms
        default:
            return false
        }
    }
    
    private func nextStep() {
        if currentStep < 3 {
            withAnimation {
                currentStep += 1
            }
        } else {
            // Create business account
            Task {
                await createBusinessAccount()
            }
        }
    }
    
    private func previousStep() {
        withAnimation {
            currentStep -= 1
        }
    }
    
    private func createBusinessAccount() async {
        viewModel.isLoading = true
        
        do {
            _ = try await viewModel.createBusinessAccount()
            
            // Update auth manager with new account type
            await MainActor.run {
                // Since User doesn't have accountType in its initializer,
                // we'll need to refresh the user data from server
                // which should now have the business account type
                Task {
                    // Refresh user profile to get updated account type
                    if authManager.isAuthenticated {
                        // The user profile will be refreshed on next app launch
                        // or when they navigate to profile
                    }
                }
                
                // Track achievement
                AchievementManager.shared.trackBusinessAccountCreated()
                
                withAnimation {
                    showSuccessView = true
                }
            }
            
            // Dismiss after delay
            try await Task.sleep(nanoseconds: 3_000_000_000) // 3 seconds
            await MainActor.run {
                dismiss()
            }
            
        } catch {
            await MainActor.run {
                viewModel.errorMessage = error.localizedDescription
                viewModel.showError = true
                viewModel.isLoading = false
            }
        }
    }
}

// MARK: - Progress Bar
struct ProgressBar: View {
    let currentStep: Int
    let totalSteps: Int
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<totalSteps, id: \.self) { step in
                RoundedRectangle(cornerRadius: 4)
                    .fill(step <= currentStep ? Theme.Colors.primary : Theme.Colors.border)
                    .frame(height: 6)
                    .animation(.easeInOut, value: currentStep)
            }
        }
    }
}

// MARK: - Step 1: Business Info
struct BusinessInfoStep: View {
    @ObservedObject var viewModel: BusinessAccountCreationViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Business Information")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(Theme.Colors.text)
                
                Text("Tell us about your business")
                    .font(.body)
                    .foregroundColor(Theme.Colors.secondaryText)
            }
            .padding(.horizontal, Theme.Spacing.md)
            
            VStack(spacing: Theme.Spacing.md) {
                // Business Name
                FormField(
                    title: "Business Name",
                    placeholder: "Enter your business name",
                    text: $viewModel.businessName,
                    icon: "building.2"
                )
                
                // Business Type
                FormField(
                    title: "Business Type",
                    placeholder: "e.g., LLC, Corporation, Sole Proprietor",
                    text: $viewModel.businessType,
                    icon: "doc.text"
                )
                
                // Tax ID
                FormField(
                    title: "Tax ID / EIN (Optional)",
                    placeholder: "XX-XXXXXXX",
                    text: $viewModel.taxId,
                    icon: "number"
                )
                
                // Business Address
                FormField(
                    title: "Business Address",
                    placeholder: "123 Main St, City, State ZIP",
                    text: $viewModel.businessAddress,
                    icon: "location"
                )
                
                // Business Phone
                FormField(
                    title: "Business Phone",
                    placeholder: "(555) 123-4567",
                    text: $viewModel.businessPhone,
                    icon: "phone"
                )
                
                // Website (Optional)
                FormField(
                    title: "Website (Optional)",
                    placeholder: "https://yourbusiness.com",
                    text: $viewModel.website,
                    icon: "globe"
                )
            }
            .padding(.horizontal, Theme.Spacing.md)
        }
    }
}

// MARK: - Step 2: Business Verification
struct BusinessVerificationStep: View {
    @ObservedObject var viewModel: BusinessAccountCreationViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Verify Your Business")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(Theme.Colors.text)
                
                Text("Upload documents to verify your business")
                    .font(.body)
                    .foregroundColor(Theme.Colors.secondaryText)
            }
            .padding(.horizontal, Theme.Spacing.md)
            
            VStack(spacing: Theme.Spacing.lg) {
                // Business License
                DocumentUploadCard(
                    title: "Business License",
                    description: "Upload your business license or registration",
                    isRequired: true,
                    isUploaded: viewModel.businessLicenseUploaded,
                    onUpload: {
                        // Handle upload
                        viewModel.uploadBusinessLicense()
                    }
                )
                
                // Tax Document
                DocumentUploadCard(
                    title: "Tax Document (Optional)",
                    description: "W-9, EIN Letter, or other tax documentation",
                    isRequired: false,
                    isUploaded: viewModel.taxDocumentUploaded,
                    onUpload: {
                        // Handle upload
                        viewModel.uploadTaxDocument()
                    }
                )
                
                // Insurance (Optional)
                DocumentUploadCard(
                    title: "Insurance Certificate (Optional)",
                    description: "General liability or business insurance",
                    isRequired: false,
                    isUploaded: viewModel.insuranceUploaded,
                    onUpload: {
                        // Handle upload
                        viewModel.uploadInsurance()
                    }
                )
            }
            .padding(.horizontal, Theme.Spacing.md)
            
            // Info Box
            InfoBox(
                icon: "info.circle.fill",
                text: "All documents are securely stored and only used for verification purposes.",
                color: .blue
            )
            .padding(.horizontal, Theme.Spacing.md)
        }
    }
}

// MARK: - Step 3: Payment Setup
struct PaymentSetupStep: View {
    @ObservedObject var viewModel: BusinessAccountCreationViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Payment Setup")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(Theme.Colors.text)
                
                Text("Set up how you'll receive payments")
                    .font(.body)
                    .foregroundColor(Theme.Colors.secondaryText)
            }
            .padding(.horizontal, Theme.Spacing.md)
            
            VStack(spacing: Theme.Spacing.lg) {
                // Stripe Connect
                VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                    HStack {
                        Image(systemName: "creditcard.fill")
                            .font(.title2)
                            .foregroundColor(Theme.Colors.primary)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Connect with Stripe")
                                .font(.headline)
                                .foregroundColor(Theme.Colors.text)
                            
                            Text("Secure payment processing for your business")
                                .font(.caption)
                                .foregroundColor(Theme.Colors.secondaryText)
                        }
                        
                        Spacer()
                    }
                    
                    if viewModel.stripeConnected {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Stripe account connected")
                                .font(.body)
                                .foregroundColor(.green)
                        }
                        .padding()
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(8)
                    } else {
                        Button(action: {
                            viewModel.connectStripe()
                        }) {
                            Text("Connect Stripe Account")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Theme.Colors.primary)
                                .cornerRadius(8)
                        }
                    }
                }
                .padding()
                .background(Theme.Colors.secondaryBackground)
                .cornerRadius(12)
                
                // Payment Schedule
                VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                    Text("Payment Schedule")
                        .font(.headline)
                        .foregroundColor(Theme.Colors.text)
                    
                    ForEach(PaymentSchedule.allCases, id: \.self) { schedule in
                        RadioButton(
                            title: schedule.title,
                            subtitle: schedule.description,
                            isSelected: viewModel.paymentSchedule == schedule,
                            action: {
                                viewModel.paymentSchedule = schedule
                            }
                        )
                    }
                }
                
                // Bank Account (Optional)
                Toggle(isOn: $viewModel.addBankAccount) {
                    HStack {
                        Image(systemName: "building.columns")
                            .foregroundColor(Theme.Colors.primary)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Add Bank Account")
                                .font(.body)
                                .foregroundColor(Theme.Colors.text)
                            
                            Text("For direct deposits (optional)")
                                .font(.caption)
                                .foregroundColor(Theme.Colors.secondaryText)
                        }
                    }
                }
                .tint(Theme.Colors.primary)
            }
            .padding(.horizontal, Theme.Spacing.md)
        }
    }
}

// MARK: - Step 4: Review & Confirm
struct ReviewConfirmStep: View {
    @ObservedObject var viewModel: BusinessAccountCreationViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Review & Confirm")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(Theme.Colors.text)
                
                Text("Review your business information")
                    .font(.body)
                    .foregroundColor(Theme.Colors.secondaryText)
            }
            .padding(.horizontal, Theme.Spacing.md)
            
            // Business Summary
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                ReviewItem(label: "Business Name", value: viewModel.businessName)
                ReviewItem(label: "Business Type", value: viewModel.businessType)
                ReviewItem(label: "Address", value: viewModel.businessAddress)
                ReviewItem(label: "Phone", value: viewModel.businessPhone)
                
                if !viewModel.website.isEmpty {
                    ReviewItem(label: "Website", value: viewModel.website)
                }
                
                Divider()
                
                ReviewItem(
                    label: "Business License",
                    value: viewModel.businessLicenseUploaded ? "Uploaded" : "Not uploaded",
                    valueColor: viewModel.businessLicenseUploaded ? .green : .orange
                )
                
                ReviewItem(
                    label: "Payment Setup",
                    value: viewModel.stripeConnected ? "Connected" : "Not connected",
                    valueColor: viewModel.stripeConnected ? .green : .orange
                )
                
                ReviewItem(
                    label: "Payment Schedule",
                    value: viewModel.paymentSchedule.title
                )
            }
            .padding()
            .background(Theme.Colors.secondaryBackground)
            .cornerRadius(12)
            .padding(.horizontal, Theme.Spacing.md)
            
            // Terms & Conditions
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                Toggle(isOn: $viewModel.hasAgreedToTerms) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("I agree to the Business Terms")
                            .font(.body)
                            .foregroundColor(Theme.Colors.text)
                        
                        Text("By creating a business account, you agree to our business terms of service and seller agreement.")
                            .font(.caption)
                            .foregroundColor(Theme.Colors.secondaryText)
                    }
                }
                .tint(Theme.Colors.primary)
                
                Button(action: {
                    // Show terms
                }) {
                    Text("Read Business Terms")
                        .font(.caption)
                        .foregroundColor(Theme.Colors.primary)
                }
            }
            .padding(.horizontal, Theme.Spacing.md)
            
            // Fee Information
            InfoBox(
                icon: "info.circle.fill",
                text: "Brrow charges a 5% platform fee on all business transactions.",
                color: Theme.Colors.primary
            )
            .padding(.horizontal, Theme.Spacing.md)
        }
    }
}

// MARK: - Supporting Views
struct FormField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Theme.Colors.text)
            
            HStack {
                Image(systemName: icon)
                    .foregroundColor(Theme.Colors.secondary)
                    .frame(width: 20)
                
                TextField(placeholder, text: $text)
                    .font(.body)
                    .foregroundColor(Theme.Colors.text)
            }
            .padding()
            .background(Theme.Colors.secondaryBackground)
            .cornerRadius(12)
        }
    }
}

struct DocumentUploadCard: View {
    let title: String
    let description: String
    let isRequired: Bool
    let isUploaded: Bool
    let onUpload: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(title)
                            .font(.headline)
                            .foregroundColor(Theme.Colors.text)
                        
                        if isRequired {
                            Text("Required")
                                .font(.caption)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.red.opacity(0.2))
                                .foregroundColor(.red)
                                .cornerRadius(4)
                        }
                    }
                    
                    Text(description)
                        .font(.caption)
                        .foregroundColor(Theme.Colors.secondaryText)
                }
                
                Spacer()
                
                if isUploaded {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.green)
                } else {
                    Button(action: onUpload) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.title2)
                            .foregroundColor(Theme.Colors.primary)
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isUploaded ? Color.green.opacity(0.1) : Theme.Colors.secondaryBackground)
            )
        }
    }
}

struct RadioButton: View {
    let title: String
    let subtitle: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundColor(isSelected ? Theme.Colors.primary : Theme.Colors.secondary)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.body)
                        .foregroundColor(Theme.Colors.text)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(Theme.Colors.secondaryText)
                }
                
                Spacer()
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Theme.Colors.primary.opacity(0.1) : Color.clear)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ReviewItem: View {
    let label: String
    let value: String
    var valueColor: Color = Theme.Colors.text
    
    var body: some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundColor(Theme.Colors.secondaryText)
            
            Spacer()
            
            Text(value)
                .font(.body)
                .foregroundColor(valueColor)
        }
    }
}

struct InfoBox: View {
    let icon: String
    let text: String
    let color: Color
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
            
            Text(text)
                .font(.caption)
                .foregroundColor(Theme.Colors.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
            
            Spacer()
        }
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}

// MARK: - Payment Schedule Enum
enum PaymentSchedule: String, CaseIterable {
    case instant = "instant"
    case daily = "daily"
    case weekly = "weekly"
    
    var title: String {
        switch self {
        case .instant: return "Instant Payouts"
        case .daily: return "Daily Payouts"
        case .weekly: return "Weekly Payouts"
        }
    }
    
    var description: String {
        switch self {
        case .instant: return "Get paid immediately (1.5% fee)"
        case .daily: return "Get paid every business day"
        case .weekly: return "Get paid every Friday"
        }
    }
}