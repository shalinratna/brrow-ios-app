import Foundation
import Combine
import SwiftUI

@MainActor
class TransactionsViewModel: ObservableObject {
    @Published var transactions: [Transaction] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var selectedFilter: TransactionFilter = .all
    
    private var cancellables = Set<AnyCancellable>()
    private let apiClient = APIClient.shared
    private let authManager = AuthManager.shared
    
    enum TransactionFilter: String, CaseIterable {
        case all = "All"
        case active = "Active"
        case completed = "Completed"
        case upcoming = "Upcoming"
    }
    
    init() {
        fetchTransactions()
        setupNotificationObserver()
    }
    
    private func setupNotificationObserver() {
        NotificationCenter.default.publisher(for: .transactionStatusChanged)
            .sink { [weak self] notification in
                if let transactionId = notification.object as? Int {
                    self?.refreshTransactionStatus(transactionId: transactionId)
                }
            }
            .store(in: &cancellables)
    }
    
    func fetchTransactions() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let fetchedTransactions = try await apiClient.fetchTransactions()
                
                await MainActor.run {
                    self.transactions = fetchedTransactions.sorted { $0.createdAt > $1.createdAt }
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
    
    func updateTransactionStatus(_ transaction: Transaction, status: TransactionStatus) {
        Task {
            do {
                let updatedTransaction = try await apiClient.updateTransactionStatus(
                    transactionId: transaction.id,
                    status: status
                )
                
                await MainActor.run {
                    if let index = self.transactions.firstIndex(where: { $0.id == transaction.id }) {
                        self.transactions[index] = updatedTransaction
                    }
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    func completeTransaction(_ transaction: Transaction) {
        updateTransactionStatus(transaction, status: .completed)
    }
    
    func cancelTransaction(_ transaction: Transaction) {
        updateTransactionStatus(transaction, status: .cancelled)
    }
    
    func extendTransaction(_ transaction: Transaction, additionalDays: Int) {
        Task {
            do {
                let updatedTransaction = try await apiClient.extendTransaction(
                    transactionId: transaction.id,
                    additionalDays: additionalDays
                )
                
                await MainActor.run {
                    if let index = self.transactions.firstIndex(where: { $0.id == transaction.id }) {
                        self.transactions[index] = updatedTransaction
                    }
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    func reportIssue(for transaction: Transaction, issue: String, details: String) {
        Task {
            do {
                try await apiClient.reportTransactionIssue(
                    transactionId: transaction.id,
                    issue: issue,
                    details: details
                )
                
                await MainActor.run {
                    // Show success message
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    private func refreshTransactionStatus(transactionId: Int) {
        Task {
            do {
                let updatedTransaction = try await apiClient.fetchTransactionDetails(id: transactionId)
                await MainActor.run {
                    if let index = self.transactions.firstIndex(where: { $0.id == transactionId }) {
                        self.transactions[index] = updatedTransaction
                    }
                }
            } catch {
                print("Failed to refresh transaction status: \(error)")
            }
        }
    }
    
    var filteredTransactions: [Transaction] {
        switch selectedFilter {
        case .all:
            return transactions
        case .active:
            return transactions.filter { $0.status == .active }
        case .completed:
            return transactions.filter { $0.status == .completed }
        case .upcoming:
            return transactions.filter { $0.startDate > Date() }
        }
    }
    
    var activeTransactionsCount: Int {
        transactions.filter { $0.status == .active }.count
    }
    
    var upcomingTransactionsCount: Int {
        transactions.filter { $0.startDate > Date() }.count
    }
}
