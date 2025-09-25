//
//  HelpSupportView.swift
//  Brrow
//
//  Created by Claude Code on 9/24/25.
//

import SwiftUI

struct StandaloneHelpSupportView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var searchText = ""
    @State private var selectedCategory: HelpCategory? = nil
    @State private var showingContactSupport = false

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search Bar
                searchBar

                // Content
                ScrollView {
                    VStack(spacing: Theme.Spacing.lg) {
                        // Quick Actions
                        quickActionsSection

                        // FAQ Categories
                        faqCategoriesSection

                        // Popular Questions
                        popularQuestionsSection

                        // Contact Support
                        contactSupportSection
                    }
                    .padding(Theme.Spacing.md)
                }
            }
            .background(Theme.Colors.background)
            .navigationTitle("Help & Support")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showingContactSupport) {
            ContactSupportView()
        }
    }

    // MARK: - Search Bar
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(Theme.Colors.secondaryText)

            TextField("Search help articles...", text: $searchText)
                .textFieldStyle(.plain)

            if !searchText.isEmpty {
                Button("Clear") {
                    searchText = ""
                }
                .font(.caption)
                .foregroundColor(Theme.Colors.primary)
            }
        }
        .padding(Theme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                .fill(Theme.Colors.secondaryBackground)
        )
        .padding(Theme.Spacing.md)
    }

    // MARK: - Quick Actions
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("Quick Actions")
                .font(Theme.Typography.headline)
                .fontWeight(.semibold)
                .foregroundColor(Theme.Colors.text)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Theme.Spacing.md) {
                HelpQuickActionCard(
                    icon: "message.circle.fill",
                    title: "Live Chat",
                    subtitle: "Get instant help",
                    color: .blue
                ) {
                    // Start live chat
                    showingContactSupport = true
                }

                HelpQuickActionCard(
                    icon: "envelope.circle.fill",
                    title: "Email Us",
                    subtitle: "Send us a message",
                    color: .green
                ) {
                    if let url = URL(string: "mailto:support@brrow.com") {
                        UIApplication.shared.open(url)
                    }
                }

                HelpQuickActionCard(
                    icon: "phone.circle.fill",
                    title: "Call Support",
                    subtitle: "Speak to an expert",
                    color: .orange
                ) {
                    if let url = URL(string: "tel:+1-555-BRROW-01") {
                        UIApplication.shared.open(url)
                    }
                }

                HelpQuickActionCard(
                    icon: "questionmark.circle.fill",
                    title: "Report Issue",
                    subtitle: "Something's wrong",
                    color: .red
                ) {
                    showingContactSupport = true
                }
            }
        }
    }

    // MARK: - FAQ Categories
    private var faqCategoriesSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("Browse Topics")
                .font(Theme.Typography.headline)
                .fontWeight(.semibold)
                .foregroundColor(Theme.Colors.text)

            VStack(spacing: Theme.Spacing.sm) {
                ForEach(HelpCategory.allCases, id: \.self) { category in
                    CategoryRow(category: category) {
                        selectedCategory = category
                    }
                }
            }
        }
    }

    // MARK: - Popular Questions
    private var popularQuestionsSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("Popular Questions")
                .font(Theme.Typography.headline)
                .fontWeight(.semibold)
                .foregroundColor(Theme.Colors.text)

            VStack(spacing: Theme.Spacing.sm) {
                ForEach(popularQuestions, id: \.id) { question in
                    FAQRow(question: question)
                }
            }
        }
    }

    // MARK: - Contact Support
    private var contactSupportSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("Still Need Help?")
                .font(Theme.Typography.headline)
                .fontWeight(.semibold)
                .foregroundColor(Theme.Colors.text)

            Text("Our support team is available 24/7 to help you with any questions or issues.")
                .font(Theme.Typography.body)
                .foregroundColor(Theme.Colors.secondaryText)

            Button("Contact Support") {
                showingContactSupport = true
            }
            .buttonStyle(HelpPrimaryButtonStyle())
        }
        .padding(Theme.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.lg)
                .fill(
                    LinearGradient(
                        colors: [Theme.Colors.primary.opacity(0.1), Theme.Colors.primary.opacity(0.05)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
    }

    // MARK: - Sample Data
    private let popularQuestions = [
        FAQQuestion(
            id: "1",
            question: "How do I rent an item?",
            answer: "Browse items, select what you need, choose rental dates, and send a request to the owner. Once approved, you can arrange pickup and payment."
        ),
        FAQQuestion(
            id: "2",
            question: "What if an item gets damaged?",
            answer: "All rentals are covered by Brrow Protection. Report any damage immediately through the app, and we'll handle the resolution process."
        ),
        FAQQuestion(
            id: "3",
            question: "How do I get paid for my rentals?",
            answer: "Payments are automatically processed when a rental is completed. Funds are transferred to your bank account within 2-3 business days."
        ),
        FAQQuestion(
            id: "4",
            question: "Can I cancel a rental request?",
            answer: "Yes, you can cancel rental requests before they're approved. Once approved, cancellation policies depend on the timing and owner's settings."
        )
    ]
}

// MARK: - Help Categories
enum HelpCategory: String, CaseIterable {
    case gettingStarted = "getting_started"
    case renting = "renting"
    case listing = "listing"
    case payments = "payments"
    case safety = "safety"
    case account = "account"

    var title: String {
        switch self {
        case .gettingStarted: return "Getting Started"
        case .renting: return "Renting Items"
        case .listing: return "Listing Items"
        case .payments: return "Payments & Billing"
        case .safety: return "Safety & Security"
        case .account: return "Account Management"
        }
    }

    var icon: String {
        switch self {
        case .gettingStarted: return "play.circle.fill"
        case .renting: return "bag.circle.fill"
        case .listing: return "plus.circle.fill"
        case .payments: return "creditcard.circle.fill"
        case .safety: return "shield.checkered"
        case .account: return "person.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .gettingStarted: return .blue
        case .renting: return .green
        case .listing: return .orange
        case .payments: return .purple
        case .safety: return .red
        case .account: return .indigo
        }
    }
}

// MARK: - FAQ Question Model
struct FAQQuestion: Identifiable {
    let id: String
    let question: String
    let answer: String
}

// MARK: - Quick Action Card
struct HelpQuickActionCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: Theme.Spacing.sm) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)

                VStack(spacing: 2) {
                    Text(title)
                        .font(Theme.Typography.callout)
                        .fontWeight(.medium)
                        .foregroundColor(Theme.Colors.text)

                    Text(subtitle)
                        .font(Theme.Typography.caption)
                        .foregroundColor(Theme.Colors.secondaryText)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(Theme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                    .fill(Theme.Colors.cardBackground)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Category Row
struct CategoryRow: View {
    let category: HelpCategory
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Theme.Spacing.md) {
                Image(systemName: category.icon)
                    .font(.title3)
                    .foregroundColor(category.color)
                    .frame(width: 24)

                Text(category.title)
                    .font(Theme.Typography.callout)
                    .fontWeight(.medium)
                    .foregroundColor(Theme.Colors.text)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(Theme.Colors.secondaryText)
            }
            .padding(Theme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                    .fill(Theme.Colors.cardBackground)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - FAQ Row
struct FAQRow: View {
    let question: FAQQuestion
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    Text(question.question)
                        .font(Theme.Typography.callout)
                        .fontWeight(.medium)
                        .foregroundColor(Theme.Colors.text)
                        .multilineTextAlignment(.leading)

                    Spacer()

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(Theme.Colors.secondaryText)
                }
                .padding(Theme.Spacing.md)
            }
            .buttonStyle(PlainButtonStyle())

            if isExpanded {
                Text(question.answer)
                    .font(Theme.Typography.body)
                    .foregroundColor(Theme.Colors.secondaryText)
                    .padding(.horizontal, Theme.Spacing.md)
                    .padding(.bottom, Theme.Spacing.md)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                .fill(Theme.Colors.cardBackground)
        )
    }
}

// MARK: - Contact Support View
struct ContactSupportView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var selectedIssueType: IssueType = .general
    @State private var subject = ""
    @State private var message = ""
    @State private var isSubmitting = false
    @State private var showSuccess = false

    var body: some View {
        NavigationView {
            Form {
                Section("Issue Type") {
                    Picker("Type", selection: $selectedIssueType) {
                        ForEach(IssueType.allCases, id: \.self) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                    .pickerStyle(.menu)
                }

                Section("Subject") {
                    TextField("Brief description of your issue", text: $subject)
                }

                Section("Message") {
                    TextEditor(text: $message)
                        .frame(minHeight: 100)
                }

                Section {
                    Button("Submit Request") {
                        submitSupportRequest()
                    }
                    .disabled(subject.isEmpty || message.isEmpty || isSubmitting)
                }
            }
            .navigationTitle("Contact Support")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .alert("Request Submitted", isPresented: $showSuccess) {
                Button("OK") {
                    presentationMode.wrappedValue.dismiss()
                }
            } message: {
                Text("We've received your support request and will get back to you within 24 hours.")
            }
        }
    }

    private func submitSupportRequest() {
        isSubmitting = true

        // Simulate API call
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            isSubmitting = false
            showSuccess = true
        }
    }
}

// MARK: - Issue Types
enum IssueType: String, CaseIterable {
    case general = "general"
    case technical = "technical"
    case payment = "payment"
    case safety = "safety"
    case account = "account"

    var displayName: String {
        switch self {
        case .general: return "General Question"
        case .technical: return "Technical Issue"
        case .payment: return "Payment Problem"
        case .safety: return "Safety Concern"
        case .account: return "Account Issue"
        }
    }
}

// MARK: - Primary Button Style
struct HelpPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Theme.Typography.callout)
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(Theme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                    .fill(Theme.Colors.primary)
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Preview
#Preview {
    StandaloneHelpSupportView()
}