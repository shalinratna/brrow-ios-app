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
                    // Balance Display Section
                    balanceDisplaySection

                    // Stripe Connection Status
                    stripeConnectionSection

                    // Quick stats cards
                    quickStatsSection

                    // Earnings chart
                    earningsChartSection

                    // Payout History
                    payoutSection

                    // Balance Transactions
                    balanceTransactionsSection

                    // Recent transactions (legacy)
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
                StripePayoutRequestView()
                    .environmentObject(viewModel)
            }
            .sheet(isPresented: $showingEarningsBreakdown) {
                EarningsBreakdownView()
                    .environmentObject(viewModel)
            }
            .alert("Success", isPresented: .constant(viewModel.payoutSuccessMessage != nil)) {
                Button("OK") {
                    viewModel.payoutSuccessMessage = nil
                }
            } message: {
                if let message = viewModel.payoutSuccessMessage {
                    Text(message)
                }
            }
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") {
                    viewModel.errorMessage = nil
                }
            } message: {
                if let error = viewModel.errorMessage {
                    Text(error)
                }
            }
        }
        .onAppear {
            viewModel.loadEarningsData()
        }
    }
    
    // MARK: - Balance Display Section
    private var balanceDisplaySection: some View {
        VStack(spacing: Theme.Spacing.md) {
            VStack(spacing: Theme.Spacing.sm) {
                // Available Balance (Large, prominent)
                VStack(alignment: .leading, spacing: 8) {
                    Text("Available Balance")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Theme.Colors.text.opacity(0.7))

                    Text(String(format: "$%.2f", viewModel.availableBalance))
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .foregroundColor(viewModel.availableBalance > 0 ? Theme.Colors.success : Theme.Colors.text)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Divider()
                    .padding(.vertical, 4)

                // Gross sales and fees breakdown
                VStack(spacing: 12) {
                    HStack(spacing: Theme.Spacing.lg) {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 4) {
                                Text("Gross Sales")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(Theme.Colors.text.opacity(0.7))
                                Image(systemName: "info.circle")
                                    .font(.system(size: 11))
                                    .foregroundColor(Theme.Colors.text.opacity(0.5))
                            }

                            Text(String(format: "$%.2f", viewModel.totalEarned / 0.95))
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(Theme.Colors.text)
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 4) {
                            Text("Net Earnings")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(Theme.Colors.text.opacity(0.7))

                            Text(String(format: "$%.2f", viewModel.totalEarned))
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(Theme.Colors.success)
                        }
                    }

                    // Fees breakdown
                    VStack(spacing: 8) {
                        HStack {
                            HStack(spacing: 4) {
                                Image(systemName: "building.columns")
                                    .font(.system(size: 11))
                                    .foregroundColor(Theme.Colors.text.opacity(0.5))
                                Text("Brrow Fee (5%)")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(Theme.Colors.text.opacity(0.7))
                            }

                            Spacer()

                            Text(String(format: "$%.2f", viewModel.platformFees))
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Theme.Colors.text.opacity(0.7))
                        }

                        HStack {
                            HStack(spacing: 4) {
                                Image(systemName: "creditcard")
                                    .font(.system(size: 11))
                                    .foregroundColor(Theme.Colors.text.opacity(0.5))
                                Text("Payment Processing")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(Theme.Colors.text.opacity(0.7))
                            }

                            Spacer()

                            Text(String(format: "$%.2f", calculateStripeFees()))
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Theme.Colors.text.opacity(0.7))
                        }
                    }
                    .padding(.top, 4)
                }

                Divider()
                    .padding(.vertical, 4)

                HStack(spacing: Theme.Spacing.lg) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Pending")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Theme.Colors.text.opacity(0.7))

                        Text(String(format: "$%.2f", viewModel.pendingBalance))
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Theme.Colors.text)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Total Withdrawn")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Theme.Colors.text.opacity(0.7))

                        Text(String(format: "$%.2f", viewModel.totalWithdrawn))
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Theme.Colors.text)
                    }
                }
            }
            .padding(Theme.Spacing.lg)
            .background(
                LinearGradient(
                    colors: [
                        Color.white,
                        Theme.Colors.success.opacity(0.03)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(Theme.CornerRadius.card)
            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        }
    }

    // Calculate Stripe payment processing fees (2.9% + $0.30 per transaction)
    private func calculateStripeFees() -> Double {
        let grossSales = viewModel.totalEarned / 0.95
        // Approximate Stripe fee: 2.9% + $0.30 per transaction
        // Assuming average transaction count based on sales
        let transactionCount = max(1.0, Double(viewModel.totalSales))
        return (grossSales * 0.029) + (0.30 * transactionCount)
    }

    // MARK: - Stripe Connection Section
    private var stripeConnectionSection: some View {
        VStack(spacing: Theme.Spacing.md) {
            if !viewModel.hasStripeConnected {
                // Not connected - show warning banner
                VStack(spacing: Theme.Spacing.sm) {
                    HStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.orange)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Connect Stripe Account")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(Theme.Colors.text)

                            Text("Connect your Stripe account to cash out your earnings")
                                .font(.system(size: 14))
                                .foregroundColor(Theme.Colors.secondaryText)
                        }

                        Spacer()
                    }

                    Button(action: {
                        Task {
                            do {
                                let url = try await viewModel.getStripeConnectURL()
                                if let stripeURL = URL(string: url) {
                                    await UIApplication.shared.open(stripeURL)
                                }
                            } catch {
                                viewModel.errorMessage = "Failed to get Stripe onboarding URL"
                            }
                        }
                    }) {
                        HStack {
                            Image(systemName: "link.circle.fill")
                            Text("Connect Stripe Account")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Theme.Colors.success)
                        .cornerRadius(12)
                    }
                }
                .padding(Theme.Spacing.lg)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(Theme.CornerRadius.card)
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.CornerRadius.card)
                        .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                )

            } else {
                // Connected - show status and payout button
                VStack(spacing: Theme.Spacing.sm) {
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(Theme.Colors.success)

                        Text("Stripe Account Connected")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Theme.Colors.success)

                        Spacer()
                    }

                    if viewModel.canRequestPayout {
                        Button(action: { showingPayoutSheet = true }) {
                            HStack {
                                Image(systemName: "dollarsign.circle.fill")
                                Text("Request Payout")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Theme.Colors.success)
                            .cornerRadius(12)
                        }
                        .disabled(viewModel.availableBalance < viewModel.minimumPayout)
                    } else {
                        Text("Minimum payout amount: $\(String(format: "%.0f", viewModel.minimumPayout))")
                            .font(.system(size: 14))
                            .foregroundColor(Theme.Colors.secondaryText)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(Theme.Spacing.lg)
                .background(Theme.Colors.success.opacity(0.1))
                .cornerRadius(Theme.CornerRadius.card)
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.CornerRadius.card)
                        .stroke(Theme.Colors.success.opacity(0.3), lineWidth: 1)
                )
            }
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
        .background(Color.white)
        .cornerRadius(Theme.CornerRadius.card)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
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
        .background(Color.white)
        .cornerRadius(Theme.CornerRadius.card)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    // MARK: - Balance Transactions Section
    private var balanceTransactionsSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("Balance History")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(Theme.Colors.text)

            if viewModel.balanceTransactions.isEmpty {
                Text("No balance transactions yet")
                    .font(.system(size: 14))
                    .foregroundColor(Theme.Colors.secondaryText)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, Theme.Spacing.lg)
            } else {
                LazyVStack(spacing: Theme.Spacing.sm) {
                    ForEach(viewModel.balanceTransactions.prefix(10), id: \.id) { transaction in
                        BalanceTransactionRow(transaction: transaction)
                    }
                }
            }
        }
        .padding(Theme.Spacing.lg)
        .background(Color.white)
        .cornerRadius(Theme.CornerRadius.card)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
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
                        type: CreatorModels.TransactionType.rental,
                        status: EarningsTransactionStatus.completed,
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
        .background(Color.white)
        .cornerRadius(Theme.CornerRadius.card)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - Opportunities Section
    private var opportunitiesSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("Helpful Tips")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(Theme.Colors.text)

            LazyVStack(spacing: Theme.Spacing.md) {
                EarningsTipCard(
                    title: "Quality Photos Increase Sales",
                    description: "Listings with 3+ clear photos get 2x more views. Use natural lighting and show items from multiple angles.",
                    icon: "camera.fill",
                    color: Theme.Colors.primary
                )

                EarningsTipCard(
                    title: "Competitive Pricing Matters",
                    description: "Check similar items in your area. Pricing 10-15% below average leads to faster bookings and higher earnings.",
                    icon: "tag.fill",
                    color: Theme.Colors.success
                )

                EarningsTipCard(
                    title: "Quick Responses = More Rentals",
                    description: "Responding within 1 hour increases booking chances by 60%. Enable push notifications to never miss a message.",
                    icon: "bolt.fill",
                    color: .orange
                )
            }
        }
        .padding(Theme.Spacing.lg)
        .background(Color.white)
        .cornerRadius(Theme.CornerRadius.card)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
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
        .background(Color.white)
        .cornerRadius(Theme.CornerRadius.card)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
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
            BrrowAsyncImage(url: transaction.itemImageUrl ?? "") { image in
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

struct EarningsTipCard: View {
    let title: String
    let description: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Icon in a circle
            ZStack {
                Circle()
                    .fill(color.opacity(0.1))
                    .frame(width: 40, height: 40)

                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(color)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Theme.Colors.text)

                Text(description)
                    .font(.system(size: 13))
                    .foregroundColor(Theme.Colors.text.opacity(0.7))
                    .multilineTextAlignment(.leading)
                    .lineSpacing(2)
            }
        }
        .padding(Theme.Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(color.opacity(0.03))
        .cornerRadius(Theme.CornerRadius.card)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.card)
                .stroke(color.opacity(0.15), lineWidth: 1)
        )
    }
}

// MARK: - Enums & Models

enum EarningsTimeframe: String, CaseIterable {
    case week = "Week"
    case month = "Month"
    case year = "Year"
}

// MARK: - Balance Transaction Row
struct BalanceTransactionRow: View {
    let transaction: BalanceTransaction

    var body: some View {
        HStack {
            Circle()
                .fill(transaction.isCredit ? Theme.Colors.success.opacity(0.2) : Theme.Colors.error.opacity(0.2))
                .frame(width: 8, height: 8)

            VStack(alignment: .leading, spacing: 2) {
                Text(transaction.description)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Theme.Colors.text)
                    .lineLimit(2)

                if let date = transaction.createdDate {
                    Text(date, style: .relative)
                        .font(.system(size: 12))
                        .foregroundColor(Theme.Colors.secondaryText)
                } else {
                    Text(transaction.createdAt)
                        .font(.system(size: 12))
                        .foregroundColor(Theme.Colors.secondaryText)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(String(format: "%@$%.2f", transaction.isCredit ? "+" : "-", abs(transaction.amount)))
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(transaction.isCredit ? Theme.Colors.success : Theme.Colors.error)

                Text(String(format: "Balance: $%.2f", transaction.balanceAfter))
                    .font(.system(size: 12))
                    .foregroundColor(Theme.Colors.secondaryText)
            }
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Stripe Payout Request View
struct StripePayoutRequestView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var viewModel: EarningsViewModel
    @State private var payoutAmount: String = ""
    @State private var showingConfirmation = false

    var amountDouble: Double {
        return Double(payoutAmount) ?? 0.0
    }

    var isValidAmount: Bool {
        let amount = amountDouble
        return amount >= viewModel.minimumPayout && amount <= viewModel.availableBalance
    }

    var body: some View {
        NavigationView {
            Form {
                Section("Available Balance") {
                    HStack {
                        Text("Available")
                        Spacer()
                        Text(String(format: "$%.2f", viewModel.availableBalance))
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(Theme.Colors.success)
                    }
                }

                Section("Payout Amount") {
                    HStack {
                        Text("$")
                            .foregroundColor(Theme.Colors.text)
                        TextField("0.00", text: $payoutAmount)
                            .keyboardType(.decimalPad)
                            .font(.system(size: 18, weight: .semibold))
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Minimum: $\(String(format: "%.0f", viewModel.minimumPayout))")
                            .font(.caption)
                            .foregroundColor(Theme.Colors.secondaryText)
                        Text("Maximum: $\(String(format: "%.2f", viewModel.availableBalance))")
                            .font(.caption)
                            .foregroundColor(Theme.Colors.secondaryText)
                    }
                }

                Section("Payout Details") {
                    HStack {
                        Text("Method")
                        Spacer()
                        Text("Stripe Transfer")
                            .foregroundColor(Theme.Colors.secondaryText)
                    }

                    HStack {
                        Text("Estimated Arrival")
                        Spacer()
                        Text("2-3 business days")
                            .foregroundColor(Theme.Colors.secondaryText)
                    }
                }

                Section {
                    Button("Request Payout") {
                        showingConfirmation = true
                    }
                    .disabled(!isValidAmount || viewModel.isRequestingPayout)
                    .frame(maxWidth: .infinity, alignment: .center)
                }

                Section {
                    Text("Funds will be transferred to your connected Stripe account. Processing typically takes 2-3 business days.")
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
            .alert("Confirm Payout", isPresented: $showingConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Confirm") {
                    Task {
                        do {
                            try await viewModel.requestStripePayout(amount: amountDouble)
                            dismiss()
                        } catch {
                            // Error already handled in viewModel
                        }
                    }
                }
            } message: {
                Text("Request a payout of $\(String(format: "%.2f", amountDouble))? This amount will be transferred to your Stripe account in 2-3 business days.")
            }
            .overlay {
                if viewModel.isRequestingPayout {
                    ProgressView()
                        .scaleEffect(1.5)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.3))
                }
            }
        }
    }
}

// MARK: - Payout Request View (Legacy)
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