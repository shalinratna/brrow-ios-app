//
//  AdvancedFiltersView.swift
//  Brrow
//
//  Advanced Search Filters
//

import SwiftUI

struct AdvancedFiltersView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var selectedCategory = "All"
    @State private var priceRange = 0.0...100.0
    @State private var distance = 5.0
    @State private var availabilityDate = Date()
    @State private var isInstantBooking = false
    @State private var hasImages = false
    @State private var minRating = 4.0
    
    private var categories: [String] {
        ["All"] + CategoryHelper.getAllCategories()
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                    // Category Section
                    filterSection(title: "Category") {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                            ForEach(categories, id: \.self) { category in
                                Button(action: {
                                    selectedCategory = category
                                }) {
                                    Text(category)
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(selectedCategory == category ? .white : Theme.Colors.primary)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .background(
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(selectedCategory == category ? Theme.Colors.primary : Theme.Colors.primary.opacity(0.1))
                                        )
                                }
                            }
                        }
                    }
                    
                    // Price Range Section
                    filterSection(title: "Price Range") {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("$\(Int(priceRange.lowerBound))")
                                    .font(.system(size: 14, weight: .semibold))
                                Spacer()
                                Text("$\(Int(priceRange.upperBound))")
                                    .font(.system(size: 14, weight: .semibold))
                            }
                            
                            // Custom range slider would go here
                            Slider(value: Binding(
                                get: { priceRange.upperBound },
                                set: { priceRange = priceRange.lowerBound...$0 }
                            ), in: 0...200)
                                .accentColor(Theme.Colors.primary)
                        }
                    }
                    
                    // Distance Section
                    filterSection(title: "Distance") {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Within \(Int(distance)) miles")
                                    .font(.system(size: 14, weight: .semibold))
                                Spacer()
                            }
                            
                            Slider(value: $distance, in: 1...50)
                                .accentColor(Theme.Colors.primary)
                        }
                    }
                    
                    // Availability Section
                    filterSection(title: "Availability") {
                        VStack(alignment: .leading, spacing: 12) {
                            DatePicker("Available from", selection: $availabilityDate, displayedComponents: .date)
                                .datePickerStyle(CompactDatePickerStyle())
                            
                            Toggle("Instant booking only", isOn: $isInstantBooking)
                                .toggleStyle(SwitchToggleStyle(tint: Theme.Colors.primary))
                        }
                    }
                    
                    // Additional Filters
                    filterSection(title: "Additional Filters") {
                        VStack(spacing: 12) {
                            Toggle("Has photos", isOn: $hasImages)
                                .toggleStyle(SwitchToggleStyle(tint: Theme.Colors.primary))
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Minimum rating: \(Int(minRating)) stars")
                                    .font(.system(size: 14, weight: .semibold))
                                
                                Slider(value: $minRating, in: 1...5, step: 1)
                                    .accentColor(Theme.Colors.primary)
                            }
                        }
                    }
                }
                .padding(Theme.Spacing.lg)
            }
            .background(Theme.Colors.background)
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
                        presentationMode.wrappedValue.dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    private func filterSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text(title)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(Theme.Colors.text)
            
            content()
        }
        .padding(Theme.Spacing.lg)
        .background(Theme.Colors.surface)
        .cornerRadius(Theme.CornerRadius.card)
    }
    
    private func applyFilters() {
        // Apply filter logic here
        print("Applying filters: category=\(selectedCategory), price=\(priceRange), distance=\(distance)")
    }
}

#Preview {
    AdvancedFiltersView()
}