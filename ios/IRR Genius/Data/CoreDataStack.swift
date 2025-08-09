//
//  CoreDataStack.swift
//  IRR Genius
//
//

import CoreData
import Foundation

class CoreDataStack {
    static let shared = CoreDataStack()

    private init() {}

    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "IRRGenius")

        // Performance optimizations
        for storeDescription in container.persistentStoreDescriptions {
            // Enable persistent history tracking for CloudKit sync
            storeDescription.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
            storeDescription.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)

            // Enable WAL mode and optimize for performance using SQLite pragmas
            let pragmas = [
                "journal_mode": "WAL",
                "synchronous": "NORMAL",
                "cache_size": "20000",
                "temp_store": "MEMORY",
            ]
            storeDescription.setOption(pragmas as NSDictionary, forKey: NSSQLitePragmasOption)
        }

        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                fatalError("Core Data error: \(error), \(error.userInfo)")
            }
        }

        // Configure main context for UI operations
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy

        // Set up background context for heavy operations
        setupBackgroundContext()

        return container
    }()

    // Background context for heavy operations
    lazy var backgroundContext: NSManagedObjectContext = {
        let context = persistentContainer.newBackgroundContext()
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return context
    }()

    private func setupBackgroundContext() {
        // Listen for background context saves and merge into main context
        NotificationCenter.default.addObserver(
            forName: .NSManagedObjectContextDidSave,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self = self,
                  let context = notification.object as? NSManagedObjectContext,
                  context !== self.persistentContainer.viewContext else { return }

            self.persistentContainer.viewContext.mergeChanges(fromContextDidSave: notification)
        }
    }

    func save() {
        let context = persistentContainer.viewContext

        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nsError = error as NSError
                fatalError("Core Data save error: \(nsError), \(nsError.userInfo)")
            }
        }
    }

    func saveBackground() {
        backgroundContext.perform { [weak self] in
            guard let self = self else { return }

            if self.backgroundContext.hasChanges {
                do {
                    try self.backgroundContext.save()
                } catch {
                    print("Background save error: \(error)")
                }
            }
        }
    }

    // Batch operations for better performance
    func performBatchOperation<T>(_ operation: @escaping (NSManagedObjectContext) throws -> T) async throws -> T {
        return try await withCheckedThrowingContinuation { continuation in
            backgroundContext.perform {
                do {
                    let result = try operation(self.backgroundContext)
                    continuation.resume(returning: result)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    // Memory management
    func clearMemoryCache() {
        persistentContainer.viewContext.refreshAllObjects()
        backgroundContext.refreshAllObjects()
    }

    // Performance monitoring
    func enableSQLiteDebugging() {
        #if DEBUG
            for storeDescription in persistentContainer.persistentStoreDescriptions {
                // Enable SQLite debugging through pragma
                var pragmas = storeDescription.options[NSSQLitePragmasOption] as? [String: Any] ?? [:]
                pragmas["debug"] = "1"
                storeDescription.setOption(pragmas as NSDictionary, forKey: NSSQLitePragmasOption)
            }
        #endif
    }

    // For testing purposes
    static func createInMemoryContainer() -> NSPersistentContainer {
        let container = NSPersistentContainer(name: "IRRGenius")
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        container.persistentStoreDescriptions = [description]

        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                fatalError("In-memory Core Data error: \(error), \(error.userInfo)")
            }
        }

        return container
    }
}
