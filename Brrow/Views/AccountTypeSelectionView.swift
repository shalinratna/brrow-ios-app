import SwiftUI

struct AccountTypeSelectionView: View {
    @Binding var showingAccountTypeSelection: Bool
    @State private var selectedAccountType: AccountType = .personal
    @State private var isCreatingAccount = false
    @State private var showingBusinessForm = false
    @Environment(\.dismiss) var dismiss
    
    enum AccountType {
        case personal
        case business
        
        var title: String {
            switch self {
            case .personal: return "Personal Account"
            case .business: return "Business Account"
            }
        }
        
        var description: String {
            switch self {
            case .personal: 
                return "Perfect for individuals who want to rent or lend items occasionally"
            case .business: 
                return "For professionals and businesses managing multiple rentals"
            }
        }
        
        var icon: String {
            switch self {
            case .personal: return "person.fill"
            case .business: return "building.2.fill"
            }
        }
        
        var features: [String] {
            switch self {
            case .personal:
                return [
                    "List up to 10 items",
                    "Basic analytics",
                    "Standard support",
                    "10% commission on rentals"
                ]
            case .business:
                return [
                    "Unlimited listings",
                    "Fleet management tools",
                    "Professional analytics",
                    "Priority support",
                    "Business verification badge",
                    "Bulk listing tools"
                ]
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Theme.Colors.background
                    .ignoresSafeArea()
                
                VStack(spacing: Theme.Spacing.lg) {
                    // Header
                    VStack(spacing: Theme.Spacing.sm) {
                        Text("Choose Your Account Type")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(Theme.Colors.text)
                        
                        Text("Select the type that best fits your needs")
                            .font(.body)
                            .foregroundColor(Theme.Colors.secondaryText)
                    }
                    .padding(.top, Theme.Spacing.xl)
                    
                    // Account Type Cards
                    VStack(spacing: Theme.Spacing.md) {
                        AccountTypeCard(
                            accountType: .personal,
                            isSelected: selectedAccountType == .personal,
                            action: { selectedAccountType = .personal }
                        )
                        
                        AccountTypeCard(
                            accountType: .business,
                            isSelected: selectedAccountType == .business,
                            action: { selectedAccountType = .business }
                        )
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                    
                    // Continue Button
                    Button(action: {
                        if selectedAccountType == .business {
                            showingBusinessForm = true
                        } else {
                            createPersonalAccount()
                        }
                    }) {
                        HStack {
                            Text("Continue with \(selectedAccountType.title)")
                                .fontWeight(.semibold)
                            
                            if isCreatingAccount {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            }
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Theme.Colors.primary)
                        .cornerRadius(12)
                    }
                    .disabled(isCreatingAccount)
                    .padding(.horizontal)
                    .padding(.bottom, Theme.Spacing.xl)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(Theme.Colors.primary)
                }
            }
        }
        .sheet(isPresented: $showingBusinessForm) {
            BusinessAccountCreationFormView(
                showingAccountTypeSelection: $showingAccountTypeSelection
            )
        }
    }
    
    private func createPersonalAccount() {
        isCreatingAccount = true
        
        // Update user account type
        Task {
            do {
                // API call to set account type as personal
                // This is typically handled during registration
                
                // For now, just dismiss
                await MainActor.run {
                    isCreatingAccount = false
                    showingAccountTypeSelection = false
                }
            } catch {
                await MainActor.run {
                    isCreatingAccount = false
                    // Handle error
                }
            }
        }
    }
}

struct AccountTypeCard: View {
    let accountType: AccountTypeSelectionView.AccountType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                HStack {
                    Image(systemName: accountType.icon)
                        .font(.title2)
                        .foregroundColor(isSelected ? Theme.Colors.primary : Theme.Colors.secondaryText)
                    
                    Text(accountType.title)
                        .font(.headline)
                        .foregroundColor(Theme.Colors.text)
                    
                    Spacer()
                    
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.title2)
                        .foregroundColor(isSelected ? Theme.Colors.primary : Theme.Colors.divider)
                }
                
                Text(accountType.description)
                    .font(.subheadline)
                    .foregroundColor(Theme.Colors.secondaryText)
                    .multilineTextAlignment(.leading)
                
                // Features list
                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    ForEach(accountType.features, id: \.self) { feature in
                        HStack(spacing: Theme.Spacing.sm) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundColor(Theme.Colors.primary.opacity(0.8))
                            
                            Text(feature)
                                .font(.caption)
                                .foregroundColor(Theme.Colors.secondaryText)
                            
                            Spacer()
                        }
                    }
                }
                .padding(.top, Theme.Spacing.xs)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Theme.Colors.secondaryBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                isSelected ? Theme.Colors.primary : Color.clear,
                                lineWidth: 2
                            )
                    )
            )
        }
    }
}

// Business Account Creation Form
struct BusinessAccountCreationFormView: View {
    @Binding var showingAccountTypeSelection: Bool
    @State private var businessName = ""
    @State private var legalName = ""
    @State private var businessType = "sole_proprietor"
    @State private var taxId = ""
    @State private var businessEmail = ""
    @State private var businessPhone = ""
    @State private var description = ""
    @State private var isCreating = false
    @State private var showError = false
    @State private var errorMessage = ""
    @Environment(\.dismiss) var dismiss
    
    let businessTypes = [
        ("sole_proprietor", "Sole Proprietor"),
        ("llc", "LLC"),
        ("corporation", "Corporation"),
        ("partnership", "Partnership")
    ]
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Business Information")) {
                    TextField("Business Name", text: $businessName)
                        .textContentType(.organizationName)
                    
                    TextField("Legal Name", text: $legalName)
                    
                    Picker("Business Type", selection: $businessType) {
                        ForEach(businessTypes, id: \.0) { type in
                            Text(type.1).tag(type.0)
                        }
                    }
                    
                    TextField("EIN/Tax ID (Optional)", text: $taxId)
                        .keyboardType(.numberPad)
                }
                
                Section(header: Text("Contact Information")) {
                    TextField("Business Email", text: $businessEmail)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                    
                    TextField("Business Phone", text: $businessPhone)
                        .textContentType(.telephoneNumber)
                        .keyboardType(.phonePad)
                }
                
                Section(header: Text("About Your Business")) {
                    TextEditor(text: $description)
                        .frame(minHeight: 100)
                        .overlay(
                            Group {
                                if description.isEmpty {
                                    Text("Tell us about your business...")
                                        .foregroundColor(Color.gray.opacity(0.5))
                                        .padding(.horizontal, 4)
                                        .padding(.vertical, 8)
                                        .allowsHitTesting(false)
                                }
                            },
                            alignment: .topLeading
                        )
                }
                
                Section {
                    Text("After creating your business account, you can submit documents for verification to get a verified business badge.")
                        .font(.caption)
                        .foregroundColor(Theme.Colors.secondaryText)
                }
            }
            .navigationTitle("Create Business Account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Back") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        createBusinessAccount()
                    }
                    .disabled(businessName.isEmpty || businessEmail.isEmpty || isCreating)
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .overlay(
                Group {
                    if isCreating {
                        Color.black.opacity(0.4)
                            .ignoresSafeArea()
                        
                        ProgressView("Creating business account...")
                            .padding()
                            .background(Color.white)
                            .cornerRadius(10)
                            .shadow(radius: 10)
                    }
                }
            )
        }
    }
    
    private func createBusinessAccount() {
        isCreating = true
        
        Task {
            do {
                let request = CreateBusinessAccountRequest(
                    businessName: businessName,
                    businessType: businessType,
                    taxId: taxId.isEmpty ? nil : taxId,
                    businessAddress: "", // Add address field to form if needed
                    businessPhone: businessPhone,
                    website: nil,
                    businessLicenseUrl: "", // These would be uploaded separately
                    taxDocumentUrl: nil,
                    insuranceUrl: nil,
                    stripeAccountId: "", // Would be connected separately
                    paymentSchedule: "weekly",
                    bankAccountAdded: false
                )
                
                // API call to create business account
                _ = try await APIClient.shared.createBusinessAccount(request)
                
                await MainActor.run {
                    isCreating = false
                    showingAccountTypeSelection = false
                    
                    // Show success message or navigate to business dashboard
                    NotificationCenter.default.post(
                        name: Notification.Name("BusinessAccountCreated"),
                        object: nil
                    )
                }
            } catch {
                await MainActor.run {
                    isCreating = false
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
}

#Preview {
    AccountTypeSelectionView(showingAccountTypeSelection: .constant(true))
}