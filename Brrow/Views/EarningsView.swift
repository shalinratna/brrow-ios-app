//
//  EarningsView.swift
//  Brrow
//
//  Complete Earnings & Monetization Dashboard
//

import SwiftUI
import Charts

struct EarningsView: View {
    @EnvironmentObject var viewModel: EarningsViewModel
    @State private var selectedTimeframe: EarningsTimeframe = .month
    @State private var showingPayoutSheet = false
    @State private var showingEarningsBreakdown = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: Theme.Spacing.lg) {
                    // Header with total earnings
                    earningsHeader
                    
                    // Quick stats cards
                    quickStatsSection
                    
                    // Earnings chart
                    earningsChartSection
                    
                    // Payout section
                    payoutSection
                    
                    // Recent transactions
                    transactionsSection
                    
                    // Earnings opportunities
                    opportunitiesSection
                }
                .padding(.horizontal, Theme.Spacing.md)
            }
            .background(Theme.Colors.background)
            .navigationTitle("Earnings")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingEarningsBreakdown = true }) {
                        Image(systemName: "chart.bar.xaxis")
                            .font(.system(size: 18))
                            .foregroundColor(Theme.Colors.primary)
                    }
                }
            }
            .sheet(isPresented: $showingPayoutSheet) {
                PayoutRequestView()
            }
            .sheet(isPresented: $showingEarningsBreakdown) {
                EarningsBreakdownView()
                    .environmentObject(viewModel)
            }
        }
        .onAppear {
            viewModel.loadEarningsData()
        }
    }
    
    // MARK: - Earnings Header
    private var earningsHeader: some View {
        VStack(spacing: Theme.Spacing.md) {
            // Total earnings card
            VStack(spacing: Theme.Spacing.sm) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Total Earnings")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Theme.Colors.secondaryText)
                        
                        Text(String(format: "$%.2f", viewModel.totalEarnings))
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundColor(Theme.Colors.text)
                        
                        HStack(spacing: 4) {
                            Image(systemName: viewModel.earningsChange >= 0 ? "arrow.up.right" : "arrow.down.right")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(viewModel.earningsChange >= 0 ? Theme.Colors.success : Theme.Colors.error)
                            
                            Text(String(format: "%.1f%% from last month", abs(viewModel.earningsChange)))
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(viewModel.earningsChange >= 0 ? Theme.Colors.success : Theme.Colors.error)
                        }
                    }
                    
                    Spacer()
                    
                    // Earnings trend mini chart
                    VStack {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.system(size: 24))
                            .foregroundColor(Theme.Colors.primary)
                        
                        Text("Trending")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Theme.Colors.primary)
                    }
                    .padding(12)
                    .background(Theme.Colors.primary.opacity(0.1))
                    .cornerRadius(12)
                }
                
                // Available balance
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Available Balance")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Theme.Colors.secondaryText)
                        
                        Text(String(format: "$%.2f", viewModel.availableBalance))
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(Theme.Colors.success)
                    }
                    
                    Spacer()
                    
                    Button(action: { showingPayoutSheet = true }) {
                        Text("Cash Out")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Theme.Colors.primary)
                            .cornerRadius(20)
                    }
                    .disabled(viewModel.availableBalance < 5.0)
                }
            }
            .padding(Theme.Spacing.lg)
            .background(
                LinearGradient(
                    colors: [
                        Theme.Colors.surface,
                        Theme.Colors.primary.opacity(0.05)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(Theme.CornerRadius.card)
            .shadow(color: Theme.Shadows.card.opacity(0.1), radius: 4, x: 0, y: 2)
        }
    }
    
    // MARK: - Quick Stats
    private var quickStatsSection: some View {
        HStack(spacing: Theme.Spacing.md) {
            EarningsStatCard(
                title: "This Month",
                value: String(format: "$%.2f", viewModel.monthlyEarnings),
                icon: "calendar",
                color: Theme.Colors.primary
            )
            
            EarningsStatCard(
                title: "Items Rented",
                value: "\(viewModel.itemsRented)",
                icon: "cube.box",
                color: Theme.Colors.secondary
            )
            
            EarningsStatCard(
                title: "Avg Per Day",
                value: String(format: "$%.2f", viewModel.avgDailyEarnings),
                icon: "chart.bar",
                color: .orange
            )
        }
    }
    
    // MARK: - Earnings Chart
    private var earningsChartSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            HStack {
                Text("Earnings Overview")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(Theme.Colors.text)
                
                Spacer()
                
                // Timeframe picker
                Picker("Timeframe", selection: $selectedTimeframe) {
                    ForEach(EarningsTimeframe.allCases, id: \.self) { timeframe in
                        Text(timeframe.rawValue)
                            .tag(timeframe)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .frame(width: 200)
            }
            
            // Chart
            if #available(iOS 16.0, *) {
                Chart(viewModel.chartData) { dataPoint in
                    LineMark(
                        x: .value("Date", dataPoint.date),
                        y: .value("Earnings", dataPoint.amount)
                    )
                    .foregroundStyle(Theme.Colors.primary)
                    .interpolationMethod(.catmullRom)
                    
                    AreaMark(
                        x: .value("Date", dataPoint.date),
                        y: .value("Earnings", dataPoint.amount)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Theme.Colors.primary.opacity(0.3), Color.clear],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.catmullRom)
                }
                .frame(height: 200)
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day, count: 7)) { _ in
                        AxisGridLine()
                        AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                    }
                }
                .chartYAxis {
                    AxisMarks { _ in
                        AxisGridLine()
                        AxisValueLabel()
                    }
                }
            } else {
                // Fallback for iOS 15
                Rectangle()
                    .fill(Theme.Colors.primary.opacity(0.1))
                    .frame(height: 200)
                    .cornerRadius(8)
                    .overlay(
                        Text("Chart Available in iOS 16+")
                            .foregroundColor(Theme.Colors.secondaryText)
                    )
            }
        }
        .padding(Theme.Spacing.lg)
        .background(Theme.Colors.surface)
        .cornerRadius(Theme.CornerRadius.card)
        .shadow(color: Theme.Shadows.card.opacity(0.1), radius: 2, x: 0, y: 1)
    }
    
    // MARK: - Payout Section
    private var payoutSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("Payouts")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(Theme.Colors.text)
            
            VStack(spacing: Theme.Spacing.sm) {
                ForEach(viewModel.recentPayouts.prefix(3), id: \.id) { payout in
                    PayoutRow(payout: payout)
                }
                
                if viewModel.recentPayouts.count > 3 {
                    Button("View All Payouts") {
                        // Navigate to full payouts list
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Theme.Colors.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .padding(Theme.Spacing.lg)
        .background(Theme.Colors.surface)
        .cornerRadius(Theme.CornerRadius.card)
        .shadow(color: Theme.Shadows.card.opacity(0.1), radius: 2, x: 0, y: 1)
    }
    
    // MARK: - Transactions Section
    private var transactionsSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            HStack {
                Text("Recent Transactions")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(Theme.Colors.text)
                
                Spacer()
                
                Button("View All") {
                    // Navigate to transactions
                }
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Theme.Colors.primary)
            }
            
            LazyVStack(spacing: Theme.Spacing.sm) {
                ForEach(viewModel.recentTransactions.prefix(5), id: \.id) { legacyTransaction in
                    let transaction = EarningsTransaction(
                        id: legacyTransaction.id,
                        bookingId: legacyTransaction.id,
                        amount: legacyTransaction.amount,
                        type: .rental,
                        status: .completed,
                        date: legacyTransaction.date,
                        description: legacyTransaction.itemTitle,
                        listingTitle: legacyTransaction.itemTitle,
                        renterName: nil,
                        itemImageUrl: legacyTransaction.itemImageUrl
                    )
                    EarningsTransactionRow(transaction: transaction)
                }
            }
        }
        .padding(Theme.Spacing.lg)
        .background(Theme.Colors.surface)
        .cornerRadius(Theme.CornerRadius.card)
        .shadow(color: Theme.Shadows.card.opacity(0.1), radius: 2, x: 0, y: 1)
    }
    
    // MARK: - Opportunities Section
    private var opportunitiesSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("Boost Your Earnings")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(Theme.Colors.text)
            
            LazyVStack(spacing: Theme.Spacing.sm) {
                EarningsOpportunityCard(
                    title: "List More Items",
                    description: "Add 3 more items to increase earnings by up to 40%",
                    icon: "plus.circle.fill",
                    color: Theme.Colors.primary,
                    action: {}
                )
                
                EarningsOpportunityCard(
                    title: "Complete Profile",
                    description: "Verified profiles earn 25% more on average",
                    icon: "checkmark.shield.fill",
                    color: Theme.Colors.success,
                    action: {}
                )
                
                EarningsOpportunityCard(
                    title: "Respond Quickly",
                    description: "Fast responders get 60% more bookings",
                    icon: "bolt.fill",
                    color: .orange,
                    action: {}
                )
            }
        }
        .padding(Theme.Spacing.lg)
        .background(Theme.Colors.surface)
        .cornerRadius(Theme.CornerRadius.card)
        .shadow(color: Theme.Shadows.card.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

// MARK: - Supporting Views

struct EarningsStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)
            
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(Theme.Colors.text)
            
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Theme.Colors.secondaryText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Theme.Spacing.md)
        .background(Theme.Colors.surface)
        .cornerRadius(Theme.CornerRadius.card)
        .shadow(color: Theme.Shadows.card.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

struct PayoutRow: View {
    let payout: EarningsPayout
    
    var body: some View {
        HStack {
            Circle()
                .fill(statusColor.opacity(0.2))
                .frame(width: 8, height: 8)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(String(format: "$%.2f", payout.amount))
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Theme.Colors.text)
                
                Text(payout.method)
                    .font(.system(size: 14))
                    .foregroundColor(Theme.Colors.secondaryText)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(payout.status)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(statusColor)

                Text(payout.date)
                    .font(.system(size: 12))
                    .foregroundColor(Theme.Colors.secondaryText)
            }
        }
        .padding(.vertical, 8)
    }
    
    private var statusColor: Color {
        switch payout.payoutStatus {
        case .pending: return .orange
        case .processing: return Theme.Colors.primary
        case .completed: return Theme.Colors.success
        case .failed: return Theme.Colors.error
        case .none: return Theme.Colors.secondaryText
        }
    }
}

struct EarningsTransactionRow: View {
    let transaction: EarningsTransaction
    
    var body: some View {
        HStack {
            AsyncImage(url: URL(string: transaction.itemImageUrl ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(Theme.Colors.secondary.opacity(0.3))
            }
            .frame(width: 40, height: 40)
            .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(transaction.listingTitle ?? "Unknown Item")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Theme.Colors.text)
                    .lineLimit(1)
                
                Text("Rented to \(transaction.renterName)")
                    .font(.system(size: 12))
                    .foregroundColor(Theme.Colors.secondaryText)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(String(format: "+$%.2f", transaction.amount))
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Theme.Colors.success)
                
                Group {
                    if let transactionDate = transaction.transactionDate {
                        Text(transactionDate, style: .relative)
                    } else {
                        Text(transaction.date)
                    }
                }
                .font(.system(size: 12))
                .foregroundColor(Theme.Colors.secondaryText)
            }
        }
        .padding(.vertical, 8)
    }
}

struct EarningsOpportunityCard: View {
    let title: String
    let description: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(color)
                    .frame(width: 32)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Theme.Colors.text)
                    
                    Text(description)
                        .font(.system(size: 14))
                        .foregroundColor(Theme.Colors.secondaryText)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                Image(systemName: "arrow.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Theme.Colors.secondaryText)
            }
            .padding(Theme.Spacing.md)
            .background(color.opacity(0.05))
            .cornerRadius(Theme.CornerRadius.card)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.card)
                    .stroke(color.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Enums & Models

enum EarningsTimeframe: String, CaseIterable {
    case week = "Week"
    case month = "Month"
    case year = "Year"
}

// MARK: - Payout Request View
struct PayoutRequestView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var payoutAmount: String = ""
    @State private var selectedMethod: EarningsPayoutMethod = .bankAccount
    @State private var bankAccount = ""
    @State private var routingNumber = ""
    @State private var paypalEmail = ""
    @State private var isSubmitting = false
    @State private var showSuccess = false

    var body: some View {
        NavigationView {
            Form {
                Section("Payout Amount") {
                    HStack {
                        Text("$")
                            .foregroundColor(Theme.Colors.text)
                        TextField("0.00", text: $payoutAmount)
                            .keyboardType(.decimalPad)
                    }

                    Text("Minimum payout: $5.00")
                        .font(.caption)
                        .foregroundColor(Theme.Colors.secondaryText)
                }

                Section("Payout Method") {
                    Picker("Method", selection: $selectedMethod) {
                        ForEach(EarningsPayoutMethod.allCases, id: \.self) { method in
                            Text(method.displayName).tag(method)
                        }
                    }
                    .pickerStyle(.menu)
                }

                if selectedMethod == .bankAccount {
                    Section("Bank Account Details") {
                        TextField("Account Number", text: $bankAccount)
                            .keyboardType(.numberPad)
                        TextField("Routing Number", text: $routingNumber)
                            .keyboardType(.numberPad)
                    }
                } else if selectedMethod == .paypal {
                    Section("PayPal Details") {
                        TextField("PayPal Email", text: $paypalEmail)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                    }
                }

                Section {
                    Button("Request Payout") {
                        submitPayoutRequest()
                    }
                    .disabled(payoutAmount.isEmpty || Double(payoutAmount) ?? 0 < 5.0 || isSubmitting)
                }

                Section {
                    Text("Payouts typically take 2-3 business days to process. You'll receive an email confirmation once your payout is complete.")
                        .font(.caption)
                        .foregroundColor(Theme.Colors.secondaryText)
                }
            }
            .navigationTitle("Request Payout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Payout Requested", isPresented: $showSuccess) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Your payout request has been submitted and will be processed within 2-3 business days.")
            }
        }
    }

    private func submitPayoutRequest() {
        isSubmitting = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            isSubmitting = false
            showSuccess = true
        }
    }
}

enum EarningsPayoutMethod: String, CaseIterable {
    case bankAccount = "bank"
    case paypal = "paypal"
    case venmo = "venmo"

    var displayName: String {
        switch self {
        case .bankAccount: return "Bank Account"
        case .paypal: return "PayPal"
        case .venmo: return "Venmo"
        }
    }
}

// MARK: - Earnings Breakdown View
struct EarningsBreakdownView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var viewModel: EarningsViewModel
    @State private var selectedTimeframe: EarningsTimeframe = .month

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: Theme.Spacing.lg) {
                    // Timeframe picker
                    Picker("Timeframe", selection: $selectedTimeframe) {
                        ForEach(EarningsTimeframe.allCases, id: \.self) { timeframe in
                            Text(timeframe.rawValue).tag(timeframe)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)

                    // Summary cards
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Theme.Spacing.md) {
                        BreakdownCard(title: "Total Earnings", value: String(format: "$%.2f", viewModel.totalEarnings), color: Theme.Colors.primary)
                        BreakdownCard(title: "Items Rented", value: "\(viewModel.itemsRented)", color: Theme.Colors.secondary)
                        BreakdownCard(title: "Avg Per Rental", value: String(format: "$%.2f", viewModel.avgDailyEarnings), color: .orange)
                        BreakdownCard(title: "Platform Fee", value: String(format: "$%.2f", viewModel.totalEarnings * 0.1), color: .red)
                    }
                    .padding(.horizontal)

                    // Category breakdown
                    VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                        Text("Earnings by Category")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .padding(.horizontal)

                        VStack(spacing: Theme.Spacing.sm) {
                            CategoryBreakdownRow(category: "Electronics", amount: viewModel.totalEarnings * 0.4, percentage: 40)
                            CategoryBreakdownRow(category: "Tools", amount: viewModel.totalEarnings * 0.3, percentage: 30)
                            CategoryBreakdownRow(category: "Sports", amount: viewModel.totalEarnings * 0.2, percentage: 20)
                            CategoryBreakdownRow(category: "Other", amount: viewModel.totalEarnings * 0.1, percentage: 10)
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical)
                    .background(Theme.Colors.surface)
                    .cornerRadius(Theme.CornerRadius.card)
                    .padding(.horizontal)

                    // Top performing items
                    VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                        Text("Top Performing Items")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .padding(.horizontal)

                        VStack(spacing: Theme.Spacing.sm) {
                            ForEach(0..<5) { index in
                                TopItemRow(
                                    rank: index + 1,
                                    title: "Sample Item \(index + 1)",
                                    earnings: viewModel.totalEarnings * Double(5 - index) / 15,
                                    rentals: 15 - (index * 3)
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical)
                    .background(Theme.Colors.surface)
                    .cornerRadius(Theme.CornerRadius.card)
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .background(Theme.Colors.background)
            .navigationTitle("Earnings Breakdown")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct BreakdownCard: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Text(value)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(color)

            Text(title)
                .font(.caption)
                .foregroundColor(Theme.Colors.secondaryText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Theme.Colors.surface)
        .cornerRadius(Theme.CornerRadius.card)
    }
}

struct CategoryBreakdownRow: View {
    let category: String
    let amount: Double
    let percentage: Int

    var body: some View {
        HStack {
            Text(category)
                .font(.callout)
                .foregroundColor(Theme.Colors.text)

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(String(format: "$%.2f", amount))
                    .font(.callout)
                    .fontWeight(.semibold)
                    .foregroundColor(Theme.Colors.text)

                Text("\(percentage)%")
                    .font(.caption)
                    .foregroundColor(Theme.Colors.secondaryText)
            }
        }
        .padding(.vertical, 4)
    }
}

struct TopItemRow: View {
    let rank: Int
    let title: String
    let earnings: Double
    let rentals: Int

    var body: some View {
        HStack {
            Text("#\(rank)")
                .font(.callout)
                .fontWeight(.bold)
                .foregroundColor(Theme.Colors.primary)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.callout)
                    .foregroundColor(Theme.Colors.text)

                Text("\(rentals) rentals")
                    .font(.caption)
                    .foregroundColor(Theme.Colors.secondaryText)
            }

            Spacer()

            Text(String(format: "$%.2f", earnings))
                .font(.callout)
                .fontWeight(.semibold)
                .foregroundColor(Theme.Colors.success)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    EarningsView()
        .environmentObject(EarningsViewModel())
}