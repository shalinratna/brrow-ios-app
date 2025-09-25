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

    @State private var selectedFilter = TransactionFilter.all
    @State private var showingFilterSheet = false

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Filter Bar
                filterBar

                // Content - Empty state for now
                emptyStateView
            }
            .navigationTitle("Transactions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Filter") {
                        showingFilterSheet = true
                    }
                }
            }
        }
        .sheet(isPresented: $showingFilterSheet) {
            TransactionFilterSheet(
                selectedFilter: $selectedFilter,
                onFilterChange: { filter in
                    selectedFilter = filter
                }
            )
        }
    }

    // MARK: - Filter Bar
    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(TransactionFilter.allCases, id: \.self) { filter in
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

// MARK: - Transaction Filter
enum TransactionFilter: String, CaseIterable {
    case all = "all"
    case rentals = "rentals"
    case purchases = "purchases"
    case earnings = "earnings"
    case pending = "pending"

    var displayName: String {
        switch self {
        case .all: return "All"
        case .rentals: return "Rentals"
        case .purchases: return "Purchases"
        case .earnings: return "Earnings"
        case .pending: return "Pending"
        }
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
    @Binding var selectedFilter: TransactionFilter
    let onFilterChange: (TransactionFilter) -> Void

    var body: some View {
        NavigationView {
            List(TransactionFilter.allCases, id: \.self) { filter in
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

// MARK: - Preview
#Preview {
    TransactionsView()
        .environmentObject(AuthManager.shared)
}