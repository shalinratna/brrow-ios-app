import SwiftUI
import SafariServices

struct StripeSubscriptionView: View {
    @StateObject private var viewModel = StripeSubscriptionViewModel()
    @State private var selectedPlan: StripeSubscriptionPlan?
    @State private var showingWebCheckout = false
    @State private var showingCancelConfirmation = false
    @State private var checkoutURL: URL?
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
                
                if viewModel.isLoading {
                    ProgressView("Loading subscription data...")
                        .padding()
                        .background(Theme.Colors.secondaryBackground)
                        .cornerRadius(12)
                } else {
                    ScrollView {
                        VStack(spacing: Theme.Spacing.lg) {
                            // Header message about cross-platform
                            crossPlatformMessage
                            
                            // Current Subscription Status
                            if let currentSubscription = viewModel.currentSubscription {
                                StripeSubscriptionCard(
                                    subscription: currentSubscription,
                                    onManage: { manageSubscription() },
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
                                    StripePlanCard(
                                        plan: plan,
                                        isCurrentPlan: viewModel.currentSubscription?.stripePriceId == plan.stripePriceId,
                                        onSelect: {
                                            selectedPlan = plan
                                            createCheckoutSession(for: plan)
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
            }
            .navigationTitle("Subscriptions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(Theme.Colors.primary)
                }
            }
            .sheet(isPresented: $showingWebCheckout) {
                if let url = checkoutURL {
                    SafariView(url: url)
                        .onDisappear {
                            // Refresh subscription status when checkout completes
                            viewModel.loadSubscriptionData()
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
    
    private var crossPlatformMessage: some View {
        HStack {
            Image(systemName: "globe")
                .foregroundColor(Theme.Colors.primary)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Cross-Platform Subscriptions")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(Theme.Colors.text)
                
                Text("Your subscription works on iOS, Android, and Web")
                    .font(.caption)
                    .foregroundColor(Theme.Colors.secondaryText)
            }
            
            Spacer()
        }
        .padding()
        .background(Theme.Colors.primary.opacity(0.1))
        .cornerRadius(12)
        .padding(.horizontal)
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
                    question: "How does Stripe billing work?",
                    answer: "We use Stripe to securely process payments. You'll be redirected to Stripe's secure checkout page to enter your payment details. Your subscription will automatically renew each month."
                )
                
                FAQItem(
                    question: "Can I use my subscription on multiple devices?",
                    answer: "Yes! Your subscription is tied to your Brrow account, not your device. You can use it on iOS, Android, and our web platform."
                )
                
                FAQItem(
                    question: "How do I manage my subscription?",
                    answer: "You can manage your subscription, update payment methods, and view invoices through our customer portal powered by Stripe."
                )
                
                FAQItem(
                    question: "What happens when I cancel?",
                    answer: "You'll keep your benefits until the end of your current billing period. After that, you'll return to the free plan."
                )
            }
            .padding(.horizontal)
        }
    }
    
    private func createCheckoutSession(for plan: StripeSubscriptionPlan) {
        viewModel.createCheckoutSession(for: plan) { result in
            switch result {
            case .success(let url):
                checkoutURL = url
                showingWebCheckout = true
            case .failure(let error):
                // Handle error
                print("Checkout error: \(error)")
            }
        }
    }
    
    private func manageSubscription() {
        viewModel.getCustomerPortalURL { result in
            switch result {
            case .success(let url):
                checkoutURL = url
                showingWebCheckout = true
            case .failure(let error):
                // Handle error
                print("Portal error: \(error)")
            }
        }
    }
}

// Stripe Subscription Card
struct StripeSubscriptionCard: View {
    let subscription: StripeSubscription
    let onManage: () -> Void
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
                Label("$\(String(format: "%.2f", Double(subscription.amount) / 100.0))/\(subscription.interval)", systemImage: "creditcard.fill")
                    .font(.subheadline)
                    .foregroundColor(Theme.Colors.secondaryText)
                
                Spacer()
                
                if let currentPeriodEnd = subscription.currentPeriodEnd {
                    Text("Next billing: \(currentPeriodEnd, formatter: dateFormatter)")
                        .font(.caption)
                        .foregroundColor(Theme.Colors.secondaryText)
                }
            }
            
            HStack(spacing: Theme.Spacing.md) {
                Button(action: onManage) {
                    Label("Manage", systemImage: "gear")
                        .font(.subheadline)
                        .foregroundColor(Theme.Colors.primary)
                }
                .buttonStyle(PlainButtonStyle())
                
                if subscription.status == "active" && !subscription.cancelAtPeriodEnd {
                    Button(action: onCancel) {
                        Label("Cancel", systemImage: "xmark.circle")
                            .font(.subheadline)
                            .foregroundColor(.red)
                    }
                    .buttonStyle(PlainButtonStyle())
                } else if subscription.cancelAtPeriodEnd {
                    Text("Cancels on \(subscription.currentPeriodEnd ?? Date(), formatter: dateFormatter)")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
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

// Stripe Plan Card
struct StripePlanCard: View {
    let plan: StripeSubscriptionPlan
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
                    Text("$\(String(format: "%.2f", Double(plan.amount) / 100.0))")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(Theme.Colors.primary)
                    
                    Text("/\(plan.interval)")
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
                Text(isCurrentPlan ? "Current Plan" : "Subscribe with Stripe")
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

// Safari View for Stripe Checkout
struct SafariView: UIViewControllerRepresentable {
    let url: URL
    
    func makeUIViewController(context: Context) -> SFSafariViewController {
        let controller = SFSafariViewController(url: url)
        controller.preferredControlTintColor = UIColor(Theme.Colors.primary)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}

// View Model
class StripeSubscriptionViewModel: ObservableObject {
    @Published var currentSubscription: StripeSubscription?
    @Published var availablePlans: [StripeSubscriptionPlan] = []
    @Published var isLoading = false
    @Published var error: String?
    
    func loadSubscriptionData() {
        isLoading = true
        
        Task {
            do {
                // Load current Stripe subscription
                let subscriptionData = try await APIClient.shared.getStripeSubscription()
                
                await MainActor.run {
                    self.currentSubscription = subscriptionData
                    self.loadAvailablePlans()
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.error = error.localizedDescription
                    self.isLoading = false
                    // Still load plans even if no current subscription
                    self.loadAvailablePlans()
                }
            }
        }
    }
    
    func loadAvailablePlans() {
        let accountType = AuthManager.shared.currentUser?.accountType ?? "personal"
        
        var plans = [
            StripeSubscriptionPlan(
                id: "green",
                stripePriceId: "price_1Rot50DZizGZADzcPaNhjrzg",
                stripeProductId: "prod_SkNq4td70VeTPW",
                name: "Brrow Green",
                amount: 599, // Amount in cents
                currency: "usd",
                interval: "month",
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
            StripeSubscriptionPlan(
                id: "gold",
                stripePriceId: "price_1Rot5gDZizGZADzckEbfJuMs",
                stripeProductId: "prod_SkNrFVUCDy8vqx",
                name: "Brrow Gold",
                amount: 999, // Amount in cents
                currency: "usd",
                interval: "month",
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
                StripeSubscriptionPlan(
                    id: "fleet",
                    stripePriceId: "price_1Rot71DZizGZADzch0kW7n91",
                    stripeProductId: "prod_SkNsil9sGFTCQv",
                    name: "Brrow Fleet Management",
                    amount: 2999, // Amount in cents
                    currency: "usd",
                    interval: "month",
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
    
    func createCheckoutSession(for plan: StripeSubscriptionPlan, completion: @escaping (Result<URL, Error>) -> Void) {
        Task {
            do {
                let sessionData = try await APIClient.shared.createStripeCheckoutSession(
                    priceId: plan.stripePriceId,
                    successUrl: "brrowapp://subscription-success",
                    cancelUrl: "brrowapp://subscription-cancel"
                )
                
                if let url = URL(string: sessionData.url) {
                    await MainActor.run {
                        completion(.success(url))
                    }
                } else {
                    throw URLError(.badURL)
                }
            } catch {
                await MainActor.run {
                    completion(.failure(error))
                }
            }
        }
    }
    
    func getCustomerPortalURL(completion: @escaping (Result<URL, Error>) -> Void) {
        Task {
            do {
                let portalData = try await APIClient.shared.getStripeCustomerPortal()
                
                if let url = URL(string: portalData.url) {
                    await MainActor.run {
                        completion(.success(url))
                    }
                } else {
                    throw URLError(.badURL)
                }
            } catch {
                await MainActor.run {
                    completion(.failure(error))
                }
            }
        }
    }
    
    func cancelSubscription() {
        Task {
            do {
                try await APIClient.shared.cancelStripeSubscription()
                await MainActor.run {
                    loadSubscriptionData()
                }
            } catch {
                await MainActor.run {
                    self.error = "Failed to cancel subscription: \(error.localizedDescription)"
                }
            }
        }
    }
}

// Models
struct StripeSubscription: Codable {
    let id: String
    let customerId: String
    let status: String
    let planName: String
    let stripePriceId: String
    let amount: Int // Amount in cents
    let currency: String
    let interval: String // month, year
    let currentPeriodStart: Date
    let currentPeriodEnd: Date?
    let cancelAtPeriodEnd: Bool
    let canceledAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id, status, amount, currency, interval
        case customerId = "customer_id"
        case planName = "plan_name"
        case stripePriceId = "stripe_price_id"
        case currentPeriodStart = "current_period_start"
        case currentPeriodEnd = "current_period_end"
        case cancelAtPeriodEnd = "cancel_at_period_end"
        case canceledAt = "canceled_at"
    }
}

struct StripeSubscriptionPlan: Identifiable {
    let id: String
    let stripePriceId: String
    let stripeProductId: String
    let name: String
    let amount: Int // Amount in cents
    let currency: String
    let interval: String
    let description: String
    let features: [String]
    let savingsText: String?
    let isPopular: Bool
    let isRecommended: Bool
    
    init(id: String, stripePriceId: String, stripeProductId: String, name: String, 
         amount: Int, currency: String, interval: String, description: String,
         features: [String], savingsText: String? = nil, 
         isPopular: Bool = false, isRecommended: Bool = false) {
        self.id = id
        self.stripePriceId = stripePriceId
        self.stripeProductId = stripeProductId
        self.name = name
        self.amount = amount
        self.currency = currency
        self.interval = interval
        self.description = description
        self.features = features
        self.savingsText = savingsText
        self.isPopular = isPopular
        self.isRecommended = isRecommended
    }
}

// Checkout session response
struct StripeCheckoutSession: Codable {
    let id: String
    let url: String
}

// Customer portal response
struct StripeCustomerPortal: Codable {
    let url: String
}

#Preview {
    StripeSubscriptionView()
}