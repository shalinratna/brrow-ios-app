//
//  AdminViews.swift
//  BrrowAdmin
//
//  All admin panel views in one file for rapid development
//

import SwiftUI

// MARK: - Login View
struct AdminLoginView: View {
    @StateObject private var authManager = AdminAuthManager.shared
    @State private var email = ""
    @State private var password = ""

    var body: some View {
        VStack(spacing: 30) {
            Image(systemName: "shield.fill")
                .font(.system(size: 80))
                .foregroundColor(.blue)

            Text("Brrow Admin")
                .font(.system(size: 36, weight: .bold))

            Text("Database & User Management")
                .font(.headline)
                .foregroundColor(.secondary)

            VStack(spacing: 15) {
                TextField("Email", text: $email)
                    .textFieldStyle(.roundedBorder)
                    .textContentType(.emailAddress)

                SecureField("Password", text: $password)
                    .textFieldStyle(.roundedBorder)
                    .textContentType(.password)

                if let error = authManager.errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                }

                Button(action: {
                    Task {
                        await authManager.login(email: email, password: password)
                    }
                }) {
                    HStack {
                        if authManager.isLoading {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                        Text(authManager.isLoading ? "Logging in..." : "Login")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .disabled(authManager.isLoading || email.isEmpty || password.isEmpty)
            }
            .padding(.horizontal, 40)

            Spacer()
        }
        .frame(width: 500, height: 600)
        .padding()
    }
}

// MARK: - Main Content View
struct AdminContentView: View {
    @State private var selectedTab: AdminTab = .dashboard

    enum AdminTab {
        case dashboard, users, listings, transactions, reports, database
    }

    var body: some View {
        NavigationSplitView {
            List(selection: $selectedTab) {
                Label("Dashboard", systemImage: "chart.bar.fill")
                    .tag(AdminTab.dashboard)

                Label("Users", systemImage: "person.2.fill")
                    .tag(AdminTab.users)

                Label("Listings", systemImage: "list.bullet.rectangle")
                    .tag(AdminTab.listings)

                Label("Transactions", systemImage: "dollarsign.circle.fill")
                    .tag(AdminTab.transactions)

                Label("Reports", systemImage: "flag.fill")
                    .tag(AdminTab.reports)

                Label("Database", systemImage: "cylinder.fill")
                    .tag(AdminTab.database)
            }
            .navigationTitle("Brrow Admin")
            .frame(minWidth: 220)
        } detail: {
            switch selectedTab {
            case .dashboard:
                DashboardView()
            case .users:
                UsersView()
            case .listings:
                ListingsView()
            case .transactions:
                TransactionsView()
            case .reports:
                ReportsView()
            case .database:
                DatabaseView()
            }
        }
        .frame(minWidth: 1200, minHeight: 800)
    }
}

// MARK: - Dashboard View
struct DashboardView: View {
    @State private var stats: DashboardStats?
    @State private var isLoading = true

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                HStack {
                    Text("Dashboard")
                        .font(.largeTitle)
                        .bold()

                    Spacer()

                    Button(action: { loadStats() }) {
                        Image(systemName: "arrow.clockwise")
                    }

                    Button("Logout") {
                        AdminAuthManager.shared.logout()
                    }
                }
                .padding()

                if isLoading {
                    ProgressView()
                } else if let stats = stats {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                        StatCard(title: "Total Users", value: "\(stats.totalUsers)", icon: "person.fill", color: .blue)
                        StatCard(title: "Active Users", value: "\(stats.activeUsers)", icon: "person.fill.checkmark", color: .green)
                        StatCard(title: "Total Listings", value: "\(stats.totalListings)", icon: "list.bullet", color: .orange)
                        StatCard(title: "Active Listings", value: "\(stats.activeListings)", icon: "checkmark.circle.fill", color: .green)
                        StatCard(title: "Pending Review", value: "\(stats.pendingListings)", icon: "clock.fill", color: .yellow)
                        StatCard(title: "Revenue Today", value: "$\(String(format: "%.2f", stats.revenueToday))", icon: "dollarsign.circle.fill", color: .purple)
                        StatCard(title: "Total Revenue", value: "$\(String(format: "%.2f", stats.totalRevenue))", icon: "banknote.fill", color: .green)
                        StatCard(title: "New Users Today", value: "\(stats.newUsersToday)", icon: "person.badge.plus", color: .cyan)
                        StatCard(title: "Flagged Listings", value: "\(stats.flaggedListings)", icon: "flag.fill", color: .red)
                    }
                    .padding()
                }
            }
        }
        .onAppear { loadStats() }
    }

    func loadStats() {
        isLoading = true
        Task {
            do {
                stats = try await AdminAPIClient.shared.getDashboardStats()
            } catch {
                print("Error loading stats: \(error)")
            }
            isLoading = false
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Spacer()
            }

            Text(value)
                .font(.system(size: 32, weight: .bold))

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, minHeight: 120, alignment: .leading)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Users View
struct UsersView: View {
    @State private var users: [AdminUserDetail] = []
    @State private var isLoading = true
    @State private var searchText = ""
    @State private var selectedUser: AdminUserDetail?

    var body: some View {
        VStack {
            HStack {
                Text("User Management")
                    .font(.largeTitle)
                    .bold()

                Spacer()

                TextField("Search users...", text: $searchText)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 300)

                Button(action: { loadUsers() }) {
                    Image(systemName: "arrow.clockwise")
                }
            }
            .padding()

            if isLoading {
                ProgressView()
            } else {
                Table(users) {
                    TableColumn("Email", value: \.email)
                    TableColumn("Name", value: \.fullName)
                    TableColumn("Status") { user in
                        HStack {
                            if user.isVerified {
                                Image(systemName: "checkmark.seal.fill")
                                    .foregroundColor(.green)
                            }
                            if user.isBanned {
                                Image(systemName: "hand.raised.fill")
                                    .foregroundColor(.red)
                            }
                            if user.isSuspended {
                                Image(systemName: "pause.circle.fill")
                                    .foregroundColor(.orange)
                            }
                        }
                    }
                    TableColumn("Listings") { user in
                        Text("\(user.listingsCount ?? 0)")
                    }
                    TableColumn("Actions") { user in
                        HStack {
                            if user.isBanned {
                                Button("Unban") {
                                    unbanUser(user.id)
                                }
                            } else {
                                Button("Ban") {
                                    banUser(user.id)
                                }
                            }

                            if user.isSuspended {
                                Button("Unsuspend") {
                                    unsuspendUser(user.id)
                                }
                            } else {
                                Button("Suspend") {
                                    suspendUser(user.id)
                                }
                            }
                        }
                    }
                }
            }
        }
        .onAppear { loadUsers() }
    }

    func loadUsers() {
        isLoading = true
        Task {
            do {
                let response = try await AdminAPIClient.shared.getUsers(search: searchText.isEmpty ? nil : searchText)
                users = response.data
            } catch {
                print("Error loading users: \(error)")
            }
            isLoading = false
        }
    }

    func banUser(_ userId: String) {
        Task {
            do {
                _ = try await AdminAPIClient.shared.banUser(userId, reason: "Banned by admin")
                loadUsers()
            } catch {
                print("Error banning user: \(error)")
            }
        }
    }

    func unbanUser(_ userId: String) {
        Task {
            do {
                _ = try await AdminAPIClient.shared.unbanUser(userId)
                loadUsers()
            } catch {
                print("Error unbanning user: \(error)")
            }
        }
    }

    func suspendUser(_ userId: String) {
        Task {
            do {
                _ = try await AdminAPIClient.shared.suspendUser(userId, reason: "Suspended by admin", expiresAt: nil)
                loadUsers()
            } catch {
                print("Error suspending user: \(error)")
            }
        }
    }

    func unsuspendUser(_ userId: String) {
        Task {
            do {
                _ = try await AdminAPIClient.shared.unsuspendUser(userId)
                loadUsers()
            } catch {
                print("Error unsuspending user: \(error)")
            }
        }
    }
}

// MARK: - Listings View
struct ListingsView: View {
    @State private var listings: [AdminListingDetail] = []
    @State private var isLoading = true
    @State private var filterStatus: String = "all"

    var body: some View {
        VStack {
            HStack {
                Text("Listing Moderation")
                    .font(.largeTitle)
                    .bold()

                Spacer()

                Picker("Status", selection: $filterStatus) {
                    Text("All").tag("all")
                    Text("Pending").tag("UPCOMING")
                    Text("Active").tag("AVAILABLE")
                    Text("Flagged").tag("FLAGGED")
                }
                .pickerStyle(.segmented)
                .frame(width: 400)

                Button(action: { loadListings() }) {
                    Image(systemName: "arrow.clockwise")
                }
            }
            .padding()

            if isLoading {
                ProgressView()
            } else {
                Table(listings) {
                    TableColumn("Title", value: \.title)
                    TableColumn("Price") { listing in
                        Text("$\(String(format: "%.2f", listing.price))")
                    }
                    TableColumn("Status", value: \.status.rawValue)
                    TableColumn("Seller") { listing in
                        Text(listing.userEmail ?? "Unknown")
                    }
                    TableColumn("Flagged") { listing in
                        if listing.isFlagged {
                            Image(systemName: "flag.fill")
                                .foregroundColor(.red)
                        }
                    }
                    TableColumn("Actions") { listing in
                        HStack {
                            if listing.status == .upcoming {
                                Button("Approve") {
                                    approveListing(listing.id)
                                }
                                .foregroundColor(.green)

                                Button("Reject") {
                                    rejectListing(listing.id)
                                }
                                .foregroundColor(.red)
                            }

                            if listing.isFlagged {
                                Button("Unflag") {
                                    unflagListing(listing.id)
                                }
                            } else {
                                Button("Flag") {
                                    flagListing(listing.id)
                                }
                            }
                        }
                    }
                }
            }
        }
        .onAppear { loadListings() }
        .onChange(of: filterStatus) { _ in loadListings() }
    }

    func loadListings() {
        isLoading = true
        Task {
            do {
                let status = filterStatus == "all" ? nil : filterStatus
                let response = try await AdminAPIClient.shared.getListings(status: status)
                listings = response.data
            } catch {
                print("Error loading listings: \(error)")
            }
            isLoading = false
        }
    }

    func approveListing(_ listingId: String) {
        Task {
            do {
                _ = try await AdminAPIClient.shared.approveListing(listingId)
                loadListings()
            } catch {
                print("Error approving listing: \(error)")
            }
        }
    }

    func rejectListing(_ listingId: String) {
        Task {
            do {
                _ = try await AdminAPIClient.shared.rejectListing(listingId, reason: "Rejected by admin")
                loadListings()
            } catch {
                print("Error rejecting listing: \(error)")
            }
        }
    }

    func flagListing(_ listingId: String) {
        Task {
            do {
                _ = try await AdminAPIClient.shared.flagListing(listingId, reason: "Flagged for review")
                loadListings()
            } catch {
                print("Error flagging listing: \(error)")
            }
        }
    }

    func unflagListing(_ listingId: String) {
        Task {
            do {
                _ = try await AdminAPIClient.shared.unflagListing(listingId)
                loadListings()
            } catch {
                print("Error unflagging listing: \(error)")
            }
        }
    }
}

// MARK: - Transactions View
struct TransactionsView: View {
    @State private var transactions: [AdminTransactionDetail] = []
    @State private var isLoading = true

    var body: some View {
        VStack {
            HStack {
                Text("Transactions")
                    .font(.largeTitle)
                    .bold()

                Spacer()

                Button(action: { loadTransactions() }) {
                    Image(systemName: "arrow.clockwise")
                }
            }
            .padding()

            if isLoading {
                ProgressView()
            } else {
                Table(transactions) {
                    TableColumn("ID") { tx in
                        Text(String(tx.id.prefix(8)))
                            .font(.system(.body, design: .monospaced))
                    }
                    TableColumn("Listing", value: \.listingTitle ?? "Unknown")
                    TableColumn("Amount") { tx in
                        Text("$\(String(format: "%.2f", tx.amount))")
                    }
                    TableColumn("Status", value: \.status.rawValue)
                    TableColumn("Buyer") { tx in
                        Text(tx.buyerEmail ?? "Unknown")
                    }
                    TableColumn("Seller") { tx in
                        Text(tx.sellerEmail ?? "Unknown")
                    }
                    TableColumn("Actions") { tx in
                        if tx.status == .completed && tx.refundedAmount == nil {
                            Button("Refund") {
                                refundTransaction(tx.id, amount: tx.amount)
                            }
                            .foregroundColor(.red)
                        }
                    }
                }
            }
        }
        .onAppear { loadTransactions() }
    }

    func loadTransactions() {
        isLoading = true
        Task {
            do {
                let response = try await AdminAPIClient.shared.getTransactions()
                transactions = response.data
            } catch {
                print("Error loading transactions: \(error)")
            }
            isLoading = false
        }
    }

    func refundTransaction(_ transactionId: String, amount: Double) {
        Task {
            do {
                _ = try await AdminAPIClient.shared.refundTransaction(transactionId, amount: amount, reason: "Admin refund")
                loadTransactions()
            } catch {
                print("Error refunding transaction: \(error)")
            }
        }
    }
}

// MARK: - Reports View
struct ReportsView: View {
    @State private var reports: [ReportDetail] = []
    @State private var isLoading = true

    var body: some View {
        VStack {
            HStack {
                Text("User Reports")
                    .font(.largeTitle)
                    .bold()

                Spacer()

                Button(action: { loadReports() }) {
                    Image(systemName: "arrow.clockwise")
                }
            }
            .padding()

            if isLoading {
                ProgressView()
            } else {
                Table(reports) {
                    TableColumn("Type", value: \.reportType)
                    TableColumn("Priority", value: \.priority.rawValue)
                    TableColumn("Reported User") { report in
                        Text(report.reportedUserEmail ?? "N/A")
                    }
                    TableColumn("Reason", value: \.reason)
                    TableColumn("Status", value: \.status.rawValue)
                    TableColumn("Actions") { report in
                        HStack {
                            if report.status == .pending {
                                Button("Resolve") {
                                    resolveReport(report.id)
                                }
                                .foregroundColor(.green)

                                Button("Dismiss") {
                                    dismissReport(report.id)
                                }
                                .foregroundColor(.orange)
                            }
                        }
                    }
                }
            }
        }
        .onAppear { loadReports() }
    }

    func loadReports() {
        isLoading = true
        Task {
            do {
                let response = try await AdminAPIClient.shared.getReports()
                reports = response.data
            } catch {
                print("Error loading reports: \(error)")
            }
            isLoading = false
        }
    }

    func resolveReport(_ reportId: String) {
        Task {
            do {
                _ = try await AdminAPIClient.shared.resolveReport(reportId, action: "Admin resolved", notes: "Handled by admin")
                loadReports()
            } catch {
                print("Error resolving report: \(error)")
            }
        }
    }

    func dismissReport(_ reportId: String) {
        Task {
            do {
                _ = try await AdminAPIClient.shared.dismissReport(reportId, reason: "Not actionable")
                loadReports()
            } catch {
                print("Error dismissing report: \(error)")
            }
        }
    }
}

// MARK: - Database View
struct DatabaseView: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("Direct Database Access")
                .font(.largeTitle)
                .bold()

            Text("Prisma Studio is running at:")
                .font(.headline)

            Text("http://localhost:5555")
                .font(.title2)
                .foregroundColor(.blue)
                .textSelection(.enabled)

            Button("Open in Browser") {
                if let url = URL(string: "http://localhost:5555") {
                    NSWorkspace.shared.open(url)
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

            Divider()

            Text("Features:")
                .font(.headline)

            VStack(alignment: .leading, spacing: 10) {
                Label("Browse all database tables", systemImage: "tablecells")
                Label("Edit records directly", systemImage: "pencil")
                Label("Add/delete rows", systemImage: "plus.circle")
                Label("Search and filter data", systemImage: "magnifyingglass")
                Label("Real-time updates", systemImage: "arrow.clockwise")
            }
            .frame(maxWidth: 400, alignment: .leading)

            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Settings View
struct AdminSettingsView: View {
    var body: some View {
        Form {
            Section("Server") {
                Toggle("Use Local Server", isOn: .constant(false))
            }

            Section("About") {
                Text("Brrow Admin Panel")
                Text("Version 1.0.0")
            }
        }
        .padding()
        .frame(width: 400, height: 300)
    }
}
