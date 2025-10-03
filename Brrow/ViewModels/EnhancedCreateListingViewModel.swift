//
//  EnhancedCreateListingViewModel.swift
//  Brrow
//
//  Enhanced listing creation with intelligent preloading, batch uploads, and optimized performance
//

import SwiftUI
import PhotosUI
import CoreLocation
import Combine

@MainActor
class EnhancedCreateListingViewModel: ObservableObject {
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

    // Enhanced Image handling with preloading
    @Published var selectedPhotos: [PhotosPickerItem] = []
    @Published var selectedImages: [UIImage] = []
    @Published var processedImages: [IntelligentImageProcessor.ProcessedImageSet] = []

    // UI State with enhanced feedback
    @Published var isLoading = false
    @Published var isPreprocessing = false
    @Published var uploadProgress: Double = 0
    @Published var uploadSpeed: Double = 0
    @Published var errorMessage = ""
    @Published var showSuccessAlert = false
    @Published var processingProgress: Double = 0
    @Published var processedImageCount = 0
    @Published var currentOperation = ""

    // Location properties
    @Published var currentCoordinate: CLLocationCoordinate2D?
    @Published var isLoadingLocation = false

    // Advanced upload state
    @Published var currentBatchId: String?
    @Published var canCancelUpload = false
    private var uploadCancellationToken: BatchUploadManager.CancellationToken?

    // Background upload cache (Instagram-style)
    private var backgroundUploadedUrls: [String: String] = [:] // imageId -> url
    private var backgroundUploadBatchId: String?

    // Services
    private let locationService = LocationService.shared
    private let imageProcessor = IntelligentImageProcessor.shared
    private let batchUploadManager = BatchUploadManager.shared
    private var cancellables = Set<AnyCancellable>()

    // Configuration
    private let processingConfig = IntelligentImageProcessor.ProcessingConfiguration.highQuality

    // MARK: - Constants
    let categories = ["Electronics", "Furniture", "Clothing", "Books", "Sports & Outdoors", "Toys & Games", "Tools & Equipment", "Home & Garden", "Automotive", "Services", "Other"]

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
        setupImageProcessorObserver()
        setupBatchUploadObserver()

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

    // MARK: - Setup Observers

    private func setupPhotoObserver() {
        $selectedPhotos
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] photos in
                self?.handlePhotoSelection(photos)
            }
            .store(in: &cancellables)
    }

    private func setupImageProcessorObserver() {
        imageProcessor.$isProcessing
            .assign(to: \.isPreprocessing, on: self)
            .store(in: &cancellables)

        imageProcessor.$processingProgress
            .assign(to: \.processingProgress, on: self)
            .store(in: &cancellables)

        imageProcessor.$processedImageCount
            .assign(to: \.processedImageCount, on: self)
            .store(in: &cancellables)
    }

    private func setupBatchUploadObserver() {
        batchUploadManager.$isUploading
            .assign(to: \.isLoading, on: self)
            .store(in: &cancellables)

        batchUploadManager.$uploadProgress
            .assign(to: \.uploadProgress, on: self)
            .store(in: &cancellables)

        batchUploadManager.$uploadSpeed
            .assign(to: \.uploadSpeed, on: self)
            .store(in: &cancellables)

        batchUploadManager.$currentBatchId
            .sink { [weak self] batchId in
                self?.currentBatchId = batchId
                self?.canCancelUpload = batchId != nil
            }
            .store(in: &cancellables)
    }

    private func setupLocationObserver() {
        locationService.$currentLocation
            .compactMap { $0 }
            .sink { [weak self] location in
                self?.currentCoordinate = location.coordinate
            }
            .store(in: &cancellables)
    }

    // MARK: - Enhanced Image Handling

    private func handlePhotoSelection(_ photos: [PhotosPickerItem]) {
        // Clear previous state
        selectedImages.removeAll()
        processedImages.removeAll()

        currentOperation = "Loading images..."

        Task {
            // Load images from photo picker
            let loadedImages = await loadImagesFromPicker(photos)

            selectedImages = loadedImages

            // Start predictive processing immediately
            if !loadedImages.isEmpty {
                currentOperation = "Optimizing images..."
                imageProcessor.startPredictiveProcessing(
                    images: loadedImages,
                    configuration: processingConfig
                )

                // ⚡️ INSTAGRAM-STYLE BACKGROUND UPLOAD: Start uploading immediately in background
                // This happens while user fills out listing details
                Task {
                    await startBackgroundUpload(images: loadedImages)
                }
            }
        }
    }

    // MARK: - Instagram-Style Background Upload

    /// Starts uploading images in background while user fills out listing details
    private func startBackgroundUpload(images: [UIImage]) async {
        print("⚡️ Starting Instagram-style background upload for \(images.count) images")

        do {
            currentOperation = "Uploading images in background..."

            // Get processed images (use cache if available, process if not)
            let processedImageSets = try await imageProcessor.getProcessedImages(
                for: images,
                configuration: processingConfig
            )

            // Store processed images for later use
            processedImages = processedImageSets

            // Start uploading immediately with LOW priority (non-blocking)
            let uploadResults = try await batchUploadManager.uploadImagesImmediately(
                images: processedImageSets,
                configuration: .listing
            )

            // Cache the uploaded URLs by image ID
            for result in uploadResults {
                backgroundUploadedUrls[result.id] = result.url
            }

            print("⚡️ Background upload complete! \(uploadResults.count) images uploaded")
            print("⚡️ Cached URLs: \(backgroundUploadedUrls.keys.joined(separator: ", "))")

            // Update UI to show upload is done
            await MainActor.run {
                currentOperation = "Images ready!"
            }

        } catch {
            print("⚠️ Background upload failed, will retry when creating listing: \(error.localizedDescription)")
            // Clear cache on failure
            backgroundUploadedUrls.removeAll()
            // Don't show error to user - we'll retry when they click "Create Listing"
        }
    }

    private func loadImagesFromPicker(_ photos: [PhotosPickerItem]) async -> [UIImage] {
        var images: [UIImage] = []

        await withTaskGroup(of: UIImage?.self) { group in
            for photo in photos {
                group.addTask {
                    do {
                        if let data = try await photo.loadTransferable(type: Data.self),
                           let image = UIImage(data: data) {
                            return image
                        }
                    } catch {
                        print("Error loading image: \(error)")
                    }
                    return nil
                }
            }

            for await image in group {
                if let image = image {
                    images.append(image)
                }
            }
        }

        return images
    }

    func removeImage(at index: Int) {
        guard index < selectedImages.count else { return }

        let removedImage = selectedImages[index]
        selectedImages.remove(at: index)

        if index < selectedPhotos.count {
            selectedPhotos.remove(at: index)
        }

        // Remove from processed images if exists
        processedImages.removeAll { $0.originalImage == removedImage }

        // Cancel processing for removed image if needed
        imageProcessor.cancelProcessing(for: [removedImage])

        print("🗑️ Removed image at index \(index)")
    }

    // MARK: - Enhanced Listing Creation

    func createListing() {
        // Validation
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
        currentOperation = "Creating listing..."

        Task {
            do {
                try await performEnhancedListingCreation()
            } catch {
                isLoading = false
                errorMessage = "Failed to create listing: \(error.localizedDescription)"
                currentOperation = ""
            }
        }
    }

    @MainActor
    private func performEnhancedListingCreation() async throws {
        var uploadedImageUrls: [String] = []

        // ⚡️ INSTAGRAM-STYLE: Check if images were already uploaded in background
        if !backgroundUploadedUrls.isEmpty && !processedImages.isEmpty {
            // Use cached upload URLs from background upload
            uploadedImageUrls = processedImages.compactMap { processedImage in
                backgroundUploadedUrls[processedImage.id]
            }

            if uploadedImageUrls.count == processedImages.count {
                print("⚡️ FAST PATH: Using \(uploadedImageUrls.count) pre-uploaded images from background!")
                currentOperation = "Creating listing with pre-uploaded images..."
            } else {
                print("⚠️ Some images missing from cache, will re-upload: \(processedImages.count - uploadedImageUrls.count)")
                uploadedImageUrls.removeAll() // Clear partial results, will re-upload all
            }
        }

        // If no cached uploads, or cache was incomplete, upload now
        if uploadedImageUrls.isEmpty && !selectedImages.isEmpty {
            currentOperation = "Processing images..."

            // Get processed images (use cache if available, process if not)
            let processedImageSets = try await imageProcessor.getProcessedImages(
                for: selectedImages,
                configuration: processingConfig
            )

            processedImages = processedImageSets

            if !processedImageSets.isEmpty {
                currentOperation = "Uploading images..."

                // Use batch upload for better performance with HIGH priority
                uploadCancellationToken = nil

                // Wait for upload completion
                let uploadResults = try await batchUploadManager.uploadImagesImmediately(
                    images: processedImageSets,
                    configuration: .listing
                )

                uploadedImageUrls = uploadResults.map { $0.url }

                print("✅ Uploaded \(uploadedImageUrls.count) images via batch upload")
            }
        }

        currentOperation = "Creating listing record..."

        // Create location object with coordinates
        let listingLocation = Location(
            address: location,
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
            dailyRate: isFree ? 0.0 : Double(price) ?? 0.0,
            categoryId: categoryId,
            condition: "GOOD",
            location: listingLocation,
            isNegotiable: true,
            deliveryOptions: DeliveryOptions(pickup: true, delivery: false, shipping: false),
            tags: [],
            images: uploadedImageUrls,
            videos: nil
        )

        let listing = try await APIClient.shared.createListing(request)

        // Success cleanup
        isLoading = false
        currentOperation = ""
        uploadCancellationToken = nil

        // Analytics and notifications
        trackListingCreationSuccess(listing)
        WidgetDataManager.shared.handleNewListingCreated()
        WidgetIntegrationService.shared.notifyListingCreated(listing)
        NotificationCenter.default.post(name: .listingCreated, object: listing)

        showSuccessAlert = true

        print("🎉 Listing created successfully with enhanced performance!")
    }

    // MARK: - Cancellation Support

    func cancelUpload() {
        guard let cancellationToken = uploadCancellationToken else { return }

        cancellationToken.cancel()

        if let batchId = currentBatchId {
            batchUploadManager.cancelBatch(batchId)
        }

        isLoading = false
        currentOperation = ""
        uploadCancellationToken = nil

        print("🚫 Upload cancelled by user")
    }

    // MARK: - Validation

    var isTitleValid: Bool {
        title.count >= 3 && title.count <= 100
    }

    var isDescriptionValid: Bool {
        description.count >= 10 && description.count <= 1000
    }

    var isPriceValid: Bool {
        if isFree { return true }
        guard let priceValue = Double(price) else { return false }
        return priceValue > 0 && priceValue <= 50000
    }

    var isLocationValid: Bool {
        location.count >= 3
    }

    var isInventoryValid: Bool {
        guard let inventory = Int(inventoryAmount) else { return false }
        return inventory > 0 && inventory <= 100
    }

    var canSubmit: Bool {
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

    // MARK: - Helper Methods

    @MainActor
    private func getCategoryId(for categoryName: String) async -> String {
        let categoryMap: [String: String] = [
            "Electronics": "cmf7c7sci0000pt0ruo6ooqui",
            "Furniture": "cmf7c7sps0001pt0rliuzbu0u",
            "Clothing & Fashion": "cmf7c7taa0002pt0r718q1iw7",
            "Vehicles": "cmf7c7tal0003pt0rw8agqrq3",
            "Sports & Outdoors": "cmf7c7tax0004pt0r0l90rc4b",
            "Books & Media": "cmf7c7tbg0005pt0rx36ct66l",
            "Toys & Games": "cmf7c7tc70006pt0rikmtbbd8",
            "Tools & Equipment": "cmf7c7tcx0007pt0rwcdafp3n",
            "Home & Garden": "cmf7c7td70008pt0rhgd2oi1r",
            "Beauty & Health": "cmf7c7u0f0009pt0rld3ijaf5",
            "Pets & Animals": "cmf7c7u19000apt0r35ztyxj9",
            "Services": "cmf7c7u1j000bpt0rtnhiwsiy",
            "Other": "cmf7c7u1x000cpt0rhf0gw3v3"
        ]

        return categoryMap[categoryName] ?? "cmf7c7u1x000cpt0rhf0gw3v3"
    }

    // Location methods
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

    // MARK: - Performance Monitoring

    private func trackListingCreationSuccess(_ listing: Listing) {
        AnalyticsService.shared.trackListingCreated(
            listingId: listing.id,
            category: listing.category?.name ?? "Unknown",
            price: listing.price
        )
        print("📊 Listing creation success: \(listing.id)")
    }

    private func trackListingCreationError(_ error: String) {
        AnalyticsService.shared.trackError(
            error: NSError(domain: "ListingCreation", code: -1, userInfo: [NSLocalizedDescriptionKey: error]),
            context: "create_listing"
        )
        print("📊 Listing creation error: \(error)")
    }

    // MARK: - Cleanup

    deinit {
        // Cancel any ongoing operations
        if let cancellationToken = uploadCancellationToken {
            cancellationToken.cancel()
        }

        // Note: Cache will be cleared automatically by the processor when needed
    }
}

// MARK: - Performance Metrics
extension EnhancedCreateListingViewModel {
    var performanceMetrics: [String: Any] {
        return [
            "preprocessed_images": processedImages.count,
            "processing_progress": processingProgress,
            "upload_progress": uploadProgress,
            "upload_speed_kbps": uploadSpeed,
            "is_preprocessing": isPreprocessing,
            "is_uploading": isLoading,
            "current_operation": currentOperation
        ]
    }
}