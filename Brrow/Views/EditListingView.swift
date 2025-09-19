//
//  EditListingView.swift
//  Brrow
//
//  Edit existing listing functionality
//

import SwiftUI
import PhotosUI

struct EditListingView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var viewModel = EditListingViewModel()
    
    let listing: Listing
    
    // Form fields
    @State private var title: String
    @State private var description: String
    @State private var price: String
    @State private var pricingType: String
    @State private var category: String
    @State private var condition: String
    @State private var location: String
    @State private var securityDeposit: String
    @State private var deliveryAvailable: Bool
    
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
    
    init(listing: Listing) {
        self.listing = listing
        self._title = State(initialValue: listing.title)
        self._description = State(initialValue: listing.description)
        self._price = State(initialValue: String(format: "%.2f", listing.price))
        self._pricingType = State(initialValue: "fixed")  // Default to fixed since priceType is computed
        self._category = State(initialValue: listing.category?.name ?? "Other")
        self._condition = State(initialValue: listing.condition)
        self._location = State(initialValue: "\(listing.location.city), \(listing.location.state)")
        self._securityDeposit = State(initialValue: String(format: "%.2f", 0))  // securityDeposit doesn't exist in new model
        self._deliveryAvailable = State(initialValue: listing.deliveryAvailable ?? false)
        self._existingImages = State(initialValue: listing.imageUrls)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Images Section
                    imagesSection
                    
                    // Basic Information
                    basicInfoSection
                    
                    // Pricing Section
                    pricingSection
                    
                    // Details Section
                    detailsSection
                    
                    // Additional Options
                    optionsSection
                    
                    // Action Buttons
                    actionButtons
                }
                .padding()
            }
            .navigationTitle("Edit Listing")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveChanges()
                    }
                    .disabled(isLoading || !hasChanges())
                }
            }
            .photosPicker(
                isPresented: $showingImagePicker,
                selection: $selectedImages,
                maxSelectionCount: 5,
                matching: .images
            )
            .onChange(of: selectedImages) { _, items in
                loadSelectedImages(items)
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
                    ProgressView("Saving...")
                        .padding()
                        .background(Color.white)
                        .cornerRadius(10)
                        .shadow(radius: 5)
                }
            }
        }
    }
    
    // MARK: - Sections
    
    private var imagesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Photos")
                .font(.headline)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    // Existing images
                    ForEach(existingImages, id: \.self) { imageUrl in
                        if !imagesToDelete.contains(imageUrl) {
                            ZStack(alignment: .topTrailing) {
                                AsyncImage(url: URL(string: imageUrl)) { image in
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                } placeholder: {
                                    Rectangle()
                                        .fill(Color.gray.opacity(0.2))
                                        .overlay(ProgressView())
                                }
                                .frame(width: 100, height: 100)
                                .cornerRadius(10)
                                
                                Button(action: {
                                    imagesToDelete.insert(imageUrl)
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.red)
                                        .background(Color.white.clipShape(Circle()))
                                }
                                .offset(x: 5, y: -5)
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
                                .cornerRadius(10)
                            
                            Button(action: {
                                newImages.remove(at: index)
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.red)
                                    .background(Color.white.clipShape(Circle()))
                            }
                            .offset(x: 5, y: -5)
                        }
                    }
                    
                    // Add photo button
                    if totalImageCount() < 5 {
                        Button(action: { showingImagePicker = true }) {
                            VStack {
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 30))
                                Text("Add Photo")
                                    .font(.caption)
                            }
                            .foregroundColor(.gray)
                            .frame(width: 100, height: 100)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(10)
                        }
                    }
                }
            }
            
            Text("\(totalImageCount())/5 photos")
                .font(.caption)
                .foregroundColor(.gray)
        }
    }
    
    private var basicInfoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Basic Information")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Title")
                    .font(.caption)
                    .foregroundColor(.gray)
                TextField("Item name", text: $title)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Description")
                    .font(.caption)
                    .foregroundColor(.gray)
                TextEditor(text: $description)
                    .frame(minHeight: 100)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Category")
                    .font(.caption)
                    .foregroundColor(.gray)
                Picker("Category", selection: $category) {
                    ForEach(BrrowCategory.allCases, id: \.rawValue) { cat in
                        Text(cat.displayName).tag(cat.rawValue)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .padding(8)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
            }
        }
    }
    
    private var pricingSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Pricing")
                .font(.headline)
            
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Price")
                        .font(.caption)
                        .foregroundColor(.gray)
                    HStack {
                        Text("$")
                        TextField("0.00", text: $price)
                            .keyboardType(.decimalPad)
                    }
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Per")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Picker("Pricing Type", selection: $pricingType) {
                        ForEach(PriceType.allCases, id: \.rawValue) { type in
                            Text(type.rawValue.capitalized).tag(type.rawValue)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .padding(8)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                }
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Security Deposit (optional)")
                    .font(.caption)
                    .foregroundColor(.gray)
                HStack {
                    Text("$")
                    TextField("0.00", text: $securityDeposit)
                        .keyboardType(.decimalPad)
                }
                .textFieldStyle(RoundedBorderTextFieldStyle())
            }
        }
    }
    
    private var detailsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Details")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Condition")
                    .font(.caption)
                    .foregroundColor(.gray)
                Picker("Condition", selection: $condition) {
                    ForEach(["new", "like_new", "excellent", "good", "fair"], id: \.self) { cond in
                        Text(cond.replacingOccurrences(of: "_", with: " ").capitalized).tag(cond)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Location")
                    .font(.caption)
                    .foregroundColor(.gray)
                TextField("City, State", text: $location)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
        }
    }
    
    private var optionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Additional Options")
                .font(.headline)
            
            Toggle("Delivery Available", isOn: $deliveryAvailable)
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
        }
    }
    
    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button(action: saveChanges) {
                HStack {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Save Changes")
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .disabled(isLoading || !hasChanges())
            
            Button(action: { showDeleteConfirmation = true }) {
                HStack {
                    Image(systemName: "trash.fill")
                    Text("Delete Listing")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.red.opacity(0.1))
                .foregroundColor(.red)
                .cornerRadius(10)
            }
            .disabled(isLoading)
        }
    }
    
    // MARK: - Helper Methods
    
    private func totalImageCount() -> Int {
        let existingCount = existingImages.count - imagesToDelete.count
        return existingCount + newImages.count
    }
    
    private func hasChanges() -> Bool {
        // Check if any field has changed
        return title != listing.title ||
               description != listing.description ||
               price != String(format: "%.2f", listing.price) ||
               pricingType != "fixed" ||
               category != (listing.category?.name ?? "Other") ||
               condition != listing.condition ||
               location != "\(listing.location.city), \(listing.location.state)" ||
               !imagesToDelete.isEmpty ||
               !newImages.isEmpty
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
                
                // Add changed fields
                if title != listing.title { updates["title"] = title }
                if description != listing.description { updates["description"] = description }
                if let priceValue = Double(price), priceValue != listing.price {
                    updates["price"] = priceValue
                }
                // Always include pricing type since it's not stored in the new model
                updates["pricing_type"] = pricingType
                
                if category != (listing.category?.name ?? "Other") {
                    updates["category"] = category
                }
                if condition != listing.condition {
                    updates["condition"] = condition
                }
                if location != "\(listing.location.city), \(listing.location.state)" {
                    updates["location"] = location
                }
                if let depositValue = Double(securityDeposit) {
                    updates["security_deposit"] = depositValue
                }
                updates["delivery_available"] = deliveryAvailable
                
                // Handle images if changed
                if !newImages.isEmpty || !imagesToDelete.isEmpty {
                    var imageData: [String] = []
                    
                    // Convert new images to base64
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

// MARK: - View Model
class EditListingViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var error: String?
}

// MARK: - Preview
struct EditListingView_Previews: PreviewProvider {
    static var previews: some View {
        let sampleListing = Listing(
            id: "lst_123",
            title: "Sample Item",
            description: "A sample listing for preview",
            categoryId: "cat_electronics",
            condition: "GOOD",
            price: 25.00,
            dailyRate: nil,
            isNegotiable: true,
            availabilityStatus: .available,
            location: Location(
                address: "123 Main St",
                city: "San Francisco",
                state: "CA",
                zipCode: "94102",
                country: "USA",
                latitude: 37.7749,
                longitude: -122.4194
            ),
            userId: "usr_123",
            viewCount: 0,
            favoriteCount: 0,
            isActive: true,
            isPremium: false,
            premiumExpiresAt: nil as String?,
            deliveryOptions: DeliveryOptions(pickup: true, delivery: false, shipping: false),
            tags: [],
            metadata: nil as [String: AnyCodable]?,
            createdAt: ISO8601DateFormatter().string(from: Date()),
            updatedAt: ISO8601DateFormatter().string(from: Date()),
            user: nil as UserInfo?,
            category: CategoryModel(
                id: "cat_electronics",
                name: "Electronics",
                description: "Electronic items",
                iconUrl: nil,
                parentId: nil,
                isActive: true,
                sortOrder: 1,
                createdAt: ISO8601DateFormatter().string(from: Date()),
                updatedAt: ISO8601DateFormatter().string(from: Date())
            ),
            images: [],
            videos: nil as [ListingVideo]?,
            _count: Listing.ListingCount(favorites: 0),
            isOwner: true,
            isFavorite: false
        )
        
        EditListingView(listing: sampleListing)
            .environmentObject(AuthManager.shared)
    }
}