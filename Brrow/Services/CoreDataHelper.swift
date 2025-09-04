//
//  CoreDataHelper.swift
//  Brrow
//
//  Helper to reset CoreData if corrupted
//

import CoreData
import Foundation

class CoreDataHelper {
    static let shared = CoreDataHelper()
    
    private init() {}
    
    func resetCoreDataIfNeeded() {
        // Check if we can access CoreData
        let container = NSPersistentContainer(name: "BrrowDataModel")
        
        container.loadPersistentStores { _, error in
            if let error = error {
                print("❌ CoreData error detected: \(error)")
                print("🔧 Attempting to reset CoreData...")
                
                // Remove existing stores
                self.deleteAllCoreDataStores()
                
                // Try loading again
                let newContainer = NSPersistentContainer(name: "BrrowDataModel")
                newContainer.loadPersistentStores { _, secondError in
                    if let secondError = secondError {
                        print("❌ Failed to recover CoreData: \(secondError)")
                    } else {
                        print("✅ CoreData reset successful")
                    }
                }
            }
        }
    }
    
    private func deleteAllCoreDataStores() {
        let storeCoordinator = NSPersistentStoreCoordinator(managedObjectModel: NSManagedObjectModel())
        
        guard let documentsDirectory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            return
        }
        
        let storeURL = documentsDirectory.appendingPathComponent("BrrowDataModel.sqlite")
        let walURL = documentsDirectory.appendingPathComponent("BrrowDataModel.sqlite-wal")
        let shmURL = documentsDirectory.appendingPathComponent("BrrowDataModel.sqlite-shm")
        
        // Remove all CoreData files
        for url in [storeURL, walURL, shmURL] {
            do {
                if FileManager.default.fileExists(atPath: url.path) {
                    try FileManager.default.removeItem(at: url)
                    print("🗑️ Deleted: \(url.lastPathComponent)")
                }
            } catch {
                print("❌ Failed to delete \(url.lastPathComponent): \(error)")
            }
        }
    }
}