//
//  RentalOptionsView.swift
//  Brrow
//
//  Rental options and checkout for listings
//

import SwiftUI

struct RentalOptionsView: View {
    let listing: Listing
    @Environment(\.dismiss) private var dismiss
    @State private var startDate = Date()
    @State private var endDate = Date().addingTimeInterval(86400) // +1 day
    @State private var showingPaymentSheet = false
    @State private var isLoading = false
    @State private var totalCost: Double = 0
    @State private var rentalDays: Int = 1
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Listing info
                    HStack(spacing: 12) {
                        if let firstImage = listing.imageUrls.first {
                            ListingImageView(
                                imageURLs: [firstImage],
                                aspectRatio: .fill,
                                cornerRadius: 8
                            )
                            .frame(width: 80, height: 80)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(listing.title)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(Theme.Colors.text)
                                .lineLimit(2)
                            
                            Text("$\(String(format: "%.2f", listing.price)) / day")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(Theme.Colors.primary)
                            
                            HStack(spacing: 4) {
                                Image(systemName: "location")
                                    .font(.system(size: 12))
                                Text(listing.location.city)
                                    .font(.system(size: 12))
                            }
                            .foregroundColor(Theme.Colors.secondaryText)
                        }
                        
                        Spacer()
                    }
                    .padding(16)
                    .background(Theme.Colors.secondaryBackground)
                    .cornerRadius(12)
                    
                    // Date selection
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Rental Period")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(Theme.Colors.text)
                        
                        // Start date
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Start Date")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Theme.Colors.secondaryText)
                            
                            DatePicker("", selection: $startDate, in: Date()..., displayedComponents: .date)
                                .datePickerStyle(CompactDatePickerStyle())
                                .labelsHidden()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .onChange(of: startDate) { _ in
                                    updateEndDate()
                                    calculateTotal()
                                }
                        }
                        
                        // End date
                        VStack(alignment: .leading, spacing: 8) {
                            Text("End Date")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Theme.Colors.secondaryText)
                            
                            DatePicker("", selection: $endDate, in: startDate..., displayedComponents: .date)
                                .datePickerStyle(CompactDatePickerStyle())
                                .labelsHidden()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .onChange(of: endDate) { _ in
                                    calculateTotal()
                                }
                        }
                        
                        // Rental duration info
                        HStack {
                            Image(systemName: "calendar")
                                .font(.system(size: 14))
                                .foregroundColor(Theme.Colors.primary)
                            
                            Text("\(rentalDays) day\(rentalDays > 1 ? "s" : "") rental")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Theme.Colors.text)
                            
                            Spacer()
                            
                            // minRentalDays not available in current Listing model
                        }
                        .padding(12)
                        .background(Theme.Colors.primary.opacity(0.05))
                        .cornerRadius(8)
                    }
                    .padding(.horizontal, 16)
                    
                    // Cost breakdown
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Cost Breakdown")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(Theme.Colors.text)
                        
                        VStack(spacing: 12) {
                            CostRow(
                                label: "$\(String(format: "%.2f", listing.price)) × \(rentalDays) days",
                                amount: listing.price * Double(rentalDays)
                            )
                            
                            // depositAmount not available in current Listing model
                            
                            Divider()
                            
                            HStack {
                                Text("Total")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(Theme.Colors.text)
                                
                                Spacer()
                                
                                Text("$\(String(format: "%.2f", totalCost))")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(Theme.Colors.primary)
                            }
                        }
                        .padding(16)
                        .background(Theme.Colors.secondaryBackground)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal, 16)
                    
                    // Terms
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Cancellation Policy", systemImage: "info.circle")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Theme.Colors.secondaryText)
                        
                        Text("Free cancellation up to 24 hours before pickup. After that, 50% refund.")
                            .font(.system(size: 12))
                            .foregroundColor(Theme.Colors.secondaryText)
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Theme.Colors.secondaryBackground.opacity(0.5))
                    .cornerRadius(8)
                    .padding(.horizontal, 16)
                }
                .padding(.vertical, 20)
            }
            .navigationTitle("Rental Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                Button(action: { proceedToPayment() }) {
                    HStack {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 16))
                        
                        Text("Proceed to Secure Payment")
                            .font(.system(size: 18, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Theme.Colors.primary)
                    .cornerRadius(12)
                    .opacity(isValidRental() ? 1 : 0.6)
                }
                .disabled(!isValidRental())
                .padding(16)
                .background(Theme.Colors.background)
            }
        }
        .onAppear {
            calculateTotal()
        }
    }
    
    private func updateEndDate() {
        // minRentalDays not available - default to 1 day minimum
        endDate = startDate.addingTimeInterval(86400)
    }
    
    private func calculateTotal() {
        let calendar = Calendar.current
        let days = calendar.dateComponents([.day], from: startDate, to: endDate).day ?? 0
        rentalDays = max(1, days)
        
        var total = listing.price * Double(rentalDays)
        // depositAmount not available in current Listing model
        
        totalCost = total
    }
    
    private func isValidRental() -> Bool {
        // minRentalDays not available - default to 1 day minimum
        if rentalDays < 1 {
            return false
        }
        // maxRentalDays not available in current Listing model
        return rentalDays > 0
    }
    
    private func proceedToPayment() {
        isLoading = true
        
        Task {
            do {
                // Create rental request
                // Show payment sheet
                // Handle payment result
                dismiss()
            } catch {
                isLoading = false
            }
        }
    }
}

struct CostRow: View {
    let label: String
    let amount: Double
    var isDeposit: Bool = false
    
    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 14))
                .foregroundColor(Theme.Colors.secondaryText)
            
            Spacer()
            
            Text("$\(String(format: "%.2f", amount))")
                .font(.system(size: 16, weight: isDeposit ? .regular : .medium))
                .foregroundColor(isDeposit ? Theme.Colors.secondary : Theme.Colors.text)
        }
    }
}