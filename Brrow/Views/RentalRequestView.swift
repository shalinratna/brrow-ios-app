//
//  RentalRequestView.swift
//  Brrow
//
//  Create a rental request for a listing
//

import SwiftUI

struct RentalRequestView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var viewModel = RentalRequestViewModel()
    
    let listing: Listing
    
    @State private var startDate = Date()
    @State private var endDate = Date().addingTimeInterval(86400) // +1 day
    @State private var deliveryMethod = "pickup"
    @State private var pickupLocation = ""
    @State private var specialInstructions = ""
    @State private var showingConfirmation = false
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showSuccess = false
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }
    
    private var rentalDays: Int {
        let days = Calendar.current.dateComponents([.day], from: startDate, to: endDate).day ?? 0
        return max(1, days + 1)
    }
    
    private var subtotal: Double {
        return listing.price * Double(rentalDays)
    }
    
    private var serviceFee: Double {
        return subtotal * 0.10
    }
    
    private var securityDeposit: Double {
        return listing.securityDeposit ?? (subtotal * 0.25)
    }
    
    private var totalAmount: Double {
        return subtotal + serviceFee
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Listing Preview
                    listingPreview
                    
                    // Rental Dates
                    datesSection
                    
                    // Delivery Options
                    deliverySection
                    
                    // Special Instructions
                    instructionsSection
                    
                    // Pricing Breakdown
                    pricingSection
                    
                    // Terms & Conditions
                    termsSection
                    
                    // Request Button
                    requestButton
                }
                .padding()
            }
            .navigationTitle("Request Rental")
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
            .alert("Success!", isPresented: $showSuccess) {
                Button("OK") {
                    presentationMode.wrappedValue.dismiss()
                }
            } message: {
                Text("Your rental request has been sent to the owner. You'll be notified when they respond.")
            }
            .overlay {
                if isLoading {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                        .overlay {
                            ProgressView("Sending request...")
                                .padding()
                                .background(Color.white)
                                .cornerRadius(10)
                                .shadow(radius: 5)
                        }
                }
            }
        }
    }
    
    private var listingPreview: some View {
        HStack(spacing: 12) {
            // Image
            if let firstImage = listing.images.first,
               let url = URL(string: firstImage) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                }
                .frame(width: 80, height: 80)
                .cornerRadius(10)
            }
            
            // Details
            VStack(alignment: .leading, spacing: 4) {
                Text(listing.title)
                    .font(.headline)
                    .lineLimit(2)
                
                Text(listing.category)
                    .font(.caption)
                    .foregroundColor(.gray)
                
                HStack {
                    Text("$\(listing.price, specifier: "%.2f")")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    Text("/ \(listing.priceType.rawValue)")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            
            Spacer()
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(10)
    }
    
    private var datesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Rental Period")
                .font(.headline)
            
            VStack(spacing: 12) {
                DatePicker("Start Date", selection: $startDate, in: Date()..., displayedComponents: .date)
                    .datePickerStyle(CompactDatePickerStyle())
                
                DatePicker("End Date", selection: $endDate, in: startDate..., displayedComponents: .date)
                    .datePickerStyle(CompactDatePickerStyle())
            }
            .padding()
            .background(Color.gray.opacity(0.05))
            .cornerRadius(10)
            
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(.blue)
                Text("\(rentalDays) day\(rentalDays == 1 ? "" : "s")")
                    .font(.subheadline)
            }
        }
    }
    
    private var deliverySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Delivery Method")
                .font(.headline)
            
            Picker("Delivery Method", selection: $deliveryMethod) {
                Text("Pickup").tag("pickup")
                Text("Delivery").tag("delivery")
                Text("Shipping").tag("shipping")
            }
            .pickerStyle(SegmentedPickerStyle())
            
            if deliveryMethod == "pickup" {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Pickup Location")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    TextField("Enter pickup location or use default", text: $pickupLocation)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    if pickupLocation.isEmpty {
                        Text("Default: \(listing.location)")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
            }
        }
    }
    
    private var instructionsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Special Instructions (Optional)")
                .font(.headline)
            
            TextEditor(text: $specialInstructions)
                .frame(minHeight: 80)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
        }
    }
    
    private var pricingSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Pricing Breakdown")
                .font(.headline)
            
            VStack(spacing: 12) {
                HStack {
                    Text("Rental (\(rentalDays) days × $\(listing.price, specifier: "%.2f"))")
                        .font(.subheadline)
                    Spacer()
                    Text("$\(subtotal, specifier: "%.2f")")
                        .font(.subheadline)
                }
                
                HStack {
                    Text("Service Fee (10%)")
                        .font(.subheadline)
                    Spacer()
                    Text("$\(serviceFee, specifier: "%.2f")")
                        .font(.subheadline)
                }
                
                Divider()
                
                HStack {
                    Text("Total")
                        .font(.headline)
                    Spacer()
                    Text("$\(totalAmount, specifier: "%.2f")")
                        .font(.headline)
                        .foregroundColor(.blue)
                }
                
                Divider()
                
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Security Deposit")
                            .font(.subheadline)
                        Text("Refunded after successful return")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    Spacer()
                    Text("$\(securityDeposit, specifier: "%.2f")")
                        .font(.subheadline)
                        .foregroundColor(.orange)
                }
            }
            .padding()
            .background(Color.gray.opacity(0.05))
            .cornerRadius(10)
        }
    }
    
    private var termsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Terms & Conditions")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 8) {
                Label("Payment due upon owner approval", systemImage: "creditcard")
                    .font(.caption)
                
                Label("Security deposit refunded after return", systemImage: "shield")
                    .font(.caption)
                
                Label("Cancellation policy applies", systemImage: "xmark.circle")
                    .font(.caption)
                
                Label("Report any damages immediately", systemImage: "exclamationmark.triangle")
                    .font(.caption)
            }
            .padding()
            .background(Color.blue.opacity(0.05))
            .cornerRadius(10)
        }
    }
    
    private var requestButton: some View {
        Button(action: submitRequest) {
            HStack {
                Image(systemName: "paperplane.fill")
                Text("Send Rental Request")
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
        .disabled(isLoading)
    }
    
    private func submitRequest() {
        guard !isLoading else { return }
        
        isLoading = true
        
        Task {
            do {
                let dateFormatter = ISO8601DateFormatter()
                dateFormatter.formatOptions = [.withFullDate]
                
                let requestData: [String: Any] = [
                    "listing_id": listing.id,
                    "start_date": dateFormatter.string(from: startDate),
                    "end_date": dateFormatter.string(from: endDate),
                    "delivery_method": deliveryMethod,
                    "pickup_location": pickupLocation.isEmpty ? listing.location.address : pickupLocation,
                    "special_instructions": specialInstructions.isEmpty ? nil : specialInstructions
                ].compactMapValues { $0 }
                
                let response = try await APIClient.shared.createRentalRequest(data: requestData)
                
                await MainActor.run {
                    isLoading = false
                    if response["success"] as? Bool == true {
                        showSuccess = true
                    } else {
                        errorMessage = response["message"] as? String ?? "Failed to send rental request"
                        showError = true
                    }
                }
                
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
}

// MARK: - View Model
class RentalRequestViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var error: String?
}

// MARK: - Preview
// Preview disabled - Listing.sample not available
/*
struct RentalRequestView_Previews: PreviewProvider {
    static var previews: some View {
        RentalRequestView(listing: Listing.sample)
            .environmentObject(AuthManager.shared)
    }
}
*/