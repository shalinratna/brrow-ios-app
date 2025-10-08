//
//  PaymentMethodSetupView.swift
//  Brrow
//
//  Payment Method Setup for Stripe
//

import SwiftUI

struct PaymentMethodSetupView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = PaymentMethodViewModel()

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: Theme.Spacing.lg) {
                    // Header
                    VStack(spacing: Theme.Spacing.sm) {
                        Image(systemName: "creditcard.fill")
                            .font(.system(size: 64))
                            .foregroundColor(Theme.Colors.primary)

                        Text("Add Payment Method")
                            .font(Theme.Typography.title)
                            .foregroundColor(Theme.Colors.text)

                        Text("Add a payment method to enable Buy Now and Make Offer features.")
                            .font(Theme.Typography.body)
                            .foregroundColor(Theme.Colors.secondaryText)
                            .multilineTextAlignment(.center)
                    }
                    .padding(Theme.Spacing.md)

                    // Payment Method Options
                    VStack(spacing: Theme.Spacing.md) {
                        // Add Card Button
                        Button(action: {
                            viewModel.addPaymentMethod()
                        }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text("Add Credit/Debit Card")
                                    .font(Theme.Typography.headline)
                            }
                        }
                        .primaryButtonStyle()
                        .disabled(viewModel.isLoading)

                        if viewModel.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                        }
                    }
                    .padding(Theme.Spacing.md)

                    // Security Info
                    VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                        HStack(alignment: .top, spacing: Theme.Spacing.sm) {
                            Image(systemName: "lock.shield.fill")
                                .foregroundColor(Theme.Colors.success)
                                .font(.system(size: 20))

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Secure Payment Processing")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(Theme.Colors.text)

                                Text("Your payment information is securely processed by Stripe. Brrow never stores your card details.")
                                    .font(.system(size: 13))
                                    .foregroundColor(Theme.Colors.secondaryText)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        .padding(Theme.Spacing.md)
                        .background(
                            RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                                .fill(Theme.Colors.success.opacity(0.1))
                        )
                    }
                    .padding(.horizontal, Theme.Spacing.md)
                }
                .padding(.top, Theme.Spacing.lg)
            }
            .navigationTitle("Payment Setup")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(Theme.Colors.text)
                }
            }
        }
        .alert("Success!", isPresented: $viewModel.showSuccess) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("Payment method added successfully!")
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage)
        }
    }
}

// MARK: - ViewModel
class PaymentMethodViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var showSuccess = false
    @Published var showError = false
    @Published var errorMessage = ""

    func addPaymentMethod() {
        isLoading = true

        // Get auth token
        guard let token = KeychainHelper().loadString(forKey: "brrow_auth_token") else {
            errorMessage = "Not authenticated"
            showError = true
            isLoading = false
            return
        }

        // Create Setup Intent for collecting payment method
        guard let url = URL(string: "https://brrow-backend-nodejs-production.up.railway.app/api/payments/setup-intent") else {
            errorMessage = "Invalid URL"
            showError = true
            isLoading = false
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isLoading = false

                if let error = error {
                    self?.errorMessage = "Network error: \(error.localizedDescription)"
                    self?.showError = true
                    return
                }

                guard let httpResponse = response as? HTTPURLResponse else {
                    self?.errorMessage = "Invalid response"
                    self?.showError = true
                    return
                }

                if httpResponse.statusCode == 200, let data = data {
                    do {
                        if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                           let clientSecret = json["clientSecret"] as? String {
                            // TODO: Open Stripe Payment Sheet with clientSecret
                            // For now, show error message to add Stripe SDK
                            self?.errorMessage = "Stripe integration coming soon. Please contact support to add a payment method."
                            self?.showError = true
                        }
                    } catch {
                        self?.errorMessage = "Failed to parse response"
                        self?.showError = true
                    }
                } else {
                    if let data = data,
                       let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let message = json["message"] as? String {
                        self?.errorMessage = message
                    } else {
                        self?.errorMessage = "Failed to create setup intent"
                    }
                    self?.showError = true
                }
            }
        }.resume()
    }
}

// MARK: - Preview
struct PaymentMethodSetupView_Previews: PreviewProvider {
    static var previews: some View {
        PaymentMethodSetupView()
    }
}
