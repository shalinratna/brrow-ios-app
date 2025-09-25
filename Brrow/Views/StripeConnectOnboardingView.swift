//
//  StripeConnectOnboardingView.swift
//  Brrow
//
//  Stripe Connect onboarding flow for sellers
//

import SwiftUI
import SafariServices

struct StripeConnectOnboardingView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = StripeConnectOnboardingViewModel()

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 16) {
                    Image(systemName: "creditcard.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.blue)

                    Text("Start Earning on Brrow")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)

                    Text("Connect your Stripe account to receive payments from buyers safely and securely.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(.top, 40)

                Spacer()

                // Benefits
                VStack(alignment: .leading, spacing: 16) {
                    FeatureRow(
                        icon: "shield.checkered",
                        title: "Secure Payments",
                        description: "Stripe processes payments securely with bank-level encryption",
                        color: Color.green
                    )

                    FeatureRow(
                        icon: "dollarsign.circle",
                        title: "Fast Payouts",
                        description: "Get paid quickly with automatic transfers to your bank account",
                        color: Color.blue
                    )

                    FeatureRow(
                        icon: "chart.line.uptrend.xyaxis",
                        title: "Track Earnings",
                        description: "Monitor your sales and earnings in real-time",
                        color: Color.orange
                    )

                    FeatureRow(
                        icon: "percent",
                        title: "Low Fees",
                        description: "Only 5% platform fee on successful transactions",
                        color: Color.purple
                    )
                }
                .padding(.horizontal)

                Spacer()

                // Buttons
                VStack(spacing: 12) {
                    Button(action: viewModel.startOnboarding) {
                        HStack {
                            if viewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            } else {
                                Text("Connect Stripe Account")
                                    .fontWeight(.semibold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .disabled(viewModel.isLoading)

                    Button("Skip for Now") {
                        dismiss()
                    }
                    .foregroundColor(.secondary)
                    .padding(.vertical, 8)
                }
                .padding(.horizontal)
                .padding(.bottom, 30)

                if !viewModel.errorMessage.isEmpty {
                    Text(viewModel.errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding(.horizontal)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .navigationBarItems(trailing:
                Button("Close") {
                    dismiss()
                }
                .foregroundColor(.blue)
            )
        }
        .sheet(isPresented: $viewModel.showingSafari, onDismiss: {
            Task {
                await viewModel.checkCompletionAndDismiss()
                if viewModel.onboardingCompleted {
                    dismiss()
                }
            }
        }) {
            if let url = viewModel.onboardingURL {
                SafariView(url: url)
            }
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    let color: Color

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)

                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
}


@MainActor
class StripeConnectOnboardingViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage = ""
    @Published var showingSafari = false
    @Published var onboardingCompleted = false
    @Published var onboardingURL: URL?

    func startOnboarding() {
        isLoading = true
        errorMessage = ""

        Task {
            do {
                let response = try await APIClient.shared.getStripeConnectOnboardingUrl()
                onboardingURL = URL(string: response.onboardingUrl)
                showingSafari = true
                isLoading = false
            } catch {
                isLoading = false
                errorMessage = "Failed to start onboarding: \(error.localizedDescription)"
            }
        }
    }

    func checkCompletionAndDismiss() async {
        do {
            // Wait a moment for Stripe to process
            try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds

            let status = try await APIClient.shared.getStripeConnectStatus()
            if status.canReceivePayments {
                onboardingCompleted = true
            }
        } catch {
            print("Failed to check onboarding status: \(error)")
        }
    }
}

#Preview {
    StripeConnectOnboardingView()
}