//
//  InlineEditViewModel.swift
//  Brrow
//
//  Created by Claude Code on 11/13/25.
//

import SwiftUI
import Combine

/// Editable fields in the listing detail view
enum EditableField: Identifiable, Equatable {
    case title
    case description
    case price
    case dailyRate
    case securityDeposit
    case category
    case condition
    case location
    case images
    case deliveryOptions
    case negotiable
    case tags

    var id: String {
        switch self {
        case .title: return "title"
        case .description: return "description"
        case .price: return "price"
        case .dailyRate: return "dailyRate"
        case .securityDeposit: return "securityDeposit"
        case .category: return "category"
        case .condition: return "condition"
        case .location: return "location"
        case .images: return "images"
        case .deliveryOptions: return "deliveryOptions"
        case .negotiable: return "negotiable"
        case .tags: return "tags"
        }
    }

    var displayName: String {
        switch self {
        case .title: return "Title"
        case .description: return "Description"
        case .price: return "Price"
        case .dailyRate: return "Daily Rate"
        case .securityDeposit: return "Security Deposit"
        case .category: return "Category"
        case .condition: return "Condition"
        case .location: return "Location"
        case .images: return "Photos"
        case .deliveryOptions: return "Delivery Options"
        case .negotiable: return "Negotiable"
        case .tags: return "Tags"
        }
    }
}

/// Save state for visual feedback
enum SaveState: Equatable {
    case idle
    case saving
    case saved
    case error(String)

    var message: String? {
        switch self {
        case .idle: return nil
        case .saving: return "Saving..."
        case .saved: return "Saved"
        case .error(let msg): return msg
        }
    }
}

/// ViewModel for managing inline editing state and operations
class InlineEditViewModel: ObservableObject {
    // MARK: - Published Properties

    /// Currently editing field (nil = not editing)
    @Published var editingField: EditableField?

    /// Draft buffer for edits before save
    @Published var editBuffer: [String: Any] = [:]

    /// Current save state
    @Published var saveState: SaveState = .idle

    /// Original listing being edited
    @Published var listing: Listing

    /// Updated listing after successful save
    @Published var updatedListing: Listing?

    // MARK: - Private Properties

    private let apiClient: APIClient
    private var cancellables = Set<AnyCancellable>()
    private var saveDebounce: AnyCancellable?

    // MARK: - Initialization

    init(listing: Listing, apiClient: APIClient = .shared) {
        self.listing = listing
        self.apiClient = apiClient
    }

    // MARK: - Public Methods

    /// Start editing a field
    func startEditing(_ field: EditableField) {
        editingField = field
        saveState = .idle

        // Pre-populate edit buffer with current value
        switch field {
        case .title:
            editBuffer["title"] = listing.title
        case .description:
            editBuffer["description"] = listing.description
        case .price:
            editBuffer["price"] = listing.price
        case .dailyRate:
            editBuffer["dailyRate"] = listing.dailyRate
        case .securityDeposit:
            // Security deposit is not part of DeliveryOptions - it's a separate listing field
            editBuffer["securityDeposit"] = 0.0
        case .category:
            editBuffer["categoryId"] = listing.categoryId
        case .condition:
            editBuffer["condition"] = listing.condition
        case .location:
            editBuffer["location"] = listing.location
        case .images:
            editBuffer["images"] = listing.images
        case .deliveryOptions:
            editBuffer["deliveryOptions"] = listing.deliveryOptions
        case .negotiable:
            editBuffer["negotiable"] = listing.isNegotiable
        case .tags:
            editBuffer["tags"] = listing.tags
        }
    }

    /// Cancel editing and discard changes
    func cancelEditing() {
        editingField = nil
        editBuffer.removeAll()
        saveState = .idle
    }

    /// Save current field edit
    func saveEdit(autoSave: Bool = false) {
        guard let field = editingField else { return }

        saveState = .saving

        // Build update payload
        var updates: [String: Any] = [:]

        switch field {
        case .title:
            if let title = editBuffer["title"] as? String, !title.isEmpty {
                updates["title"] = title
            } else {
                saveState = .error("Title cannot be empty")
                return
            }
        case .description:
            if let description = editBuffer["description"] as? String {
                updates["description"] = description
            }
        case .price:
            if let price = editBuffer["price"] as? Double, price >= 0 {
                updates["price"] = price
            } else {
                saveState = .error("Invalid price")
                return
            }
        case .dailyRate:
            if let rate = editBuffer["dailyRate"] as? Double {
                updates["daily_rate"] = rate >= 0 ? rate : nil
            }
        case .securityDeposit:
            if let deposit = editBuffer["securityDeposit"] as? Double {
                updates["security_deposit"] = deposit >= 0 ? deposit : 0
            }
        case .category:
            if let categoryId = editBuffer["categoryId"] as? String {
                updates["category_id"] = categoryId
            }
        case .condition:
            if let condition = editBuffer["condition"] as? String {
                updates["condition"] = condition
            }
        case .location:
            if let location = editBuffer["location"] as? Location {
                updates["location"] = location.formattedAddress
                updates["latitude"] = location.latitude
                updates["longitude"] = location.longitude
            }
        case .deliveryOptions:
            if let options = editBuffer["deliveryOptions"] as? DeliveryOptions {
                updates["delivery_available"] = options.delivery
                updates["pickup_available"] = options.pickup
                updates["shipping_available"] = options.shipping
            }
        case .negotiable:
            if let negotiable = editBuffer["negotiable"] as? Bool {
                updates["is_negotiable"] = negotiable
            }
        case .tags:
            if let tags = editBuffer["tags"] as? [String] {
                updates["tags"] = tags
            }
        case .images:
            // Image updates handled separately via upload
            saveState = .error("Image updates not yet implemented")
            return
        }

        // Call API to update listing
        Task { [weak self] in
            do {
                let updatedListing = try await self?.apiClient.updateListing(listingId: listing.id, updates: updates)

                await MainActor.run {
                    guard let self = self, let updatedListing = updatedListing else { return }
                    self.listing = updatedListing
                    self.updatedListing = updatedListing
                    self.saveState = .saved

                    // Auto-dismiss after showing success
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        if !autoSave {
                            self.cancelEditing()
                        }
                    }
                }
            } catch {
                await MainActor.run { [weak self] in
                    self?.saveState = .error(error.localizedDescription)
                }
            }
        }
    }

    /// Update buffer value (with optional auto-save debounce)
    func updateBuffer(key: String, value: Any, autoSave: Bool = false) {
        editBuffer[key] = value

        if autoSave {
            // Debounce auto-save by 500ms
            saveDebounce?.cancel()
            saveDebounce = Just(())
                .delay(for: .milliseconds(500), scheduler: DispatchQueue.main)
                .sink { [weak self] _ in
                    self?.saveEdit(autoSave: true)
                }
        }
    }

    /// Validate field value
    func validate(field: EditableField) -> String? {
        switch field {
        case .title:
            guard let title = editBuffer["title"] as? String else { return "Title is required" }
            if title.isEmpty { return "Title cannot be empty" }
            if title.count > 60 { return "Title must be 60 characters or less" }
            return nil

        case .description:
            guard let description = editBuffer["description"] as? String else { return nil }
            if description.count > 500 { return "Description must be 500 characters or less" }
            return nil

        case .price:
            guard let price = editBuffer["price"] as? Double else { return "Price is required" }
            if price < 0 { return "Price cannot be negative" }
            return nil

        case .dailyRate:
            if let rate = editBuffer["dailyRate"] as? Double, rate < 0 {
                return "Daily rate cannot be negative"
            }
            return nil

        case .securityDeposit:
            if let deposit = editBuffer["securityDeposit"] as? Double, deposit < 0 {
                return "Security deposit cannot be negative"
            }
            return nil

        default:
            return nil
        }
    }
}
