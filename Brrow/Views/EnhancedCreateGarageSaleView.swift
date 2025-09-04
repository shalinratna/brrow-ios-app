//
//  EnhancedCreateGarageSaleView.swift
//  Brrow
//
//  Enhanced garage sale creation with improved location handling
//

import SwiftUI
import MapKit
import CoreLocation
import Combine

struct EnhancedCreateGarageSaleView: View {
    @StateObject private var viewModel = EnhancedCreateGarageSaleViewModel()
    @StateObject private var locationService = LocationService.shared
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                headerView
                
                // Content
                ScrollView {
                    VStack(spacing: 24) {
                        // Basic Info
                        basicInfoSection
                        
                        // Date & Time
                        dateTimeSection
                        
                        // Enhanced Location Section
                        enhancedLocationSection
                        
                        // Photos
                        photosSection
                        
                        // Create Button
                        createButton
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 100)
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                viewModel.requestLocationPermission()
            }
        }
    }
    
    // MARK: - Header
    private var headerView: some View {
        HStack {
            Button(action: { presentationMode.wrappedValue.dismiss() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(Theme.Colors.text)
                    .frame(width: 44, height: 44)
            }
            
            Spacer()
            
            Text("Create Garage Sale")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(Theme.Colors.text)
            
            Spacer()
            
            Color.clear.frame(width: 44, height: 44)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Theme.Colors.background)
    }
    
    // MARK: - Basic Info Section
    private var basicInfoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("Basic Information", icon: "info.circle.fill")
            
            VStack(spacing: 12) {
                TextField("Garage Sale Title", text: $viewModel.title)
                    .textFieldStyle(ModernTextFieldStyle())
                
                TextField("Description", text: $viewModel.description, axis: .vertical)
                    .textFieldStyle(ModernTextFieldStyle())
                    .lineLimit(3...6)
            }
        }
    }
    
    // MARK: - Date & Time Section
    private var dateTimeSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("Date & Time", icon: "calendar.circle.fill")
            
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Start Date")
                            .font(.caption)
                            .foregroundColor(Theme.Colors.secondaryText)
                        DatePicker("", selection: $viewModel.startDate, displayedComponents: [.date, .hourAndMinute])
                            .datePickerStyle(.compact)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("End Date")
                            .font(.caption)
                            .foregroundColor(Theme.Colors.secondaryText)
                        DatePicker("", selection: $viewModel.endDate, displayedComponents: [.date, .hourAndMinute])
                            .datePickerStyle(.compact)
                    }
                }
                .padding(16)
                .background(Theme.Colors.secondaryBackground)
                .cornerRadius(12)
            }
        }
    }
    
    // MARK: - Enhanced Location Section
    private var enhancedLocationSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("Location", icon: "location.circle.fill")
            
            VStack(spacing: 12) {
                // Location permission prompt
                if locationService.authorizationStatus == .notDetermined {
                    locationPermissionPrompt
                } else if locationService.authorizationStatus == .denied {
                    locationDeniedView
                } else {
                    // Address input with auto-complete
                    addressInputSection
                    
                    // Map preview
                    if viewModel.hasValidLocation {
                        mapPreviewSection
                    }
                    
                    // Location options
                    locationOptionsSection
                }
            }
        }
    }
    
    private var locationPermissionPrompt: some View {
        VStack(spacing: 12) {
            Image(systemName: "location.circle")
                .font(.system(size: 40))
                .foregroundColor(Theme.Colors.primary)
            
            Text("Enable Location Access")
                .font(.headline)
                .foregroundColor(Theme.Colors.text)
            
            Text("We'll help you find and format your address correctly")
                .font(.caption)
                .foregroundColor(Theme.Colors.secondaryText)
                .multilineTextAlignment(.center)
            
            Button(action: { locationService.requestLocationPermission() }) {
                Text("Allow Location Access")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(Theme.Colors.primary)
                    .cornerRadius(12)
            }
        }
        .padding(16)
        .background(Theme.Colors.secondaryBackground)
        .cornerRadius(12)
    }
    
    private var locationDeniedView: some View {
        VStack(spacing: 12) {
            Image(systemName: "location.slash")
                .font(.system(size: 40))
                .foregroundColor(Theme.Colors.text.opacity(0.5))
            
            Text("Location Access Denied")
                .font(.headline)
                .foregroundColor(Theme.Colors.text)
            
            Text("You can still enter your address manually")
                .font(.caption)
                .foregroundColor(Theme.Colors.secondaryText)
                .multilineTextAlignment(.center)
        }
        .padding(16)
        .background(Theme.Colors.secondaryBackground)
        .cornerRadius(12)
    }
    
    private var addressInputSection: some View {
        VStack(spacing: 12) {
            // Use current location button
            if locationService.authorizationStatus == .authorizedWhenInUse || locationService.authorizationStatus == .authorizedAlways {
                Button(action: { viewModel.useCurrentLocation() }) {
                    HStack {
                        Image(systemName: "location.fill")
                        Text("Use Current Location")
                        Spacer()
                        if viewModel.isUsingCurrentLocation {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                    }
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Theme.Colors.primary)
                    .padding(12)
                    .background(Theme.Colors.primary.opacity(0.1))
                    .cornerRadius(8)
                }
                .disabled(viewModel.isUsingCurrentLocation)
            }
            
            // Manual address input
            VStack(spacing: 8) {
                TextField("Street Address", text: $viewModel.streetAddress)
                    .textFieldStyle(ModernTextFieldStyle())
                    .onChange(of: viewModel.streetAddress) { _ in
                        viewModel.validateAddress()
                    }
                
                HStack(spacing: 8) {
                    TextField("City", text: $viewModel.city)
                        .textFieldStyle(ModernTextFieldStyle())
                        .onChange(of: viewModel.city) { _ in
                            viewModel.validateAddress()
                        }
                    
                    TextField("State", text: $viewModel.state)
                        .textFieldStyle(ModernTextFieldStyle())
                        .frame(maxWidth: 80)
                        .onChange(of: viewModel.state) { _ in
                            viewModel.validateAddress()
                        }
                    
                    TextField("ZIP", text: $viewModel.zipCode)
                        .textFieldStyle(ModernTextFieldStyle())
                        .frame(maxWidth: 80)
                        .keyboardType(.numberPad)
                        .onChange(of: viewModel.zipCode) { _ in
                            viewModel.validateAddress()
                        }
                }
            }
            
            // Address validation feedback
            if let error = viewModel.addressError {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.orange)
                    Spacer()
                }
            } else if viewModel.isAddressValid {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(Theme.Colors.success)
                    Text("Address verified")
                        .font(.caption)
                        .foregroundColor(Theme.Colors.success)
                    Spacer()
                }
            }
        }
    }
    
    private var mapPreviewSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Location Preview")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Theme.Colors.text)
            
            Map(coordinateRegion: $viewModel.mapRegion, annotationItems: [viewModel.locationAnnotation]) { annotation in
                MapMarker(coordinate: annotation.coordinate, tint: Theme.Colors.primary)
            }
            .frame(height: 200)
            .cornerRadius(12)
            .disabled(true)
        }
    }
    
    private var locationOptionsSection: some View {
        VStack(spacing: 8) {
            Toggle(isOn: $viewModel.showExactAddress) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Show exact address")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Theme.Colors.text)
                    Text("Display full address or just city/state")
                        .font(.caption)
                        .foregroundColor(Theme.Colors.secondaryText)
                }
            }
            .toggleStyle(SwitchToggleStyle(tint: Theme.Colors.primary))
            
            // Formatted address preview
            if let formatted = viewModel.formattedAddress {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Address will display as:")
                        .font(.caption)
                        .foregroundColor(Theme.Colors.secondaryText)
                    Text(viewModel.showExactAddress ? formatted.fullAddress : formatted.shortAddress)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Theme.Colors.text)
                        .padding(8)
                        .background(Theme.Colors.secondaryBackground.opacity(0.5))
                        .cornerRadius(6)
                }
            }
        }
        .padding(12)
        .background(Theme.Colors.secondaryBackground)
        .cornerRadius(8)
    }
    
    // MARK: - Photos Section
    private var photosSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("Photos", icon: "photo.circle.fill")
            
            VStack(spacing: 12) {
                // Photo grid
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
                    ForEach(Array(viewModel.photos.enumerated()), id: \.offset) { index, photo in
                        ZStack(alignment: .topTrailing) {
                            Image(uiImage: photo)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(height: 100)
                                .clipped()
                                .cornerRadius(8)
                            
                            Button(action: { viewModel.removePhoto(at: index) }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.white)
                                    .background(Circle().fill(Color.black.opacity(0.6)))
                            }
                            .offset(x: -4, y: 4)
                        }
                    }
                    
                    // Add photo button
                    if viewModel.photos.count < 10 {
                        Button(action: { viewModel.showImagePicker = true }) {
                            VStack {
                                Image(systemName: "plus")
                                    .font(.system(size: 24))
                                Text("Add Photo")
                                    .font(.caption)
                            }
                            .foregroundColor(Theme.Colors.primary)
                            .frame(height: 100)
                            .frame(maxWidth: .infinity)
                            .background(Theme.Colors.primary.opacity(0.1))
                            .cornerRadius(8)
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $viewModel.showImagePicker) {
            ImagePicker { image in
                viewModel.selectedImage = image
            }
        }
        .onChange(of: viewModel.selectedImage) { image in
            if let image = image {
                viewModel.addPhoto(image)
            }
        }
    }
    
    // MARK: - Create Button
    private var createButton: some View {
        Button(action: { viewModel.createGarageSale() }) {
            HStack {
                if viewModel.isCreating {
                    ProgressView()
                        .scaleEffect(0.8)
                        .foregroundColor(.white)
                } else {
                    Text("Create Garage Sale")
                        .font(.system(size: 18, weight: .bold))
                }
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(viewModel.canCreate ? Theme.Colors.primary : Theme.Colors.text.opacity(0.3))
            .cornerRadius(16)
        }
        .disabled(!viewModel.canCreate || viewModel.isCreating)
    }
    
    // MARK: - Section Header
    private func sectionHeader(_ title: String, icon: String) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(Theme.Colors.primary)
            Text(title)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(Theme.Colors.text)
            Spacer()
        }
    }
}

// MARK: - Modern Text Field Style
struct ModernTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(12)
            .background(Theme.Colors.secondaryBackground)
            .cornerRadius(8)
            .font(.system(size: 16))
    }
}