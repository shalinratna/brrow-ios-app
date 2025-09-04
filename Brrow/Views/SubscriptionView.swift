import SwiftUI
import StoreKit

struct SubscriptionView: View {
    @StateObject private var viewModel = SubscriptionViewModel()
    @State private var selectedPlan: SubscriptionPlan?
    @State private var showingPaymentSheet = false
    @State private var showingCancelConfirmation = false
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [
                        Theme.Colors.primary.opacity(0.05),
                        Theme.Colors.background
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: Theme.Spacing.lg) {
                        // Current Subscription Status
                        if let currentSubscription = viewModel.currentSubscription {
                            CurrentSubscriptionCard(
                                subscription: currentSubscription,
                                onCancel: { showingCancelConfirmation = true }
                            )
                        }
                        
                        // Subscription Benefits Overview
                        benefitsOverview
                        
                        // Available Plans
                        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                            Text("Available Plans")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(Theme.Colors.text)
                                .padding(.horizontal)
                            
                            ForEach(viewModel.availablePlans) { plan in
                                SubscriptionPlanCard(
                                    plan: plan,
                                    isCurrentPlan: viewModel.currentSubscription?.type == plan.type,
                                    onSelect: {
                                        selectedPlan = plan
                                        showingPaymentSheet = true
                                    }
                                )
                                .padding(.horizontal)
                            }
                        }
                        
                        // FAQ Section
                        faqSection
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("Subscriptions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(Theme.Colors.primary)
                }
            }
            .sheet(isPresented: $showingPaymentSheet) {
                if let plan = selectedPlan {
                    SubscriptionPaymentView(plan: plan) { success in
                        if success {
                            viewModel.refreshSubscriptionStatus()
                        }
                        showingPaymentSheet = false
                    }
                }
            }
            .alert("Cancel Subscription", isPresented: $showingCancelConfirmation) {
                Button("Cancel Subscription", role: .destructive) {
                    viewModel.cancelSubscription()
                }
                Button("Keep Subscription", role: .cancel) { }
            } message: {
                Text("Are you sure you want to cancel your subscription? You'll lose access to premium features at the end of your billing period.")
            }
        }
        .onAppear {
            viewModel.loadSubscriptionData()
        }
    }
    
    private var benefitsOverview: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("Why Subscribe?")
                .font(.headline)
                .foregroundColor(Theme.Colors.text)
            
            HStack(spacing: Theme.Spacing.md) {
                BenefitCard(
                    icon: "percent",
                    title: "Save on Fees",
                    description: "Reduced or zero commission"
                )
                
                BenefitCard(
                    icon: "star.fill",
                    title: "Premium Features",
                    description: "Access advanced tools"
                )
                
                BenefitCard(
                    icon: "headphones",
                    title: "Priority Support",
                    description: "Get help faster"
                )
            }
        }
        .padding(.horizontal)
    }
    
    private var faqSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("Frequently Asked Questions")
                .font(.headline)
                .foregroundColor(Theme.Colors.text)
                .padding(.horizontal)
            
            VStack(spacing: Theme.Spacing.sm) {
                FAQItem(
                    question: "Can I change plans anytime?",
                    answer: "Yes! You can upgrade or downgrade your plan at any time. Changes take effect immediately."
                )
                
                FAQItem(
                    question: "What happens when I cancel?",
                    answer: "You'll keep your benefits until the end of your current billing period. After that, you'll return to the free plan."
                )
                
                FAQItem(
                    question: "Are there any hidden fees?",
                    answer: "No hidden fees! You only pay the monthly subscription price plus standard payment processing fees on transactions."
                )
            }
            .padding(.horizontal)
        }
    }
}

struct CurrentSubscriptionCard: View {
    let subscription: CurrentSubscription
    let onCancel: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Current Plan")
                        .font(.subheadline)
                        .foregroundColor(Theme.Colors.secondaryText)
                    
                    Text(subscription.planName)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(Theme.Colors.text)
                }
                
                Spacer()
                
                StatusBadge(status: subscription.status)
            }
            
            HStack {
                Label("$\(String(format: "%.2f", subscription.price))/month", systemImage: "creditcard.fill")
                    .font(.subheadline)
                    .foregroundColor(Theme.Colors.secondaryText)
                
                Spacer()
                
                if let nextBillingDate = subscription.nextBillingDate {
                    Text("Next billing: \(nextBillingDate, formatter: dateFormatter)")
                        .font(.caption)
                        .foregroundColor(Theme.Colors.secondaryText)
                }
            }
            
            if subscription.status == "active" && !subscription.cancelAtPeriodEnd {
                Button(action: onCancel) {
                    Text("Cancel Subscription")
                        .font(.subheadline)
                        .foregroundColor(.red)
                }
            } else if subscription.cancelAtPeriodEnd {
                Text("Cancels on \(subscription.currentPeriodEnd ?? Date(), formatter: dateFormatter)")
                    .font(.caption)
                    .foregroundColor(.orange)
            }
        }
        .padding()
        .background(Theme.Colors.secondaryBackground)
        .cornerRadius(12)
        .padding(.horizontal)
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }
}

struct SubscriptionPlanCard: View {
    let plan: SubscriptionPlan
    let isCurrentPlan: Bool
    let onSelect: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(plan.name)
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(Theme.Colors.text)
                        
                        if plan.isPopular {
                            Text("POPULAR")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.orange)
                                .cornerRadius(4)
                        }
                        
                        if plan.isRecommended {
                            Text("RECOMMENDED")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Theme.Colors.primary)
                                .cornerRadius(4)
                        }
                    }
                    
                    Text(plan.description)
                        .font(.subheadline)
                        .foregroundColor(Theme.Colors.secondaryText)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("$\(String(format: "%.2f", plan.price))")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(Theme.Colors.primary)
                    
                    Text("/month")
                        .font(.caption)
                        .foregroundColor(Theme.Colors.secondaryText)
                }
            }
            
            // Savings highlight
            if let savings = plan.savingsText {
                HStack {
                    Image(systemName: "arrow.down.circle.fill")
                        .foregroundColor(.green)
                    Text(savings)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.green)
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(Color.green.opacity(0.1))
                .cornerRadius(8)
            }
            
            // Features
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                ForEach(plan.features, id: \.self) { feature in
                    HStack(spacing: Theme.Spacing.sm) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.body)
                            .foregroundColor(Theme.Colors.primary)
                        
                        Text(feature)
                            .font(.subheadline)
                            .foregroundColor(Theme.Colors.text)
                        
                        Spacer()
                    }
                }
            }
            
            // Action button
            Button(action: onSelect) {
                Text(isCurrentPlan ? "Current Plan" : "Select Plan")
                    .fontWeight(.semibold)
                    .foregroundColor(isCurrentPlan ? Theme.Colors.secondaryText : .white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(isCurrentPlan ? Color.gray.opacity(0.2) : Theme.Colors.primary)
                    .cornerRadius(8)
            }
            .disabled(isCurrentPlan)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Theme.Colors.secondaryBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            plan.isRecommended ? Theme.Colors.primary : Color.clear,
                            lineWidth: 2
                        )
                )
        )
    }
}

struct BenefitCard: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        VStack(spacing: Theme.Spacing.sm) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(Theme.Colors.primary)
            
            Text(title)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(Theme.Colors.text)
                .multilineTextAlignment(.center)
            
            Text(description)
                .font(.caption2)
                .foregroundColor(Theme.Colors.secondaryText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Theme.Colors.secondaryBackground)
        .cornerRadius(12)
    }
}

struct FAQItem: View {
    let question: String
    let answer: String
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Button(action: { isExpanded.toggle() }) {
                HStack {
                    Text(question)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(Theme.Colors.text)
                        .multilineTextAlignment(.leading)
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(Theme.Colors.secondaryText)
                }
            }
            
            if isExpanded {
                Text(answer)
                    .font(.caption)
                    .foregroundColor(Theme.Colors.secondaryText)
                    .padding(.top, 4)
            }
        }
        .padding()
        .background(Theme.Colors.secondaryBackground)
        .cornerRadius(8)
    }
}

struct StatusBadge: View {
    let status: String
    
    var body: some View {
        Text(status.capitalized)
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                status == "active" ? Color.green : 
                status == "cancelled" ? Color.red : 
                Color.orange
            )
            .cornerRadius(4)
    }
}

// Payment View
struct SubscriptionPaymentView: View {
    let plan: SubscriptionPlan
    let completion: (Bool) -> Void
    @State private var isProcessing = false
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: Theme.Spacing.lg) {
                // Plan summary
                VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                    Text("Subscribe to \(plan.name)")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    HStack {
                        Text("$\(String(format: "%.2f", plan.price))/month")
                            .font(.title3)
                            .foregroundColor(Theme.Colors.primary)
                        
                        Spacer()
                        
                        if plan.type != "free" {
                            Text("Cancel anytime")
                                .font(.caption)
                                .foregroundColor(Theme.Colors.secondaryText)
                        }
                    }
                }
                .padding()
                .background(Theme.Colors.secondaryBackground)
                .cornerRadius(12)
                
                // Payment method selector
                // In a real app, this would integrate with Stripe
                VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                    Text("Payment Method")
                        .font(.headline)
                    
                    Button(action: {}) {
                        HStack {
                            Image(systemName: "creditcard.fill")
                            Text("Add Payment Method")
                            Spacer()
                            Image(systemName: "chevron.right")
                        }
                        .padding()
                        .background(Theme.Colors.secondaryBackground)
                        .cornerRadius(8)
                    }
                }
                
                Spacer()
                
                // Subscribe button
                Button(action: subscribe) {
                    HStack {
                        if isProcessing {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else {
                            Text("Subscribe Now")
                                .fontWeight(.semibold)
                        }
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Theme.Colors.primary)
                    .cornerRadius(12)
                }
                .disabled(isProcessing)
            }
            .padding()
            .navigationTitle("Payment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
    
    private func subscribe() {
        isProcessing = true
        
        // In a real app, this would process payment through Stripe
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            isProcessing = false
            completion(true)
            dismiss()
        }
    }
}

// View Model
class SubscriptionViewModel: ObservableObject {
    @Published var currentSubscription: CurrentSubscription?
    @Published var availablePlans: [SubscriptionPlan] = []
    @Published var isLoading = false
    
    func loadSubscriptionData() {
        isLoading = true
        
        Task {
            do {
                // Load current subscription
                let subscriptionData = try await APIClient.shared.getCurrentSubscription()
                
                await MainActor.run {
                    self.currentSubscription = subscriptionData
                    self.loadAvailablePlans()
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    // Handle error
                }
            }
        }
    }
    
    func loadAvailablePlans() {
        let accountType = AuthManager.shared.currentUser?.accountType ?? "personal"
        
        var plans = [
            SubscriptionPlan(
                id: "green",
                type: "green",
                name: "Brrow Green",
                price: 5.99,
                description: "Reduced commission fees and priority support",
                features: [
                    "1% commission rate (down from 10%)",
                    "Up to 50 active listings",
                    "Basic analytics",
                    "Priority customer support"
                ],
                savingsText: "Save 9% on every transaction",
                isPopular: true
            ),
            SubscriptionPlan(
                id: "gold",
                type: "gold",
                name: "Brrow Gold",
                price: 9.99,
                description: "Zero commission fees and premium features",
                features: [
                    "0% commission rate",
                    "Up to 100 active listings",
                    "Advanced analytics",
                    "Priority customer support",
                    "5 featured listings per month"
                ],
                savingsText: "Save 10% on every transaction",
                isPopular: true
            )
        ]
        
        if accountType == "business" {
            plans.append(
                SubscriptionPlan(
                    id: "fleet",
                    type: "fleet",
                    name: "Brrow Fleet Management",
                    price: 29.99,
                    description: "Professional tools for business renters",
                    features: [
                        "0% commission rate",
                        "Unlimited listings",
                        "Multi-item inventory management",
                        "Bulk listing tools",
                        "Professional analytics dashboard",
                        "Automated availability calendars",
                        "Revenue optimization tools",
                        "API access",
                        "Webhook integrations",
                        "Dedicated account manager"
                    ],
                    savingsText: "Professional tools to scale your business",
                    isRecommended: true
                )
            )
        }
        
        availablePlans = plans
    }
    
    func refreshSubscriptionStatus() {
        loadSubscriptionData()
    }
    
    func cancelSubscription() {
        Task {
            do {
                try await APIClient.shared.cancelSubscription(immediately: false)
                await MainActor.run {
                    loadSubscriptionData()
                }
            } catch {
                // Handle error
            }
        }
    }
}

// Models
struct CurrentSubscription: Codable {
    let id: String
    let type: String
    let planName: String
    let price: Double
    let status: String
    let nextBillingDate: Date?
    let currentPeriodEnd: Date?
    let cancelAtPeriodEnd: Bool
    
    enum CodingKeys: String, CodingKey {
        case id, type, status, price
        case planName = "plan_name"
        case nextBillingDate = "next_billing_date"
        case currentPeriodEnd = "current_period_end"
        case cancelAtPeriodEnd = "cancel_at_period_end"
    }
}

struct SubscriptionPlan: Identifiable {
    let id: String
    let type: String
    let name: String
    let price: Double
    let description: String
    let features: [String]
    let savingsText: String?
    let isPopular: Bool
    let isRecommended: Bool
    
    init(id: String, type: String, name: String, price: Double, description: String, 
         features: [String], savingsText: String? = nil, 
         isPopular: Bool = false, isRecommended: Bool = false) {
        self.id = id
        self.type = type
        self.name = name
        self.price = price
        self.description = description
        self.features = features
        self.savingsText = savingsText
        self.isPopular = isPopular
        self.isRecommended = isRecommended
    }
}

#Preview {
    SubscriptionView()
}