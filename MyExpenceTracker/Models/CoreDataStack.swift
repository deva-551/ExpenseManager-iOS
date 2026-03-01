//
//  CoreDataStack.swift
//  MyExpenceTracker
//
//  Created by Devendran A on 23/02/26.
//

import Foundation
import CoreData
import Combine

class CoreDataStack: ObservableObject {
    static let shared = CoreDataStack()
    
    /// Set to true if the persistent store failed to load.
    @Published private(set) var loadError: Error?
    
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "ExpenseTracker")
        container.loadPersistentStores { [weak self] _, error in
            if let error = error {
                // Log the error; do NOT crash in production.
                print("⚠️ Core Data store failed to load: \(error.localizedDescription)")
                self?.loadError = error
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return container
    }()
    
    var viewContext: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    /// Saves the view context, returning any error instead of crashing.
    @discardableResult
    func save() -> Error? {
        let context = viewContext
        guard context.hasChanges else { return nil }
        
        do {
            try context.save()
            return nil
        } catch {
            print("⚠️ Core Data save error: \(error.localizedDescription)")
            return error
        }
    }
    
    private init() {}
}
