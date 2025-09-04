//
//  FiltersView.swift
//  Brrow
//
//  Created by Shalin Ratna on 7/16/25.
//

import SwiftUI

struct FiltersView: View {
    @ObservedObject var viewModel: HomeViewModel
    @Environment(\.presentationMode) var presentationMode
    
    @State private var tempCategory: String
    @State private var tempPriceRange: ClosedRange<Double>
    @State private var tempMaxDistance: Double
    @State private var tempListingType: String
    
    init(viewModel: HomeViewModel) {
        self.viewModel = viewModel
        self._tempCategory = State(initialValue: viewModel.selectedCategory)
        self._tempPriceRange = State(initialValue: viewModel.priceRange)
        self._tempMaxDistance = State(initialValue: viewModel.maxDistance)
        self._tempListingType = State(initialValue: viewModel.listingType)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                    // Category Filter
                    categorySection
                    
                    // Price Range Filter
                    priceRangeSection
                    
                    // Distance Filter
                    distanceSection
                    
                    // Listing Type Filter
                    listingTypeSection
                    
                    Spacer()
                }
                .padding(Theme.Spacing.md)
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Apply") {
                        applyFilters()
                    }
                    .foregroundColor(Theme.Colors.primary)
                }
            }
        }
    }
    
    // MARK: - Category Section
    private var categorySection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("Category")
                .font(Theme.Typography.headline)
                .fontWeight(.semibold)
                .foregroundColor(Theme.Colors.text)
            
            let categories = ["All"] + CategoryHelper.getAllCategories()
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: Theme.Spacing.sm) {
                ForEach(categories, id: \.self) { category in
                    Button(action: {
                        tempCategory = category
                    }) {
                        Text(category)
                            .font(Theme.Typography.callout)
                            .foregroundColor(tempCategory == category ? .white : Theme.Colors.text)
                            .padding(.horizontal, Theme.Spacing.md)
                            .padding(.vertical, Theme.Spacing.sm)
                            .background(tempCategory == category ? Theme.Colors.primary : Theme.Colors.cardBackground)
                            .cornerRadius(Theme.CornerRadius.md)
                            .overlay(
                                RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                                    .stroke(tempCategory == category ? Theme.Colors.primary : Theme.Colors.divider, lineWidth: 1)
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .cardStyle()
    }
    
    // MARK: - Price Range Section
    private var priceRangeSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("Price Range")
                .font(Theme.Typography.headline)
                .fontWeight(.semibold)
                .foregroundColor(Theme.Colors.text)
            
            VStack(spacing: Theme.Spacing.sm) {
                HStack {
                    Text("$\(Int(tempPriceRange.lowerBound))")
                        .font(Theme.Typography.callout)
                        .foregroundColor(Theme.Colors.secondaryText)
                    
                    Spacer()
                    
                    Text("$\(Int(tempPriceRange.upperBound))")
                        .font(Theme.Typography.callout)
                        .foregroundColor(Theme.Colors.secondaryText)
                }
                
                FiltersRangeSlider(
                    range: $tempPriceRange,
                    bounds: 0...1000,
                    step: 10
                )
                .accentColor(Theme.Colors.primary)
            }
        }
        .cardStyle()
    }
    
    // MARK: - Distance Section
    private var distanceSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("Maximum Distance")
                .font(Theme.Typography.headline)
                .fontWeight(.semibold)
                .foregroundColor(Theme.Colors.text)
            
            VStack(spacing: Theme.Spacing.sm) {
                HStack {
                    Text("Within \(String(format: "%.1f", tempMaxDistance)) km")
                        .font(Theme.Typography.callout)
                        .foregroundColor(Theme.Colors.secondaryText)
                    
                    Spacer()
                }
                
                Slider(value: $tempMaxDistance, in: 1...50, step: 1)
                    .accentColor(Theme.Colors.primary)
            }
        }
        .cardStyle()
    }
    
    // MARK: - Listing Type Section
    private var listingTypeSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("Listing Type")
                .font(Theme.Typography.headline)
                .fontWeight(.semibold)
                .foregroundColor(Theme.Colors.text)
            
            let types = ["All", "for_sale", "for_rent", "borrow", "giveaway"]
            let typeLabels = ["All", "For Sale", "For Rent", "Borrow", "Giveaway"]
            
            VStack(spacing: Theme.Spacing.sm) {
                ForEach(Array(zip(types, typeLabels)), id: \.0) { type, label in
                    Button(action: {
                        tempListingType = type
                    }) {
                        HStack {
                            Image(systemName: tempListingType == type ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(tempListingType == type ? Theme.Colors.primary : Theme.Colors.secondaryText)
                            
                            Text(label)
                                .font(Theme.Typography.callout)
                                .foregroundColor(Theme.Colors.text)
                            
                            Spacer()
                        }
                        .padding(.vertical, Theme.Spacing.xs)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .cardStyle()
    }
    
    // MARK: - Actions
    private func applyFilters() {
        viewModel.selectedCategory = tempCategory
        viewModel.priceRange = tempPriceRange
        viewModel.maxDistance = tempMaxDistance
        viewModel.listingType = tempListingType
        
        presentationMode.wrappedValue.dismiss()
    }
}

// MARK: - Range Slider Component
struct FiltersRangeSlider: View {
    @Binding var range: ClosedRange<Double>
    let bounds: ClosedRange<Double>
    let step: Double
    
    var body: some View {
        // Simplified range slider - in production, you'd use a proper range slider component
        VStack {
            HStack {
                Text("Min: $\(Int(range.lowerBound))")
                    .font(Theme.Typography.caption)
                
                Spacer()
                
                Text("Max: $\(Int(range.upperBound))")
                    .font(Theme.Typography.caption)
            }
            .foregroundColor(Theme.Colors.secondaryText)
            
            // TODO: Implement proper range slider
            Slider(value: Binding(
                get: { range.upperBound },
                set: { range = range.lowerBound...$0 }
            ), in: bounds, step: step)
            .accentColor(Theme.Colors.primary)
        }
    }
}

struct FiltersView_Previews: PreviewProvider {
    static var previews: some View {
        FiltersView(viewModel: HomeViewModel())
    }
}