//
//  CreateListingViewModel.swift
//  Brrow
//
//  Created by Shalin Ratna on 7/16/25.
//

import SwiftUI
import PhotosUI
import CoreLocation
import Combine

@MainActor
class CreateListingViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var title = ""
    @Published var description = ""
    @Published var selectedCategory = ""
    @Published var selectedType = ""
    @Published var price = ""
    @Published var pricePerDay = ""
    @Published var buyoutValue = ""
    @Published var location = ""
    @Published var inventoryAmount = "1"
    @Published var isFree = false
    
    // Image handling
    @Published var selectedPhotos: [PhotosPickerItem] = []
    @Published var selectedImages: [UIImage] = []

    // UI State
    @Published var isLoading = false
    @Published var errorMessage = ""
    @Published var showSuccessAlert = false

    // Upload progress tracking
    @Published var uploadProgress: Double = 0
    @Published var uploadedImageCount: Int = 0
    @Published var totalImageCount: Int = 0
    @Published var uploadSpeed: Double = 0 // KB/s
    private var currentBatchId: String?
    private var cancellationToken: BatchUploadManager.CancellationToken?

    // Location properties
    @Published var currentCoordinate: CLLocationCoordinate2D?
    @Published var isLoadingLocation = false
    private let locationService = LocationService.shared
    private var cancellables = Set<AnyCancellable>()

    // Category service
    private let categoryService = CategoryService.shared

    // MARK: - Constants
    var categories: [String] {
        categoryService.getCategoryNames()
    }
    
    let listingTypes: [(key: String, value: (title: String, description: String))] = [
        ("for_sale", (title: "For Sale", description: "Sell this item permanently")),
        ("for_rent", (title: "For Rent", description: "Rent this item for a period of time")),
        ("borrow", (title: "Borrow", description: "Lend this item temporarily for free")),
        ("giveaway", (title: "Giveaway", description: "Give this item away for free"))
    ]
    
    // MARK: - Initialization
    init() {
        setupLocationObserver()
        setupPhotoObserver()
        setupUploadProgressObserver()

        // Use current location as default if available
        if let currentLocation = locationService.currentLocation {
            self.currentCoordinate = currentLocation.coordinate

            // Get formatted address
            locationService.getAddress(from: currentLocation)
                .sink(
                    receiveCompletion: { _ in },
                    receiveValue: { [weak self] address in
                        self?.location = address
                    }
                )
                .store(in: &cancellables)
        }
    }

    @MainActor
    private func setupUploadProgressObserver() {
        // Observe BatchUploadManager's progress updates
        // Use receive(on:) to ensure updates happen on MainActor
        BatchUploadManager.shared.$uploadProgress
            .receive(on: DispatchQueue.main)
            .sink { [weak self] progress in
                self?.uploadProgress = progress
            }
            .store(in: &cancellables)

        BatchUploadManager.shared.$uploadedCount
            .receive(on: DispatchQueue.main)
            .sink { [weak self] count in
                self?.uploadedImageCount = count
            }
            .store(in: &cancellables)

        BatchUploadManager.shared.$totalCount
            .receive(on: DispatchQueue.main)
            .sink { [weak self] count in
                self?.totalImageCount = count
            }
            .store(in: &cancellables)

        BatchUploadManager.shared.$uploadSpeed
            .receive(on: DispatchQueue.main)
            .sink { [weak self] speed in
                self?.uploadSpeed = speed
            }
            .store(in: &cancellables)
    }
    
    private func setupPhotoObserver() {
        $selectedPhotos
            .sink { [weak self] photos in
                self?.loadImages(from: photos)
            }
            .store(in: &cancellables)
    }
    
    func refreshLocation() {
        locationService.startUpdatingLocation()
        
        // If we already have a location, use it
        if let currentLocation = locationService.currentLocation {
            self.currentCoordinate = currentLocation.coordinate
            
            // Get formatted address if location field is empty
            if self.location.isEmpty {
                locationService.getAddress(from: currentLocation)
                    .sink(
                        receiveCompletion: { _ in },
                        receiveValue: { [weak self] address in
                            self?.location = address
                        }
                    )
                    .store(in: &cancellables)
            }
        }
    }
    
    private func setupLocationObserver() {
        locationService.$currentLocation
            .sink { [weak self] location in
                guard let self = self, let location = location else { return }
                self.currentCoordinate = location.coordinate
                
                // Auto-fill location field with address if empty
                if self.location.isEmpty {
                    self.locationService.getAddress(from: location)
                        .sink(
                            receiveCompletion: { _ in },
                            receiveValue: { [weak self] address in
                                self?.location = address
                            }
                        )
                        .store(in: &self.cancellables)
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Validation
    var isTitleValid: Bool {
        // Check length
        guard title.count >= 3 && title.count <= 100 else { return false }
        // Check for special characters - only allow letters, numbers, spaces, and basic punctuation
        let allowedCharacters = CharacterSet.alphanumerics.union(.whitespaces).union(.punctuationCharacters)
        let specialCharacters = CharacterSet(charactersIn: "#@$%^&*()_+={}[]|\\:;<>?,/~`")
        return title.rangeOfCharacter(from: specialCharacters) == nil
    }
    
    var titleValidationMessage: String? {
        if title.isEmpty {
            return nil
        }
        if title.count < 3 {
            return "Title must be at least 3 characters"
        }
        if title.count > 100 {
            return "Title must be less than 100 characters"
        }
        let specialCharacters = CharacterSet(charactersIn: "#@$%^&*()_+={}[]|\\:;<>?,/~`")
        if title.rangeOfCharacter(from: specialCharacters) != nil {
            return "Title cannot contain special characters like #, @, $, etc."
        }
        return nil
    }
    
    var isDescriptionValid: Bool {
        // Check length
        guard description.count >= 10 && description.count <= 1000 else { return false }
        // Allow more characters in description but still block potentially harmful ones
        let dangerousCharacters = CharacterSet(charactersIn: "<>{}[]\\|`")
        return description.rangeOfCharacter(from: dangerousCharacters) == nil
    }
    
    var descriptionValidationMessage: String? {
        if description.isEmpty {
            return nil
        }
        if description.count < 10 {
            return "Description must be at least 10 characters"
        }
        if description.count > 1000 {
            return "Description must be less than 1000 characters"
        }
        let dangerousCharacters = CharacterSet(charactersIn: "<>{}[]\\|`")
        if description.rangeOfCharacter(from: dangerousCharacters) != nil {
            return "Description cannot contain characters like <, >, {, }, etc."
        }
        return nil
    }
    
    var isPriceValid: Bool {
        if isFree { return true }
        guard let priceValue = Double(price) else { return false }
        // Minimum price is $3, maximum is $10000
        return priceValue >= 3.0 && priceValue <= 10000
    }
    
    var priceValidationMessage: String? {
        if isFree { return nil }
        guard let priceValue = Double(price) else {
            return "Please enter a valid price"
        }
        if priceValue < 3.0 {
            return "Minimum price is $3"
        }
        if priceValue >= 100 && !(AuthManager.shared.currentUser?.verified ?? false) {
            return "Verified account required for listings $100+"
        }
        if priceValue > 10000 {
            return "Maximum price is $10,000"
        }
        return nil
    }
    
    var isLocationValid: Bool {
        // Location is optional - allow empty or valid length
        return location.isEmpty || (location.count >= 3 && location.count <= 100)
    }
    
    var isInventoryValid: Bool {
        guard let inventory = Int(inventoryAmount) else { return false }
        return inventory > 0 && inventory <= 100
    }
    
    var canSubmit: Bool {
        // Check basic validations
        let basicValid = isTitleValid &&
                        isDescriptionValid &&
                        !selectedCategory.isEmpty &&
                        !selectedType.isEmpty &&
                        isPriceValid &&
                        isLocationValid &&
                        isInventoryValid &&
                        !isLoading
        
        // Check verified account requirement for high-value listings
        if !isFree, let priceValue = Double(price), priceValue >= 100 {
            return basicValid && (AuthManager.shared.currentUser?.verified ?? false)
        }
        
        return basicValid
    }
    
    // MARK: - Image Handling
    private func loadImages(from photos: [PhotosPickerItem]) {
        selectedImages.removeAll()
        
        for photo in photos {
            photo.loadTransferable(type: Data.self) { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let data):
                        if let data = data, let image = UIImage(data: data) {
                            self.selectedImages.append(image)
                        }
                    case .failure(let error):
                        print("Error loading image: \(error)")
                    }
                }
            }
        }
    }
    
    func removeImage(at index: Int) {
        guard index < selectedImages.count else { return }
        selectedImages.remove(at: index)
        selectedPhotos.remove(at: index)
    }
    
    // MARK: - Helper Methods
    
    @MainActor
    private func getCategoryId(for categoryName: String) async -> String {
        // Use CategoryService to get category ID
        if let category = categoryService.getCategory(byName: categoryName) {
            return category.id
        }

        // Fallback to "Other" category if not found
        if let otherCategory = categoryService.categories.first(where: { $0.name == "Other" }) {
            return otherCategory.id
        }

        // Ultimate fallback to hardcoded "Other" ID
        return "cmf7c7u1x000cpt0rhf0gw3v3"
    }
    
    // MARK: - Location Methods
    func requestLocationPermission() {
        locationService.requestLocationPermission()
    }
    
    func geocodeLocation() {
        guard !location.isEmpty else { return }
        
        isLoadingLocation = true
        locationService.getCoordinates(from: location)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoadingLocation = false
                    if case .failure(let error) = completion {
                        print("Geocoding error: \(error)")
                    }
                },
                receiveValue: { [weak self] coordinate in
                    self?.currentCoordinate = coordinate
                }
            )
            .store(in: &cancellables)
    }
    
    // MARK: - Stripe Connect State
    @Published var showStripeConnectRequirement = false
    @Published var stripeConnectOnboardingUrl: String?
    @Published var isCheckingStripeConnect = false

    // MARK: - API Methods
    func createListing() {
        // Check price validation first
        if let priceError = priceValidationMessage {
            errorMessage = priceError
            return
        }

        guard canSubmit else {
            errorMessage = "Please fill in all required fields correctly"
            return
        }

        // Perform local content moderation
        let moderationResult = ContentModerator.shared.moderateListingContent(
            title: title,
            description: description,
            category: selectedCategory
        )

        if !moderationResult.isPassed {
            errorMessage = moderationResult.message
            return
        }

        isLoading = true
        errorMessage = ""

        Task { @MainActor in
            // Proceed directly with listing creation - Stripe Connect will be required later for payments
            do {
                try await performListingCreation()
            } catch {
                isLoading = false
                errorMessage = "Failed to create listing: \(error.localizedDescription)"
            }
        }
    }

    @MainActor
    private func performListingCreation() async throws {
        do {
            // Upload images with proper error handling and parallel execution
            let uploadedImageUrls = try await uploadImagesInParallel()
                

            // If no images uploaded successfully, show error
            if selectedImages.count > 0 && uploadedImageUrls.isEmpty {
                throw BrrowAPIError.networkError("Failed to upload images. Please try again.")
            }
                

            // Note: The location coordinates are now passed directly in the request

            // Use image URLs directly as strings
            let imageUploads = uploadedImageUrls
                

            // Create location object with coordinates
            // Use user's location if available, otherwise use default San Francisco
            let listingLocation = Location(
                address: location.isEmpty ? "Location not specified" : location,
                city: "",
                state: "",
                zipCode: "",
                country: "USA",
                latitude: currentCoordinate?.latitude ?? 37.7749,
                longitude: currentCoordinate?.longitude ?? -122.4194
            )
                

            // Get the proper category ID
            let categoryId = await getCategoryId(for: selectedCategory)

            let request = CreateListingRequest(
                title: title,
                description: description,
                dailyRate: isFree ? 0.0 : Double(price) ?? 0.0,  // Changed to dailyRate for Railway backend
                categoryId: categoryId,  // Using proper category ID
                condition: "GOOD",  // Default condition, you can make this selectable
                location: listingLocation,
                isNegotiable: true,  // You can make this configurable
                deliveryOptions: DeliveryOptions(pickup: true, delivery: false, shipping: false),
                tags: [],  // You can add tag support later
                images: imageUploads,  // Always send array, even if empty (Railway backend expects array)
                videos: nil
            )
                
            let listing = try await APIClient.shared.createListing(request)

            isLoading = false
            trackListingCreationSuccess(listing)
            // Update widget data
            WidgetDataManager.shared.handleNewListingCreated()
            WidgetIntegrationService.shared.notifyListingCreated(listing)
            // Post notification for other observers
            NotificationCenter.default.post(name: .listingCreated, object: listing)
            // Show success alert last to avoid any UI conflicts
            showSuccessAlert = true

        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
            trackListingCreationError(error.localizedDescription)
        }
    }
    
    // Upload images with optimized performance using BatchUploadManager
    private func uploadImagesInParallel() async throws -> [String] {
        guard !selectedImages.isEmpty else { return [] }

        print("📤 Processing and uploading \(selectedImages.count) images with BatchUploadManager...")

        do {
            // Step 1: Process images using IntelligentImageProcessor
            let processedImages = try await IntelligentImageProcessor.shared.getProcessedImages(
                for: selectedImages,
                configuration: .highQuality
            )

            guard !processedImages.isEmpty else {
                throw BrrowAPIError.networkError("Failed to process images")
            }

            print("✅ Processed \(processedImages.count) images, starting batch upload...")

            // Step 2: Upload images immediately using BatchUploadManager
            // This method handles priority queue, retry logic, and returns results
            let uploadResults = try await BatchUploadManager.shared.uploadImagesImmediately(
                images: processedImages,
                configuration: .listing
            )

            print("✅ Successfully uploaded \(uploadResults.count) of \(selectedImages.count) images")

            // Extract URLs from upload results
            let urls = uploadResults.map { $0.url }

            return urls

        } catch {
            print("❌ Batch upload failed: \(error)")
            throw BrrowAPIError.networkError("Failed to upload images: \(error.localizedDescription)")
        }
    }

    /// Cancel ongoing upload when user exits create listing
    @MainActor
    func cancelUpload() {
        if let batchId = currentBatchId {
            BatchUploadManager.shared.cancelBatch(batchId)
            print("🚫 Cancelled batch upload: \(batchId)")
        }
        currentBatchId = nil
        cancellationToken = nil
    }
    
    func resetForm() {
        title = ""
        description = ""
        selectedCategory = ""
        selectedType = ""
        price = ""
        pricePerDay = ""
        buyoutValue = ""
        location = ""
        inventoryAmount = "1"
        isFree = false
        selectedPhotos.removeAll()
        selectedImages.removeAll()
    }

    // MARK: - Stripe Connect Methods
    func openStripeConnectOnboarding() {
        guard let urlString = stripeConnectOnboardingUrl,
              let url = URL(string: urlString) else {
            errorMessage = "Unable to open Stripe Connect onboarding"
            return
        }

        UIApplication.shared.open(url)
    }

    func dismissStripeConnectRequirement() {
        showStripeConnectRequirement = false
        stripeConnectOnboardingUrl = nil
    }

    // Check Stripe Connect status for payment processing (called when user needs to receive payments)
    func checkStripeConnectForPayments() async -> Bool {
        do {
            let stripeStatus = try await APIClient.shared.getStripeConnectStatus()
            return stripeStatus.canReceivePayments
        } catch {
            print("Failed to check Stripe Connect status: \(error)")
            return false
        }
    }

    // Prompt user to set up Stripe Connect for payments
    func promptStripeConnectForPayments() {
        Task { @MainActor in
            showStripeConnectRequirement = true

            // Get onboarding URL
            do {
                let onboardingResponse = try await APIClient.shared.getStripeConnectOnboardingUrl()
                stripeConnectOnboardingUrl = onboardingResponse.onboardingUrl
            } catch {
                print("Failed to get Stripe onboarding URL: \(error)")
                errorMessage = "Unable to set up payments. Please try again."
            }
        }
    }

    // MARK: - Analytics
    private func trackListingCreationSuccess(_ listing: Listing) {
        let event = AnalyticsEvent(
            eventName: "listing_created",
            eventType: "content",
            userId: AuthManager.shared.currentUser?.apiId,
            sessionId: AuthManager.shared.sessionId,
            timestamp: ISO8601DateFormatter().string(from: Date()),
            metadata: [
                "listing_id": listing.id,
                "category": selectedCategory,
                "type": selectedType,
                "has_images": String(selectedImages.count > 0),
                "image_count": String(selectedImages.count),
                "is_free": String(isFree),
                "platform": "ios"
            ]
        )
        
        Task {
            try? await APIClient.shared.trackAnalytics(event: event)
        }
    }
    
    private func trackListingCreationError(_ error: String) {
        let event = AnalyticsEvent(
            eventName: "listing_creation_error",
            eventType: "error",
            userId: AuthManager.shared.currentUser?.apiId,
            sessionId: AuthManager.shared.sessionId,
            timestamp: ISO8601DateFormatter().string(from: Date()),
            metadata: [
                "error": error,
                "category": selectedCategory,
                "type": selectedType,
                "platform": "ios"
            ]
        )
        
        Task {
            try? await APIClient.shared.trackAnalytics(event: event)
        }
    }
}

// MARK: - UIImage Extension
extension UIImage {
    func resizedImage(to size: CGSize) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        defer { UIGraphicsEndImageContext() }
        draw(in: CGRect(origin: .zero, size: size))
        return UIGraphicsGetImageFromCurrentImageContext() ?? self
    }
}