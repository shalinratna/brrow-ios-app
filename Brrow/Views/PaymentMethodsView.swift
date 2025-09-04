//
//  PaymentMethodsView.swift
//  Brrow
//
//  Payment methods management and Stripe integration
//

import SwiftUI
import StripePaymentSheet

struct PaymentMethodsView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var paymentMethods: [PaymentMethodDisplay] = []
    @State private var isLoading = false
    @State private var showingAddCard = false
    @State private var showingStripeSheet = false
    @State private var paymentSheet: PaymentSheet?
    @State private var paymentResult: PaymentSheetResult?
    
    var body: some View {
        NavigationView {
            VStack {
                if isLoading {
                    ProgressView("Loading payment methods...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if paymentMethods.isEmpty {
                    emptyStateView
                } else {
                    paymentMethodsList
                }
            }
            .navigationTitle("Payment Methods")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddCard = true }) {
                        Image(systemName: "plus")
                            .foregroundColor(Theme.Colors.primary)
                    }
                }
            }
        }
        .onAppear {
            loadPaymentMethods()
        }
        .sheet(isPresented: $showingAddCard) {
            AddPaymentMethodView { success in
                if success {
                    loadPaymentMethods()
                }
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Image(systemName: "creditcard")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            VStack(spacing: 12) {
                Text("No Payment Methods")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Add a payment method to rent items and receive payouts securely.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button(action: { showingAddCard = true }) {
                Label("Add Payment Method", systemImage: "plus.circle.fill")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Theme.Colors.primary)
                    .cornerRadius(12)
            }
            .padding(.horizontal)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var paymentMethodsList: some View {
        List {
            Section("Cards") {
                ForEach(paymentMethods, id: \.id) { method in
                    PaymentMethodRow(method: method) {
                        deletePaymentMethod(method)
                    }
                }
            }
            
            Section("Actions") {
                Button(action: { showingAddCard = true }) {
                    Label("Add New Card", systemImage: "plus.circle")
                        .foregroundColor(Theme.Colors.primary)
                }
                
                NavigationLink(destination: BillingHistoryView()) {
                    Label("Billing History", systemImage: "doc.text")
                }
                
                NavigationLink(destination: PaymentSettingsView()) {
                    Label("Payment Settings", systemImage: "gearshape")
                }
            }
        }
    }
    
    private func loadPaymentMethods() {
        isLoading = true
        
        // Simulate API call to load payment methods
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            // Mock data - in real app, this would come from Stripe
            paymentMethods = [
                PaymentMethodDisplay(
                    id: "pm_1234",
                    brand: "visa",
                    lastFour: "4242",
                    expiryMonth: 12,
                    expiryYear: 2025,
                    isDefault: true
                ),
                PaymentMethodDisplay(
                    id: "pm_5678",
                    brand: "mastercard",
                    lastFour: "5555",
                    expiryMonth: 8,
                    expiryYear: 2026,
                    isDefault: false
                )
            ]
            isLoading = false
        }
    }
    
    private func deletePaymentMethod(_ method: PaymentMethodDisplay) {
        paymentMethods.removeAll { $0.id == method.id }
        ToastManager.shared.showSuccess(
            title: "Card Removed",
            message: "Payment method has been removed"
        )
    }
}

struct PaymentMethodDisplay {
    let id: String
    let brand: String
    let lastFour: String
    let expiryMonth: Int
    let expiryYear: Int
    let isDefault: Bool
}

struct PaymentMethodRow: View {
    let method: PaymentMethodDisplay
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            // Card Brand Icon
            Image(systemName: cardIcon)
                .font(.title2)
                .foregroundColor(cardColor)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(method.brand.capitalized)
                        .font(.headline)
                    
                    if method.isDefault {
                        Text("Default")
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Theme.Colors.primary.opacity(0.2))
                            .foregroundColor(Theme.Colors.primary)
                            .cornerRadius(4)
                    }
                }
                
                Text("•••• •••• •••• \(method.lastFour)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text("Expires \(method.expiryMonth)/\(method.expiryYear)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Menu {
                if !method.isDefault {
                    Button("Set as Default") {
                        setAsDefault()
                    }
                }
                
                Button("Remove", role: .destructive) {
                    onDelete()
                }
            } label: {
                Image(systemName: "ellipsis")
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
    
    private var cardIcon: String {
        switch method.brand.lowercased() {
        case "visa": return "creditcard"
        case "mastercard": return "creditcard"
        case "amex": return "creditcard"
        default: return "creditcard"
        }
    }
    
    private var cardColor: Color {
        switch method.brand.lowercased() {
        case "visa": return .blue
        case "mastercard": return .orange
        case "amex": return .green
        default: return .gray
        }
    }
    
    private func setAsDefault() {
        ToastManager.shared.showSuccess(
            title: "Default Updated",
            message: "\(method.brand.capitalized) ending in \(method.lastFour) is now your default payment method"
        )
    }
}

// MARK: - Add Payment Method View
struct AddPaymentMethodView: View {
    @Environment(\.presentationMode) var presentationMode
    let onSuccess: (Bool) -> Void
    
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                VStack(spacing: 16) {
                    Image(systemName: "creditcard.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(Theme.Colors.primary)
                    
                    Text("Add Payment Method")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Your card information is securely processed by Stripe and never stored on our servers.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                VStack(spacing: 16) {
                    Button(action: addCardWithStripe) {
                        if isLoading {
                            HStack {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("Processing...")
                            }
                        } else {
                            Label("Add Credit/Debit Card", systemImage: "creditcard")
                        }
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Theme.Colors.primary)
                    .cornerRadius(12)
                    .disabled(isLoading)
                    
                    Button(action: addApplePay) {
                        Label("Apple Pay", systemImage: "applelogo")
                            .font(.headline)
                    }
                    .foregroundColor(Theme.Colors.text)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Theme.Colors.secondaryBackground)
                    .cornerRadius(12)
                }
                
                Spacer()
                
                // Security badges
                HStack(spacing: 20) {
                    SecurityBadge(icon: "lock.shield", text: "256-bit SSL")
                    SecurityBadge(icon: "checkmark.shield", text: "PCI Compliant")
                    SecurityBadge(icon: "creditcard.shield", text: "Stripe Secured")
                }
                .padding(.bottom)
            }
            .padding()
            .navigationTitle("Payment Method")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
    
    private func addCardWithStripe() {
        isLoading = true
        
        // In a real app, you would create a PaymentSheet here
        // For demo purposes, simulate the flow
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            isLoading = false
            presentationMode.wrappedValue.dismiss()
            onSuccess(true)
            
            ToastManager.shared.showSuccess(
                title: "Card Added",
                message: "Your payment method has been added successfully"
            )
        }
    }
    
    private func addApplePay() {
        ToastManager.shared.showInfo(
            title: "Apple Pay",
            message: "Apple Pay integration coming soon"
        )
    }
}

struct SecurityBadge: View {
    let icon: String
    let text: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(Theme.Colors.success)
            
            Text(text)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Supporting Views
struct BillingHistoryView: View {
    @State private var transactions: [BillingTransaction] = []
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            Group {
                if isLoading {
                    ProgressView("Loading transactions...")
                } else if transactions.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "doc.text")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)
                        
                        Text("No Transactions")
                            .font(.title2)
                            .fontWeight(.medium)
                        
                        Text("Your billing history will appear here.")
                            .foregroundColor(.secondary)
                    }
                } else {
                    List(transactions, id: \.id) { transaction in
                        BillingTransactionRow(transaction: transaction)
                    }
                }
            }
            .navigationTitle("Billing History")
            .navigationBarTitleDisplayMode(.large)
        }
        .onAppear {
            loadTransactions()
        }
    }
    
    private func loadTransactions() {
        isLoading = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            // Mock data
            transactions = []
            isLoading = false
        }
    }
}

struct BillingTransaction {
    let id: String
    let amount: Double
    let description: String
    let date: Date
    let status: String
}

struct BillingTransactionRow: View {
    let transaction: BillingTransaction
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(transaction.description)
                    .font(.headline)
                
                Text(transaction.date, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("$\(transaction.amount, specifier: "%.2f")")
                    .font(.headline)
                
                Text(transaction.status)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct PaymentSettingsView: View {
    @State private var autoPayEnabled = true
    @State private var payoutSchedule = "Weekly"
    @State private var selectedCurrency = "USD"
    
    var body: some View {
        Form {
            Section("Payment Preferences") {
                Toggle("Auto-pay for rentals", isOn: $autoPayEnabled)
                
                Picker("Default currency", selection: $selectedCurrency) {
                    Text("USD ($)").tag("USD")
                    Text("EUR (€)").tag("EUR")
                    Text("GBP (£)").tag("GBP")
                }
            }
            
            Section("Payouts") {
                Picker("Payout schedule", selection: $payoutSchedule) {
                    Text("Daily").tag("Daily")
                    Text("Weekly").tag("Weekly")
                    Text("Monthly").tag("Monthly")
                }
                
                NavigationLink(destination: PayoutAccountView()) {
                    Label("Payout Account", systemImage: "building.columns")
                }
            }
            
            Section("Notifications") {
                Toggle("Payment confirmations", isOn: .constant(true))
                Toggle("Payout notifications", isOn: .constant(true))
                Toggle("Failed payment alerts", isOn: .constant(true))
            }
        }
        .navigationTitle("Payment Settings")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct PayoutAccountView: View {
    var body: some View {
        Form {
            Section("Bank Account") {
                Text("No bank account connected")
                    .foregroundColor(.secondary)
                
                Button("Connect Bank Account") {
                    ToastManager.shared.showInfo(title: "Coming Soon", message: "Bank account connection will be available soon")
                }
                .foregroundColor(Theme.Colors.primary)
            }
            
            Section {
                Text("Connect your bank account to receive payouts from your rentals. All transactions are secured by Stripe.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .navigationTitle("Payout Account")
        .navigationBarTitleDisplayMode(.inline)
    }
}