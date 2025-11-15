//
//  EarningsViewModel.swift
//  Brrow
//
//  Complete Earnings Management & Analytics
//

import Foundation
import Combine

@MainActor
class EarningsViewModel: ObservableObject {
    // NEW BALANCE SYSTEM FIELDS
    @Published var availableBalance: Double = 0.0
    @Published var pendingBalance: Double = 0.0
    @Published var totalEarned: Double = 0.0
    @Published var totalWithdrawn: Double = 0.0
    @Published var hasStripeConnected: Bool = false
    @Published var canRequestPayout: Bool = false

    // LEGACY FIELDS (for backward compatibility)
    @Published var totalEarnings: Double = 0.0
    @Published var monthlyEarnings: Double = 0.0
    @Published var earningsChange: Double = 0.0
    @Published var itemsRented: Int = 0
    @Published var avgDailyEarnings: Double = 0.0
    @Published var pendingPayments: Int = 0
    @Published var totalSales: Int = 0
    @Published var platformFees: Double = 0.0

    // PAYOUT INFO
    @Published var minimumPayout: Double = 10.0
    @Published var payoutMethod: String = "not_connected"
    @Published var stripeAccountId: String?
    @Published var nextPayoutDate: String?

    // PAYOUT TIER INFO
    @Published var payoutTier: String = "New User"
    @Published var payoutTierCode: String = "UNVERIFIED"
    @Published var holdDays: Int = 7
    @Published var emailVerified: Bool = false
    @Published var idVerified: Bool = false
    @Published var tierCompletedSales: Int = 0

    // DATA LISTS
    @Published var chartData: [EarningsDataPoint] = []
    @Published var recentPayouts: [EarningsPayout] = []
    @Published var recentTransactions: [LegacyEarningsTransaction] = []
    @Published var balanceTransactions: [BalanceTransaction] = []

    // UI STATE
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isRequestingPayout = false
    @Published var payoutSuccessMessage: String?
    
    private var cancellables = Set<AnyCancellable>()
    private let apiClient = APIClient.shared
    private let authManager = AuthManager.shared
    
    init() {
        // INDUSTRY-STANDARD: Don't load data in init - wait for view to appear
        // This implements lazy loading (Step 2 of the 4-step architecture)
        setupDataBinding()
    }
    
    func loadEarningsData() {
        isLoading = true
        errorMessage = nil

        Task {
            do {
                async let earningsTask = fetchEarningsOverview()
                async let transactionsTask = fetchRecentTransactions()
                async let payoutsTask = fetchRecentPayouts()
                async let chartTask = fetchChartData()
                async let balanceTransactionsTask = fetchBalanceTransactions()

                let (earnings, transactions, payouts, chart, balanceTxs) = try await (
                    earningsTask,
                    transactionsTask,
                    payoutsTask,
                    chartTask,
                    balanceTransactionsTask
                )

                // Also check Stripe connection status
                await checkStripeAccountStatus()

                await MainActor.run {
                    self.updateEarningsData(earnings)
                    self.recentTransactions = transactions
                    self.recentPayouts = payouts
                    self.chartData = chart
                    self.balanceTransactions = balanceTxs
                    self.isLoading = false
                }

            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }
    
    func requestPayout(amount: Double, method: PayoutMethod) async throws {
        let payoutRequest = PayoutRequest(
            amount: amount,
            method: method,
            userId: authManager.currentUser?.apiId ?? ""
        )

        try await apiClient.requestPayout(payoutRequest)

        // Refresh data after successful payout request
        loadEarningsData()
    }

    // NEW: Request payout via Stripe
    func requestStripePayout(amount: Double) async throws {
        isRequestingPayout = true
        errorMessage = nil
        payoutSuccessMessage = nil

        do {
            try await apiClient.requestStripePayout(amount: amount)

            await MainActor.run {
                self.payoutSuccessMessage = "Payout requested successfully! Funds will arrive in 2-3 business days."
                self.isRequestingPayout = false
            }

            // Refresh data after successful payout request
            loadEarningsData()

        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isRequestingPayout = false
            }
            throw error
        }
    }

    // NEW: Get Stripe Connect onboarding URL
    func getStripeConnectURL() async throws -> String {
        return try await apiClient.getStripeConnectOnboardingURL()
    }

    // NEW: Check Stripe account status
    func checkStripeAccountStatus() async {
        do {
            let isConnected = try await apiClient.checkStripeAccountStatus()
            await MainActor.run {
                self.hasStripeConnected = isConnected
            }
        } catch {
            print("Error checking Stripe account status: \(error)")
        }
    }
    
    func refreshData() async {
        await loadEarningsData()
    }
    
    // MARK: - Private Methods
    
    private func setupDataBinding() {
        // Listen for new transactions
        NotificationCenter.default.publisher(for: .newLegacyEarningsTransaction)
            .sink { [weak self] notification in
                if let transaction = notification.object as? LegacyEarningsTransaction {
                    self?.addNewTransaction(transaction)
                }
            }
            .store(in: &cancellables)
    }
    
    private func fetchEarningsOverview() async throws -> EarningsOverview {
        return try await apiClient.fetchEarningsOverview()
    }
    
    private func fetchRecentTransactions() async throws -> [LegacyEarningsTransaction] {
        return try await apiClient.fetchRecentLegacyEarningsTransactions()
    }
    
    private func fetchRecentPayouts() async throws -> [EarningsPayout] {
        return try await apiClient.fetchRecentPayouts()
    }
    
    private func fetchChartData() async throws -> [EarningsDataPoint] {
        return try await apiClient.fetchEarningsChartData()
    }

    private func fetchBalanceTransactions() async throws -> [BalanceTransaction] {
        return try await apiClient.fetchBalanceTransactions()
    }
    
    private func updateEarningsData(_ overview: EarningsOverview) {
        // NEW BALANCE SYSTEM FIELDS
        availableBalance = overview.availableBalance
        pendingBalance = overview.pendingBalanceValue
        totalEarned = overview.totalEarnedValue
        totalWithdrawn = overview.totalWithdrawnValue
        hasStripeConnected = overview.hasStripeConnectedValue
        canRequestPayout = overview.canRequestPayoutValue

        // LEGACY FIELDS
        totalEarnings = overview.totalEarnings
        monthlyEarnings = overview.monthlyEarningsValue
        earningsChange = overview.earningsChangeValue
        itemsRented = overview.itemsRentedValue
        avgDailyEarnings = overview.avgDailyEarningsValue
        pendingPayments = overview.pendingPaymentsValue
        totalSales = overview.totalSalesValue
        platformFees = overview.platformFeesValue
    }
    
    private func addNewTransaction(_ transaction: LegacyEarningsTransaction) {
        recentTransactions.insert(transaction, at: 0)
        
        // Update totals
        totalEarnings += transaction.amount
        availableBalance += transaction.amount
        
        // Update chart data
        if let today = chartData.last {
            chartData[chartData.count - 1] = EarningsDataPoint(
                date: today.date,
                amount: today.amount + transaction.amount
            )
        }
    }
    
}


// MARK: - Notification Extensions

extension Notification.Name {
    static let newLegacyEarningsTransaction = Notification.Name("newLegacyEarningsTransaction")
}


