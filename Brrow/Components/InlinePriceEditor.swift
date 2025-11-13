//
//  InlinePriceEditor.swift
//  Brrow
//
//  Created by Claude Code on 11/13/25.
//

import SwiftUI

/// Inline editor for price fields (price, dailyRate, securityDeposit)
struct InlinePriceEditor: View {
    let field: EditableField
    @ObservedObject var viewModel: InlineEditViewModel
    @FocusState private var isFocused: Bool

    // Local state for price input
    @State private var priceText: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
            // Price input
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                Text(fieldLabel)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Theme.Colors.secondaryText)

                HStack(spacing: Theme.Spacing.sm) {
                    Text("$")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(Theme.Colors.text)

                    TextField("0.00", text: $priceText)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(Theme.Colors.text)
                        .keyboardType(.decimalPad)
                        .focused($isFocused)
                        .onChange(of: priceText) { newValue in
                            // Format and validate input
                            let filtered = newValue.filter { "0123456789.".contains($0) }
                            if filtered != newValue {
                                priceText = filtered
                            }

                            // Update buffer
                            if let price = Double(filtered) {
                                viewModel.updateBuffer(key: bufferKey, value: price)
                            }
                        }
                }
                .padding(Theme.Spacing.md)
                .background(Theme.Colors.secondaryBackground)
                .cornerRadius(Theme.CornerRadius.md)

                Text(fieldDescription)
                    .font(.system(size: 13))
                    .foregroundColor(Theme.Colors.secondaryText)
            }

            // Additional options based on field type
            if field == .price {
                negotiableToggle
            }

            // Quick price suggestions
            if field == .price || field == .dailyRate {
                quickPriceSuggestions
            }
        }
        .onAppear {
            // Initialize from edit buffer
            if let price = viewModel.editBuffer[bufferKey] as? Double {
                priceText = String(format: "%.2f", price)
            } else if field == .price, let price = viewModel.listing.price {
                priceText = String(format: "%.2f", price)
            } else if field == .dailyRate, let rate = viewModel.listing.dailyRate {
                priceText = String(format: "%.2f", rate)
            }
            isFocused = true
        }
    }

    // MARK: - Field-Specific Properties

    private var fieldLabel: String {
        switch field {
        case .price: return "Sale Price"
        case .dailyRate: return "Daily Rental Rate"
        case .securityDeposit: return "Security Deposit"
        default: return "Price"
        }
    }

    private var fieldDescription: String {
        switch field {
        case .price: return "The full purchase price for this item"
        case .dailyRate: return "How much to charge per day for rental"
        case .securityDeposit: return "Refundable deposit to hold during rental (optional)"
        default: return ""
        }
    }

    private var bufferKey: String {
        switch field {
        case .price: return "price"
        case .dailyRate: return "dailyRate"
        case .securityDeposit: return "securityDeposit"
        default: return "price"
        }
    }

    // MARK: - Negotiable Toggle

    private var negotiableToggle: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Allow Offers")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Theme.Colors.text)

                    Text("Let buyers make offers below your asking price")
                        .font(.system(size: 14))
                        .foregroundColor(Theme.Colors.secondaryText)
                }

                Spacer()

                Toggle("", isOn: Binding(
                    get: { (viewModel.editBuffer["negotiable"] as? Bool) ?? viewModel.listing.isNegotiable },
                    set: { viewModel.updateBuffer(key: "negotiable", value: $0) }
                ))
                .labelsHidden()
                .tint(Theme.Colors.primary)
            }
            .padding(Theme.Spacing.md)
            .background(Theme.Colors.secondaryBackground)
            .cornerRadius(Theme.CornerRadius.md)
        }
    }

    // MARK: - Quick Price Suggestions

    private var quickPriceSuggestions: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Quick Suggestions")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Theme.Colors.secondaryText)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Theme.Spacing.sm) {
                    ForEach(priceSuggestions, id: \.self) { price in
                        Button(action: {
                            priceText = String(format: "%.2f", price)
                            viewModel.updateBuffer(key: bufferKey, value: price)
                        }) {
                            Text("$\(Int(price))")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(Theme.Colors.primary)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Theme.Colors.primary.opacity(0.1))
                                .cornerRadius(Theme.CornerRadius.sm)
                        }
                    }
                }
            }
        }
    }

    private var priceSuggestions: [Double] {
        if field == .dailyRate {
            return [5, 10, 15, 20, 25, 30, 40, 50, 75, 100]
        } else {
            return [10, 25, 50, 75, 100, 150, 200, 300, 500, 1000]
        }
    }
}
