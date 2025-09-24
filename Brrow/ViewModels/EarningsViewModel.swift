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
    @Published var totalEarnings: Double = 0.0
    @Published var availableBalance: Double = 0.0
    @Published var monthlyEarnings: Double = 0.0
    @Published var earningsChange: Double = 0.0
    @Published var itemsRented: Int = 0
    @Published var avgDailyEarnings: Double = 0.0
    @Published var pendingPayments: Int = 0
    
    @Published var chartData: [EarningsDataPoint] = []
    @Published var recentPayouts: [EarningsPayout] = []
    @Published var recentTransactions: [LegacyEarningsTransaction] = []
    
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private var cancellables = Set<AnyCancellable>()
    private let apiClient = APIClient.shared
    private let authManager = AuthManager.shared
    
    init() {
        setupDataBinding()
        // Only load earnings data for authenticated non-guest users
        if authManager.isAuthenticated && !authManager.isGuestUser {
            loadEarningsData()
        }
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
                
                let (earnings, transactions, payouts, chart) = try await (earningsTask, transactionsTask, payoutsTask, chartTask)
                
                await MainActor.run {
                    self.updateEarningsData(earnings)
                    self.recentTransactions = transactions
                    self.recentPayouts = payouts
                    self.chartData = chart
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
    
    private func updateEarningsData(_ overview: EarningsOverview) {
        totalEarnings = overview.totalEarnings
        availableBalance = overview.availableBalance
        monthlyEarnings = overview.monthlyEarningsValue
        earningsChange = overview.earningsChangeValue
        itemsRented = overview.itemsRentedValue
        avgDailyEarnings = overview.avgDailyEarningsValue
        pendingPayments = overview.pendingPaymentsValue
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


