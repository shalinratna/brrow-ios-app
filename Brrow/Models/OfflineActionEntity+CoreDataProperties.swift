//
//  OfflineActionEntity+CoreDataProperties.swift
//  Brrow
//
//  Core Data properties for offline actions
//

import Foundation
import CoreData

extension OfflineActionEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<OfflineActionEntity> {
        return NSFetchRequest<OfflineActionEntity>(entityName: "OfflineActionEntity")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var actionType: String?
    @NSManaged public var payload: Data?
    @NSManaged public var createdAt: Date?
    @NSManaged public var retryCount: Int16
    @NSManaged public var syncStatus: String?

}