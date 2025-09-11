//
//  PersistenceController.swift
//  Brrow
//
//  Created by Shalin Ratna on 7/16/25.
//

import CoreData
import Foundation
import Combine

// MARK: - Core Data Persistence Controller (Shaiitech Warrior X10)
class PersistenceController: ObservableObject {
    static let shared = PersistenceController()
    
    // MARK: - Core Data Stack
    lazy var container: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "BrrowDataModel")
        
        // Configure for encryption and security (Warrior X10)
        container.persistentStoreDescriptions.forEach { description in
            description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
            description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
            
            // Enable encryption
            description.setOption(FileProtectionType.complete as NSString, forKey: NSPersistentStoreFileProtectionKey)
        }
        
        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                // Log to Shaiitech PEST X1
                self.logError("Core Data failed to load: \(error), \(error.userInfo)")
                fatalError("Core Data failed to load: \(error)")
            }
        }
        
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        return container
    }()
    
    var context: NSManagedObjectContext {
        return container.viewContext
    }
    
    // MARK: - Save Context
    func save() {
        let context = container.viewContext
        
        if context.hasChanges {
            do {
                try context.save()
                logActivity("Core Data saved successfully")
            } catch {
                logError("Core Data save failed: \(error)")
            }
        }
    }
    
    // MARK: - User Operations
    func saveUser(_ user: User) {
        let userEntity = UserEntity(context: context)
        userEntity.id = Int32(Int(user.id) ?? 0)
        userEntity.username = user.username
        userEntity.email = user.email
        userEntity.profilePicture = user.profilePicture
        userEntity.verified = user.verified ?? false
        userEntity.apiId = user.apiId ?? ""
        userEntity.listerRating = user.listerRating ?? 0
        userEntity.renteeRating = user.renteeRating ?? 0
        userEntity.emailVerified = user.emailVerified ?? false
        userEntity.isVerified = user.verified ?? false
        userEntity.idVerified = user.idVerified ?? false
        userEntity.stripeLinked = user.stripeLinked ?? false
        userEntity.createdAt = ISO8601DateFormatter().date(from: user.createdAt ?? "") ?? Date()
        userEntity.lastActive = ISO8601DateFormatter().date(from: user.lastActive ?? "") ?? Date()
        
        save()
    }
    
    func fetchUser(byApiId apiId: String) -> UserEntity? {
        let request: NSFetchRequest<UserEntity> = UserEntity.fetchRequest()
        request.predicate = NSPredicate(format: "apiId == %@", apiId)
        request.fetchLimit = 1
        
        do {
            let users = try context.fetch(request)
            return users.first
        } catch {
            logError("Failed to fetch user: \(error)")
            return nil
        }
    }
    
    // MARK: - Listing Operations
    func saveListings(_ listings: [Listing]) {
        listings.forEach { listing in
            let listingEntity = ListingEntity(context: context)
            listingEntity.id = String(listing.id)
            listingEntity.listingId = String(listing.id) // Use same ID for consistency
            listingEntity.userId = Int32(Int(listing.userId) ?? 0)
            listingEntity.userApiId = String(Int(listing.userId) ?? 0)
            listingEntity.title = listing.title
            listingEntity.listingDescription = listing.description
            listingEntity.price = String(listing.price)
            listingEntity.pricePerDay = nil // Will be calculated from price and priceType
            listingEntity.buyoutValue = nil // buyoutValue not available in new model
            listingEntity.createdAt = listing.createdAt
            listingEntity.status = listing.status
            listingEntity.category = listing.category?.name ?? "General"
            listingEntity.location = listing.location.formattedAddress
            listingEntity.views = Int32(listing.viewCount)
            listingEntity.timesBorrowed = 0 // timesBorrowed not available in new model
            listingEntity.inventoryAmt = Int32(listing.inventoryAmt)
            listingEntity.isFree = listing.isFree
            listingEntity.isArchived = listing.isArchived
            listingEntity.type = listing.price == 0 ? "free" : "daily"
            listingEntity.rating = listing.ownerRating != nil ? String(listing.ownerRating!) : nil
            listingEntity.isActive = listing.isActive
            listingEntity.isFavorite = false // Set default value for isFavorite
            
            // Encode image URLs as JSON data
            if let imageData = try? JSONEncoder().encode(listing.imageUrls) {
                listingEntity.images = imageData
            }
        }
        
        save()
    }
    
    func fetchListings() -> [ListingEntity] {
        let request: NSFetchRequest<ListingEntity> = ListingEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \ListingEntity.createdAt, ascending: false)]
        
        do {
            return try context.fetch(request)
        } catch {
            logError("Failed to fetch listings: \(error)")
            return []
        }
    }
    
    func fetchFavoriteListings() -> [ListingEntity] {
        let request: NSFetchRequest<ListingEntity> = ListingEntity.fetchRequest()
        request.predicate = NSPredicate(format: "isFavorite == true")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \ListingEntity.createdAt, ascending: false)]
        
        do {
            return try context.fetch(request)
        } catch {
            logError("Failed to fetch favorite listings: \(error)")
            return []
        }
    }
    
    func toggleFavorite(listingId: String) {
        let request: NSFetchRequest<ListingEntity> = ListingEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", listingId)
        
        do {
            let listings = try context.fetch(request)
            if let listing = listings.first {
                listing.isFavorite.toggle()
                save()
            }
        } catch {
            logError("Failed to toggle favorite: \(error)")
        }
    }
    
    // MARK: - Garage Sale Operations
    func saveGarageSales(_ garageSales: [GarageSale]) {
        garageSales.forEach { garageSale in
            let entity = GarageSaleEntity(context: context)
            entity.id = String(garageSale.id)
            entity.hostId = String(garageSale.userId)
            entity.title = garageSale.title
            entity.saleDescription = garageSale.description ?? ""
            entity.location = garageSale.address ?? garageSale.location
            entity.latitude = garageSale.latitude ?? 0.0
            entity.longitude = garageSale.longitude ?? 0.0
            entity.startDate = Date() // Convert from string later
            entity.endDate = Date() // Convert from string later
            entity.createdAt = Date() // Convert from string later
            entity.updatedAt = Date() // Convert from string later
            entity.status = garageSale.isActive ? "active" : "inactive"
            entity.attendeeCount = Int32(garageSale.rsvpCount)
            entity.maxAttendees = 0
            entity.isPublic = true
            
            // Encode arrays as JSON data
            if let imageData = try? JSONEncoder().encode(garageSale.photos.map { $0.url }) {
                entity.images = imageData
            }
            if let tagsData = try? JSONEncoder().encode(garageSale.categories) {
                entity.tags = tagsData
            }
        }
        
        save()
    }
    
    func fetchGarageSales() -> [GarageSaleEntity] {
        let request: NSFetchRequest<GarageSaleEntity> = GarageSaleEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \GarageSaleEntity.startDate, ascending: true)]
        
        do {
            return try context.fetch(request)
        } catch {
            logError("Failed to fetch garage sales: \(error)")
            return []
        }
    }
    
    // MARK: - Seek Operations
    func saveSeeks(_ seeks: [Seek]) {
        seeks.forEach { seek in
            let entity = SeekEntity(context: context)
            entity.id = String(seek.id)
            entity.userId = String(seek.userId)
            entity.title = seek.title
            entity.seekDescription = seek.description
            entity.category = seek.category
            entity.location = seek.location
            entity.latitude = seek.latitude ?? 0.0
            entity.longitude = seek.longitude ?? 0.0
            entity.maxDistance = seek.maxDistance
            entity.minBudget = seek.minBudget ?? 0.0
            entity.maxBudget = seek.maxBudget ?? 0.0
            entity.urgency = seek.urgency
            entity.status = seek.status
            entity.createdAt = ISO8601DateFormatter().date(from: seek.createdAt) ?? Date()
            entity.expiresAt = seek.expiresAt != nil ? ISO8601DateFormatter().date(from: seek.expiresAt!) : nil
            entity.matchCount = Int32(seek.matchCount)
            
            // Encode arrays as JSON data
            if let imageData = try? JSONEncoder().encode(seek.images) {
                entity.images = imageData
            }
            if let tagsData = try? JSONEncoder().encode(seek.tags) {
                entity.tags = tagsData
            }
        }
        
        save()
    }
    
    func fetchSeeks() -> [SeekEntity] {
        let request: NSFetchRequest<SeekEntity> = SeekEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \SeekEntity.createdAt, ascending: false)]
        
        do {
            return try context.fetch(request)
        } catch {
            logError("Failed to fetch seeks: \(error)")
            return []
        }
    }
    
    // MARK: - Shaiitech Integration
    private func logActivity(_ message: String) {
        // Log to Shaiitech BlackBox Z1
        _ = ActivityLog(
            action: "core_data_operation",
            message: message,
            timestamp: Date(),
            userId: AuthManager.shared.currentUser?.apiId
        )
        
        // TODO: Send to BlackBox Z1 endpoint
        print("🔒 BlackBox Z1: \(message)")
    }
    
    private func logError(_ message: String) {
        // Log to Shaiitech PEST X1
        _ = ErrorLog(
            message: message,
            timestamp: Date(),
            userId: AuthManager.shared.currentUser?.apiId,
            context: "Core Data"
        )
        
        // TODO: Send to PEST X1 endpoint
        print("🐛 PEST X1: \(message)")
    }
}

// MARK: - Logging Models
struct ActivityLog {
    let action: String
    let message: String
    let timestamp: Date
    let userId: String?
}

struct ErrorLog {
    let message: String
    let timestamp: Date
    let userId: String?
    let context: String
}

// MARK: - Core Data Model Extensions
extension UserEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<UserEntity> {
        return NSFetchRequest<UserEntity>(entityName: "UserEntity")
    }
}

extension ListingEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<ListingEntity> {
        return NSFetchRequest<ListingEntity>(entityName: "ListingEntity")
    }
}

extension GarageSaleEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<GarageSaleEntity> {
        return NSFetchRequest<GarageSaleEntity>(entityName: "GarageSaleEntity")
    }
}

extension SeekEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<SeekEntity> {
        return NSFetchRequest<SeekEntity>(entityName: "SeekEntity")
    }
}
