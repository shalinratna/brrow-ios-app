//
//  TransactionsView.swift
//  Brrow
//
//  Created by Claude Code on 9/24/25.
//

import SwiftUI

struct TransactionsView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var viewModel = TransactionsViewModel()

    @State private var selectedFilter = TransactionsViewModel.TransactionFilter.all
    @State private var showingFilterSheet = false
    @State private var selectedTransaction: Transaction?
    @State private var showingWriteReview = false

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Filter Bar
                filterBar

                // Content
                if viewModel.isLoading {
                    loadingView
                } else if viewModel.filteredTransactions.isEmpty {
                    emptyStateView
                } else {
                    transactionsList
                }
            }
            .navigationTitle("Transactions")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Close") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Filter") {
                    showingFilterSheet = true
                }
            )
            .sheet(isPresented: $showingFilterSheet) {
                TransactionFilterSheet(
                    selectedFilter: $selectedFilter,
                    onFilterChange: { filter in
                        selectedFilter = filter
                        viewModel.selectedFilter = filter
                    }
                )
            }
            .sheet(isPresented: $showingWriteReview) {
                if let transaction = selectedTransaction {
                    ReviewSubmissionView(
                        reviewee: UserInfo(
                            id: String(transaction.lenderId == Int(authManager.currentUser?.id ?? "") ? transaction.borrowerId : transaction.lenderId),
                            username: "User",
                            profilePictureUrl: nil,
                            averageRating: nil,
                            bio: nil,
                            totalRatings: nil,
                            isVerified: nil,
                            createdAt: nil
                        ),
                        listing: ListingInfo(
                            id: String(transaction.listingId),
                            title: "Item",
                            imageUrl: nil,
                            price: transaction.totalCost
                        ),
                        transaction: TransactionInfo(
                            id: String(transaction.id),
                            type: "RENTAL",
                            amount: transaction.totalCost,
                            completedAt: ISO8601DateFormatter().string(from: transaction.endDate)
                        ),
                        reviewType: transaction.lenderId == Int(authManager.currentUser?.id ?? "") ? .buyer : .seller
                    )
                }
            }
        }
    }

    // MARK: - Filter Bar
    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(TransactionsViewModel.TransactionFilter.allCases, id: \.self) { filter in
                    FilterChip(
                        title: filter.displayName,
                        isSelected: selectedFilter == filter
                    ) {
                        selectedFilter = filter
                    }
                }
            }
            .padding(.horizontal, Theme.Spacing.md)
        }
        .padding(.vertical, Theme.Spacing.sm)
        .background(Theme.Colors.cardBackground)
    }

    // MARK: - Loading View
    private var loadingView: some View {
        VStack(spacing: Theme.Spacing.md) {
            ProgressView()
            Text("Loading transactions...")
                .font(Theme.Typography.callout)
                .foregroundColor(Theme.Colors.secondaryText)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.Colors.background)
    }

    // MARK: - Transactions List
    private var transactionsList: some View {
        ScrollView {
            LazyVStack(spacing: Theme.Spacing.md) {
                ForEach(viewModel.filteredTransactions) { transaction in
                    TransactionCard(
                        transaction: transaction,
                        currentUserId: authManager.currentUser?.id ?? "",
                        onWriteReview: {
                            selectedTransaction = transaction
                            showingWriteReview = true
                        }
                    )
                }
            }
            .padding(Theme.Spacing.md)
        }
        .background(Theme.Colors.background)
    }

    // MARK: - Empty State View
    private var emptyStateView: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(Theme.Colors.secondaryText)

            VStack(spacing: Theme.Spacing.sm) {
                Text("No Transactions Yet")
                    .font(Theme.Typography.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(Theme.Colors.text)

                Text("Your rental and purchase history will appear here")
                    .font(Theme.Typography.callout)
                    .foregroundColor(Theme.Colors.secondaryText)
                    .multilineTextAlignment(.center)
            }

            Button("Browse Items") {
                // Navigate to home/browse
                presentationMode.wrappedValue.dismiss()
            }
            .buttonStyle(TransactionPrimaryButtonStyle())
        }
        .padding(Theme.Spacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.Colors.background)
    }
}

// MARK: - Filter Chip
struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(Theme.Typography.callout)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? .white : Theme.Colors.text)
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.vertical, Theme.Spacing.sm)
                .background(
                    RoundedRectangle(cornerRadius: Theme.CornerRadius.lg)
                        .fill(isSelected ? Theme.Colors.primary : Theme.Colors.secondaryBackground)
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Transaction Filter Sheet
struct TransactionFilterSheet: View {
    @Environment(\.presentationMode) var presentationMode
    @Binding var selectedFilter: TransactionsViewModel.TransactionFilter
    let onFilterChange: (TransactionsViewModel.TransactionFilter) -> Void

    var body: some View {
        NavigationView {
            List(TransactionsViewModel.TransactionFilter.allCases, id: \.self) { filter in
                Button(action: {
                    selectedFilter = filter
                    onFilterChange(filter)
                    presentationMode.wrappedValue.dismiss()
                }) {
                    HStack {
                        Text(filter.displayName)
                            .foregroundColor(Theme.Colors.text)
                        Spacer()
                        if selectedFilter == filter {
                            Image(systemName: "checkmark")
                                .foregroundColor(Theme.Colors.primary)
                        }
                    }
                }
            }
            .navigationTitle("Filter Transactions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Transaction Primary Button Style
struct TransactionPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Theme.Typography.callout)
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.vertical, Theme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                    .fill(Theme.Colors.primary)
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Transaction Card
struct TransactionCard: View {
    let transaction: Transaction
    let currentUserId: String
    let onWriteReview: () -> Void

    private var isCompleted: Bool {
        transaction.status == .completed
    }

    private var hasReview: Bool {
        transaction.rating != nil && transaction.review != nil
    }

    private var statusColor: Color {
        switch transaction.status {
        case .active: return .green
        case .completed: return .blue
        case .cancelled: return .red
        case .pending: return .orange
        case .confirmed: return .green
        case .disputed: return .purple
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Transaction #\(transaction.id)")
                        .font(Theme.Typography.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(Theme.Colors.text)

                    Text(formatDate(transaction.createdAt))
                        .font(Theme.Typography.caption)
                        .foregroundColor(Theme.Colors.secondaryText)
                }

                Spacer()

                // Status badge
                Text(transaction.status.rawValue.capitalized)
                    .font(Theme.Typography.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, Theme.Spacing.sm)
                    .padding(.vertical, 4)
                    .background(statusColor)
                    .cornerRadius(8)
            }

            Divider()

            // Transaction details
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                HStack {
                    Text("Amount:")
                        .font(Theme.Typography.callout)
                        .foregroundColor(Theme.Colors.secondaryText)
                    Spacer()
                    Text("$\(String(format: "%.2f", transaction.totalCost))")
                        .font(Theme.Typography.callout)
                        .fontWeight(.semibold)
                        .foregroundColor(Theme.Colors.text)
                }

                HStack {
                    Text("Period:")
                        .font(Theme.Typography.callout)
                        .foregroundColor(Theme.Colors.secondaryText)
                    Spacer()
                    Text("\(formatDate(transaction.startDate)) - \(formatDate(transaction.endDate))")
                        .font(Theme.Typography.callout)
                        .foregroundColor(Theme.Colors.text)
                }
            }

            // Write Review Button (only for completed transactions without review)
            if isCompleted && !hasReview {
                Button(action: onWriteReview) {
                    HStack {
                        Image(systemName: "star.bubble")
                            .font(.system(size: 16))
                        Text("Write Review")
                            .font(.system(size: 15, weight: .medium))
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14))
                    }
                    .foregroundColor(Theme.Colors.primary)
                    .padding(Theme.Spacing.sm)
                    .background(Theme.Colors.primary.opacity(0.1))
                    .cornerRadius(8)
                }
            } else if hasReview {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Review submitted")
                        .font(Theme.Typography.callout)
                        .foregroundColor(Theme.Colors.secondaryText)
                }
            }
        }
        .padding(Theme.Spacing.md)
        .background(Theme.Colors.cardBackground)
        .cornerRadius(Theme.CornerRadius.card)
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

// MARK: - Preview
#Preview {
    TransactionsView()
        .environmentObject(AuthManager.shared)
}