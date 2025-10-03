//
//  EnhancedCreateGarageSaleViewModel.swift
//  Brrow
//
//  Enhanced view model for garage sale creation with improved location handling
//

import Foundation
import SwiftUI
import MapKit
import CoreLocation
import Combine

@MainActor
class EnhancedCreateGarageSaleViewModel: ObservableObject {
    // Basic info
    @Published var title = ""
    @Published var description = ""
    @Published var selectedCategories: Set<String> = []
    @Published var customTags: [String] = []
    
    // Date & time
    @Published var startDate = Date()
    @Published var endDate: Date
    
    // Location
    @Published var streetAddress = ""
    @Published var city = ""
    @Published var state = ""
    @Published var zipCode = ""
    @Published var showExactAddress = true
    @Published var mapRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )
    
    // Location state
    @Published var formattedAddress: LocationService.FormattedAddress?
    @Published var isAddressValid = false
    @Published var addressError: String?
    @Published var isValidatingAddress = false
    @Published var isUsingCurrentLocation = false
    
    // Photos - Enhanced with background upload support
    @Published var photos: [UIImage] = []
    @Published var selectedImage: UIImage?
    @Published var showImagePicker = false
    @Published var processedImages: [IntelligentImageProcessor.ProcessedImageSet] = []
    @Published var uploadProgress: Double = 0
    @Published var processingProgress: Double = 0
    @Published var isPreprocessing = false

    // UI state
    @Published var isCreating = false
    @Published var errorMessage: String?
    @Published var showSuccess = false
    @Published var currentOperation = ""

    private let locationService = LocationService.shared
    private let apiClient = APIClient.shared
    private let imageProcessor = IntelligentImageProcessor.shared
    private let batchUploadManager = BatchUploadManager.shared
    private var cancellables = Set<AnyCancellable>()
    private var validationCancellable: AnyCancellable?
    private var uploadCancellationToken: BatchUploadManager.CancellationToken?

    // Configuration for image processing
    private let processingConfig = IntelligentImageProcessor.ProcessingConfiguration.highQuality
    
    init() {
        // Set default end date to 4 hours after start
        let defaultStart = Date()
        self.endDate = Calendar.current.date(byAdding: .hour, value: 4, to: defaultStart) ?? Date()
        
        // Update end date when start date changes
        $startDate
            .sink { [weak self] newStartDate in
                guard let self = self else { return }
                if self.endDate <= newStartDate {
                    self.endDate = Calendar.current.date(byAdding: .hour, value: 4, to: newStartDate) ?? newStartDate
                }
            }
            .store(in: &cancellables)
    }
    
    // Available categories for garage sales
    let availableCategories = ["Electronics", "Furniture", "Clothing", "Books", "Toys", "Sports", "Tools", "Kitchen", "Home Decor", "Other"]

    // MARK: - Computed Properties

    var hasValidLocation: Bool {
        return isAddressValid && formattedAddress != nil
    }
    
    var locationAnnotation: LocationAnnotation {
        return LocationAnnotation(
            id: UUID(),
            coordinate: mapRegion.center
        )
    }
    
    var canCreate: Bool {
        return !title.isEmpty &&
               !description.isEmpty &&
               endDate > startDate &&
               hasValidLocation &&
               !photos.isEmpty
    }
    
    // MARK: - Location Methods
    
    func requestLocationPermission() {
        locationService.requestLocationPermission()
    }
    
    func useCurrentLocation() {
        guard locationService.authorizationStatus == .authorizedWhenInUse ||
              locationService.authorizationStatus == .authorizedAlways else {
            addressError = "Location permission required"
            return
        }
        
        isUsingCurrentLocation = true
        addressError = nil
        
        locationService.getCurrentLocationFormatted()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isUsingCurrentLocation = false
                    
                    if case .failure(let error) = completion {
                        self?.addressError = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] result in
                    self?.applyLocationResult(result.location, formatted: result.formatted)
                }
            )
            .store(in: &cancellables)
    }
    
    func validateAddress() {
        // Cancel previous validation
        validationCancellable?.cancel()
        
        // Clear previous state
        isAddressValid = false
        addressError = nil
        formattedAddress = nil
        
        // Check if we have enough info to validate
        guard !streetAddress.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !city.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !zipCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }
        
        isValidatingAddress = true
        
        // Debounce validation by 1 second
        validationCancellable = Just(())
            .delay(for: .seconds(1), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.performAddressValidation()
            }
    }
    
    private func performAddressValidation() {
        let state = self.state.isEmpty ? nil : self.state
        
        locationService.validateAndFormatAddress(
            street: streetAddress,
            city: city,
            state: state,
            zipCode: zipCode
        )
        .receive(on: DispatchQueue.main)
        .sink(
            receiveCompletion: { [weak self] completion in
                self?.isValidatingAddress = false
                
                if case .failure(let error) = completion {
                    self?.addressError = error.localizedDescription
                    self?.isAddressValid = false
                }
            },
            receiveValue: { [weak self] formatted in
                self?.formattedAddress = formatted
                self?.isAddressValid = true
                self?.addressError = nil
                
                // Update map region
                self?.updateMapRegion(for: formatted)
            }
        )
        .store(in: &cancellables)
    }
    
    private func applyLocationResult(_ location: CLLocation, formatted: LocationService.FormattedAddress) {
        // Update address fields
        if let streetNumber = formatted.streetNumber,
           let streetName = formatted.streetName {
            streetAddress = "\(streetNumber) \(streetName)"
        } else if let streetName = formatted.streetName {
            streetAddress = streetName
        }
        
        city = formatted.city
        state = formatted.state
        zipCode = formatted.zipCode
        
        // Update validation state
        formattedAddress = formatted
        isAddressValid = true
        addressError = nil
        
        // Update map
        mapRegion = MKCoordinateRegion(
            center: location.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )
    }
    
    private func updateMapRegion(for address: LocationService.FormattedAddress) {
        locationService.geocodeAndFormat(address: address.fullAddress)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { [weak self] result in
                    self?.mapRegion = MKCoordinateRegion(
                        center: result.coordinate,
                        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                    )
                }
            )
            .store(in: &cancellables)
    }
    
    // MARK: - Photo Methods

    func addPhoto(_ image: UIImage) {
        if photos.count < 10 {
            photos.append(image)

            // Start predictive processing immediately for better UX
            currentOperation = "Optimizing images..."
            imageProcessor.startPredictiveProcessing(
                images: photos,
                configuration: processingConfig
            )
        }
        selectedImage = nil
    }

    func removePhoto(at index: Int) {
        if index < photos.count {
            let removedImage = photos[index]
            photos.remove(at: index)

            // Remove from processed images if exists
            processedImages.removeAll { $0.originalImage == removedImage }

            // Cancel processing for removed image if needed
            imageProcessor.cancelProcessing(for: [removedImage])
        }
    }
    
    // MARK: - Create Garage Sale
    
    func createGarageSale() {
        guard canCreate,
              let formatted = formattedAddress else {
            errorMessage = "Please fill in all required fields"
            return
        }
        
        // Perform local content moderation
        let moderationResult = ContentModerator.shared.moderateGarageSaleContent(
            title: title,
            description: description,
            address: formatted.standardFormat
        )
        
        if !moderationResult.isPassed {
            errorMessage = moderationResult.message
            return
        }
        
        isCreating = true
        errorMessage = nil
        
        Task {
            do {
                // Upload photos first
                let photoURLs = try await uploadPhotos()
                
                // Format times
                let timeFormatter = DateFormatter()
                timeFormatter.dateFormat = "HH:mm"
                let startTimeStr = timeFormatter.string(from: startDate)
                let endTimeStr = timeFormatter.string(from: endDate)
                
                // Create garage sale
                let request = CreateGarageSaleRequest(
                    title: title,
                    description: description,
                    startDate: startDate,
                    endDate: endDate,
                    address: formatted.standardFormat,
                    location: formatted.standardFormat, // Added location field
                    latitude: mapRegion.center.latitude,
                    longitude: mapRegion.center.longitude,
                    categories: Array(selectedCategories),
                    photos: photoURLs,
                    images: photoURLs, // Also send as images
                    tags: customTags + Array(selectedCategories), // Combine custom tags with categories
                    showExactAddress: showExactAddress,
                    showPinOnMap: true,
                    isPublic: true,
                    startTime: startTimeStr,
                    endTime: endTimeStr,
                    linkedListingIds: [] // Empty array instead of nil
                )
                
                _ = try await apiClient.createGarageSale(request)
                
                await MainActor.run {
                    self.isCreating = false
                    self.showSuccess = true
                    
                    // Track successful creation
                    self.trackGarageSaleCreated()
                }
                
            } catch {
                await MainActor.run {
                    self.isCreating = false
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    private func uploadPhotos() async throws -> [String] {
        guard !photos.isEmpty else { return [] }

        await MainActor.run {
            currentOperation = "Processing images..."
        }

        // Get processed images (use cache if available, process if not)
        let processedImageSets = try await imageProcessor.getProcessedImages(
            for: photos,
            configuration: processingConfig
        )

        await MainActor.run {
            processedImages = processedImageSets
            currentOperation = "Uploading images..."
        }

        var uploadedUrls: [String] = []

        if !processedImageSets.isEmpty {
            // Use batch upload for better performance and reliability
            let uploadResults = try await batchUploadManager.uploadImagesImmediately(
                images: processedImageSets,
                configuration: .listing
            )

            uploadedUrls = uploadResults.map { $0.url }
            print("✅ Uploaded \(uploadedUrls.count) garage sale images via batch upload")
        }

        await MainActor.run {
            currentOperation = ""
        }

        return uploadedUrls
    }
    
    private func trackGarageSaleCreated() {
        let event = AnalyticsEvent(
            eventName: "garage_sale_created",
            eventType: "creation",
            userId: AuthManager.shared.currentUser?.apiId,
            sessionId: AuthManager.shared.sessionId,
            timestamp: ISO8601DateFormatter().string(from: Date()),
            metadata: [
                "photo_count": String(photos.count),
                "has_exact_address": String(showExactAddress),
                "duration_hours": String(Int(endDate.timeIntervalSince(startDate) / 3600)),
                "city": formattedAddress?.city ?? "",
                "state": formattedAddress?.state ?? ""
            ]
        )
        
        apiClient.trackAnalytics(event: event)
            .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
            .store(in: &cancellables)
    }
}

// MARK: - Supporting Types

struct LocationAnnotation: Identifiable {
    let id: UUID
    let coordinate: CLLocationCoordinate2D
}


