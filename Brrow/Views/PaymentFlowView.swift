import SwiftUI
import StripePaymentSheet

struct PaymentFlowView: View {
    let listing: Listing
    @State private var transactionType: TransactionType = .purchase
    @State private var deliveryMethod: DeliveryMethod = .pickup
    @State private var buyerMessage = ""
    @State private var rentalStartDate = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
    @State private var rentalEndDate = Calendar.current.date(byAdding: .day, value: 2, to: Date()) ?? Date()
    
    @StateObject private var paymentService = PaymentService.shared
    @State private var paymentSheet: PaymentSheet?
    @State private var paymentResult: PaymentSheetResult?
    @State private var currentStep: PaymentStep = .configure
    @State private var paymentIntent: MarketplacePaymentIntent?
    @State private var showingSuccess = false
    @State private var showingError = false
    @State private var errorMessage = ""
    
    @Environment(\.presentationMode) var presentationMode
    
    enum TransactionType: String, CaseIterable {
        case purchase = "PURCHASE"
        case rental = "RENTAL"
        
        var title: String {
            switch self {
            case .purchase: return "Buy"
            case .rental: return "Rent"
            }
        }
    }
    
    enum DeliveryMethod: String, CaseIterable {
        case pickup = "PICKUP"
        case delivery = "DELIVERY"
        case shipping = "SHIPPING"
        
        var title: String {
            switch self {
            case .pickup: return "Pickup"
            case .delivery: return "Delivery"
            case .shipping: return "Shipping"
            }
        }
        
        var icon: String {
            switch self {
            case .pickup: return "car.fill"
            case .delivery: return "truck.box.fill"
            case .shipping: return "shippingbox.fill"
            }
        }
    }
    
    enum PaymentStep {
        case configure
        case review
        case processing
        case success
    }
    
    var totalAmount: Double {
        if transactionType == .rental {
            let dailyRate = listing.price
            let days = max(1, Calendar.current.dateComponents([.day], from: rentalStartDate, to: rentalEndDate).day ?? 1)
            return dailyRate * Double(days)
        }
        return listing.price
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    switch currentStep {
                    case .configure:
                        configurationView
                    case .review:
                        reviewView
                    case .processing:
                        processingView
                    case .success:
                        successView
                    }
                }
                .padding()
            }
            .navigationTitle("Complete Purchase")
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: trailingButton
            )
        }
        .alert("Payment Failed", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
        .alert("Payment Successful!", isPresented: $showingSuccess) {
            Button("OK") {
                presentationMode.wrappedValue.dismiss()
            }
        } message: {
            Text("Your transaction has been completed successfully.")
        }
    }
    
    private var configurationView: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Listing Info
            listingInfoCard
            
            // Transaction Type
            VStack(alignment: .leading, spacing: 12) {
                Text("Transaction Type")
                    .font(.headline)
                
                Picker("Type", selection: $transactionType) {
                    ForEach(TransactionType.allCases, id: \.self) { type in
                        Text(type.title).tag(type)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
            }
            
            // Rental Dates (if rental)
            if transactionType == .rental {
                rentalDatesView
            }
            
            // Delivery Method
            VStack(alignment: .leading, spacing: 12) {
                Text("Delivery Method")
                    .font(.headline)
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
                    ForEach(DeliveryMethod.allCases, id: \.self) { method in
                        DeliveryMethodCard(
                            method: method,
                            isSelected: deliveryMethod == method
                        ) {
                            deliveryMethod = method
                        }
                    }
                }
            }
            
            // Buyer Message
            VStack(alignment: .leading, spacing: 12) {
                Text("Message to Seller (Optional)")
                    .font(.headline)
                
                TextEditor(text: $buyerMessage)
                    .frame(minHeight: 80)
                    .padding(8)
                    .background(Color(UIColor.systemGray6))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
            }
            
            // Cost Breakdown
            costBreakdownView
            
            Spacer()
        }
    }
    
    private var reviewView: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Review Your Order")
                .font(.title2)
                .fontWeight(.bold)
            
            listingInfoCard
            
            // Order Summary
            VStack(alignment: .leading, spacing: 16) {
                Text("Order Summary")
                    .font(.headline)
                
                VStack(spacing: 12) {
                    OrderRow(title: "Transaction Type", value: transactionType.title)
                    
                    if transactionType == .rental {
                        OrderRow(title: "Rental Period", value: rentalPeriodText)
                        OrderRow(title: "Daily Rate", value: PaymentService.shared.formatCurrency(listing.price))
                    }
                    
                    OrderRow(title: "Delivery Method", value: deliveryMethod.title)
                    
                    if !buyerMessage.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Message to Seller:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(buyerMessage)
                                .font(.subheadline)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
            
            costBreakdownView
            
            // Payment Method
            if let paymentIntent = paymentIntent {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Payment")
                        .font(.headline)
                    
                    Button("Pay with Card") {
                        presentPaymentSheet()
                    }
                    .buttonStyle(PrimaryButtonStyle())
                }
            }
            
            Spacer()
        }
    }
    
    private var processingView: some View {
        VStack(spacing: 24) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text("Processing Payment...")
                .font(.headline)
            
            Text("Please wait while we process your payment securely.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var successView: some View {
        VStack(spacing: 24) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.green)
            
            Text("Payment Successful!")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Your transaction has been completed. The seller will be notified.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var listingInfoCard: some View {
        HStack(spacing: 16) {
            AsyncImage(url: URL(string: listing.images.first?.imageUrl ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.3))
            }
            .frame(width: 80, height: 80)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            
            VStack(alignment: .leading, spacing: 8) {
                Text(listing.title)
                    .font(.headline)
                    .lineLimit(2)
                
                Text(PaymentService.shared.formatCurrency(listing.price))
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                if transactionType == .rental {
                    Text("\(PaymentService.shared.formatCurrency(listing.price))/day")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
        .padding()
        .background(Color(UIColor.systemGray6))
        .cornerRadius(12)
    }
    
    private var rentalDatesView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Rental Period")
                .font(.headline)
            
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Start Date")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    DatePicker("Start", selection: $rentalStartDate, in: Date()..., displayedComponents: .date)
                        .labelsHidden()
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("End Date")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    DatePicker("End", selection: $rentalEndDate, in: rentalStartDate..., displayedComponents: .date)
                        .labelsHidden()
                }
            }
            
            Text(rentalPeriodText)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private var costBreakdownView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Cost Breakdown")
                .font(.headline)
            
            VStack(spacing: 8) {
                let costs = PaymentService.shared.calculateTotalCost(amount: totalAmount)
                
                OrderRow(title: itemCostTitle, value: PaymentService.shared.formatCurrency(totalAmount))
                OrderRow(title: "Platform Fee (5%)", value: PaymentService.shared.formatCurrency(costs.platformFee))
                OrderRow(title: "Processing Fee", value: PaymentService.shared.formatCurrency(costs.stripeFee))
                
                Divider()
                
                OrderRow(
                    title: "Total",
                    value: PaymentService.shared.formatCurrency(costs.total),
                    isTotal: true
                )
            }
        }
        .padding()
        .background(Color(UIColor.systemGray6))
        .cornerRadius(12)
    }
    
    private var trailingButton: some View {
        Button(currentStep == .configure ? "Continue" : "Back") {
            switch currentStep {
            case .configure:
                currentStep = .review
                createPaymentIntent()
            case .review:
                currentStep = .configure
            case .processing, .success:
                break
            }
        }
        .disabled(paymentService.isLoading)
    }
    
    private var itemCostTitle: String {
        if transactionType == .rental {
            let days = max(1, Calendar.current.dateComponents([.day], from: rentalStartDate, to: rentalEndDate).day ?? 1)
            return "Rental Cost (\(days) day\(days == 1 ? "" : "s"))"
        }
        return "Item Cost"
    }
    
    private var rentalPeriodText: String {
        let days = max(1, Calendar.current.dateComponents([.day], from: rentalStartDate, to: rentalEndDate).day ?? 1)
        return "\(days) day\(days == 1 ? "" : "s") rental"
    }
    
    private func createPaymentIntent() {
        Task {
            do {
                let intent = try await paymentService.createMarketplacePaymentIntent(
                    listingId: listing.listingId,
                    sellerId: listing.userId,
                    transactionType: transactionType.rawValue,
                    rentalStartDate: transactionType == .rental ? rentalStartDate : nil,
                    rentalEndDate: transactionType == .rental ? rentalEndDate : nil,
                    deliveryMethod: deliveryMethod.rawValue,
                    buyerMessage: buyerMessage.isEmpty ? nil : buyerMessage
                )
                
                await MainActor.run {
                    self.paymentIntent = intent
                    setupPaymentSheet(clientSecret: intent.clientSecret)
                }
                
            } catch PaymentError.sellerOnboardingRequired {
                await MainActor.run {
                    errorMessage = "The seller needs to complete their payment setup first. Please try again later."
                    showingError = true
                    currentStep = .configure
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showingError = true
                    currentStep = .configure
                }
            }
        }
    }
    
    private func setupPaymentSheet(clientSecret: String) {
        var configuration = PaymentSheet.Configuration()
        configuration.merchantDisplayName = "Brrow"
        configuration.allowsDelayedPaymentMethods = false
        
        paymentSheet = PaymentSheet(
            paymentIntentClientSecret: clientSecret,
            configuration: configuration
        )
    }
    
    private func presentPaymentSheet() {
        guard let paymentSheet = paymentSheet else { return }
        
        currentStep = .processing
        
        if let rootViewController = UIApplication.shared.windows.first?.rootViewController {
            paymentSheet.present(from: rootViewController) { result in
                Task {
                    await handlePaymentResult(result)
                }
            }
        }
    }
    
    private func handlePaymentResult(_ result: PaymentSheetResult) async {
        switch result {
        case .completed:
            // Confirm payment on backend
            if let transactionId = paymentIntent?.transactionId {
                do {
                    try await paymentService.confirmPayment(transactionId: transactionId)
                    await MainActor.run {
                        currentStep = .success
                        showingSuccess = true
                    }
                } catch {
                    await MainActor.run {
                        errorMessage = "Payment succeeded but confirmation failed. Please contact support."
                        showingError = true
                        currentStep = .review
                    }
                }
            }
            
        case .canceled:
            await MainActor.run {
                currentStep = .review
            }
            
        case .failed(let error):
            await MainActor.run {
                errorMessage = error.localizedDescription
                showingError = true
                currentStep = .review
            }
        }
    }
}

// MARK: - Supporting Views
struct DeliveryMethodCard: View {
    let method: PaymentFlowView.DeliveryMethod
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: method.icon)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : .primary)
                
                Text(method.title)
                    .font(.caption)
                    .foregroundColor(isSelected ? .white : .primary)
            }
            .frame(maxWidth: .infinity, minHeight: 60)
            .background(isSelected ? Color.blue : Color(UIColor.systemGray6))
            .cornerRadius(8)
        }
    }
}

struct OrderRow: View {
    let title: String
    let value: String
    var isTotal: Bool = false
    
    var body: some View {
        HStack {
            Text(title)
                .font(isTotal ? .headline : .subheadline)
                .fontWeight(isTotal ? .semibold : .regular)
            
            Spacer()
            
            Text(value)
                .font(isTotal ? .headline : .subheadline)
                .fontWeight(isTotal ? .bold : .medium)
        }
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(12)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

#Preview {
    PaymentFlowView(listing: Listing.example)
}