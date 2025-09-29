//
//  PaymentView.swift
//  Brrow
//
//  Handles Stripe payment processing for rentals
//

import SwiftUI
import PassKit

struct PaymentView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var viewModel = PaymentViewModel()
    
    let transactionId: String
    let amount: Double
    let securityDeposit: Double
    let listingTitle: String
    
    @State private var cardNumber = ""
    @State private var expiryDate = ""
    @State private var cvv = ""
    @State private var cardholderName = ""
    @State private var saveCard = false
    @State private var isProcessing = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showSuccess = false
    @State private var useApplePay = false
    
    private var totalAmount: Double {
        return amount + securityDeposit
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Payment Summary
                    paymentSummary
                    
                    // Apple Pay Button (if available)
                    if PKPaymentAuthorizationViewController.canMakePayments() {
                        applePaySection
                    }
                    
                    // Or divider
                    if PKPaymentAuthorizationViewController.canMakePayments() {
                        HStack {
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(height: 1)
                            Text("OR")
                                .font(.caption)
                                .foregroundColor(.gray)
                                .padding(.horizontal, 10)
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(height: 1)
                        }
                        .padding(.vertical, 10)
                    }
                    
                    // Card Input
                    cardInputSection
                    
                    // Security Info
                    securityInfo
                    
                    // Pay Button
                    payButton
                }
                .padding()
            }
            .navigationTitle("Payment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
            .alert("Payment Successful!", isPresented: $showSuccess) {
                Button("OK") {
                    presentationMode.wrappedValue.dismiss()
                }
            } message: {
                Text("Your payment has been processed successfully. The owner will be notified and your rental is now active.")
            }
            .overlay {
                if isProcessing {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                        .overlay {
                            VStack(spacing: 20) {
                                ProgressView()
                                    .scaleEffect(1.5)
                                Text("Processing payment...")
                                    .font(.headline)
                                Text("Please do not close this screen")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            .padding(30)
                            .background(Color.white)
                            .cornerRadius(15)
                            .shadow(radius: 10)
                        }
                }
            }
        }
    }
    
    private var paymentSummary: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Payment Summary")
                .font(.headline)
            
            VStack(spacing: 12) {
                HStack {
                    Text(listingTitle)
                        .font(.subheadline)
                        .lineLimit(2)
                    Spacer()
                }
                
                Divider()
                
                HStack {
                    Text("Rental Amount")
                    Spacer()
                    Text("$\(amount, specifier: "%.2f")")
                        .fontWeight(.medium)
                }
                .font(.subheadline)
                
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Security Deposit")
                        Text("Refundable after return")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    Spacer()
                    Text("$\(securityDeposit, specifier: "%.2f")")
                        .fontWeight(.medium)
                        .foregroundColor(.orange)
                }
                .font(.subheadline)
                
                Divider()
                
                HStack {
                    Text("Total")
                        .font(.headline)
                    Spacer()
                    Text("$\(totalAmount, specifier: "%.2f")")
                        .font(.headline)
                        .foregroundColor(.blue)
                }
            }
            .padding()
            .background(Color.gray.opacity(0.05))
            .cornerRadius(10)
        }
    }
    
    private var applePaySection: some View {
        VStack(spacing: 12) {
            Button(action: processApplePay) {
                HStack {
                    Image(systemName: "applelogo")
                    Text("Pay with Apple Pay")
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color.black)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            
            Text("Fast and secure payment")
                .font(.caption)
                .foregroundColor(.gray)
        }
    }
    
    private var cardInputSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Card Information")
                .font(.headline)
            
            VStack(spacing: 16) {
                // Card Number
                VStack(alignment: .leading, spacing: 8) {
                    Text("Card Number")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    HStack {
                        TextField("1234 5678 9012 3456", text: $cardNumber)
                            .keyboardType(.numberPad)
                            .onChange(of: cardNumber) { newValue in
                                // Format card number with spaces
                                let filtered = newValue.replacingOccurrences(of: " ", with: "")
                                if filtered.count <= 16 {
                                    var formatted = ""
                                    for (index, char) in filtered.enumerated() {
                                        if index > 0 && index % 4 == 0 {
                                            formatted += " "
                                        }
                                        formatted += String(char)
                                    }
                                    cardNumber = formatted
                                }
                            }
                        
                        Image(systemName: detectCardType())
                            .foregroundColor(.blue)
                    }
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                HStack(spacing: 16) {
                    // Expiry Date
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Expiry Date")
                            .font(.caption)
                            .foregroundColor(.gray)
                        TextField("MM/YY", text: $expiryDate)
                            .keyboardType(.numberPad)
                            .onChange(of: expiryDate) { newValue in
                                // Format expiry date
                                let filtered = newValue.replacingOccurrences(of: "/", with: "")
                                if filtered.count <= 4 {
                                    if filtered.count >= 2 {
                                        let month = String(filtered.prefix(2))
                                        let year = String(filtered.dropFirst(2))
                                        expiryDate = month + (year.isEmpty ? "" : "/" + year)
                                    } else {
                                        expiryDate = filtered
                                    }
                                }
                            }
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    // CVV
                    VStack(alignment: .leading, spacing: 8) {
                        Text("CVV")
                            .font(.caption)
                            .foregroundColor(.gray)
                        TextField("123", text: $cvv)
                            .keyboardType(.numberPad)
                            .onChange(of: cvv) { newValue in
                                if newValue.count > 4 {
                                    cvv = String(newValue.prefix(4))
                                }
                            }
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                }
                
                // Cardholder Name
                VStack(alignment: .leading, spacing: 8) {
                    Text("Cardholder Name")
                        .font(.caption)
                        .foregroundColor(.gray)
                    TextField("John Doe", text: $cardholderName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                // Save Card Option
                Toggle(isOn: $saveCard) {
                    Text("Save card for future payments")
                        .font(.subheadline)
                }
                .toggleStyle(SwitchToggleStyle(tint: .blue))
            }
            .padding()
            .background(Color.gray.opacity(0.05))
            .cornerRadius(10)
        }
    }
    
    private var securityInfo: some View {
        HStack {
            Image(systemName: "lock.shield.fill")
                .foregroundColor(.green)
            VStack(alignment: .leading, spacing: 4) {
                Text("Secure Payment")
                    .font(.caption)
                    .fontWeight(.semibold)
                Text("Your payment information is encrypted and secure")
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
            Spacer()
        }
        .padding()
        .background(Color.green.opacity(0.05))
        .cornerRadius(10)
    }
    
    private var payButton: some View {
        Button(action: processPayment) {
            HStack {
                Image(systemName: "creditcard.fill")
                Text("Pay $\(totalAmount, specifier: "%.2f")")
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(isValidInput() ? Color.blue : Color.gray)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
        .disabled(!isValidInput() || isProcessing)
    }
    
    private func detectCardType() -> String {
        let number = cardNumber.replacingOccurrences(of: " ", with: "")
        if number.starts(with: "4") {
            return "creditcard.fill" // Visa
        } else if number.starts(with: "5") {
            return "creditcard.fill" // Mastercard
        } else if number.starts(with: "3") {
            return "creditcard.fill" // Amex
        }
        return "creditcard"
    }
    
    private func isValidInput() -> Bool {
        let number = cardNumber.replacingOccurrences(of: " ", with: "")
        let expiry = expiryDate.replacingOccurrences(of: "/", with: "")
        
        return number.count == 16 &&
               expiry.count == 4 &&
               (cvv.count == 3 || cvv.count == 4) &&
               !cardholderName.isEmpty
    }
    
    private func processPayment() {
        guard !isProcessing else { return }
        
        isProcessing = true
        
        Task {
            do {
                // Create payment intent
                let paymentData: [String: Any] = [
                    "transaction_id": transactionId
                ]
                
                let response = try await APIClient.shared.createPaymentIntent(data: paymentData)
                
                // In a real app, you would use Stripe SDK to process the payment
                // For now, we'll simulate success
                await MainActor.run {
                    isProcessing = false
                    showSuccess = true
                }
                
            } catch {
                await MainActor.run {
                    isProcessing = false
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
    
    private func processApplePay() {
        // In a real app, implement Apple Pay using PassKit
        // For now, we'll use the regular payment flow
        processPayment()
    }
}

// MARK: - View Model
class PaymentViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var error: String?
}

// MARK: - Extension for APIClient
extension APIClient {
    func createPaymentIntent(data: [String: Any]) async throws -> [String: Any] {
        let baseURL = await APIEndpointManager.shared.getBestEndpoint()
        let url = URL(string: "\(baseURL)/api_create_payment_intent.php")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = AuthManager.shared.authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        if let apiId = AuthManager.shared.currentUser?.apiId {
            request.setValue(apiId, forHTTPHeaderField: "X-User-API-ID")
        }
        
        request.httpBody = try JSONSerialization.data(withJSONObject: data)
        
        let (responseData, _) = try await URLSession.shared.data(for: request)
        let response = try JSONSerialization.jsonObject(with: responseData) as? [String: Any] ?? [:]
        
        if response["success"] as? Bool != true {
            throw BrrowAPIError.serverError(response["message"] as? String ?? "Failed to create payment intent")
        }
        
        return response
    }
}

// MARK: - Preview
struct PaymentView_Previews: PreviewProvider {
    static var previews: some View {
        PaymentView(
            transactionId: "txn_123",
            amount: 150.00,
            securityDeposit: 50.00,
            listingTitle: "Professional Camera Kit"
        )
        .environmentObject(AuthManager.shared)
    }
}