//
//  EnhancedEditListingView.swift
//  Brrow
//
//  Enhanced edit listing functionality with improved UX
//

import SwiftUI
import PhotosUI
import MapKit

struct EnhancedEditListingView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var viewModel = EditListingViewModel()
    @StateObject private var locationViewModel = LocationPickerViewModel()

    let listing: Listing

    // Form fields
    @State private var title: String
    @State private var description: String
    @State private var price: String
    @State private var dailyRate: String
    @State private var pricingType: String
    @State private var category: String
    @State private var condition: String
    @State private var location: String
    @State private var securityDeposit: String
    @State private var deliveryAvailable: Bool
    @State private var pickupAvailable: Bool
    @State private var shippingAvailable: Bool
    @State private var isNegotiable: Bool
    @State private var tags: [String] = []
    @State private var newTag: String = ""

    // Enhanced location fields
    @State private var coordinates: CLLocationCoordinate2D?
    @State private var address: String = ""
    @State private var city: String = ""
    @State private var state: String = ""
    @State private var zipCode: String = ""

    // Images
    @State private var existingImages: [String]
    @State private var selectedImages: [PhotosPickerItem] = []
    @State private var newImages: [UIImage] = []
    @State private var imagesToDelete: Set<String> = []
    @State private var showingImagePicker = false

    // UI State
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showDeleteConfirmation = false
    @State private var showSuccessAlert = false
    @State private var showLocationPicker = false
    @State private var validationErrors: [String] = []
    @State private var showValidationAlert = false

    init(listing: Listing) {
        self.listing = listing
        self._title = State(initialValue: listing.title)
        self._description = State(initialValue: listing.description)
        self._price = State(initialValue: String(format: "%.2f", listing.price))
        self._dailyRate = State(initialValue: listing.dailyRate != nil ? String(format: "%.2f", listing.dailyRate!) : "")
        self._pricingType = State(initialValue: listing.listingType)
        self._category = State(initialValue: listing.category?.name ?? "Other")
        self._condition = State(initialValue: listing.condition)
        self._location = State(initialValue: "\(listing.location.city), \(listing.location.state)")
        self._securityDeposit = State(initialValue: listing.securityDeposit != nil ? String(format: "%.2f", listing.securityDeposit!) : "0.00")
        self._deliveryAvailable = State(initialValue: listing.deliveryOptions?.delivery ?? false)
        self._pickupAvailable = State(initialValue: listing.deliveryOptions?.pickup ?? true)
        self._shippingAvailable = State(initialValue: listing.deliveryOptions?.shipping ?? false)
        self._isNegotiable = State(initialValue: listing.isNegotiable)
        self._existingImages = State(initialValue: listing.imageUrls)

        // Initialize enhanced location fields
        self._coordinates = State(initialValue: CLLocationCoordinate2D(
            latitude: listing.location.latitude,
            longitude: listing.location.longitude
        ))
        self._address = State(initialValue: listing.location.address)
        self._city = State(initialValue: listing.location.city)
        self._state = State(initialValue: listing.location.state)
        self._zipCode = State(initialValue: listing.location.zipCode)
        self._tags = State(initialValue: listing.tags)
    }

    var body: some View {
        NavigationView {
            ZStack {
                Theme.Colors.background.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Header
                    header

                    ScrollView {
                        VStack(spacing: Theme.Spacing.md) {
                            // Images Section
                            imagesSection

                            // Basic Information
                            basicInfoSection

                            // Pricing Section
                            pricingSection

                            // Location Section
                            locationSection

                            // Details Section
                            detailsSection

                            // Delivery Options
                            deliveryOptionsSection

                            // Tags Section (if needed)
                            if !tags.isEmpty || !newTag.isEmpty {
                                tagsSection
                            }
                        }
                        .padding(Theme.Spacing.md)
                    }
                    .scrollDismissesKeyboard(.interactively)

                    // Save Button at Bottom
                    saveButton
                }
            }
            .photosPicker(
                isPresented: $showingImagePicker,
                selection: $selectedImages,
                maxSelectionCount: 5,
                matching: .images
            )
            .onChange(of: selectedImages) { items in
                loadSelectedImages(items)
            }
            .sheet(isPresented: $showLocationPicker) {
                LocationPickerView(
                    selectedLocation: $coordinates,
                    address: $address,
                    city: $city,
                    state: $state,
                    zipCode: $zipCode
                ) {
                    updateLocationString()
                }
            }
            .alert("Validation Errors", isPresented: $showValidationAlert) {
                Button("OK") { }
            } message: {
                Text(validationErrors.joined(separator: "\n"))
            }
            .alert("Error", isPresented: $showError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
            .alert("Delete Listing", isPresented: $showDeleteConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    deleteListing()
                }
            } message: {
                Text("Are you sure you want to delete this listing? This action cannot be undone.")
            }
            .alert("Success", isPresented: $showSuccessAlert) {
                Button("OK") {
                    presentationMode.wrappedValue.dismiss()
                }
            } message: {
                Text("Your listing has been updated successfully!")
            }
            .overlay {
                if isLoading {
                    ZStack {
                        Color.black.opacity(0.3)
                            .ignoresSafeArea()

                        VStack(spacing: Theme.Spacing.md) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: Theme.Colors.primary))
                                .scaleEffect(1.5)

                            Text("Saving Changes...")
                                .font(Theme.Typography.body)
                                .foregroundColor(Theme.Colors.text)
                        }
                        .padding(Theme.Spacing.lg)
                        .background(RoundedRectangle(cornerRadius: Theme.CornerRadius.md).fill(Theme.Colors.surface))
                        .shadow(color: Theme.Shadows.modal, radius: 10)
                    }
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }

    // MARK: - Header
    private var header: some View {
        HStack {
            Button(action: { presentationMode.wrappedValue.dismiss() }) {
                Image(systemName: "xmark")
                    .font(.title3)
                    .foregroundColor(Theme.Colors.text)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(Theme.Colors.cardBackground))
            }

            Spacer()

            Text("Edit Listing")
                .font(Theme.Typography.title)
                .foregroundColor(Theme.Colors.text)

            Spacer()

            Button(action: { showDeleteConfirmation = true }) {
                Image(systemName: "trash")
                    .font(.title3)
                    .foregroundColor(Theme.Colors.error)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(Theme.Colors.cardBackground))
            }
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.top, 60)
        .padding(.bottom, Theme.Spacing.md)
        .background(Theme.Colors.background)
    }

    // MARK: - Images Section
    private var imagesSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Photos")
                .font(Theme.Typography.headline)
                .foregroundColor(Theme.Colors.text)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Theme.Spacing.sm) {
                    // Existing images
                    ForEach(existingImages, id: \.self) { imageUrl in
                        if !imagesToDelete.contains(imageUrl) {
                            ZStack(alignment: .topTrailing) {
                                BrrowAsyncImage(url: imageUrl) { image in
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                } placeholder: {
                                    Rectangle()
                                        .fill(Theme.Colors.secondaryBackground)
                                        .overlay(ProgressView())
                                }
                                .frame(width: 100, height: 100)
                                .cornerRadius(Theme.CornerRadius.card)

                                Button(action: {
                                    imagesToDelete.insert(imageUrl)
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.white)
                                        .background(Circle().fill(Theme.Colors.error))
                                }
                                .padding(4)
                            }
                        }
                    }

                    // New images
                    ForEach(Array(newImages.enumerated()), id: \.offset) { index, image in
                        ZStack(alignment: .topTrailing) {
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 100, height: 100)
                                .cornerRadius(Theme.CornerRadius.card)

                            Button(action: {
                                newImages.remove(at: index)
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.white)
                                    .background(Circle().fill(Theme.Colors.error))
                            }
                            .padding(4)
                        }
                    }

                    // Add photo button
                    if totalImageCount() < 5 {
                        Button(action: { showingImagePicker = true }) {
                            VStack(spacing: 8) {
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 24))
                                Text("Add Photo")
                                    .font(Theme.Typography.caption)
                            }
                            .foregroundColor(Theme.Colors.primary)
                            .frame(width: 100, height: 100)
                            .background(Theme.Colors.primary.opacity(0.1))
                            .cornerRadius(Theme.CornerRadius.card)
                            .overlay(
                                RoundedRectangle(cornerRadius: Theme.CornerRadius.card)
                                    .stroke(Theme.Colors.primary, lineWidth: 2, dash: [5])
                            )
                        }
                    }
                }
            }

            Text("\(totalImageCount())/5 photos")
                .font(Theme.Typography.caption)
                .foregroundColor(Theme.Colors.secondaryText)
        }
        .padding(Theme.Spacing.md)
        .background(RoundedRectangle(cornerRadius: Theme.CornerRadius.card).fill(Theme.Colors.cardBackground))
    }

    // MARK: - Basic Info Section
    private var basicInfoSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("Basic Information")
                .font(Theme.Typography.headline)
                .foregroundColor(Theme.Colors.text)

            // Title
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                HStack {
                    Text("Title")
                        .font(Theme.Typography.label)
                        .foregroundColor(Theme.Colors.secondaryText)
                    Spacer()
                    Text("\(title.count)/60")
                        .font(Theme.Typography.caption)
                        .foregroundColor(title.count > 60 ? Theme.Colors.error : Theme.Colors.secondaryText)
                }
                TextField("Item name", text: $title)
                    .textFieldStyle(BrrowTextFieldStyle())
            }

            // Description
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                HStack {
                    Text("Description")
                        .font(Theme.Typography.label)
                        .foregroundColor(Theme.Colors.secondaryText)
                    Spacer()
                    Text("\(description.count)/500")
                        .font(Theme.Typography.caption)
                        .foregroundColor(description.count > 500 ? Theme.Colors.error : Theme.Colors.secondaryText)
                }
                TextEditor(text: $description)
                    .frame(minHeight: 100)
                    .padding(Theme.Spacing.sm)
                    .background(Theme.Colors.inputBackground)
                    .cornerRadius(Theme.CornerRadius.card)
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.CornerRadius.card)
                            .stroke(Theme.Colors.border, lineWidth: 1)
                    )
            }

            // Category
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text("Category")
                    .font(Theme.Typography.label)
                    .foregroundColor(Theme.Colors.secondaryText)
                Picker("Category", selection: $category) {
                    ForEach(BrrowCategory.allCases, id: \.rawValue) { cat in
                        Text(cat.displayName).tag(cat.rawValue)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .padding(Theme.Spacing.gutter)
                .background(Theme.Colors.inputBackground)
                .cornerRadius(Theme.CornerRadius.card)
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.CornerRadius.card)
                        .stroke(Theme.Colors.border, lineWidth: 1)
                )
            }
        }
        .padding(Theme.Spacing.md)
        .background(RoundedRectangle(cornerRadius: Theme.CornerRadius.card).fill(Theme.Colors.cardBackground))
    }

    // MARK: - Pricing Section
    private var pricingSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("Pricing")
                .font(Theme.Typography.headline)
                .foregroundColor(Theme.Colors.text)

            // Listing Type
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text("Listing Type")
                    .font(Theme.Typography.label)
                    .foregroundColor(Theme.Colors.secondaryText)

                HStack(spacing: Theme.Spacing.sm) {
                    Button(action: { pricingType = "sale" }) {
                        HStack {
                            Image(systemName: "tag.fill")
                            Text("For Sale")
                        }
                        .font(Theme.Typography.body)
                        .foregroundColor(pricingType == "sale" ? .white : Theme.Colors.primary)
                        .frame(maxWidth: .infinity)
                        .padding(Theme.Spacing.gutter)
                        .background(pricingType == "sale" ? Theme.Colors.primary : Theme.Colors.primary.opacity(0.1))
                        .cornerRadius(Theme.CornerRadius.card)
                    }

                    Button(action: { pricingType = "rental" }) {
                        HStack {
                            Image(systemName: "arrow.triangle.2.circlepath")
                            Text("For Rent")
                        }
                        .font(Theme.Typography.body)
                        .foregroundColor(pricingType == "rental" ? .white : Theme.Colors.primary)
                        .frame(maxWidth: .infinity)
                        .padding(Theme.Spacing.gutter)
                        .background(pricingType == "rental" ? Theme.Colors.primary : Theme.Colors.primary.opacity(0.1))
                        .cornerRadius(Theme.CornerRadius.card)
                    }
                }
            }

            // Price
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text(pricingType == "sale" ? "Sale Price" : "Rental Price")
                    .font(Theme.Typography.label)
                    .foregroundColor(Theme.Colors.secondaryText)
                HStack {
                    Text("$")
                        .foregroundColor(Theme.Colors.secondaryText)
                    TextField("0.00", text: $price)
                        .keyboardType(.decimalPad)
                }
                .textFieldStyle(BrrowTextFieldStyle())
            }

            // Daily Rate (for rentals)
            if pricingType == "rental" {
                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    Text("Daily Rate")
                        .font(Theme.Typography.label)
                        .foregroundColor(Theme.Colors.secondaryText)
                    HStack {
                        Text("$")
                            .foregroundColor(Theme.Colors.secondaryText)
                        TextField("0.00", text: $dailyRate)
                            .keyboardType(.decimalPad)
                    }
                    .textFieldStyle(BrrowTextFieldStyle())
                }

                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    Text("Security Deposit (optional)")
                        .font(Theme.Typography.label)
                        .foregroundColor(Theme.Colors.secondaryText)
                    HStack {
                        Text("$")
                            .foregroundColor(Theme.Colors.secondaryText)
                        TextField("0.00", text: $securityDeposit)
                            .keyboardType(.decimalPad)
                    }
                    .textFieldStyle(BrrowTextFieldStyle())
                }
            }

            // Negotiable toggle
            Toggle(isOn: $isNegotiable) {
                Text("Price is negotiable")
                    .font(Theme.Typography.body)
                    .foregroundColor(Theme.Colors.text)
            }
            .tint(Theme.Colors.primary)
        }
        .padding(Theme.Spacing.md)
        .background(RoundedRectangle(cornerRadius: Theme.CornerRadius.card).fill(Theme.Colors.cardBackground))
    }

    // MARK: - Location Section
    private var locationSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("Location")
                .font(Theme.Typography.headline)
                .foregroundColor(Theme.Colors.text)

            // City and State
            HStack(spacing: Theme.Spacing.sm) {
                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    Text("City")
                        .font(Theme.Typography.label)
                        .foregroundColor(Theme.Colors.secondaryText)
                    TextField("San Francisco", text: $city)
                        .textFieldStyle(BrrowTextFieldStyle())
                }

                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    Text("State")
                        .font(Theme.Typography.label)
                        .foregroundColor(Theme.Colors.secondaryText)
                    TextField("CA", text: $state)
                        .textFieldStyle(BrrowTextFieldStyle())
                }
                .frame(width: 80)
            }
        }
        .padding(Theme.Spacing.md)
        .background(RoundedRectangle(cornerRadius: Theme.CornerRadius.card).fill(Theme.Colors.cardBackground))
    }

    // MARK: - Details Section
    private var detailsSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("Details")
                .font(Theme.Typography.headline)
                .foregroundColor(Theme.Colors.text)

            // Condition
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text("Condition")
                    .font(Theme.Typography.label)
                    .foregroundColor(Theme.Colors.secondaryText)
                Picker("Condition", selection: $condition) {
                    ForEach(["NEW", "LIKE_NEW", "EXCELLENT", "GOOD", "FAIR"], id: \.self) { cond in
                        Text(cond.replacingOccurrences(of: "_", with: " ").capitalized).tag(cond)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
            }
        }
        .padding(Theme.Spacing.md)
        .background(RoundedRectangle(cornerRadius: Theme.CornerRadius.card).fill(Theme.Colors.cardBackground))
    }

    // MARK: - Delivery Options Section
    private var deliveryOptionsSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("Delivery Options")
                .font(Theme.Typography.headline)
                .foregroundColor(Theme.Colors.text)

            VStack(spacing: Theme.Spacing.sm) {
                Toggle(isOn: $pickupAvailable) {
                    Text("Pickup Available")
                        .font(Theme.Typography.body)
                        .foregroundColor(Theme.Colors.text)
                }
                .tint(Theme.Colors.primary)

                Divider()

                Toggle(isOn: $deliveryAvailable) {
                    Text("Delivery Available")
                        .font(Theme.Typography.body)
                        .foregroundColor(Theme.Colors.text)
                }
                .tint(Theme.Colors.primary)

                Divider()

                Toggle(isOn: $shippingAvailable) {
                    Text("Shipping Available")
                        .font(Theme.Typography.body)
                        .foregroundColor(Theme.Colors.text)
                }
                .tint(Theme.Colors.primary)
            }
        }
        .padding(Theme.Spacing.md)
        .background(RoundedRectangle(cornerRadius: Theme.CornerRadius.card).fill(Theme.Colors.cardBackground))
    }

    // MARK: - Tags Section
    private var tagsSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("Tags")
                .font(Theme.Typography.headline)
                .foregroundColor(Theme.Colors.text)

            // Existing tags
            if !tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Theme.Spacing.xs) {
                        ForEach(tags, id: \.self) { tag in
                            HStack(spacing: 4) {
                                Text(tag)
                                    .font(Theme.Typography.caption)
                                Button(action: {
                                    tags.removeAll { $0 == tag }
                                }) {
                                    Image(systemName: "xmark")
                                        .font(Theme.Typography.caption)
                                }
                            }
                            .padding(.horizontal, Theme.Spacing.sm)
                            .padding(.vertical, Theme.Spacing.xs)
                            .background(Theme.Colors.primary.opacity(0.1))
                            .foregroundColor(Theme.Colors.primary)
                            .cornerRadius(Theme.CornerRadius.sm)
                        }
                    }
                }
            }

            // Add new tag
            HStack {
                TextField("Add tag...", text: $newTag)
                    .textFieldStyle(BrrowTextFieldStyle())
                    .onSubmit {
                        addTag()
                    }

                Button("Add") {
                    addTag()
                }
                .foregroundColor(Theme.Colors.primary)
                .disabled(newTag.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(Theme.Spacing.md)
        .background(RoundedRectangle(cornerRadius: Theme.CornerRadius.card).fill(Theme.Colors.cardBackground))
    }

    // MARK: - Save Button
    private var saveButton: some View {
        VStack(spacing: 0) {
            Divider()

            Button(action: {
                if validateForm() {
                    saveChanges()
                } else {
                    showValidationAlert = true
                }
            }) {
                HStack {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Save Changes")
                    }
                }
                .font(Theme.Typography.body.weight(.semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(RoundedRectangle(cornerRadius: Theme.CornerRadius.card).fill(hasChanges() && !isLoading ? Theme.Colors.primary : Theme.Colors.secondaryText))
            }
            .disabled(isLoading || !hasChanges())
            .padding(Theme.Spacing.md)
        }
        .background(Theme.Colors.background)
    }

    // MARK: - Helper Methods

    private func validateForm() -> Bool {
        validationErrors.removeAll()

        if title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            validationErrors.append("Title is required")
        }

        if title.count > 60 {
            validationErrors.append("Title must be 60 characters or less")
        }

        if description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            validationErrors.append("Description is required")
        }

        if description.count > 500 {
            validationErrors.append("Description must be 500 characters or less")
        }

        if pricingType == "sale" || pricingType == "rental" {
            if Double(price) == nil || Double(price)! <= 0 {
                validationErrors.append("Valid price is required")
            }
        }

        if pricingType == "rental" {
            if !dailyRate.isEmpty, let rate = Double(dailyRate), rate <= 0 {
                validationErrors.append("Daily rate must be greater than zero")
            }
        }

        if city.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            validationErrors.append("City is required")
        }

        return validationErrors.isEmpty
    }

    private func updateLocationString() {
        location = "\(city), \(state)"
    }

    private func addTag() {
        let trimmedTag = newTag.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedTag.isEmpty && !tags.contains(trimmedTag) {
            tags.append(trimmedTag)
            newTag = ""
        }
    }

    private func totalImageCount() -> Int {
        let existingCount = existingImages.count - imagesToDelete.count
        return existingCount + newImages.count
    }

    private func hasChanges() -> Bool {
        return title != listing.title ||
               description != listing.description ||
               price != String(format: "%.2f", listing.price) ||
               category != (listing.category?.name ?? "Other") ||
               condition != listing.condition ||
               isNegotiable != listing.isNegotiable ||
               !imagesToDelete.isEmpty ||
               !newImages.isEmpty ||
               tags != listing.tags
    }

    private func loadSelectedImages(_ items: [PhotosPickerItem]) {
        Task {
            for item in items {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    await MainActor.run {
                        newImages.append(image)
                    }
                }
            }
            selectedImages = []
        }
    }

    private func saveChanges() {
        guard !isLoading else { return }

        isLoading = true

        Task {
            do {
                var updates: [String: Any] = [:]

                // Add all changed fields
                if title != listing.title { updates["title"] = title }
                if description != listing.description { updates["description"] = description }

                if let priceValue = Double(price), priceValue != listing.price {
                    updates["price"] = priceValue
                }

                if let dailyRateValue = Double(dailyRate) {
                    updates["daily_rate"] = dailyRateValue
                }

                if let depositValue = Double(securityDeposit) {
                    updates["security_deposit"] = depositValue
                }

                updates["pricing_type"] = pricingType
                updates["category"] = category
                updates["condition"] = condition
                updates["is_negotiable"] = isNegotiable
                updates["tags"] = tags

                // Location updates
                updates["address"] = address
                updates["city"] = city
                updates["state"] = state
                updates["zip_code"] = zipCode
                if let coordinates = coordinates {
                    updates["latitude"] = coordinates.latitude
                    updates["longitude"] = coordinates.longitude
                }

                // Delivery options
                updates["pickup_available"] = pickupAvailable
                updates["delivery_available"] = deliveryAvailable
                updates["shipping_available"] = shippingAvailable

                // Handle images
                if !newImages.isEmpty || !imagesToDelete.isEmpty {
                    var imageData: [String] = []
                    for image in newImages {
                        if let data = image.jpegData(compressionQuality: 0.8) {
                            imageData.append(data.base64EncodedString())
                        }
                    }
                    if !imageData.isEmpty {
                        updates["images"] = imageData
                        updates["replace_images"] = !imagesToDelete.isEmpty
                    }
                }

                // Call API to update listing
                let _ = try await APIClient.shared.updateListing(
                    listingId: listing.listingId,
                    updates: updates
                )

                await MainActor.run {
                    isLoading = false
                    showSuccessAlert = true
                }

            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }

    private func deleteListing() {
        guard !isLoading else { return }

        isLoading = true

        Task {
            do {
                try await APIClient.shared.deleteListing(listingId: listing.listingId)

                await MainActor.run {
                    isLoading = false
                    presentationMode.wrappedValue.dismiss()
                }

            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
}

// MARK: - Supporting Views

struct BrrowTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(Theme.Spacing.gutter)
            .background(Theme.Colors.inputBackground)
            .cornerRadius(Theme.CornerRadius.card)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.card)
                    .stroke(Theme.Colors.border, lineWidth: 1)
            )
    }
}


struct LocationPreviewView: View {
    let coordinates: CLLocationCoordinate2D

    var body: some View {
        Map(coordinateRegion: .constant(MKCoordinateRegion(
            center: coordinates,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )), annotationItems: [MapLocation(coordinate: coordinates)]) { location in
            MapPin(coordinate: location.coordinate, tint: .red)
        }
        .disabled(true)
    }
}

struct MapLocation: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
}

// MARK: - Location Picker

struct LocationPickerView: View {
    @Binding var selectedLocation: CLLocationCoordinate2D?
    @Binding var address: String
    @Binding var city: String
    @Binding var state: String
    @Binding var zipCode: String
    let onLocationSelected: () -> Void

    @Environment(\.presentationMode) var presentationMode
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )

    var body: some View {
        NavigationView {
            VStack {
                Map(coordinateRegion: $region, annotationItems: selectedLocation != nil ? [MapLocation(coordinate: selectedLocation!)] : []) { location in
                    MapPin(coordinate: location.coordinate, tint: .red)
                }
                .onTapGesture { location in
                    // Handle map tap to set location
                }

                Button("Use This Location") {
                    onLocationSelected()
                    presentationMode.wrappedValue.dismiss()
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Theme.Colors.primary)
                .foregroundColor(.white)
                .cornerRadius(12)
                .padding()
            }
            .navigationTitle("Pick Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}

class LocationPickerViewModel: ObservableObject {
    // Location picker functionality
}

struct ListingPreviewView: View {
    let listing: Listing

    var body: some View {
        // Preview implementation
        Text("Listing Preview")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Theme.Colors.background)
    }
}

// MARK: - BrrowCategory Extension

extension BrrowCategory {
    var iconName: String {
        switch self {
        case .electronics: return "desktopcomputer"
        case .homeKitchen: return "fork.knife"
        case .tools: return "hammer"
        case .outdoor: return "leaf"
        case .vehicles: return "car"
        case .furniture: return "sofa"
        case .toys: return "teddybear"
        case .sports: return "football"
        case .camping: return "tent"
        case .party: return "party.popper"
        case .music: return "guitars"
        case .baby: return "figure.and.child.holdinghands"
        case .clothing: return "tshirt"
        case .business: return "briefcase"
        case .books: return "book"
        case .homeGarden: return "house"
        }
    }
}

// MARK: - Preview

struct EnhancedEditListingView_Previews: PreviewProvider {
    static var previews: some View {
        let sampleListing = Listing.example

        EnhancedEditListingView(listing: sampleListing)
            .environmentObject(AuthManager.shared)
    }
}