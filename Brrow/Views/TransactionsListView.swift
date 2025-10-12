//
//  TransactionsListView.swift
//  Brrow
//
//  Transaction list with search and filtering
//

import SwiftUI

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
            default: return "all"
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Transactions")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Spacer()
            }
            .padding(.horizontal)
            .padding(.top)

            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)

                TextField("Search transactions...", text: $searchText)
                    .textFieldStyle(.plain)

                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(12)
            .background(Color(.systemGray6))
            .cornerRadius(10)
            .padding(.horizontal)
            .padding(.vertical, 8)

            // Filter pills
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(TransactionFilter.allCases, id: \.self) { filter in
                        FilterPill(
                            title: filter.rawValue,
                            isSelected: selectedFilter == filter,
                            action: {
                                selectedFilter = filter
                                viewModel.fetchPurchases(
                                    role: filter.roleValue,
                                    status: filter.apiValue,
                                    search: searchText.isEmpty ? nil : searchText
                                )
                            }
                        )
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical, 8)

            // Content
            if viewModel.isLoading && viewModel.purchases.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.purchases.isEmpty {
                EmptyTransactionsView()
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(filteredPurchases) { purchase in
                            NavigationLink(destination: TransactionDetailView(purchaseId: purchase.id)) {
                                TransactionCard(purchase: purchase)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding()
                }
            }
        }
        .onAppear {
            viewModel.fetchPurchases(role: "all", status: nil, search: nil)
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
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.blue : Color(.systemGray6))
                .cornerRadius(20)
        }
    }
}

struct TransactionCard: View {
    let purchase: PurchaseSummary

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                // Status badge
                Text(purchase.isActive ? "ACTIVE" : "PAST")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(purchase.isActive ? Color.green : Color.gray)
                    .cornerRadius(6)

                Spacer()

                // Transaction ID
                if let displayId = purchase.transactionDisplayId {
                    Text(displayId)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.gray)
                }
            }

            HStack(spacing: 12) {
                // Listing image
                if let imageUrl = purchase.listing?.imageUrl {
                    AsyncImage(url: URL(string: imageUrl)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Color.gray.opacity(0.2)
                    }
                    .frame(width: 60, height: 60)
                    .cornerRadius(8)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(purchase.listing?.title ?? "Unknown Item")
                        .font(.headline)
                        .lineLimit(2)

                    HStack {
                        Text("$\(String(format: "%.2f", purchase.amount))")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)

                        Text("•")
                            .foregroundColor(.gray)

                        Text(purchase.paymentStatus.replacingOccurrences(of: "_", with: " ").capitalized)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }

                    Text(formatDate(purchase.createdAt))
                        .font(.caption)
                        .foregroundColor(.gray)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }

    func formatDate(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        if let date = formatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .medium
            displayFormatter.timeStyle = .short
            return displayFormatter.string(from: date)
        }
        return dateString
    }
}

struct EmptyTransactionsView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "cart.badge.questionmark")
                .font(.system(size: 60))
                .foregroundColor(.gray.opacity(0.5))

            Text("No Transactions Yet")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Your purchases and sales will appear here")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .padding()
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
