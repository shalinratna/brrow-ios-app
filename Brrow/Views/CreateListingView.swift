//
//  CreateListingView.swift
//  Brrow
//
//  Created by Shalin Ratna on 7/16/25.
//

import SwiftUI
import PhotosUI

struct CreateListingView: View {
    @StateObject private var viewModel = CreateListingViewModel()
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                    // Image Selection
                    imageSelectionSection
                    
                    // Basic Info
                    basicInfoSection
                    
                    // Category and Type
                    categoryTypeSection
                    
                    // Pricing
                    pricingSection
                    
                    // Location
                    locationSection
                    
                    // Additional Details
                    additionalDetailsSection
                    
                    Spacer()
                }
                .padding(Theme.Spacing.md)
            }
            .navigationTitle("Create Listing")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Post") {
                        viewModel.createListing()
                    }
                    .foregroundColor(Theme.Colors.primary)
                    .disabled(!viewModel.canSubmit)
                }
            }
            .alert("Error", isPresented: Binding(
                get: { !viewModel.errorMessage.isEmpty },
                set: { _ in viewModel.errorMessage = "" }
            )) {
                Button("OK") {
                    viewModel.errorMessage = ""
                }
            } message: {
                Text(viewModel.errorMessage)
            }
            .alert("Success", isPresented: $viewModel.showSuccessAlert) {
                Button("View Listing") {
                    viewModel.showSuccessAlert = false
                    presentationMode.wrappedValue.dismiss()
                    // Navigate to marketplace after dismissal
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        TabSelectionManager.shared.selectedTab = 0 // Marketplace tab
                    }
                }
                Button("Create Another") {
                    viewModel.showSuccessAlert = false
                    viewModel.resetForm()
                }
            } message: {
                Text("Your listing has been posted successfully!")
            }
        }
    }
    
    // MARK: - Image Selection Section
    private var imageSelectionSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("Photos")
                .font(Theme.Typography.headline)
                .fontWeight(.semibold)
                .foregroundColor(Theme.Colors.text)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Theme.Spacing.sm) {
                    // Add Photo Button
                    PhotosPicker(selection: $viewModel.selectedPhotos, maxSelectionCount: 10, matching: .images) {
                        VStack {
                            Image(systemName: "plus")
                                .font(.headline)
                                .foregroundColor(Theme.Colors.primary)
                            
                            Text("Add Photo")
                                .font(Theme.Typography.caption)
                                .foregroundColor(Theme.Colors.primary)
                        }
                        .frame(width: 100, height: 100)
                        .background(Theme.Colors.primary.opacity(0.1))
                        .cornerRadius(Theme.CornerRadius.md)
                        .overlay(
                            RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                                .stroke(Theme.Colors.primary, style: StrokeStyle(lineWidth: 1, dash: [5]))
                        )
                    }
                    
                    // Selected Photos
                    ForEach(viewModel.selectedImages.indices, id: \.self) { index in
                        ZStack(alignment: .topTrailing) {
                            Image(uiImage: viewModel.selectedImages[index])
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 100, height: 100)
                                .clipped()
                                .cornerRadius(Theme.CornerRadius.md)
                            
                            Button(action: {
                                viewModel.removeImage(at: index)
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.white)
                                    .background(Color.black.opacity(0.6))
                                    .clipShape(Circle())
                            }
                            .padding(Theme.Spacing.xs)
                        }
                    }
                }
                .padding(.horizontal, Theme.Spacing.xs)
            }
            
            Text("Add up to 10 photos to showcase your item")
                .font(Theme.Typography.caption)
                .foregroundColor(Theme.Colors.secondaryText)
        }
        .cardStyle()
    }
    
    // MARK: - Basic Info Section
    private var basicInfoSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("Basic Information")
                .font(Theme.Typography.headline)
                .fontWeight(.semibold)
                .foregroundColor(Theme.Colors.text)
            
            VStack(spacing: Theme.Spacing.md) {
                // Title with validation
                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    CustomTextField(
                        title: "Title",
                        text: $viewModel.title,
                        placeholder: "What are you sharing?",
                        keyboardType: .default,
                        isValid: viewModel.isTitleValid
                    )
                    
                    if let errorMessage = viewModel.titleValidationMessage {
                        HStack {
                            Image(systemName: "exclamationmark.circle.fill")
                                .font(.caption)
                                .foregroundColor(.red)
                            Text(errorMessage)
                                .font(Theme.Typography.caption)
                                .foregroundColor(.red)
                        }
                        .transition(.scale.combined(with: .opacity))
                    }
                }
                
                // Description with validation
                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    Text("Description")
                        .font(Theme.Typography.callout)
                        .fontWeight(.medium)
                        .foregroundColor(Theme.Colors.text)
                    
                    TextEditor(text: $viewModel.description)
                        .font(Theme.Typography.body)
                        .frame(minHeight: 100)
                        .padding(Theme.Spacing.sm)
                        .background(Theme.Colors.cardBackground)
                        .cornerRadius(Theme.CornerRadius.md)
                        .overlay(
                            RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                                .stroke(viewModel.isDescriptionValid ? Theme.Colors.success : Theme.Colors.divider, lineWidth: 1)
                        )
                    
                    if let errorMessage = viewModel.descriptionValidationMessage {
                        HStack {
                            Image(systemName: "exclamationmark.circle.fill")
                                .font(.caption)
                                .foregroundColor(.red)
                            Text(errorMessage)
                                .font(Theme.Typography.caption)
                                .foregroundColor(.red)
                        }
                        .transition(.scale.combined(with: .opacity))
                    }
                }
            }
        }
        .cardStyle()
    }
    
    // MARK: - Category and Type Section
    private var categoryTypeSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("Category & Type")
                .font(Theme.Typography.headline)
                .fontWeight(.semibold)
                .foregroundColor(Theme.Colors.text)
            
            VStack(spacing: Theme.Spacing.md) {
                // Category Selection
                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    Text("Category")
                        .font(Theme.Typography.callout)
                        .fontWeight(.medium)
                        .foregroundColor(Theme.Colors.text)
                    
                    Menu {
                        ForEach(viewModel.categories, id: \.self) { category in
                            Button(category) {
                                viewModel.selectedCategory = category
                            }
                        }
                    } label: {
                        HStack {
                            Text(viewModel.selectedCategory.isEmpty ? "Select Category" : viewModel.selectedCategory)
                                .font(Theme.Typography.body)
                                .foregroundColor(viewModel.selectedCategory.isEmpty ? Theme.Colors.secondaryText : Theme.Colors.text)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.down")
                                .foregroundColor(Theme.Colors.secondaryText)
                        }
                        .padding(Theme.Spacing.md)
                        .background(Theme.Colors.cardBackground)
                        .cornerRadius(Theme.CornerRadius.md)
                        .overlay(
                            RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                                .stroke(Theme.Colors.divider, lineWidth: 1)
                        )
                    }
                }
                
                // Type Selection
                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    Text("Listing Type")
                        .font(Theme.Typography.callout)
                        .fontWeight(.medium)
                        .foregroundColor(Theme.Colors.text)
                    
                    VStack(spacing: Theme.Spacing.sm) {
                        ForEach(viewModel.listingTypes, id: \.key) { type in
                            Button(action: {
                                viewModel.selectedType = type.key
                            }) {
                                HStack {
                                    Image(systemName: viewModel.selectedType == type.key ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(viewModel.selectedType == type.key ? Theme.Colors.primary : Theme.Colors.secondaryText)
                                    
                                    VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                                        Text(type.value.title)
                                            .font(Theme.Typography.callout)
                                            .fontWeight(.medium)
                                            .foregroundColor(Theme.Colors.text)
                                        
                                        Text(type.value.description)
                                            .font(Theme.Typography.caption)
                                            .foregroundColor(Theme.Colors.secondaryText)
                                    }
                                    
                                    Spacer()
                                }
                                .padding(.vertical, Theme.Spacing.xs)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
            }
        }
        .cardStyle()
    }
    
    // MARK: - Pricing Section
    private var pricingSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("Pricing")
                .font(Theme.Typography.headline)
                .fontWeight(.semibold)
                .foregroundColor(Theme.Colors.text)
            
            VStack(spacing: Theme.Spacing.md) {
                // Free toggle
                Toggle("This item is free", isOn: $viewModel.isFree)
                    .font(Theme.Typography.callout)
                    .foregroundColor(Theme.Colors.text)
                    .tint(Theme.Colors.primary)
                
                if !viewModel.isFree {
                    VStack(spacing: Theme.Spacing.md) {
                        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                            CustomTextField(
                                title: "Price",
                                text: $viewModel.price,
                                placeholder: "0.00",
                                keyboardType: .decimalPad,
                                isValid: viewModel.isPriceValid
                            )
                            
                            // Show price validation message
                            if let priceMessage = viewModel.priceValidationMessage {
                                Text(priceMessage)
                                    .font(Theme.Typography.caption)
                                    .foregroundColor(Theme.Colors.error)
                            } else if !viewModel.price.isEmpty {
                                Text("Minimum price: $3")
                                    .font(Theme.Typography.caption)
                                    .foregroundColor(Theme.Colors.secondaryText)
                            }
                        }
                        
                        if viewModel.selectedType == "for_rent" {
                            CustomTextField(
                                title: "Price per day (optional)",
                                text: $viewModel.pricePerDay,
                                placeholder: "0.00",
                                keyboardType: .decimalPad,
                                isValid: true
                            )
                        }
                    }
                }
            }
        }
        .cardStyle()
    }
    
    // MARK: - Location Section
    private var locationSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("Location")
                .font(Theme.Typography.headline)
                .fontWeight(.semibold)
                .foregroundColor(Theme.Colors.text)
            
            CustomTextField(
                title: "Location",
                text: $viewModel.location,
                placeholder: "City, State",
                keyboardType: .default,
                isValid: viewModel.isLocationValid
            )
        }
        .cardStyle()
    }
    
    // MARK: - Additional Details Section
    private var additionalDetailsSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("Additional Details")
                .font(Theme.Typography.headline)
                .fontWeight(.semibold)
                .foregroundColor(Theme.Colors.text)
            
            VStack(spacing: Theme.Spacing.md) {
                CustomTextField(
                    title: "Quantity Available",
                    text: $viewModel.inventoryAmount,
                    placeholder: "1",
                    keyboardType: .numberPad,
                    isValid: viewModel.isInventoryValid
                )
                
                if viewModel.selectedType == "for_rent" {
                    CustomTextField(
                        title: "Buyout Price (optional)",
                        text: $viewModel.buyoutValue,
                        placeholder: "0.00",
                        keyboardType: .decimalPad,
                        isValid: true
                    )
                }
            }
        }
        .cardStyle()
    }
}

struct CreateListingView_Previews: PreviewProvider {
    static var previews: some View {
        CreateListingView()
    }
}