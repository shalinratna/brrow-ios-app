//
//  CreateSeekView.swift
//  Brrow
//
//  Create a "seek" request to find specific items
//

import SwiftUI
import CoreLocation

struct CreateSeekView: View {
    @Environment(\.dismiss) var dismiss
    @FocusState private var focusedField: Field?
    @State private var title = ""
    @State private var description = ""
    @State private var selectedCategory: String = "Other"
    @State private var maxBudget = ""
    @State private var searchRadius = 10.0
    @State private var urgency: UrgencyLevel = .normal
    @State private var isSubmitting = false
    
    enum Field: Hashable {
        case title
        case description
        case budget
    }
    
    enum UrgencyLevel: String, CaseIterable {
        case urgent = "Urgent"
        case normal = "Normal"
        case whenever = "Whenever"
        
        var color: Color {
            switch self {
            case .urgent: return .red
            case .normal: return Theme.Colors.primary
            case .whenever: return .blue
            }
        }
        
        var description: String {
            switch self {
            case .urgent: return "Need within 24 hours"
            case .normal: return "Need within a week"
            case .whenever: return "No rush"
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                ScrollViewReader { scrollProxy in
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(Theme.Colors.primary.opacity(0.1))
                                .frame(width: 100, height: 100)
                            
                            Image(systemName: "eye.fill")
                                .font(.system(size: 50))
                                .foregroundColor(Theme.Colors.primary)
                        }
                        
                        Text("Create a Seek")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(Theme.Colors.text)
                        
                        Text("Let neighbors know what you're looking for")
                            .font(.system(size: 16))
                            .foregroundColor(Theme.Colors.secondaryText)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    .padding(.top, 20)
                    
                    // Form
                    VStack(spacing: 20) {
                        // Title
                        VStack(alignment: .leading, spacing: 8) {
                            Label("What are you looking for?", systemImage: "magnifyingglass")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(Theme.Colors.text)
                            
                            TextField("e.g., Power drill for weekend project", text: $title)
                                .padding()
                                .background(Theme.Colors.secondaryBackground)
                                .cornerRadius(12)
                                .focused($focusedField, equals: .title)
                                .submitLabel(.next)
                                .onSubmit {
                                    focusedField = .description
                                }
                        }
                        
                        // Description
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Additional Details", systemImage: "text.alignleft")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(Theme.Colors.text)
                            
                            ZStack(alignment: .topLeading) {
                                if description.isEmpty {
                                    Text("Describe what you need, when you need it, and any specific requirements...")
                                        .foregroundColor(Theme.Colors.tertiaryText)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 20)
                                        .allowsHitTesting(false)
                                }
                                
                                TextEditor(text: $description)
                                    .frame(height: 100)
                                    .padding(12)
                                    .scrollContentBackground(.hidden)
                                    .background(Color.clear)
                                    .focused($focusedField, equals: .description)
                            }
                            .background(Theme.Colors.secondaryBackground)
                            .cornerRadius(12)
                        }
                        
                        // Category
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Category", systemImage: "square.grid.2x2")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(Theme.Colors.text)
                            
                            Menu {
                                ForEach(CategoryHelper.getPopularCategories(), id: \.self) { category in
                                    Button(category) {
                                        selectedCategory = category
                                    }
                                }
                            } label: {
                                HStack {
                                    Text(selectedCategory)
                                        .foregroundColor(Theme.Colors.text)
                                    Spacer()
                                    Image(systemName: "chevron.down")
                                        .foregroundColor(Theme.Colors.secondaryText)
                                }
                                .padding()
                                .background(Theme.Colors.secondaryBackground)
                                .cornerRadius(12)
                            }
                        }
                        
                        // Budget
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Maximum Budget", systemImage: "dollarsign.circle")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(Theme.Colors.text)
                            
                            HStack {
                                Text("$")
                                    .foregroundColor(Theme.Colors.secondaryText)
                                TextField("0", text: $maxBudget)
                                    .keyboardType(.decimalPad)
                                    .focused($focusedField, equals: .budget)
                            }
                            .padding()
                            .background(Theme.Colors.secondaryBackground)
                            .cornerRadius(12)
                        }
                        
                        // Search Radius
                        VStack(alignment: .leading, spacing: 12) {
                            Label("Search Radius", systemImage: "location.circle")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(Theme.Colors.text)
                            
                            VStack(spacing: 8) {
                                HStack {
                                    Text("\(Int(searchRadius)) miles")
                                        .font(.system(size: 18, weight: .medium))
                                        .foregroundColor(Theme.Colors.primary)
                                    Spacer()
                                }
                                
                                Slider(value: $searchRadius, in: 1...50, step: 1)
                                    .accentColor(Theme.Colors.primary)
                            }
                        }
                        
                        // Urgency
                        VStack(alignment: .leading, spacing: 12) {
                            Label("How urgent is this?", systemImage: "clock")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(Theme.Colors.text)
                            
                            HStack(spacing: 12) {
                                ForEach(UrgencyLevel.allCases, id: \.self) { level in
                                    UrgencyButton(
                                        level: level,
                                        isSelected: urgency == level,
                                        action: { urgency = level }
                                    )
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Tips Section
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Tips for Success", systemImage: "lightbulb")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Theme.Colors.accentOrange)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            TipRow(text: "Be specific about what you need")
                            TipRow(text: "Include your timeline and flexibility")
                            TipRow(text: "Set a reasonable budget range")
                            TipRow(text: "Mention if you can pick up or need delivery")
                        }
                    }
                    .padding()
                    .background(Theme.Colors.accentOrange.opacity(0.1))
                    .cornerRadius(12)
                    .padding(.horizontal, 20)
                    
                    // Submit Button
                    Button(action: submitSeek) {
                        HStack {
                            if isSubmitting {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            } else {
                                Text("Post Seek")
                                    .font(.system(size: 18, weight: .semibold))
                            }
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(Theme.Colors.primary)
                        .cornerRadius(27)
                        .padding(.horizontal, 20)
                    }
                    .disabled(title.isEmpty || isSubmitting)
                }
                .padding(.bottom, 40)
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        focusedField = nil
                        dismiss()
                    }
                    .foregroundColor(Theme.Colors.primary)
                }
                ToolbarItem(placement: .keyboard) {
                    HStack {
                        Spacer()
                        Button("Done") {
                            focusedField = nil
                        }
                        .foregroundColor(Theme.Colors.primary)
                    }
                }
            }
        }
    }
    
    private func submitSeek() {
        // Dismiss keyboard first
        focusedField = nil
        
        // Validate input
        guard !title.isEmpty else {
            return
        }
        
        isSubmitting = true
        
        Task {
            do {
                // Get current location and address from LocationManager
                let locationManager = LocationManager.shared
                let latitude: Double
                let longitude: Double
                let address: String
                let city: String
                let state: String
                let zipCode: String
                
                if let currentLocation = locationManager.currentLocation {
                    latitude = currentLocation.coordinate.latitude
                    longitude = currentLocation.coordinate.longitude
                    address = locationManager.address.isEmpty ? "Unknown Address" : locationManager.address
                    city = locationManager.city.isEmpty ? "San Francisco" : locationManager.city
                    state = locationManager.state.isEmpty ? "CA" : locationManager.state
                    zipCode = locationManager.zipCode.isEmpty ? "94102" : locationManager.zipCode
                } else {
                    // Default to San Francisco
                    latitude = 37.7749
                    longitude = -122.4194
                    address = "Market Street"
                    city = "San Francisco"
                    state = "CA"
                    zipCode = "94102"
                }
                
                // Create location object
                let location = Location(
                    address: address,
                    city: city,
                    state: state,
                    zipCode: zipCode,
                    country: "US",
                    latitude: latitude,
                    longitude: longitude
                )
                
                // Create seek request
                let seekRequest = CreateSeekRequest(
                    title: title,
                    description: description,
                    category: selectedCategory,
                    maxPrice: maxBudget.isEmpty ? 0 : Double(maxBudget) ?? 0,
                    radius: searchRadius,
                    location: location
                )
                
                // Call API to create seek
                _ = try await APIClient.shared.createSeek(seekRequest)
                
                await MainActor.run {
                    isSubmitting = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isSubmitting = false
                    // Handle error silently to prevent crash
                    print("Error creating seek: \(error)")
                }
            }
        }
    }
}

// MARK: - Supporting Views
struct UrgencyButton: View {
    let level: CreateSeekView.UrgencyLevel
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(level.rawValue)
                    .font(.system(size: 14, weight: .semibold))
                Text(level.description)
                    .font(.system(size: 11))
                    .foregroundColor(isSelected ? level.color.opacity(0.8) : Theme.Colors.secondaryText)
            }
            .foregroundColor(isSelected ? .white : Theme.Colors.text)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(isSelected ? level.color : Theme.Colors.secondaryBackground)
            .cornerRadius(12)
        }
    }
}

struct TipRow: View {
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 14))
                .foregroundColor(Theme.Colors.accentOrange)
            Text(text)
                .font(.system(size: 14))
                .foregroundColor(Theme.Colors.text)
        }
    }
}

// MARK: - TextEditor Placeholder Extension
extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .topLeading,
        @ViewBuilder placeholder: () -> Content) -> some View {

        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}