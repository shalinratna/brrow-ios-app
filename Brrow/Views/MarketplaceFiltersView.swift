//
//  MarketplaceFiltersView.swift
//  Brrow
//
//  Advanced filters for marketplace
//

import SwiftUI

struct MarketplaceFiltersView: View {
    @Environment(\.presentationMode) var presentationMode
    @Binding var selectedCategory: String?
    let onApply: (MarketplaceFilters) -> Void
    
    // Filter states
    @State private var priceRange: ClosedRange<Double> = 0...500
    @State private var maxPrice: Double = 500
    @State private var distance: Double = 10
    @State private var availableOnly = false
    @State private var verifiedUsersOnly = false
    @State private var freeItemsOnly = false
    @State private var selectedConditions: Set<String> = []
    @State private var selectedSort: MarketplaceSortOption = .newest
    
    let conditions = ["New", "Like New", "Good", "Fair"]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Price Range
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Price Range", systemImage: "dollarsign.circle")
                            .font(.headline)
                        
                        VStack(spacing: 8) {
                            HStack {
                                Text("$\(Int(priceRange.lowerBound))")
                                Spacer()
                                Text("$\(Int(priceRange.upperBound))+")
                            }
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            
                            MarketplaceRangeSlider(
                                value: $priceRange,
                                bounds: 0...maxPrice,
                                step: 5
                            )
                            
                            Toggle("Free items only", isOn: $freeItemsOnly)
                                .toggleStyle(SwitchToggleStyle(tint: Theme.Colors.primary))
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                    
                    // Distance
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Distance", systemImage: "location.circle")
                            .font(.headline)
                        
                        VStack(spacing: 8) {
                            HStack {
                                Text("\(Int(distance)) miles")
                                    .font(.subheadline)
                                Spacer()
                                Text(distanceDescription)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            
                            Slider(value: $distance, in: 1...50, step: 1)
                                .accentColor(Theme.Colors.primary)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                    
                    // Category
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Category", systemImage: "square.grid.2x2")
                            .font(.headline)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                CategoryFilterChip(
                                    title: "All Categories",
                                    isSelected: selectedCategory == nil,
                                    action: { selectedCategory = nil }
                                )
                                
                                ForEach(ListingCategory.allCases, id: \.self) { category in
                                    CategoryFilterChip(
                                        title: category.displayName,
                                        isSelected: selectedCategory == category.rawValue,
                                        action: { selectedCategory = category.rawValue }
                                    )
                                }
                            }
                        }
                    }
                    
                    // Condition
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Condition", systemImage: "sparkles")
                            .font(.headline)
                        
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 12) {
                            ForEach(conditions, id: \.self) { condition in
                                ConditionChip(
                                    title: condition,
                                    isSelected: selectedConditions.contains(condition),
                                    action: {
                                        if selectedConditions.contains(condition) {
                                            selectedConditions.remove(condition)
                                        } else {
                                            selectedConditions.insert(condition)
                                        }
                                    }
                                )
                            }
                        }
                    }
                    
                    // Additional Filters
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Additional Filters", systemImage: "slider.horizontal.3")
                            .font(.headline)
                        
                        VStack(spacing: 16) {
                            Toggle("Available now only", isOn: $availableOnly)
                            Toggle("Verified users only", isOn: $verifiedUsersOnly)
                        }
                        .toggleStyle(SwitchToggleStyle(tint: Theme.Colors.primary))
                    }
                    
                    // Sort By
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Sort By", systemImage: "arrow.up.arrow.down")
                            .font(.headline)
                        
                        VStack(spacing: 0) {
                            SortOptionRow(
                                title: "Newest First",
                                icon: "clock",
                                isSelected: selectedSort == .newest,
                                action: { selectedSort = .newest }
                            )
                            
                            Divider()
                            
                            SortOptionRow(
                                title: "Price: Low to High",
                                icon: "arrow.up",
                                isSelected: selectedSort == .priceLowToHigh,
                                action: { selectedSort = .priceLowToHigh }
                            )
                            
                            Divider()
                            
                            SortOptionRow(
                                title: "Price: High to Low",
                                icon: "arrow.down",
                                isSelected: selectedSort == .priceHighToLow,
                                action: { selectedSort = .priceHighToLow }
                            )
                            
                            Divider()
                            
                            SortOptionRow(
                                title: "Distance",
                                icon: "location",
                                isSelected: selectedSort == .distance,
                                action: { selectedSort = .distance }
                            )
                            
                            Divider()
                            
                            SortOptionRow(
                                title: "Most Popular",
                                icon: "star",
                                isSelected: selectedSort == .popularity,
                                action: { selectedSort = .popularity }
                            )
                        }
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                }
                .padding()
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Reset") {
                        resetFilters()
                    }
                    .foregroundColor(Theme.Colors.primary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Apply") {
                        applyFilters()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(Theme.Colors.primary)
                }
            }
        }
    }
    
    private var distanceDescription: String {
        switch distance {
        case 1...5: return "Walking distance"
        case 6...10: return "Short drive"
        case 11...25: return "Within city"
        case 26...50: return "Extended area"
        default: return "Any distance"
        }
    }
    
    private func resetFilters() {
        priceRange = 0...500
        distance = 10
        availableOnly = false
        verifiedUsersOnly = false
        freeItemsOnly = false
        selectedConditions = []
        selectedSort = .newest
        selectedCategory = nil
    }
    
    private func applyFilters() {
        let filters = MarketplaceFilters(
            priceRange: freeItemsOnly ? 0...0 : priceRange,
            distance: distance,
            availability: availableOnly ? true : nil,
            condition: selectedConditions.isEmpty ? nil : selectedConditions.joined(separator: ","),
            sortBy: selectedSort
        )
        
        onApply(filters)
        presentationMode.wrappedValue.dismiss()
    }
}

// MARK: - Supporting Views

struct CategoryFilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Theme.Colors.primary : Color(.systemGray6))
                .foregroundColor(isSelected ? .white : Theme.Colors.text)
                .cornerRadius(20)
        }
    }
}

struct ConditionChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption)
                }
                Text(title)
                    .font(.subheadline)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
            .background(isSelected ? Theme.Colors.primary.opacity(0.1) : Color(.systemGray6))
            .foregroundColor(isSelected ? Theme.Colors.primary : Theme.Colors.text)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isSelected ? Theme.Colors.primary : Color.clear, lineWidth: 1)
            )
            .cornerRadius(20)
        }
    }
}

struct SortOptionRow: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(isSelected ? Theme.Colors.primary : .gray)
                    .frame(width: 24)
                
                Text(title)
                    .foregroundColor(Theme.Colors.text)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundColor(Theme.Colors.primary)
                }
            }
            .padding()
            .background(Color(.systemGray6))
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// Custom Range Slider
struct MarketplaceRangeSlider: View {
    @Binding var value: ClosedRange<Double>
    let bounds: ClosedRange<Double>
    let step: Double
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Track
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color(.systemGray4))
                    .frame(height: 4)
                
                // Fill
                RoundedRectangle(cornerRadius: 2)
                    .fill(Theme.Colors.primary)
                    .frame(
                        width: fillWidth(in: geometry),
                        height: 4
                    )
                    .offset(x: fillOffset(in: geometry))
                
                // Knobs
                HStack(spacing: 0) {
                    Circle()
                        .fill(Theme.Colors.primary)
                        .frame(width: 20, height: 20)
                        .offset(x: lowerKnobOffset(in: geometry))
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    updateLowerBound(with: value, in: geometry)
                                }
                        )
                    
                    Spacer()
                    
                    Circle()
                        .fill(Theme.Colors.primary)
                        .frame(width: 20, height: 20)
                        .offset(x: upperKnobOffset(in: geometry))
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    updateUpperBound(with: value, in: geometry)
                                }
                        )
                }
            }
        }
        .frame(height: 20)
    }
    
    private func fillWidth(in geometry: GeometryProxy) -> CGFloat {
        let totalWidth = geometry.size.width
        let range = bounds.upperBound - bounds.lowerBound
        let fillRange = value.upperBound - value.lowerBound
        return (fillRange / range) * totalWidth
    }
    
    private func fillOffset(in geometry: GeometryProxy) -> CGFloat {
        let totalWidth = geometry.size.width
        let range = bounds.upperBound - bounds.lowerBound
        let offset = value.lowerBound - bounds.lowerBound
        return (offset / range) * totalWidth
    }
    
    private func lowerKnobOffset(in geometry: GeometryProxy) -> CGFloat {
        let totalWidth = geometry.size.width - 20
        let range = bounds.upperBound - bounds.lowerBound
        let offset = value.lowerBound - bounds.lowerBound
        return (offset / range) * totalWidth
    }
    
    private func upperKnobOffset(in geometry: GeometryProxy) -> CGFloat {
        let totalWidth = geometry.size.width - 20
        let range = bounds.upperBound - bounds.lowerBound
        let offset = value.upperBound - bounds.lowerBound
        return (offset / range) * totalWidth - totalWidth
    }
    
    private func updateLowerBound(with drag: DragGesture.Value, in geometry: GeometryProxy) {
        let totalWidth = geometry.size.width
        let range = bounds.upperBound - bounds.lowerBound
        let location = drag.location.x / totalWidth
        let newValue = bounds.lowerBound + (location * range)
        let steppedValue = round(newValue / step) * step
        
        if steppedValue < value.upperBound && steppedValue >= bounds.lowerBound {
            value = steppedValue...value.upperBound
        }
    }
    
    private func updateUpperBound(with drag: DragGesture.Value, in geometry: GeometryProxy) {
        let totalWidth = geometry.size.width
        let range = bounds.upperBound - bounds.lowerBound
        let location = drag.location.x / totalWidth
        let newValue = bounds.lowerBound + (location * range)
        let steppedValue = round(newValue / step) * step
        
        if steppedValue > value.lowerBound && steppedValue <= bounds.upperBound {
            value = value.lowerBound...steppedValue
        }
    }
}

// MARK: - Preview

struct MarketplaceFiltersView_Previews: PreviewProvider {
    static var previews: some View {
        MarketplaceFiltersView(
            selectedCategory: .constant(nil),
            onApply: { _ in }
        )
    }
}