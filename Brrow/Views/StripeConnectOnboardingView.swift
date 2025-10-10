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

                // Error message (if any)
                if !viewModel.errorMessage.isEmpty {
                    VStack(spacing: 12) {
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                                .font(.title3)

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Connection Error")
                                    .font(.headline)
                                    .foregroundColor(.primary)

                                Text(viewModel.errorMessage)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        .padding()
                        .background(Color.orange.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.horizontal)
                    .transition(.opacity)
                }

                // Buttons
                VStack(spacing: 12) {
                    Button(action: viewModel.errorMessage.isEmpty ? viewModel.startOnboarding : viewModel.retryOnboarding) {
                        HStack {
                            if viewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            } else {
                                if !viewModel.errorMessage.isEmpty {
                                    Image(systemName: "arrow.clockwise")
                                        .font(.body)
                                }
                                Text(viewModel.errorMessage.isEmpty ? "Connect Stripe Account" : "Retry Connection")
                                    .fontWeight(.semibold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(viewModel.errorMessage.isEmpty ? Color.blue : Color.orange)
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
            }
        }) {
            if let url = viewModel.onboardingURL {
                SafariView(url: url)
            }
        }
        .fullScreenCover(isPresented: $viewModel.showSuccessScreen) {
            StripeConnectSuccessView {
                // Dismiss success screen, then dismiss onboarding view
                viewModel.showSuccessScreen = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    dismiss()
                }
            }
        }
    }
}

struct SafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        return SFSafariViewController(url: url)
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {
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
    @Published var showSuccessScreen = false
    @Published var onboardingURL: URL?
    @Published var retryCount = 0

    func startOnboarding() {
        isLoading = true
        errorMessage = ""

        Task {
            do {
                print("[StripeConnect] Requesting onboarding URL...")
                let response = try await APIClient.shared.getStripeConnectOnboardingUrl()

                print("[StripeConnect] Received onboarding URL: \(response.onboardingUrl)")
                guard let url = URL(string: response.onboardingUrl) else {
                    throw StripeConnectError.invalidURL
                }

                onboardingURL = url
                showingSafari = true
                isLoading = false
                retryCount = 0 // Reset retry count on success

                print("[StripeConnect] Opening Safari for onboarding")
            } catch let error as BrrowAPIError {
                isLoading = false
                errorMessage = handleAPIError(error)
                print("[StripeConnect] API Error: \(errorMessage)")
            } catch StripeConnectError.invalidURL {
                isLoading = false
                errorMessage = "Received invalid onboarding link. Please try again."
                print("[StripeConnect] Invalid URL received")
            } catch {
                isLoading = false
                errorMessage = "An unexpected error occurred: \(error.localizedDescription)"
                print("[StripeConnect] Unexpected error: \(error)")
            }
        }
    }

    func checkCompletionAndDismiss() async {
        do {
            print("[StripeConnect] Checking onboarding completion status...")

            // Wait a moment for Stripe to process
            try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds

            let status = try await APIClient.shared.getStripeConnectStatus()
            print("[StripeConnect] Status check result - canReceivePayments: \(status.canReceivePayments)")

            if status.canReceivePayments {
                onboardingCompleted = true
                print("[StripeConnect] Onboarding completed successfully!")

                // Show success animation
                await MainActor.run {
                    showSuccessScreen = true
                }
            } else {
                print("[StripeConnect] Onboarding not yet complete")
                // Show helpful message if not complete
                if status.requiresOnboarding == true {
                    errorMessage = "Please complete all required steps in the Stripe onboarding process."
                }
            }
        } catch let error as BrrowAPIError {
            let errorMsg = handleAPIError(error)
            print("[StripeConnect] Status check error: \(errorMsg)")
            // Don't show error to user on status check - just log it
        } catch {
            print("[StripeConnect] Failed to check onboarding status: \(error)")
        }
    }

    func retryOnboarding() {
        retryCount += 1
        startOnboarding()
    }

    private func handleAPIError(_ error: BrrowAPIError) -> String {
        switch error {
        case .networkError(let message):
            if message.contains("No internet") || message.contains("connection") {
                return "No internet connection. Please check your network and try again."
            } else if message.contains("timed out") {
                return "Request timed out. Please try again."
            } else {
                return "Network error: \(message)"
            }

        case .unauthorized:
            return "Your session has expired. Please log in again."

        case .validationError(let message):
            return message

        case .serverError(let message):
            return "Server error: \(message). Please try again later."

        case .serverErrorCode(let code):
            if code == 502 {
                return "Unable to connect to Stripe. Please try again in a few moments."
            } else {
                return "Server error (code \(code)). Please try again later."
            }

        case .invalidResponse:
            return "Received invalid response from server. Please try again."

        case .decodingError(let message):
            return "Data processing error: \(message). Please contact support if this persists."

        default:
            return "An error occurred. Please try again."
        }
    }
}

enum StripeConnectError: Error {
    case invalidURL
}

#Preview {
    StripeConnectOnboardingView()
}