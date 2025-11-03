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

// MARK: - Upload Tracker Models

/// Tracks the upload status of individual images (Instagram-style)
struct UploadTracker {
    let imageId: String
    let image: UIImage
    var status: UploadStatus
    var url: String?
    var error: String?
    var progress: Double
    var uploadTask: Task<Void, Never>?
    let startTime: Date
    var endTime: Date?

    var uploadDuration: TimeInterval? {
        guard let endTime = endTime else { return nil }
        return endTime.timeIntervalSince(startTime)
    }
}

enum UploadStatus: Equatable {
    case pending
    case uploading(progress: Double)
    case completed
    case failed(error: String)
    case cancelled

    var displayName: String {
        switch self {
        case .pending: return "Waiting"
        case .uploading(let progress): return "Uploading \(Int(progress * 100))%"
        case .completed: return "Done"
        case .failed: return "Failed"
        case .cancelled: return "Cancelled"
        }
    }

    var isComplete: Bool {
        switch self {
        case .completed: return true
        default: return false
        }
    }

    var isFailed: Bool {
        switch self {
        case .failed, .cancelled: return true
        default: return false
        }
    }
}

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

    // ⚡️ INSTAGRAM-STYLE PER-IMAGE UPLOAD TRACKING
    @Published var uploadTrackers: [String: UploadTracker] = [:] // imageId -> tracker
    @Published var overallUploadProgress: Double = 0
    @Published var uploadedImageCount: Int = 0
    @Published var totalImagesToUpload: Int = 0
    @Published var backgroundUploadActive = false

    // Background upload cache (Instagram-style)
    private var backgroundUploadedUrls: [String: String] = [:] // imageId -> url
    private var backgroundUploadBatchId: String?
    private var backgroundUploadTasks: [String: Task<Void, Never>] = [:]
    private let maxConcurrentUploads = 3

    // Services
    private let locationService = LocationService.shared
    private let imageProcessor = IntelligentImageProcessor.shared
    private let batchUploadManager = BatchUploadManager.shared
    private let categoryService = CategoryService.shared
    private var cancellables = Set<AnyCancellable>()

    // Configuration
    private let processingConfig = IntelligentImageProcessor.ProcessingConfiguration.highQuality

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

    // MARK: - ⚡️ TRUE INSTAGRAM-STYLE INSTANT BACKGROUND UPLOAD ⚡️

    /// Starts uploading images INSTANTLY in parallel while user fills out listing details
    /// This is the EXACT flow Instagram uses - uploads start the MOMENT photos are selected!
    private func startBackgroundUpload(images: [UIImage]) async {
        print("⚡️⚡️⚡️ INSTAGRAM MODE: Starting INSTANT parallel background upload for \(images.count) images")

        backgroundUploadActive = true
        totalImagesToUpload = images.count
        uploadedImageCount = 0
        uploadTrackers.removeAll()
        backgroundUploadedUrls.removeAll()

        // Initialize trackers for all images
        for (index, image) in images.enumerated() {
            let imageId = "img_\(index)_\(UUID().uuidString)"
            let tracker = UploadTracker(
                imageId: imageId,
                image: image,
                status: .pending,
                url: nil,
                error: nil,
                progress: 0,
                uploadTask: nil,
                startTime: Date(),
                endTime: nil
            )
            uploadTrackers[imageId] = tracker
        }

        currentOperation = "Uploading \(uploadedImageCount)/\(totalImagesToUpload) images..."

        // Process images first (in parallel)
        do {
            let processedImageSets = try await imageProcessor.getProcessedImages(
                for: images,
                configuration: processingConfig
            )
            processedImages = processedImageSets

            // Create mapping of processed images to trackers
            var imageToTracker: [(processed: IntelligentImageProcessor.ProcessedImageSet, trackerId: String)] = []
            let trackerIds = Array(uploadTrackers.keys)

            for (index, processedSet) in processedImageSets.enumerated() where index < trackerIds.count {
                imageToTracker.append((processedSet, trackerIds[index]))
            }

            // ⚡️ START PARALLEL UPLOADS IMMEDIATELY (3-5 concurrent)
            await withTaskGroup(of: Void.self) { group in
                var activeUploads = 0

                for (processedSet, trackerId) in imageToTracker {
                    // Wait if we've hit max concurrent uploads
                    while activeUploads >= maxConcurrentUploads {
                        await Task.yield()
                        activeUploads = backgroundUploadTasks.count
                    }

                    // Start upload task
                    group.addTask { [weak self] in
                        await self?.uploadSingleImageInBackground(
                            trackerId: trackerId,
                            processedImage: processedSet
                        )
                    }

                    activeUploads += 1
                }

                // Wait for all uploads to complete
                await group.waitForAll()
            }

            // All done!
            let completedCount = uploadTrackers.values.filter { $0.status.isComplete }.count
            print("⚡️⚡️⚡️ INSTAGRAM MODE COMPLETE: \(completedCount)/\(totalImagesToUpload) images uploaded")

            if completedCount == totalImagesToUpload {
                currentOperation = "All images ready!"
                backgroundUploadActive = false
            } else {
                let failedCount = totalImagesToUpload - completedCount
                print("⚠️ \(failedCount) images failed to upload, will retry on submit")
                currentOperation = "\(completedCount)/\(totalImagesToUpload) images ready"
            }

        } catch {
            print("⚠️ Background upload process failed: \(error.localizedDescription)")
            currentOperation = "Some images failed to upload"
            backgroundUploadActive = false
        }
    }

    /// Upload a single image in the background with progress tracking
    private func uploadSingleImageInBackground(trackerId: String, processedImage: IntelligentImageProcessor.ProcessedImageSet) async {
        print("⚡️ Starting upload for tracker: \(trackerId)")

        // Update status to uploading
        uploadTrackers[trackerId]?.status = .uploading(progress: 0)
        uploadTrackers[trackerId]?.progress = 0

        let task = Task<Void, Never> { @MainActor in
            do {
                // Create upload payload
                let payload: [String: Any] = [
                    "image": processedImage.base64Data,
                    "type": "listing",
                    "preserve_metadata": true,
                    "entity_type": "listing",
                    "media_type": "image"
                ]

                guard let jsonData = try? JSONSerialization.data(withJSONObject: payload, options: []) else {
                    throw FileUploadError.compressionFailed
                }

                let baseURL = await APIEndpointManager.shared.getBestEndpoint()
                guard let url = URL(string: "\(baseURL)/api/upload") else {
                    throw FileUploadError.invalidURL
                }

                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.timeoutInterval = 30

                // Add auth headers
                if let token = AuthManager.shared.authToken {
                    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                }

                if let user = AuthManager.shared.currentUser {
                    request.setValue(user.apiId, forHTTPHeaderField: "X-User-API-ID")
                }

                request.httpBody = jsonData

                // Simulate progress updates
                for progress in stride(from: 0.1, through: 0.8, by: 0.2) {
                    try? await Task.sleep(nanoseconds: 100_000_000) // 0.1s
                    self.uploadTrackers[trackerId]?.progress = progress
                    self.uploadTrackers[trackerId]?.status = .uploading(progress: progress)
                }

                // Perform actual upload
                let (responseData, response) = try await URLSession.shared.data(for: request)

                guard let httpResponse = response as? HTTPURLResponse else {
                    throw FileUploadError.invalidResponse
                }

                guard httpResponse.statusCode == 200 else {
                    throw FileUploadError.serverError("HTTP \(httpResponse.statusCode)")
                }

                // Parse response
                guard let json = try JSONSerialization.jsonObject(with: responseData, options: []) as? [String: Any],
                      let success = json["success"] as? Bool,
                      success,
                      let data = json["data"] as? [String: Any],
                      let fileUrl = data["url"] as? String else {
                    throw FileUploadError.invalidResponse
                }

                // ✅ SUCCESS!
                self.uploadTrackers[trackerId]?.status = .completed
                self.uploadTrackers[trackerId]?.url = fileUrl
                self.uploadTrackers[trackerId]?.progress = 1.0
                self.uploadTrackers[trackerId]?.endTime = Date()

                // Cache the URL for fast listing creation
                self.backgroundUploadedUrls[processedImage.id] = fileUrl

                // Update counters
                self.uploadedImageCount += 1
                self.updateOverallProgress()

                print("✅ Upload complete for \(trackerId): \(fileUrl)")

            } catch {
                // ❌ FAILED
                let errorMsg = error.localizedDescription
                self.uploadTrackers[trackerId]?.status = .failed(error: errorMsg)
                self.uploadTrackers[trackerId]?.error = errorMsg
                self.uploadTrackers[trackerId]?.endTime = Date()

                print("❌ Upload failed for \(trackerId): \(errorMsg)")
            }

            // Clean up task reference
            self.backgroundUploadTasks.removeValue(forKey: trackerId)
        }

        backgroundUploadTasks[trackerId] = task
        uploadTrackers[trackerId]?.uploadTask = task

        await task.value
    }

    /// Update overall upload progress based on individual trackers
    private func updateOverallProgress() {
        let completedCount = uploadTrackers.values.filter { $0.status.isComplete }.count
        overallUploadProgress = totalImagesToUpload > 0 ? Double(completedCount) / Double(totalImagesToUpload) : 0
        currentOperation = "Uploading \(completedCount)/\(totalImagesToUpload) images..."
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

    /// ⚡️⚡️⚡️ INSTAGRAM MODE: Handle photo selection and start instant background upload
    func handlePhotoSelection(_ newPhotos: [PhotosPickerItem]) async {
        guard !newPhotos.isEmpty else { return }

        print("⚡️⚡️⚡️ INSTAGRAM MODE: Photo selection detected, loading \(newPhotos.count) images...")

        // Load images from picker items
        let loadedImages = await loadImagesFromPicker(newPhotos)

        await MainActor.run {
            self.selectedImages = loadedImages
            print("⚡️⚡️⚡️ INSTAGRAM MODE: Loaded \(loadedImages.count) images, starting background upload NOW")
        }

        // Start instant background upload (Instagram-style)
        if !loadedImages.isEmpty {
            await startBackgroundUpload(images: loadedImages)
        }
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
            price: nil,  // This is for sale listings only
            dailyRate: isFree ? 0.0 : Double(price) ?? 0.0,
            estimatedValue: nil,  // Not collected in this simplified flow
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
        print("🚫 CANCELLING ALL UPLOADS...")

        // Cancel old batch upload system
        if let cancellationToken = uploadCancellationToken {
            cancellationToken.cancel()
        }

        if let batchId = currentBatchId {
            batchUploadManager.cancelBatch(batchId)
        }

        // ⚡️ CANCEL ALL BACKGROUND UPLOAD TASKS
        for (trackerId, task) in backgroundUploadTasks {
            task.cancel()
            uploadTrackers[trackerId]?.status = .cancelled
            uploadTrackers[trackerId]?.uploadTask = nil
        }
        backgroundUploadTasks.removeAll()

        // 🗑️ ADD UPLOADED URLS TO CLEANUP QUEUE
        let uploadedUrls = uploadTrackers.values
            .filter { $0.status.isComplete }
            .compactMap { $0.url }

        if !uploadedUrls.isEmpty {
            print("🗑️ Adding \(uploadedUrls.count) uploaded images to cleanup queue")
            CleanupQueue.shared.addForDeletion(urls: uploadedUrls)
        }

        // Clear state
        uploadTrackers.removeAll()
        backgroundUploadedUrls.removeAll()
        backgroundUploadActive = false
        uploadedImageCount = 0
        totalImagesToUpload = 0
        overallUploadProgress = 0
        isLoading = false
        currentOperation = ""
        uploadCancellationToken = nil

        print("✅ Cancellation complete")
    }

    /// Called when view is dismissed - cleanup orphaned uploads
    func handleViewDismissal() {
        // If uploads are in progress, cancel and clean up
        if backgroundUploadActive || !backgroundUploadTasks.isEmpty {
            print("🚪 View dismissed during upload - triggering cleanup")
            cancelUpload()
        }
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
        // ⚡️ NEW: Cancel all background uploads and trigger cleanup
        Task { @MainActor in
            // Cancel old batch upload system
            if let cancellationToken = uploadCancellationToken {
                cancellationToken.cancel()
            }

            // Cancel all background upload tasks
            for (trackerId, task) in backgroundUploadTasks {
                task.cancel()
            }

            // Add uploaded images to cleanup queue (orphaned uploads)
            let uploadedUrls = uploadTrackers.values
                .filter { $0.status.isComplete }
                .compactMap { $0.url }

            if !uploadedUrls.isEmpty {
                print("🗑️ DEINIT: Cleaning up \(uploadedUrls.count) orphaned uploads")
                CleanupQueue.shared.addForDeletion(urls: uploadedUrls)
            }
        }
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