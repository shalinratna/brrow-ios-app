//
//  AdvancedFiltersSheet.swift
//  Brrow
//
//  Comprehensive search filters with price range slider and all options
//

import SwiftUI
import CoreLocation

struct AdvancedFiltersSheet: View {
    @Binding var filters: SearchFilters
    @Environment(\.dismiss) private var dismiss
    let onApply: () -> Void
    
    // Local state for editing
    @State private var localFilters: SearchFilters
    @State private var showingLocationPicker = false
    @State private var selectedCategories: Set<String> = []
    
    // Price range slider state
    @State private var minPrice: Double = 0
    @State private var maxPrice: Double = 1000
    @State private var isDraggingPrice = false
    
    init(filters: Binding<SearchFilters>, onApply: @escaping () -> Void) {
        self._filters = filters
        self.onApply = onApply
        self._localFilters = State(initialValue: filters.wrappedValue)
        self._minPrice = State(initialValue: filters.wrappedValue.priceRange.lowerBound)
        self._maxPrice = State(initialValue: filters.wrappedValue.priceRange.upperBound)
        self._selectedCategories = State(initialValue: filters.wrappedValue.categories)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    // Categories Section
                    categoriesSection
                    
                    Divider()
                        .padding(.vertical, Theme.Spacing.md)
                    
                    // Price Range Section with Slider
                    priceRangeSection
                    
                    Divider()
                        .padding(.vertical, Theme.Spacing.md)
                    
                    // Distance Section
                    distanceSection
                    
                    Divider()
                        .padding(.vertical, Theme.Spacing.md)
                    
                    // Condition Section
                    conditionSection
                    
                    Divider()
                        .padding(.vertical, Theme.Spacing.md)
                    
                    // Availability Section
                    availabilitySection
                    
                    Divider()
                        .padding(.vertical, Theme.Spacing.md)
                    
                    // Additional Filters
                    additionalFiltersSection
                    
                    Divider()
                        .padding(.vertical, Theme.Spacing.md)
                    
                    // Sort By Section
                    sortBySection
                    
                    // Bottom padding for button
                    Color.clear.frame(height: 100)
                }
                .padding(.horizontal, Theme.Spacing.lg)
                .padding(.top, Theme.Spacing.md)
            }
            .background(Theme.Colors.background)
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(Theme.Colors.primary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Reset") {
                        resetFilters()
                    }
                    .foregroundColor(Theme.Colors.accent)
                }
            }
            .overlay(
                VStack {
                    Spacer()
                    applyButton
                }
            )
        }
    }
    
    // MARK: - Categories Section
    private var categoriesSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("Categories")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(Theme.Colors.text)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(ItemCategory.allCases, id: \.rawValue) { category in
                    CategorySelectionChip(
                        category: category,
                        isSelected: selectedCategories.contains(category.rawValue)
                    ) {
                        if selectedCategories.contains(category.rawValue) {
                            selectedCategories.remove(category.rawValue)
                        } else {
                            selectedCategories.insert(category.rawValue)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Price Range Section with Slider
    private var priceRangeSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            HStack {
                Text("Price Range")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Theme.Colors.text)
                
                Spacer()
                
                Text("$\(Int(minPrice)) - $\(Int(maxPrice))")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Theme.Colors.primary)
            }
            
            // Custom Range Slider
            VStack(spacing: Theme.Spacing.sm) {
                // Price inputs
                HStack(spacing: Theme.Spacing.md) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Min")
                            .font(.system(size: 12))
                            .foregroundColor(Theme.Colors.secondaryText)
                        
                        HStack {
                            Text("$")
                                .foregroundColor(Theme.Colors.secondaryText)
                            TextField("0", value: $minPrice, format: .number)
                                .keyboardType(.numberPad)
                                .frame(width: 80)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Theme.Colors.secondaryBackground)
                        .cornerRadius(8)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Max")
                            .font(.system(size: 12))
                            .foregroundColor(Theme.Colors.secondaryText)
                        
                        HStack {
                            Text("$")
                                .foregroundColor(Theme.Colors.secondaryText)
                            TextField("1000", value: $maxPrice, format: .number)
                                .keyboardType(.numberPad)
                                .frame(width: 80)
                                .multilineTextAlignment(.trailing)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Theme.Colors.secondaryBackground)
                        .cornerRadius(8)
                    }
                }
                
                // Range Slider
                RangeSlider(
                    minValue: $minPrice,
                    maxValue: $maxPrice,
                    range: 0...5000,
                    isDragging: $isDraggingPrice
                )
                .padding(.vertical, Theme.Spacing.sm)
                
                // Quick price options
                HStack(spacing: 8) {
                    QuickPriceButton(title: "Under $25", action: {
                        minPrice = 0
                        maxPrice = 25
                    })
                    
                    QuickPriceButton(title: "Under $50", action: {
                        minPrice = 0
                        maxPrice = 50
                    })
                    
                    QuickPriceButton(title: "$50-$100", action: {
                        minPrice = 50
                        maxPrice = 100
                    })
                    
                    QuickPriceButton(title: "$100+", action: {
                        minPrice = 100
                        maxPrice = 5000
                    })
                }
                
                // Free items toggle
                Toggle(isOn: $localFilters.freeItemsOnly) {
                    Label("Free items only", systemImage: "gift")
                        .font(.system(size: 15, weight: .medium))
                }
                .tint(Theme.Colors.primary)
                .padding(.top, 8)
            }
        }
    }
    
    // MARK: - Distance Section
    private var distanceSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            HStack {
                Text("Distance")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Theme.Colors.text)
                
                Spacer()
                
                Text("\(Int(localFilters.distance)) miles")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Theme.Colors.primary)
            }
            
            Slider(value: $localFilters.distance, in: 1...100, step: 1)
                .tint(Theme.Colors.primary)
            
            HStack {
                Text("1 mi")
                    .font(.system(size: 12))
                    .foregroundColor(Theme.Colors.secondaryText)
                
                Spacer()
                
                Text("100 mi")
                    .font(.system(size: 12))
                    .foregroundColor(Theme.Colors.secondaryText)
            }
            
            // Location picker
            Button(action: { showingLocationPicker = true }) {
                HStack {
                    Image(systemName: "location")
                    Text("Change search location")
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14))
                }
                .foregroundColor(Theme.Colors.primary)
                .padding()
                .background(Theme.Colors.primary.opacity(0.1))
                .cornerRadius(12)
            }
        }
    }
    
    // MARK: - Condition Section
    private var conditionSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("Condition")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(Theme.Colors.text)
            
            ForEach(ItemCondition.allCases, id: \.self) { condition in
                RadioButton(
                    title: condition.displayName,
                    subtitle: "",
                    isSelected: localFilters.condition == condition,
                    action: {
                        localFilters.condition = condition == .any ? nil : condition
                    }
                )
            }
        }
    }
    
    // MARK: - Availability Section
    private var availabilitySection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("Availability")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(Theme.Colors.text)
            
            ForEach(SearchFilters.AvailabilityFilter.allCases, id: \.self) { availability in
                RadioButton(
                    title: availability.displayName,
                    subtitle: "",
                    isSelected: localFilters.availability == availability,
                    action: {
                        localFilters.availability = availability
                    }
                )
            }
        }
    }
    
    // MARK: - Additional Filters Section
    private var additionalFiltersSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("Additional Filters")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(Theme.Colors.text)
            
            Toggle(isOn: $localFilters.verifiedSellersOnly) {
                Label("Verified sellers only", systemImage: "checkmark.seal")
                    .font(.system(size: 15, weight: .medium))
            }
            .tint(Theme.Colors.primary)
            
            Toggle(isOn: $localFilters.deliveryAvailable) {
                Label("Delivery available", systemImage: "shippingbox")
                    .font(.system(size: 15, weight: .medium))
            }
            .tint(Theme.Colors.primary)
            
            Toggle(isOn: $localFilters.instantBooking) {
                Label("Instant booking", systemImage: "bolt")
                    .font(.system(size: 15, weight: .medium))
            }
            .tint(Theme.Colors.primary)
            
            Toggle(isOn: $localFilters.includeGarageSales) {
                Label("Include garage sales", systemImage: "house")
                    .font(.system(size: 15, weight: .medium))
            }
            .tint(Theme.Colors.primary)
        }
    }
    
    // MARK: - Sort By Section
    private var sortBySection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("Sort By")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(Theme.Colors.text)
            
            ForEach(SearchFilters.SortOption.allCases, id: \.self) { option in
                RadioButton(
                    title: option.displayName,
                    subtitle: "",
                    isSelected: localFilters.sortBy == option,
                    action: {
                        localFilters.sortBy = option
                    }
                )
            }
        }
    }
    
    // MARK: - Apply Button
    private var applyButton: some View {
        VStack(spacing: 0) {
            Divider()
            
            HStack(spacing: 12) {
                Button(action: {
                    resetFilters()
                }) {
                    Text("Clear All")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Theme.Colors.primary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Theme.Colors.primary, lineWidth: 2)
                        )
                }
                .frame(maxWidth: .infinity)
                
                Button(action: {
                    applyFilters()
                }) {
                    HStack {
                        Text("Apply Filters")
                        if getActiveFilterCount() > 0 {
                            Text("(\(getActiveFilterCount()))")
                        }
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Theme.Colors.primary)
                    .cornerRadius(12)
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.vertical, Theme.Spacing.md)
            .background(
                Theme.Colors.background
                    .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: -5)
            )
        }
    }
    
    // MARK: - Helper Methods
    private func resetFilters() {
        localFilters = SearchFilters()
        selectedCategories = []
        minPrice = 0
        maxPrice = 1000
    }
    
    private func applyFilters() {
        localFilters.categories = selectedCategories
        localFilters.priceRange = minPrice...maxPrice
        filters = localFilters
        onApply()
        dismiss()
    }
    
    private func getActiveFilterCount() -> Int {
        var count = 0
        if !selectedCategories.isEmpty { count += 1 }
        if localFilters.priceRange != 0...1000 { count += 1 }
        if localFilters.distance != 10.0 { count += 1 }
        if localFilters.condition != nil { count += 1 }
        if localFilters.availability != .all { count += 1 }
        if localFilters.verifiedSellersOnly { count += 1 }
        if localFilters.freeItemsOnly { count += 1 }
        if localFilters.deliveryAvailable { count += 1 }
        if localFilters.instantBooking { count += 1 }
        if !localFilters.includeGarageSales { count += 1 }
        if localFilters.sortBy != .relevance { count += 1 }
        return count
    }
}

// MARK: - Supporting Views

struct CategorySelectionChip: View {
    let category: ItemCategory
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: category.icon)
                    .font(.system(size: 20))
                    .foregroundColor(isSelected ? .white : Theme.Colors.text)
                
                Text(category.displayName)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(isSelected ? .white : Theme.Colors.text)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 70)
            .background(isSelected ? Theme.Colors.primary : Theme.Colors.secondaryBackground)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Theme.Colors.primary : Color.clear, lineWidth: 2)
            )
        }
    }
}


struct QuickPriceButton: View {
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Theme.Colors.primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Theme.Colors.primary.opacity(0.1))
                .cornerRadius(8)
        }
    }
}

// MARK: - Custom Range Slider
struct RangeSlider: View {
    @Binding var minValue: Double
    @Binding var maxValue: Double
    let range: ClosedRange<Double>
    @Binding var isDragging: Bool
    
    @State private var width: CGFloat = 0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background track
                RoundedRectangle(cornerRadius: 4)
                    .fill(Theme.Colors.secondaryBackground)
                    .frame(height: 8)
                
                // Selected range
                RoundedRectangle(cornerRadius: 4)
                    .fill(Theme.Colors.primary)
                    .frame(
                        width: max(0, (maxValue - minValue) / (range.upperBound - range.lowerBound) * geometry.size.width),
                        height: 8
                    )
                    .offset(x: (minValue - range.lowerBound) / (range.upperBound - range.lowerBound) * geometry.size.width)
                
                // Min thumb
                Circle()
                    .fill(Theme.Colors.primary)
                    .frame(width: 24, height: 24)
                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                    .offset(x: (minValue - range.lowerBound) / (range.upperBound - range.lowerBound) * geometry.size.width - 12)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                isDragging = true
                                let newValue = (value.location.x / geometry.size.width) * (range.upperBound - range.lowerBound) + range.lowerBound
                                minValue = min(max(range.lowerBound, newValue), maxValue - 10)
                            }
                            .onEnded { _ in
                                isDragging = false
                            }
                    )
                
                // Max thumb
                Circle()
                    .fill(Theme.Colors.primary)
                    .frame(width: 24, height: 24)
                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                    .offset(x: (maxValue - range.lowerBound) / (range.upperBound - range.lowerBound) * geometry.size.width - 12)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                isDragging = true
                                let newValue = (value.location.x / geometry.size.width) * (range.upperBound - range.lowerBound) + range.lowerBound
                                maxValue = max(min(range.upperBound, newValue), minValue + 10)
                            }
                            .onEnded { _ in
                                isDragging = false
                            }
                    )
            }
            .onAppear {
                width = geometry.size.width
            }
        }
        .frame(height: 24)
    }
}

enum ItemCategory: String, CaseIterable {
    case electronics = "Electronics"
    case furniture = "Furniture"
    case tools = "Tools"
    case sports = "Sports"
    case books = "Books"
    case clothing = "Clothing"
    case toys = "Toys"
    case garden = "Garden"
    case automotive = "Automotive"
    
    var displayName: String { rawValue }
    
    var icon: String {
        switch self {
        case .electronics: return "tv"
        case .furniture: return "sofa"
        case .tools: return "wrench"
        case .sports: return "sportscourt"
        case .books: return "book"
        case .clothing: return "tshirt"
        case .toys: return "teddybear"
        case .garden: return "leaf"
        case .automotive: return "car"
        }
    }
}

#Preview {
    AdvancedFiltersSheet(filters: .constant(SearchFilters())) {
        print("Filters applied")
    }
}