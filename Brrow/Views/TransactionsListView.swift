//
//  TransactionsListView.swift
//  Brrow
//
//  Transaction list with search and filtering
//

import SwiftUI

// Helper to access auth token
struct TokenStorage {
    static let shared = TokenStorage()
    func getToken() -> String? {
        return AuthManager.shared.authToken
    }
}

// Helper to access base URL
struct AppConfig {
    static let baseURL = "https://brrow-backend-nodejs-production.up.railway.app"
}

struct TransactionsListView: View {
    @StateObject private var viewModel = TransactionsViewModel()
    @State private var searchText = ""
    @State private var selectedFilter: TransactionFilter = .all

    enum TransactionFilter: String, CaseIterable {
        case all = "All"
        case active = "Active"
        case past = "Past"
        case buying = "Buying"
        case selling = "Selling"

        var apiValue: String? {
            switch self {
            case .all: return nil
            case .active: return "HELD"
            case .past: return "CAPTURED"
            case .buying, .selling: return nil
            }
        }

        var roleValue: String? {
            switch self {
            case .buying: return "buyer"
            case .selling: return "seller"
            default: return nil  // Don't filter by role, backend will return user's transactions
            }
        }
    }

    var body: some View {
        ZStack {
            Theme.Colors.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header with count
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Transactions")
                            .font(Theme.Typography.largeTitle)
                            .foregroundColor(Theme.Colors.text)

                        Text("\(filteredPurchases.count) items")
                            .font(Theme.Typography.subheadline)
                            .foregroundColor(Theme.Colors.secondaryText)
                    }

                    Spacer()
                }
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.top, Theme.Spacing.lg)
                .padding(.bottom, Theme.Spacing.sm)

                // Search bar
                HStack(spacing: Theme.Spacing.sm) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(Theme.Colors.secondaryText)
                        .font(.system(size: 16))

                    TextField("Search transactions...", text: $searchText)
                        .textFieldStyle(.plain)
                        .font(Theme.Typography.body)

                    if !searchText.isEmpty {
                        Button(action: { searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(Theme.Colors.secondaryText)
                        }
                    }
                }
                .padding(Theme.Spacing.gutter)
                .background(Theme.Colors.inputBackground)
                .cornerRadius(Theme.CornerRadius.card)
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.vertical, Theme.Spacing.sm)

                // Filter pills
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Theme.Spacing.sm) {
                        ForEach(TransactionFilter.allCases, id: \.self) { filter in
                            FilterPill(
                                title: filter.rawValue,
                                isSelected: selectedFilter == filter,
                                action: {
                                    withAnimation(.spring(response: 0.3)) {
                                        selectedFilter = filter
                                    }
                                    viewModel.fetchPurchases(
                                        role: filter.roleValue,
                                        status: filter.apiValue,
                                        search: searchText.isEmpty ? nil : searchText
                                    )
                                }
                            )
                        }
                    }
                    .padding(.horizontal, Theme.Spacing.md)
                }
                .padding(.vertical, Theme.Spacing.sm)

                // Content
                if viewModel.isLoading && viewModel.purchases.isEmpty {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: Theme.Colors.primary))
                        .scaleEffect(1.5)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.purchases.isEmpty {
                    EmptyTransactionsView()
                } else {
                    ScrollView {
                        LazyVStack(spacing: Theme.Spacing.gutter) {
                            ForEach(filteredPurchases) { purchase in
                                NavigationLink(destination: TransactionDetailView(purchaseId: purchase.id)) {
                                    TransactionCard(purchase: purchase)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(Theme.Spacing.md)
                    }
                }
            }
        }
        .onAppear {
            viewModel.fetchPurchases(role: nil, status: nil, search: nil)
        }
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    var filteredPurchases: [PurchaseSummary] {
        let filtered = viewModel.purchases.filter { purchase in
            if searchText.isEmpty { return true }
            return purchase.listing?.title.localizedCaseInsensitiveContains(searchText) ?? false
        }

        // Client-side filter for active/past if needed
        switch selectedFilter {
        case .active:
            return filtered.filter { $0.isActive }
        case .past:
            return filtered.filter { $0.isPast }
        default:
            return filtered
        }
    }
}

struct FilterPill: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(Theme.Typography.label)
                .foregroundColor(isSelected ? .white : Theme.Colors.text)
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.vertical, Theme.Spacing.sm)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(isSelected ? Theme.Colors.primary : Theme.Colors.secondaryBackground)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(isSelected ? Color.clear : Theme.Colors.border, lineWidth: 1)
                )
                .scaleEffect(isSelected ? 1.0 : 0.95)
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

struct TransactionCard: View {
    let purchase: PurchaseSummary

    var body: some View {
        HStack(spacing: Theme.Spacing.gutter) {
            // Listing image with status overlay
            ZStack(alignment: .topLeading) {
                if let imageUrl = purchase.listing?.imageUrl {
                    AsyncImage(url: URL(string: imageUrl)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Rectangle()
                            .fill(Theme.Colors.secondaryBackground)
                            .overlay(
                                Image(systemName: "photo")
                                    .foregroundColor(Theme.Colors.secondaryText)
                            )
                    }
                    .frame(width: 80, height: 80)
                    .cornerRadius(Theme.CornerRadius.card)
                } else {
                    Rectangle()
                        .fill(Theme.Colors.secondaryBackground)
                        .overlay(
                            Image(systemName: "photo")
                                .foregroundColor(Theme.Colors.secondaryText)
                        )
                        .frame(width: 80, height: 80)
                        .cornerRadius(Theme.CornerRadius.card)
                }

                // Status badge
                statusBadge
                    .padding(6)
            }

            // Content
            VStack(alignment: .leading, spacing: 6) {
                // Title
                Text(purchase.listing?.title ?? "Unknown Item")
                    .font(Theme.Typography.headline)
                    .foregroundColor(Theme.Colors.text)
                    .lineLimit(2)

                // Amount
                Text("$\(String(format: "%.2f", purchase.amount))")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(Theme.Colors.primary)

                // Status and date
                HStack(spacing: 6) {
                    Text(formatPaymentStatus(purchase.paymentStatus))
                        .font(Theme.Typography.caption)
                        .foregroundColor(Theme.Colors.secondaryText)

                    Text("•")
                        .foregroundColor(Theme.Colors.tertiaryText)

                    Text(formatDate(purchase.createdAt))
                        .font(Theme.Typography.caption)
                        .foregroundColor(Theme.Colors.secondaryText)
                }
            }

            Spacer()

            // Chevron
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Theme.Colors.tertiaryText)
        }
        .padding(Theme.Spacing.gutter)
        .background(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.card)
                .fill(Theme.Colors.cardBackground)
        )
        .shadow(color: Theme.Shadows.card, radius: Theme.Shadows.cardRadius, y: 2)
    }

    // Status badge view
    private var statusBadge: some View {
        Group {
            if purchase.isActive {
                HStack(spacing: 4) {
                    Circle()
                        .fill(Theme.Colors.success)
                        .frame(width: 6, height: 6)
                    Text("Active")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(Theme.Colors.success.opacity(0.9))
                )
            } else {
                Text("Past")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Theme.Colors.secondaryText.opacity(0.8))
                    )
            }
        }
    }

    // Format payment status for display
    private func formatPaymentStatus(_ status: String) -> String {
        switch status.lowercased() {
        case "held":
            return "Payment Held"
        case "captured":
            return "Completed"
        case "pending":
            return "Pending"
        case "failed":
            return "Failed"
        case "refunded":
            return "Refunded"
        case "cancelled":
            // Check if it's an expired transaction
            if let reason = purchase.cancellationReason, reason.lowercased().contains("expired") {
                return "Expired"
            }
            return "Cancelled"
        default:
            return status.replacingOccurrences(of: "_", with: " ").capitalized
        }
    }

    func formatDate(_ dateString: String) -> String {
        return dateString.toUserFriendlyDate()
    }
}

struct EmptyTransactionsView: View {
    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            // Icon with gradient background
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Theme.Colors.primary.opacity(0.2), Theme.Colors.secondary.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)

                Image(systemName: "arrow.left.arrow.right.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(Theme.Colors.primary)
            }

            VStack(spacing: Theme.Spacing.sm) {
                Text("No Transactions Yet")
                    .font(Theme.Typography.largeTitle)
                    .foregroundColor(Theme.Colors.text)

                Text("Your purchases and sales will appear here")
                    .font(Theme.Typography.body)
                    .foregroundColor(Theme.Colors.secondaryText)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(Theme.Spacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - ViewModel
@MainActor
class TransactionsViewModel: ObservableObject {
    @Published var purchases: [PurchaseSummary] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    func fetchPurchases(role: String?, status: String?, search: String?) {
        isLoading = true
        errorMessage = nil

        Task {
            do {
                var urlString = "\(AppConfig.baseURL)/api/purchases/my-purchases"
                var queryParams: [String] = []

                if let role = role {
                    queryParams.append("role=\(role)")
                }
                if let status = status {
                    queryParams.append("status=\(status)")
                }
                if let search = search {
                    queryParams.append("search=\(search)")
                }

                if !queryParams.isEmpty {
                    urlString += "?" + queryParams.joined(separator: "&")
                }

                guard let url = URL(string: urlString) else {
                    throw URLError(.badURL)
                }

                var request = URLRequest(url: url)
                request.httpMethod = "GET"

                if let token = TokenStorage.shared.getToken() {
                    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                }

                let (data, _) = try await URLSession.shared.data(for: request)
                let response = try JSONDecoder().decode(PurchasesListResponse.self, from: data)

                self.purchases = response.purchases
                self.isLoading = false
            } catch {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
}

#Preview {
    NavigationView {
        TransactionsListView()
    }
}
