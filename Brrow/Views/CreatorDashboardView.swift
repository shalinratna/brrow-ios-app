import SwiftUI
import Charts

struct CreatorDashboardView: View {
    @StateObject private var viewModel = CreatorDashboardViewModel()
    @State private var selectedTab = 0
    @State private var showShareSheet = false
    @State private var showStripeOnboarding = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "#F5F5F5")
                    .ignoresSafeArea()
                
                if viewModel.isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                } else if let dashboard = viewModel.dashboard {
                    ScrollView {
                        VStack(spacing: 20) {
                            // Header Card
                            headerCard(dashboard: dashboard)
                            
                            // Stats Grid
                            statsGrid(dashboard: dashboard)
                            
                            // Tab Selection
                            Picker("", selection: $selectedTab) {
                                Text("Overview").tag(0)
                                Text("Earnings").tag(1)
                                Text("Activity").tag(2)
                            }
                            .pickerStyle(SegmentedPickerStyle())
                            .padding(.horizontal)
                            
                            // Tab Content
                            switch selectedTab {
                            case 0:
                                overviewTab(dashboard: dashboard)
                            case 1:
                                earningsTab(dashboard: dashboard)
                            case 2:
                                activityTab(dashboard: dashboard)
                            default:
                                EmptyView()
                            }
                        }
                        .padding(.bottom, 30)
                    }
                } else if viewModel.error != nil {
                    VStack(spacing: 20) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.orange)
                        
                        Text("Unable to load creator dashboard")
                            .font(.headline)
                        
                        Text(viewModel.error ?? "Unknown error")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        Button("Try Again") {
                            Task {
                                await viewModel.loadDashboard()
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color(hex: "#2ABF5A"))
                        .foregroundColor(.white)
                        .cornerRadius(20)
                    }
                    .padding()
                }
            }
            .navigationTitle("Creator Dashboard")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Done") {
                dismiss()
            })
        }
        .task {
            await viewModel.loadDashboard()
        }
        .sheet(isPresented: $showShareSheet) {
            if let shareLink = viewModel.dashboard?.shareLink {
                CreatorShareSheet(items: [shareLink])
            }
        }
        .sheet(isPresented: $showStripeOnboarding) {
            StripeOnboardingView()
        }
    }
    
    private func headerCard(dashboard: CreatorDashboard) -> some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Creator Code")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    HStack {
                        Text(dashboard.creator.creatorCode)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(Color(hex: "#2ABF5A"))
                        
                        Button {
                            UIPasteboard.general.string = dashboard.creator.creatorCode
                            // Haptic feedback
                            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                            impactFeedback.impactOccurred()
                        } label: {
                            Image(systemName: "doc.on.doc")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                }
                
                Spacer()
                
                Button {
                    showShareSheet = true
                } label: {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                        Text("Share")
                    }
                    .font(.caption)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color(hex: "#2ABF5A"))
                    .foregroundColor(.white)
                    .cornerRadius(20)
                }
            }
            
            if !dashboard.creator.stripeConnected {
                HStack {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundColor(.orange)
                    
                    Text("Connect Stripe to receive payouts")
                        .font(.caption)
                        .foregroundColor(.orange)
                    
                    Spacer()
                    
                    Button("Connect") {
                        showStripeOnboarding = true
                    }
                    .font(.caption)
                    .foregroundColor(Color(hex: "#2ABF5A"))
                }
                .padding()
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        .padding(.horizontal)
    }
    
    private func statsGrid(dashboard: CreatorDashboard) -> some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
            CreatorStatCard(
                title: "Total Earned",
                value: "$\(String(format: "%.2f", dashboard.stats.totalEarned))",
                icon: "dollarsign.circle.fill",
                color: .green
            )
            
            CreatorStatCard(
                title: "Referrals",
                value: "\(dashboard.stats.totalReferrals)",
                icon: "person.2.fill",
                color: .blue
            )
            
            CreatorStatCard(
                title: "Pending",
                value: "$\(String(format: "%.2f", dashboard.stats.pendingEarnings))",
                icon: "clock.fill",
                color: .orange
            )
            
            CreatorStatCard(
                title: "Transactions",
                value: "\(dashboard.stats.totalTransactions)",
                icon: "arrow.right.arrow.left.circle.fill",
                color: .purple
            )
        }
        .padding(.horizontal)
    }
    
    private func overviewTab(dashboard: CreatorDashboard) -> some View {
        VStack(spacing: 20) {
            // Share Link Card
            VStack(alignment: .leading, spacing: 12) {
                Label("Your Share Link", systemImage: "link")
                    .font(.headline)
                
                Text(dashboard.shareLink)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                    .onTapGesture {
                        UIPasteboard.general.string = dashboard.shareLink
                        // Haptic feedback
                        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                        impactFeedback.impactOccurred()
                    }
                
                Text("Tap to copy • Share this link to earn 1% on all referrals")
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
            .padding()
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
            .padding(.horizontal)
            
            // How It Works
            VStack(alignment: .leading, spacing: 16) {
                Label("How It Works", systemImage: "questionmark.circle")
                    .font(.headline)
                
                VStack(alignment: .leading, spacing: 12) {
                    HowItWorksRow(number: "1", text: "Share your unique code or link")
                    HowItWorksRow(number: "2", text: "Users sign up with your code")
                    HowItWorksRow(number: "3", text: "Earn 1% on all their transactions")
                    HowItWorksRow(number: "4", text: "Get paid directly via Stripe")
                }
            }
            .padding()
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
            .padding(.horizontal)
        }
    }
    
    private func earningsTab(dashboard: CreatorDashboard) -> some View {
        VStack(spacing: 20) {
            // Monthly Earnings Chart
            if !dashboard.monthlyEarnings.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Monthly Earnings")
                        .font(.headline)
                    
                    Chart(dashboard.monthlyEarnings) { earning in
                        BarMark(
                            x: .value("Month", earning.month),
                            y: .value("Earnings", earning.earnings)
                        )
                        .foregroundStyle(Color(hex: "#2ABF5A"))
                    }
                    .frame(height: 200)
                }
                .padding()
                .background(Color.white)
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                .padding(.horizontal)
            }
            
            // Average Commission
            VStack(spacing: 8) {
                Text("Average Commission")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Text("$\(String(format: "%.2f", dashboard.stats.averageCommission))")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(Color(hex: "#2ABF5A"))
                
                Text("per transaction")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
            .padding(.horizontal)
        }
    }
    
    private func activityTab(dashboard: CreatorDashboard) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Commissions")
                .font(.headline)
                .padding(.horizontal)
            
            if dashboard.recentCommissions.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "tray")
                        .font(.system(size: 40))
                        .foregroundColor(.gray)
                    
                    Text("No commissions yet")
                        .font(.headline)
                        .foregroundColor(.gray)
                    
                    Text("Share your code to start earning!")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                ForEach(dashboard.recentCommissions) { commission in
                    CommissionRow(commission: commission)
                }
            }
        }
    }
}

// MARK: - Supporting Views

struct CreatorStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Spacer()
            }
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

struct HowItWorksRow: View {
    let number: String
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(number)
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(width: 24, height: 24)
                .background(Color(hex: "#2ABF5A"))
                .clipShape(Circle())
            
            Text(text)
                .font(.callout)
                .foregroundColor(.gray)
            
            Spacer()
        }
    }
}

struct CommissionRow: View {
    let commission: CreatorCommission
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(commission.listingTitle ?? "Transaction")
                    .font(.callout)
                    .lineLimit(1)
                
                Text("From @\(commission.buyerUsername)")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("+$\(String(format: "%.2f", commission.commissionAmount))")
                    .font(.callout)
                    .fontWeight(.semibold)
                    .foregroundColor(commission.paymentStatus == "paid" ? .green : .orange)
                
                Text(commission.paymentStatus.capitalized)
                    .font(.caption2)
                    .foregroundColor(commission.paymentStatus == "paid" ? .green : .orange)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(8)
        .shadow(color: Color.black.opacity(0.02), radius: 2, x: 0, y: 1)
        .padding(.horizontal)
    }
}

struct StripeOnboardingView: View {
    @StateObject private var viewModel = StripeOnboardingViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                if viewModel.isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                } else {
                    Image(systemName: "creditcard.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(Color(hex: "#2ABF5A"))
                    
                    Text("Connect Stripe Account")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Connect your Stripe account to receive creator payouts directly to your bank account.")
                        .font(.callout)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    Spacer()
                    
                    Button {
                        Task {
                            await viewModel.startOnboarding()
                        }
                    } label: {
                        HStack {
                            Image(systemName: "arrow.right.circle.fill")
                            Text("Connect Stripe")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding()
                    .background(Color(hex: "#2ABF5A"))
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
            .navigationTitle("Payment Setup")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Cancel") {
                dismiss()
            })
            .alert("Error", isPresented: .constant(viewModel.error != nil)) {
                Button("OK") {
                    viewModel.error = nil
                }
            } message: {
                Text(viewModel.error ?? "")
            }
        }
    }
}

// MARK: - Share Sheet

struct CreatorShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}