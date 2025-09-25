//
//  ModernCreateGarageSaleView.swift
//  Brrow
//
//  Modern garage sale creation with preview and boost options - FIXED VERSION
//

import SwiftUI
import PhotosUI
import MapKit
import CoreLocation
import Combine

struct ModernCreateGarageSaleView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = CreateGarageSaleViewModel()
    @StateObject private var locationManager = LocationManager.shared
    @State private var currentStep = 0
    @State private var showPhotosPicker = false
    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var showPreview = false
    @State private var showBoostOptions = false
    @State private var animateProgress = false
    @FocusState private var focusedField: Field?
    
    enum Field: Hashable {
        case title, description, address, city, zipCode
    }
    
    private let steps = ["Details", "Date & Time", "Location", "Photos", "Listings", "Review"]
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                Theme.Colors.background
                    .ignoresSafeArea()
                    .onTapGesture {
                        // Dismiss keyboard when tapping outside
                        focusedField = nil
                    }
                
                VStack(spacing: 0) {
                    // Progress header
                    progressHeader
                    
                    // Content
                    ScrollView {
                        VStack(spacing: 24) {
                            stepContent
                                .padding(.horizontal, 16)
                                .padding(.top, 24)
                        }
                    }
                    
                    // Bottom navigation
                    bottomNavigation
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showPhotosPicker) {
                PhotosPicker(
                    selection: $selectedPhotos,
                    maxSelectionCount: 10,
                    matching: .images
                ) {
                    Text("Select Photos")
                }
                .onChange(of: selectedPhotos) { newValue in
                    Task {
                        await loadPhotos(from: newValue)
                        // Auto-dismiss the sheet after photos are loaded
                        await MainActor.run {
                            showPhotosPicker = false
                        }
                    }
                }
            }
            .sheet(isPresented: $showPreview) {
                GarageSalePreviewView(viewModel: viewModel)
            }
            .sheet(isPresented: $showBoostOptions) {
                GarageSaleBoostView(viewModel: viewModel)
            }
            .sheet(isPresented: $viewModel.showAddressConflictAlert) {
                if let conflictData = viewModel.addressConflictData {
                    AddressConflictAlertView(
                        conflictData: conflictData,
                        isPresented: $viewModel.showAddressConflictAlert
                    )
                }
            }
            .fullScreenCover(isPresented: $viewModel.showSuccessAnimation) {
                GarageSaleSuccessView(garageSale: viewModel.createdGarageSale)
            }
            .alert("Error", isPresented: .constant(viewModel.validationError != nil || viewModel.createError != nil)) {
                Button("OK") {
                    viewModel.validationError = nil
                    viewModel.createError = nil
                }
            } message: {
                Text(viewModel.validationError ?? viewModel.createError ?? "An error occurred")
            }
            .overlay {
                if viewModel.isCreating {
                    ZStack {
                        Color.black.opacity(0.5)
                            .ignoresSafeArea()
                        
                        VStack(spacing: 16) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(1.5)
                            
                            Text("Creating your garage sale...")
                                .font(.headline)
                                .foregroundColor(.white)
                        }
                        .padding(40)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.black.opacity(0.8))
                        )
                    }
                }
            }
            .onAppear {
                withAnimation(.spring()) {
                    animateProgress = true
                }
            }
        }
    }
    
    // MARK: - Progress Header
    private var progressHeader: some View {
        VStack(spacing: 0) {
            // Close and title
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(Theme.Colors.text)
                        .frame(width: 44, height: 44)
                        .background(Circle().fill(Theme.Colors.secondaryBackground))
                }
                
                Spacer()
                
                Text("Host Garage Sale")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(Theme.Colors.text)
                
                Spacer()
                
                // Balance
                Color.clear
                    .frame(width: 44, height: 44)
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            
            // Progress indicators
            HStack(spacing: 0) {
                ForEach(0..<steps.count, id: \.self) { index in
                    VStack(spacing: 4) {
                        HStack(spacing: 0) {
                            if index > 0 {
                                Rectangle()
                                    .fill(index <= currentStep ? Theme.Colors.primary : Theme.Colors.secondary.opacity(0.3))
                                    .frame(height: 2)
                                    .animation(.spring(), value: currentStep)
                            }
                            
                            Circle()
                                .fill(index <= currentStep ? Theme.Colors.primary : Theme.Colors.secondary.opacity(0.3))
                                .frame(width: 32, height: 32)
                                .overlay(
                                    Group {
                                        if index < currentStep {
                                            Image(systemName: "checkmark")
                                                .font(.system(size: 14, weight: .bold))
                                                .foregroundColor(.white)
                                        } else {
                                            Text("\(index + 1)")
                                                .font(.system(size: 14, weight: .semibold))
                                                .foregroundColor(index == currentStep ? .white : Theme.Colors.secondaryText)
                                        }
                                    }
                                )
                                .animation(.spring(), value: currentStep)
                            
                            if index < steps.count - 1 {
                                Rectangle()
                                    .fill(index < currentStep ? Theme.Colors.primary : Theme.Colors.secondary.opacity(0.3))
                                    .frame(height: 2)
                                    .animation(.spring(), value: currentStep)
                            }
                        }
                        
                        Text(steps[index])
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(index <= currentStep ? Theme.Colors.text : Theme.Colors.secondaryText)
                            .lineLimit(1)
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            
            Divider()
        }
    }
    
    // MARK: - Bottom Navigation
    private var bottomNavigation: some View {
        VStack(spacing: 0) {
            Divider()
            
            HStack {
                if currentStep > 0 {
                    Button(action: { 
                        focusedField = nil // Dismiss keyboard
                        withAnimation(.spring()) {
                            currentStep -= 1
                        }
                    }) {
                        HStack {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Theme.Colors.text)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(Theme.Colors.secondaryBackground)
                        .cornerRadius(25)
                    }
                }
                
                Spacer()
                
                if currentStep < steps.count - 1 {
                    Button(action: {
                        focusedField = nil // Dismiss keyboard before moving to next step
                        withAnimation(.spring()) {
                            currentStep += 1
                        }
                    }) {
                        HStack {
                            Text("Next")
                            Image(systemName: "chevron.right")
                        }
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(isStepValid ? Theme.Colors.primary : Color.gray)
                        .cornerRadius(25)
                    }
                    .disabled(!isStepValid)
                } else {
                    Button(action: {
                        Task {
                            await viewModel.createGarageSale()
                        }
                    }) {
                        HStack {
                            if viewModel.isCreating {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            } else {
                                Text("Create Sale")
                                Image(systemName: "arrow.right.circle.fill")
                            }
                        }
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(isStepValid ? Theme.Colors.primary : Color.gray)
                        .cornerRadius(25)
                    }
                    .disabled(!isStepValid || viewModel.isCreating)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .background(Theme.Colors.background)
    }
    
    // MARK: - Step Content
    @ViewBuilder
    private var stepContent: some View {
        switch currentStep {
        case 0:
            detailsStep
        case 1:
            dateTimeStep
        case 2:
            locationStep
        case 3:
            photosStep
        case 4:
            listingsStep
        case 5:
            reviewStep
        default:
            EmptyView()
        }
    }
    
    // MARK: - Details Step
    private var detailsStep: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Title
            VStack(alignment: .leading, spacing: 8) {
                Label("Sale Title", systemImage: "textformat")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Theme.Colors.secondaryText)
                
                TextField("e.g., Neighborhood Moving Sale", text: $viewModel.title)
                    .font(.system(size: 16))
                    .padding()
                    .background(Theme.Colors.secondaryBackground)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(viewModel.title.isEmpty ? Color.clear : Theme.Colors.primary, lineWidth: 2)
                    )
                    .focused($focusedField, equals: .title)
            }
            
            // Description
            VStack(alignment: .leading, spacing: 8) {
                Label("Description", systemImage: "text.alignleft")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Theme.Colors.secondaryText)
                
                ZStack(alignment: .topLeading) {
                    TextEditor(text: $viewModel.description)
                        .font(.system(size: 16))
                        .padding(8)
                        .scrollContentBackground(.hidden)
                        .background(Theme.Colors.secondaryBackground)
                        .cornerRadius(12)
                        .frame(minHeight: 100)
                        .focused($focusedField, equals: .description)
                    
                    if viewModel.description.isEmpty {
                        Text("Describe what you're selling, special items, etc.")
                            .font(.system(size: 16))
                            .foregroundColor(Theme.Colors.secondaryText.opacity(0.5))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 16)
                            .allowsHitTesting(false)
                    }
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(viewModel.description.isEmpty ? Color.clear : Theme.Colors.primary, lineWidth: 2)
                )
            }
            
            // Item categories - FIXED WITH PROPER LAYOUT
            VStack(alignment: .leading, spacing: 8) {
                Label("What types of items?", systemImage: "tag.fill")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Theme.Colors.secondaryText)
                
                // Use a wrapped layout that prevents cutoff
                WrappedHStack(data: GarageSaleCategory.allCases, spacing: 8) { category in
                    CategoryChip(
                        title: category.title,
                        isSelected: viewModel.categories.contains(category)
                    ) {
                        withAnimation(.spring()) {
                            if viewModel.categories.contains(category) {
                                viewModel.categories.remove(category)
                            } else {
                                viewModel.categories.insert(category)
                            }
                        }
                    }
                }
            }
            
            // Tip
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(Theme.Colors.accentOrange)
                Text("A good title and description helps buyers find your sale")
                    .font(.system(size: 13))
                    .foregroundColor(Theme.Colors.secondaryText)
            }
            .padding()
            .background(Theme.Colors.accentOrange.opacity(0.1))
            .cornerRadius(8)
        }
        .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
    }
    
    // MARK: - Date & Time Step
    private var dateTimeStep: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Multi-day toggle
            Toggle(isOn: $viewModel.isMultiDay) {
                VStack(alignment: .leading) {
                    Text("Multi-day sale")
                        .font(.system(size: 16, weight: .medium))
                    Text("Sale spans multiple days")
                        .font(.caption)
                        .foregroundColor(Theme.Colors.secondaryText)
                }
            }
            .padding()
            .background(Theme.Colors.secondaryBackground)
            .cornerRadius(12)
            
            // Date selection
            VStack(alignment: .leading, spacing: 16) {
                Label("Sale Date", systemImage: "calendar")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Theme.Colors.secondaryText)
                
                DatePicker("Start Date", selection: $viewModel.startDate, displayedComponents: .date)
                    .datePickerStyle(.graphical)
                    .padding()
                    .background(Theme.Colors.secondaryBackground)
                    .cornerRadius(12)
                
                if viewModel.isMultiDay {
                    DatePicker("End Date", selection: $viewModel.endDate, displayedComponents: .date)
                        .datePickerStyle(.compact)
                        .padding()
                        .background(Theme.Colors.secondaryBackground)
                        .cornerRadius(12)
                }
            }
            
            // Time selection
            VStack(alignment: .leading, spacing: 8) {
                Label("Hours", systemImage: "clock")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Theme.Colors.secondaryText)
                
                HStack {
                    DatePicker("Start", selection: $viewModel.startTime, displayedComponents: .hourAndMinute)
                        .labelsHidden()
                    
                    Text("to")
                        .foregroundColor(Theme.Colors.secondaryText)
                    
                    DatePicker("End", selection: $viewModel.endTime, displayedComponents: .hourAndMinute)
                        .labelsHidden()
                }
                .padding()
                .background(Theme.Colors.secondaryBackground)
                .cornerRadius(12)
            }
            
            // Common times
            VStack(alignment: .leading, spacing: 8) {
                Text("Common times")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Theme.Colors.secondaryText)
                
                HStack(spacing: 8) {
                    Button("8AM-2PM") { setTime(start: 8, end: 14) }
                        .buttonStyle(TimeButtonStyle())
                    
                    Button("9AM-4PM") { setTime(start: 9, end: 16) }
                        .buttonStyle(TimeButtonStyle())
                    
                    Button("7AM-12PM") { setTime(start: 7, end: 12) }
                        .buttonStyle(TimeButtonStyle())
                }
            }
        }
        .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
    }
    
    // MARK: - Location Step - FIXED ADDRESS INPUT
    private var locationStep: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Use Current Location button - only show if location services are available
            if locationManager.canUseCurrentLocation {
                Button(action: {
                    Task {
                        await viewModel.useCurrentLocation()
                    }
                }) {
                HStack {
                    Image(systemName: "location.circle.fill")
                    Text("Use Current Location")
                    Spacer()
                    if viewModel.isLoadingLocation {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                            .scaleEffect(0.8)
                    }
                }
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
                .padding()
                .background(Theme.Colors.primary)
                .cornerRadius(12)
                }
                .disabled(viewModel.isLoadingLocation)
            }

            // Show location permission prompt if needed
            if !locationManager.canUseCurrentLocation {
                LocationPermissionPrompt(locationManager: locationManager)
            }

            // Address input with manual control
            VStack(alignment: .leading, spacing: 8) {
                Label("Address", systemImage: "location.fill")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Theme.Colors.secondaryText)
                
                TextField("Street address", text: $viewModel.manualAddress)
                    .font(.system(size: 16))
                    .padding()
                    .background(Theme.Colors.secondaryBackground)
                    .cornerRadius(12)
                    .focused($focusedField, equals: .address)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.words)
                
                HStack(spacing: 8) {
                    TextField("City", text: $viewModel.manualCity)
                        .font(.system(size: 16))
                        .padding()
                        .background(Theme.Colors.secondaryBackground)
                        .cornerRadius(12)
                        .focused($focusedField, equals: .city)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.words)
                    
                    TextField("ZIP", text: $viewModel.manualZipCode)
                        .font(.system(size: 16))
                        .padding()
                        .background(Theme.Colors.secondaryBackground)
                        .cornerRadius(12)
                        .frame(width: 100)
                        .focused($focusedField, equals: .zipCode)
                        .keyboardType(.numberPad)
                }
                
                // Geocode button
                Button(action: {
                    focusedField = nil
                    viewModel.geocodeManualAddress()
                }) {
                    HStack {
                        Image(systemName: "location.magnifyingglass")
                        Text("Find on Map")
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Theme.Colors.primary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Theme.Colors.primary.opacity(0.1))
                    .cornerRadius(20)
                }
            }
            
            // Map preview
            VStack(alignment: .leading, spacing: 8) {
                Label("Location Preview", systemImage: "map")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Theme.Colors.secondaryText)
                
                ZStack {
                    Map(coordinateRegion: $viewModel.region, annotationItems: [viewModel.locationPin]) { pin in
                        MapMarker(coordinate: pin.coordinate, tint: Theme.Colors.primary)
                    }
                    .frame(height: 200)
                    .cornerRadius(12)
                    .allowsHitTesting(false)
                    
                    if viewModel.isGeocoding {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.black.opacity(0.3))
                            .overlay(
                                VStack {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    Text("Locating address...")
                                        .font(.caption)
                                        .foregroundColor(.white)
                                        .padding(.top, 4)
                                }
                            )
                    }
                }
            }
            
            // Privacy options
            VStack(alignment: .leading, spacing: 8) {
                Label("Privacy", systemImage: "lock.shield.fill")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Theme.Colors.secondaryText)
                
                Toggle(isOn: $viewModel.showExactAddress) {
                    VStack(alignment: .leading) {
                        Text("Show exact address")
                            .font(.system(size: 15, weight: .medium))
                        Text("Hide until day of sale for privacy")
                            .font(.caption)
                            .foregroundColor(Theme.Colors.secondaryText)
                    }
                }
                .padding()
                .background(Theme.Colors.secondaryBackground)
                .cornerRadius(12)
            }
            
            // Map pin toggle
            VStack(alignment: .leading, spacing: 8) {
                Label("Map Visibility", systemImage: "mappin.circle.fill")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Theme.Colors.secondaryText)
                
                Toggle(isOn: $viewModel.showPinOnMap) {
                    VStack(alignment: .leading) {
                        Text("Show on map")
                            .font(.system(size: 15, weight: .medium))
                        Text("Required for boosting")
                            .font(.caption)
                            .foregroundColor(Theme.Colors.secondaryText)
                    }
                }
                .padding()
                .background(Theme.Colors.secondaryBackground)
                .cornerRadius(12)
                
                if !viewModel.showPinOnMap {
                    HStack {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(Theme.Colors.accentBlue)
                        Text("Your sale won't appear on the map")
                            .font(.system(size: 13))
                            .foregroundColor(Theme.Colors.secondaryText)
                    }
                    .padding()
                    .background(Theme.Colors.accentBlue.opacity(0.1))
                    .cornerRadius(8)
                }
            }
        }
        .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
    }
    
    // MARK: - Photos Step - FIXED IMAGE CONSTRAINTS
    private var photosStep: some View {
        VStack(alignment: .leading, spacing: 24) {
            photosStepHeader
            photosStepContent
            photosStepTips
        }
    }
    
    private var photosStepHeader: some View {
        HStack {
                Label("Photos (\(viewModel.photos.count)/10)", systemImage: "photo.on.rectangle.angled")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Theme.Colors.secondaryText)
                
                Spacer()
                
                if viewModel.photos.count < 10 {
                    Button(action: { showPhotosPicker = true }) {
                        HStack(spacing: 6) {
                            Image(systemName: "plus")
                            Text("Add Photos")
                        }
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Theme.Colors.primary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Theme.Colors.primary.opacity(0.1))
                        .cornerRadius(20)
                    }
                }
            }
    }
    
    private var photosStepContent: some View {
        Group {
            if viewModel.photos.isEmpty {
                photosEmptyState
            } else {
                photosGrid
            }
        }
    }
    
    private var photosEmptyState: some View {
        VStack(spacing: 16) {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 48))
                        .foregroundColor(Theme.Colors.secondary)
                    
                    Text("Add photos to attract more visitors")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Theme.Colors.text)
                    
                    Text("Show your best items and setup")
                        .font(.system(size: 14))
                        .foregroundColor(Theme.Colors.secondaryText)
                    
                    Button(action: { showPhotosPicker = true }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Add Photos")
                        }
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Theme.Colors.primary)
                        .cornerRadius(25)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
                .padding(.horizontal, 20)
                .background(Theme.Colors.secondaryBackground)
                .cornerRadius(16)
    }
    
    private var photosGrid: some View {
        let columns = [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12)
        ]
        
        return LazyVGrid(columns: columns, spacing: 12) {
            ForEach(0..<viewModel.photos.count, id: \.self) { index in
                photoThumbnail(at: index)
            }
            
            if viewModel.photos.count < 10 {
                addPhotoButton
            }
        }
    }
    
    private func photoThumbnail(at index: Int) -> some View {
        ZStack(alignment: .topTrailing) {
            GeometryReader { geometry in
                Image(uiImage: viewModel.photos[index])
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: geometry.size.width, height: geometry.size.width)
                    .clipped()
                    .cornerRadius(12)
            }
            .aspectRatio(1, contentMode: .fit)
            
            Button(action: {
                withAnimation(.spring()) {
                    _ = viewModel.photos.remove(at: index)
                }
            }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.white)
                    .background(Circle().fill(Color.black.opacity(0.5)))
            }
            .padding(6)
        }
    }
    
    private var addPhotoButton: some View {
        Button(action: { showPhotosPicker = true }) {
            RoundedRectangle(cornerRadius: 12)
                .fill(Theme.Colors.secondaryBackground)
                .aspectRatio(1, contentMode: .fit)
                .overlay(
                    VStack(spacing: 4) {
                        Image(systemName: "plus")
                            .font(.system(size: 24))
                        Text("Add")
                            .font(.system(size: 12))
                    }
                    .foregroundColor(Theme.Colors.secondary)
                )
        }
    }
    
    private var photosStepTips: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "camera.fill")
                    .foregroundColor(Theme.Colors.primary)
                Text("Photo Tips")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Theme.Colors.text)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Label("Show variety of items", systemImage: "checkmark.circle.fill")
                    .font(.system(size: 13))
                    .foregroundColor(Theme.Colors.secondaryText)
                
                Label("Good lighting is key", systemImage: "checkmark.circle.fill")
                    .font(.system(size: 13))
                    .foregroundColor(Theme.Colors.secondaryText)
                
                Label("Include setup/display photos", systemImage: "checkmark.circle.fill")
                    .font(.system(size: 13))
                    .foregroundColor(Theme.Colors.secondaryText)
            }
        }
        .padding()
        .background(Theme.Colors.primary.opacity(0.1))
        .cornerRadius(12)
    }
    
    // MARK: - Listings Step
    private var listingsStep: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Link Your Listings")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(Theme.Colors.text)
                    
                    Text("Add items you're selling at the garage sale")
                        .font(.system(size: 14))
                        .foregroundColor(Theme.Colors.secondaryText)
                }
                
                Spacer()
            }
            
            if viewModel.isLoadingListings {
                HStack {
                    Spacer()
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                    Spacer()
                }
                .padding(.vertical, 40)
            } else if viewModel.availableListings.isEmpty {
                // Empty state
                VStack(spacing: 16) {
                    Image(systemName: "bag.circle")
                        .font(.system(size: 48))
                        .foregroundColor(Theme.Colors.secondary)
                    
                    Text("No sale listings found")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Theme.Colors.text)
                    
                    Text("You don't have any items listed for sale yet")
                        .font(.system(size: 14))
                        .foregroundColor(Theme.Colors.secondaryText)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
                .padding(.horizontal, 20)
                .background(Theme.Colors.secondaryBackground)
                .cornerRadius(16)
            } else {
                // Listings grid
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(viewModel.availableListings, id: \.id) { listing in
                            listingRow(listing)
                        }
                    }
                }
                .frame(maxHeight: 400)
            }
            
            // Selected count
            if !viewModel.selectedListingIds.isEmpty {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(Theme.Colors.success)
                    Text("\(viewModel.selectedListingIds.count) listing\(viewModel.selectedListingIds.count == 1 ? "" : "s") selected")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Theme.Colors.text)
                    Spacer()
                    Button("Clear All") {
                        viewModel.selectedListingIds.removeAll()
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Theme.Colors.primary)
                }
                .padding()
                .background(Theme.Colors.success.opacity(0.1))
                .cornerRadius(12)
            }
        }
        .onAppear {
            Task {
                await viewModel.loadUserListings()
            }
        }
    }
    
    private func listingRow(_ listing: Listing) -> some View {
        HStack(spacing: 12) {
            // Thumbnail
            if let firstImage = listing.imageUrls.first {
                CachedAsyncImage(url: firstImage) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Theme.Colors.secondaryBackground)
                        .overlay(
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                        )
                }
                .frame(width: 60, height: 60)
                .cornerRadius(8)
                .clipped()
            } else {
                Rectangle()
                    .fill(Theme.Colors.secondaryBackground)
                    .frame(width: 60, height: 60)
                    .cornerRadius(8)
                    .overlay(
                        Image(systemName: "photo")
                            .foregroundColor(Theme.Colors.secondary)
                    )
            }
            
            // Details
            VStack(alignment: .leading, spacing: 4) {
                Text(listing.title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Theme.Colors.text)
                    .lineLimit(1)
                
                Text("$\(listing.price, specifier: "%.2f")")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Theme.Colors.primary)
            }
            
            Spacer()
            
            // Selection checkbox
            Button(action: {
                let listingIdStr = String(listing.id)
                if viewModel.selectedListingIds.contains(listingIdStr) {
                    viewModel.selectedListingIds.remove(listingIdStr)
                } else {
                    viewModel.selectedListingIds.insert(listingIdStr)
                }
            }) {
                let isSelected = viewModel.selectedListingIds.contains(String(listing.id))
                Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? Theme.Colors.primary : Theme.Colors.secondary)
            }
        }
        .padding()
        .background(Theme.Colors.secondaryBackground)
        .cornerRadius(12)
    }
    
    // MARK: - Review Step
    private var reviewStep: some View {
        VStack(alignment: .leading, spacing: 24) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Review Your Sale")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(Theme.Colors.text)
                    
                    Text("Make sure everything looks good")
                        .font(.system(size: 14))
                        .foregroundColor(Theme.Colors.secondaryText)
                }
                
                Spacer()
                
                Button(action: { showPreview = true }) {
                    HStack {
                        Image(systemName: "eye")
                        Text("Preview")
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Theme.Colors.primary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Theme.Colors.primary.opacity(0.1))
                    .cornerRadius(20)
                }
            }
            
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Photos with aspect ratio constraint
                    if !viewModel.photos.isEmpty {
                        TabView {
                            ForEach(Array(viewModel.photos.enumerated()), id: \.offset) { _, photo in
                                Image(uiImage: photo)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(maxHeight: 300)
                                    .clipped()
                            }
                        }
                        .tabViewStyle(PageTabViewStyle())
                        .frame(height: 300)
                    }
                    
                    VStack(alignment: .leading, spacing: 16) {
                        // Title
                        Text(viewModel.title)
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(Theme.Colors.text)
                        
                        // Date & Time
                        HStack {
                            Image(systemName: "calendar")
                                .foregroundColor(Theme.Colors.primary)
                            Text(viewModel.formattedDateRange)
                                .font(.system(size: 16))
                                .foregroundColor(Theme.Colors.text)
                        }
                        
                        // Location
                        HStack {
                            Image(systemName: "location.fill")
                                .foregroundColor(Theme.Colors.primary)
                            Text(viewModel.formattedAddress)
                                .font(.system(size: 16))
                                .foregroundColor(Theme.Colors.text)
                        }
                        
                        // Categories
                        if !viewModel.categories.isEmpty {
                            WrappedHStack(data: Array(viewModel.categories), spacing: 8) { category in
                                Text(category.title)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(Theme.Colors.primary)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Theme.Colors.primary.opacity(0.1))
                                    .cornerRadius(15)
                            }
                        }
                        
                        // Description
                        Text(viewModel.description)
                            .font(.system(size: 16))
                            .foregroundColor(Theme.Colors.text)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    
                    // Boost options
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Image(systemName: "rocket.fill")
                                .foregroundColor(Theme.Colors.primary)
                            Text("Boost Your Sale")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(Theme.Colors.text)
                            
                            Spacer()
                            
                            Button(action: { showBoostOptions = true }) {
                                Text("View Options")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(Theme.Colors.primary)
                            }
                        }
                        
                        Text("Get more visitors with promoted placement")
                            .font(.system(size: 14))
                            .foregroundColor(Theme.Colors.secondaryText)
                    }
                    .padding()
                    .background(Theme.Colors.primary.opacity(0.1))
                    .cornerRadius(12)
                }
            }
        }
        .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
    }
    
    // MARK: - Helpers
    private var isStepValid: Bool {
        switch currentStep {
        case 0:
            return !viewModel.title.isEmpty && !viewModel.description.isEmpty
        case 1:
            return true
        case 2:
            return !viewModel.manualAddress.isEmpty && !viewModel.manualCity.isEmpty && !viewModel.manualZipCode.isEmpty
        case 3:
            return true
        default:
            return true
        }
    }
    
    private func setTime(start: Int, end: Int) {
        var calendar = Calendar.current
        calendar.timeZone = TimeZone.current
        
        if let startTime = calendar.date(bySettingHour: start, minute: 0, second: 0, of: Date()),
           let endTime = calendar.date(bySettingHour: end, minute: 0, second: 0, of: Date()) {
            viewModel.startTime = startTime
            viewModel.endTime = endTime
        }
    }
    
    private func loadPhotos(from items: [PhotosPickerItem]) async {
        for item in items {
            if let data = try? await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                await MainActor.run {
                    viewModel.photos.append(image)
                }
            }
        }
    }
}

// MARK: - Wrapped HStack for Categories
struct WrappedHStack<Content: View>: View {
    let items: [AnyView]
    let spacing: CGFloat
    
    init<Data: RandomAccessCollection>(
        data: Data,
        spacing: CGFloat = 8,
        @ViewBuilder content: @escaping (Data.Element) -> Content
    ) where Data.Element: Hashable {
        self.spacing = spacing
        self.items = data.map { AnyView(content($0)) }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: spacing) {
            ForEach(0..<rows.count, id: \.self) { rowIndex in
                HStack(spacing: spacing) {
                    ForEach(0..<rows[rowIndex].count, id: \.self) { itemIndex in
                        rows[rowIndex][itemIndex]
                    }
                }
            }
        }
    }
    
    private var rows: [[AnyView]] {
        var rows: [[AnyView]] = []
        var currentRow: [AnyView] = []
        
        for item in items {
            currentRow.append(item)
            
            // Simple wrapping - 3 items per row
            if currentRow.count >= 3 {
                rows.append(currentRow)
                currentRow = []
            }
        }
        
        if !currentRow.isEmpty {
            rows.append(currentRow)
        }
        
        return rows
    }
}

// MARK: - Category Chip
struct CategoryChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(isSelected ? .white : Theme.Colors.text)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Theme.Colors.primary : Theme.Colors.secondaryBackground)
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(isSelected ? Color.clear : Theme.Colors.secondary.opacity(0.3), lineWidth: 1)
                )
        }
        .animation(.spring(), value: isSelected)
    }
}

// MARK: - Time Button Style
struct TimeButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(Theme.Colors.text)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Theme.Colors.secondaryBackground)
            .cornerRadius(20)
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
    }
}

// MARK: - Categories
enum GarageSaleCategory: String, CaseIterable {
    case furniture = "Furniture"
    case electronics = "Electronics"
    case clothing = "Clothing"
    case toys = "Toys"
    case books = "Books"
    case kitchen = "Kitchen"
    case tools = "Tools"
    case sports = "Sports"
    case antiques = "Antiques"
    case baby = "Baby Items"
    case garden = "Garden"
    case crafts = "Crafts"
    case misc = "Miscellaneous"
    
    var title: String { rawValue }
}

struct LocationPin: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
}

// MARK: - Updated View Model
@MainActor
class CreateGarageSaleViewModel: ObservableObject {
    @Published var title = ""
    @Published var description = ""
    @Published var categories: Set<GarageSaleCategory> = []
    @Published var startDate = Date()
    @Published var endDate = Date()
    @Published var startTime = Date()
    @Published var endTime = Date()
    @Published var isMultiDay = false
    
    // Separate fields for manual address entry
    @Published var manualAddress = ""
    @Published var manualCity = ""
    @Published var manualZipCode = ""
    
    @Published var showExactAddress = false
    @Published var showPinOnMap = true
    @Published var photos: [UIImage] = []
    @Published var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )
    @Published var isGeocoding = false
    @Published var isCreating = false
    @Published var createError: String?
    @Published var uploadedPhotoURLs: [String] = []
    @Published var showSuccessAnimation = false
    @Published var validationError: String?
    @Published var createdGarageSale: GarageSale?
    @Published var addressConflictData: AddressConflictData?
    @Published var showAddressConflictAlert = false
    @Published var selectedListingIds: Set<String> = []
    @Published var availableListings: [Listing] = []
    @Published var isLoadingListings = false
    @Published var isLoadingLocation = false
    
    private let geocoder = CLGeocoder()
    private let apiClient = APIClient.shared
    private let locationManager = LocationManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    var locationPin: LocationPin {
        LocationPin(coordinate: region.center)
    }
    
    var formattedDateRange: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        
        if isMultiDay {
            return "\(formatter.string(from: startDate)) - \(formatter.string(from: endDate))"
        } else {
            formatter.dateFormat = "EEEE, MMM d"
            return formatter.string(from: startDate)
        }
    }
    
    var formattedTimeRange: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return "\(formatter.string(from: startTime)) - \(formatter.string(from: endTime))"
    }
    
    var formattedAddress: String {
        if showExactAddress {
            return "\(manualAddress), \(manualCity) \(manualZipCode)"
        } else {
            return "\(manualCity) area"
        }
    }
    
    var isValid: Bool {
        !title.isEmpty && !description.isEmpty && description.count >= 10 && 
        !manualAddress.isEmpty && !manualCity.isEmpty && !manualZipCode.isEmpty
    }
    
    func validateLocally() -> String? {
        if title.isEmpty {
            return "Please enter a title"
        }
        if description.isEmpty {
            return "Please enter a description"
        }
        if description.count < 10 {
            return "Description must be at least 10 characters"
        }
        if manualAddress.isEmpty || manualCity.isEmpty || manualZipCode.isEmpty {
            return "Please complete the address"
        }
        if endDate <= startDate && isMultiDay {
            return "End date must be after start date"
        }
        return nil
    }
    
    func loadUserListings() async {
        guard let userId = AuthManager.shared.currentUser?.apiId else { return }
        
        await MainActor.run {
            isLoadingListings = true
        }
        
        do {
            // Fetch user's listings that can be linked to garage sales
            let response = try await apiClient.fetchUserListings(userId: userId)
            let listings = response.allListings
            
            // Include all active listings regardless of type - users can sell anything at garage sales
            let availableListings = listings.filter { listing in
                listing.status.lowercased() == "active" || 
                listing.status.lowercased() == "available"
            }
            
            print("📦 Found \(listings.count) total listings, \(availableListings.count) available for garage sale")
            
            await MainActor.run {
                self.availableListings = availableListings
                self.isLoadingListings = false
            }
        } catch {
            print("❌ Error loading listings: \(error)")
            await MainActor.run {
                self.isLoadingListings = false
            }
        }
    }
    
    func useCurrentLocation() async {
        await MainActor.run {
            isLoadingLocation = true
        }

        // Get current location with automatic permission request
        guard let currentLocation = await locationManager.getCurrentLocationAsync() else {
            await MainActor.run {
                self.isLoadingLocation = false
                self.createError = "Unable to get current location. Please check location permissions in Settings."
            }
            return
        }
        
        // Update map region
        await MainActor.run {
            self.region = MKCoordinateRegion(
                center: currentLocation.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            )
        }
        
        // Reverse geocode to get address
        let clLocation = currentLocation
        
        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(clLocation)
            
            if let placemark = placemarks.first {
                await MainActor.run {
                    // Auto-fill address fields
                    if let streetNumber = placemark.subThoroughfare,
                       let streetName = placemark.thoroughfare {
                        self.manualAddress = "\(streetNumber) \(streetName)"
                    } else if let streetName = placemark.thoroughfare {
                        self.manualAddress = streetName
                    }
                    
                    if let city = placemark.locality {
                        self.manualCity = city
                    }
                    
                    if let zipCode = placemark.postalCode {
                        self.manualZipCode = zipCode
                    }
                    
                    self.isLoadingLocation = false
                }
            }
        } catch {
            print("Reverse geocoding error: \(error)")
            await MainActor.run {
                self.isLoadingLocation = false
                self.createError = "Unable to get address from location"
            }
        }
    }
    
    func geocodeManualAddress() {
        let fullAddress = "\(manualAddress), \(manualCity) \(manualZipCode)"
        guard !fullAddress.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              fullAddress != ", " else { return }
        
        isGeocoding = true
        
        geocoder.geocodeAddressString(fullAddress) { [weak self] placemarks, error in
            DispatchQueue.main.async {
                self?.isGeocoding = false
                
                if let placemark = placemarks?.first,
                   let location = placemark.location {
                    self?.region = MKCoordinateRegion(
                        center: location.coordinate,
                        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                    )
                } else if let error = error {
                    print("Geocoding error: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func uploadPhotos() async throws -> [String] {
        guard !photos.isEmpty else { return [] }
        
        // Use high-quality image processor for best quality
        let processor = HighQualityImageProcessor.shared
        
        // Show upload progress
        await MainActor.run {
            print("Processing \(photos.count) photos with highest quality...")
        }
        
        // Process all images with high quality settings
        let processedImages = try await processor.processImages(
            photos,
            for: .garageSale,
            progress: { progress in
                Task { @MainActor in
                    print("Processing progress: \(Int(progress * 100))%")
                }
            }
        )
        
        // Upload processed images in parallel for speed
        let uploadedUrls = try await processor.uploadProcessedImages(
            processedImages,
            to: "api_upload_file.php",  // Use api_upload_file.php which has correct response format
            entityType: "garage_sales",
            entityId: nil  // Will be assigned by server
        )
        
        print("Successfully uploaded \(uploadedUrls.count) photos with high quality")
        for (index, url) in uploadedUrls.enumerated() {
            let size = processedImages[index].readableFileSize
            print("  Photo \(index + 1): \(url) (\(size))")
        }
        
        uploadedPhotoURLs = uploadedUrls
        return uploadedUrls
    }
    
    func createGarageSale() async {
        // Validate locally first
        if let error = validateLocally() {
            await MainActor.run {
                self.validationError = error
                self.createError = error
            }
            return
        }
        
        await MainActor.run {
            self.isCreating = true
            self.createError = nil
            self.validationError = nil
        }
        
        do {
            // Upload photos first
            let photoURLs = try await uploadPhotos()
            
            print("Uploaded \(photoURLs.count) photos:")
            for (index, url) in photoURLs.enumerated() {
                print("  Photo \(index + 1): \(url)")
            }
            
            // Combine date and time properly
            let calendar = Calendar.current
            let startTimeComponents = calendar.dateComponents([.hour, .minute], from: startTime)
            let endTimeComponents = calendar.dateComponents([.hour, .minute], from: endTime)
            
            // Create start datetime
            var startDateComponents = calendar.dateComponents([.year, .month, .day], from: startDate)
            startDateComponents.hour = startTimeComponents.hour ?? 8
            startDateComponents.minute = startTimeComponents.minute ?? 0
            startDateComponents.second = 0
            let startDateTime = calendar.date(from: startDateComponents) ?? startDate
            
            // Create end datetime
            let endBaseDate = isMultiDay ? endDate : startDate
            var endDateComponents = calendar.dateComponents([.year, .month, .day], from: endBaseDate)
            endDateComponents.hour = endTimeComponents.hour ?? 17
            endDateComponents.minute = endTimeComponents.minute ?? 0
            endDateComponents.second = 0
            let endDateTime = calendar.date(from: endDateComponents) ?? endBaseDate
            
            // Format dates properly for API
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            dateFormatter.timeZone = TimeZone.current
            
            let timeFormatter = DateFormatter()
            timeFormatter.dateFormat = "HH:mm"
            timeFormatter.timeZone = TimeZone.current
            
            let startDateStr = dateFormatter.string(from: startDate)
            let endDateStr = dateFormatter.string(from: isMultiDay ? endDate : startDate)
            let startTimeStr = timeFormatter.string(from: startTime)
            let endTimeStr = timeFormatter.string(from: endTime)
            
            print("Creating garage sale with dates:")
            print("  Start: \(startDateStr) at \(startTimeStr)")
            print("  End: \(endDateStr) at \(endTimeStr)")
            print("  Categories: \(Array(categories.map { $0.rawValue }))")
            print("  Photos: \(photoURLs.count) uploaded")
            
            // Create garage sale request with all fields
            let categoriesArray = Array(categories.map { $0.rawValue })
            let fullAddress = "\(manualAddress), \(manualCity), \(manualZipCode.isEmpty ? "" : "\(manualZipCode)")"
            
            let createRequest = CreateGarageSaleRequest(
                title: title,
                description: description,
                startDate: startDateTime,
                endDate: endDateTime,
                address: fullAddress,
                location: fullAddress,
                latitude: region.center.latitude,
                longitude: region.center.longitude,
                categories: categoriesArray,
                photos: photoURLs,
                images: photoURLs, // Send both for compatibility
                tags: categoriesArray, // Use categories as tags
                showExactAddress: showExactAddress,
                showPinOnMap: showPinOnMap,
                isPublic: true,
                startTime: startTimeStr,
                endTime: endTimeStr,
                linkedListingIds: Array(selectedListingIds) // Include selected listings
            )
            
            // Create garage sale via API
            print("🏠 CreateGarageSaleViewModel: Attempting to create garage sale")
            print("   📝 Title: \(createRequest.title)")
            print("   📍 Address: \(createRequest.address)")
            print("   📅 Start Date: \(createRequest.startDate)")
            print("   📅 End Date: \(createRequest.endDate)")

            let createdGarageSale = try await apiClient.createGarageSale(createRequest)
            print("✅ CreateGarageSaleViewModel: Garage sale created successfully with ID: \(createdGarageSale.id)")
            
            await MainActor.run {
                self.createdGarageSale = createdGarageSale
                self.isCreating = false
                self.showSuccessAnimation = true
                
                // Track achievement for hosting garage sale
                AchievementManager.shared.trackGarageSaleHosted()
                
                // Track analytics via event
                self.trackCreationEvent()
            }
        } catch {
            print("❌ CreateGarageSaleViewModel: Failed to create garage sale")
            print("   🔍 Error: \(error)")
            if let urlError = error as? URLError {
                print("   🌐 URL Error Code: \(urlError.code.rawValue)")
                print("   🌐 URL Error Description: \(urlError.localizedDescription)")
            }

            await MainActor.run {
                self.isCreating = false
                if let apiError = error as? BrrowAPIError {
                    print("   🔍 BrrowAPIError: \(apiError)")
                    switch apiError {
                    case .addressConflict(let jsonString):
                        // Parse the conflict response
                        if let data = jsonString.data(using: .utf8),
                           let conflictResponse = try? JSONDecoder().decode(AddressConflictResponse.self, from: data),
                           let details = conflictResponse.data {
                            // Set the conflict data for the parent view
                            self.addressConflictData = AddressConflictData(
                                garageSaleId: details.existingSale.id,
                                address: details.existingSale.address,
                                existingSaleTitle: details.existingSale.title,
                                saleDate: details.existingSale.saleDate,
                                isOwnSale: details.existingSale.isOwnSale
                            )
                            self.showAddressConflictAlert = true
                        } else {
                            self.createError = "Another garage sale already exists at this address"
                        }
                    case .serverError(let message):
                        self.createError = message
                    default:
                        self.createError = error.localizedDescription
                    }
                } else {
                    self.createError = error.localizedDescription
                }
                print("Garage sale creation failed: \(error)")
            }
        }
    }
    
    private func trackCreationEvent() {
        let event = AnalyticsEvent(
            eventName: "garage_sale_created",
            eventType: "creation",
            userId: AuthManager.shared.currentUser?.apiId,
            sessionId: AuthManager.shared.sessionId,
            timestamp: ISO8601DateFormatter().string(from: Date()),
            metadata: [
                "photo_count": String(photos.count),
                "has_exact_address": String(showExactAddress),
                "city": manualCity,
                "categories": categories.map { $0.rawValue }.joined(separator: ",")
            ]
        )
        
        apiClient.trackAnalytics(event: event)
            .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
            .store(in: &cancellables)
    }
}

// MARK: - Updated Create Request
// Note: CreateGarageSaleRequest is defined in APIResponses.swift

// MARK: - Preview View
struct GarageSalePreviewView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: CreateGarageSaleViewModel
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Images
                    if !viewModel.photos.isEmpty {
                        TabView {
                            ForEach(Array(viewModel.photos.enumerated()), id: \.offset) { _, photo in
                                Image(uiImage: photo)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(maxHeight: 300)
                            }
                        }
                        .tabViewStyle(PageTabViewStyle())
                        .frame(height: 300)
                    }
                    
                    VStack(alignment: .leading, spacing: 16) {
                        Text(viewModel.title)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        HStack {
                            Label(viewModel.formattedDateRange, systemImage: "calendar")
                            Spacer()
                            Label(viewModel.formattedTimeRange, systemImage: "clock")
                        }
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        
                        Label(viewModel.formattedAddress, systemImage: "location")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        if !viewModel.categories.isEmpty {
                            WrappedHStack(data: Array(viewModel.categories), spacing: 8) { category in
                                Text(category.title)
                                    .font(.caption)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 4)
                                    .background(Theme.Colors.primary.opacity(0.1))
                                    .foregroundColor(Theme.Colors.primary)
                                    .cornerRadius(12)
                            }
                        }
                        
                        Text(viewModel.description)
                            .font(.body)
                    }
                    .padding()
                }
            }
            .navigationTitle("Preview")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Boost View
struct GarageSaleBoostView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: CreateGarageSaleViewModel
    @State private var selectedBoost: BoostOption? = nil
    
    enum BoostOption: String, CaseIterable {
        case none = "No Boost"
        case basic = "Basic Boost"
        case premium = "Premium Boost"
        
        var price: String {
            switch self {
            case .none: return "Free"
            case .basic: return "$2.99"
            case .premium: return "$5.99"
            }
        }
        
        var features: [String] {
            switch self {
            case .none:
                return ["Standard listing", "Basic visibility"]
            case .basic:
                return ["Featured on map", "2x visibility", "Priority in search"]
            case .premium:
                return ["Top placement", "5x visibility", "Featured badge", "Push notifications"]
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                ForEach(BoostOption.allCases, id: \.self) { option in
                    BoostOptionCard(
                        option: option,
                        isSelected: selectedBoost == option
                    ) {
                        selectedBoost = option
                    }
                }
                
                Spacer()
                
                Button(action: {
                    // Apply boost
                    dismiss()
                }) {
                    Text("Continue")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Theme.Colors.primary)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
            }
            .padding()
            .navigationTitle("Boost Your Sale")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

struct BoostOptionCard: View {
    let option: GarageSaleBoostView.BoostOption
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(option.rawValue)
                        .font(.headline)
                    Spacer()
                    Text(option.price)
                        .font(.headline)
                        .foregroundColor(Theme.Colors.primary)
                }
                
                ForEach(option.features, id: \.self) { feature in
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(Theme.Colors.primary)
                            .font(.caption)
                        Text(feature)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
            .background(isSelected ? Theme.Colors.primary.opacity(0.1) : Theme.Colors.secondaryBackground)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Theme.Colors.primary : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Success Animation View
struct GarageSaleSuccessView: View {
    let garageSale: GarageSale?
    @Environment(\.dismiss) private var dismiss
    @State private var showAnimation = false
    @State private var showContent = false
    @State private var navigateToDetail = false
    
    var body: some View {
        ZStack {
            // Background
            Theme.Colors.primary
                .ignoresSafeArea()
                .opacity(0.95)
            
            VStack(spacing: 40) {
                Spacer()
                
                // Success icon
                ZStack {
                    Circle()
                        .fill(.white)
                        .frame(width: 120, height: 120)
                        .scaleEffect(showAnimation ? 1 : 0)
                        .animation(.spring(response: 0.5, dampingFraction: 0.6), value: showAnimation)
                    
                    Image(systemName: "checkmark")
                        .font(.system(size: 60, weight: .bold))
                        .foregroundColor(Theme.Colors.primary)
                        .scaleEffect(showAnimation ? 1 : 0)
                        .animation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.2), value: showAnimation)
                }
                
                // Success message
                VStack(spacing: 16) {
                    Text("Garage Sale Created!")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("Your garage sale is now live and visible to nearby shoppers")
                        .font(.system(size: 18))
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 20)
                .animation(.easeOut(duration: 0.4).delay(0.5), value: showContent)
                
                Spacer()
                
                // Action buttons
                VStack(spacing: 16) {
                    if garageSale != nil {
                        Button(action: {
                            // Dismiss the success view
                            dismiss()
                            
                            // Navigate to My Posts to see the created garage sale
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                // Switch to profile tab
                                TabSelectionManager.shared.selectedTab = 4
                                
                                // Post notification to open My Posts
                                NotificationCenter.default.post(
                                    name: .navigateToMyPosts,
                                    object: nil
                                )
                            }
                        }) {
                            Text("View Your Sale")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(Theme.Colors.primary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(.white)
                                .cornerRadius(25)
                        }
                    }
                    
                    Button(action: {
                        dismiss()
                    }) {
                        Text("Done")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white)
                    }
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 40)
                .opacity(showContent ? 1 : 0)
                .animation(.easeOut(duration: 0.4).delay(0.8), value: showContent)
            }
        }
        .onAppear {
            withAnimation {
                showAnimation = true
                showContent = true
            }
            
            // Haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
        }
    }
}

// MARK: - Location Permission Prompt
struct LocationPermissionPrompt: View {
    @ObservedObject var locationManager: LocationManager

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "location.slash")
                    .foregroundColor(.orange)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Location Services Required")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.primary)
                    Text("Enable location access to auto-fill your address")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }

            Button(action: {
                if locationManager.authorizationStatus == .notDetermined {
                    locationManager.requestLocationPermission()
                } else {
                    LocationManager.openSettings()
                }
            }) {
                Text(locationManager.authorizationStatus == .notDetermined ? "Enable Location" : "Open Settings")
                    .font(.caption)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Theme.Colors.primary)
                    .cornerRadius(16)
            }
        }
        .padding(12)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Preview
struct ModernCreateGarageSaleView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ModernCreateGarageSaleView()
            GarageSaleSuccessView(garageSale: nil)
        }
    }
}