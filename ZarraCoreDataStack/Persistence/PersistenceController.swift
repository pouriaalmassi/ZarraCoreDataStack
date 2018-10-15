//
//  PersistenceController.swift
//  ZarraCoreDataStack
//
//  Created by Pouria Almassi on 15/10/18.
//  Copyright © 2018 The City. All rights reserved.
//

import Foundation
import CoreData

// Source: http://martiancraft.com/blog/2015/03/core-data-stack/

final class PersistenceController: NSObject {
    typealias InitCallbackBlock = () -> ()

    internal var managedObjectContext: NSManagedObjectContext?
    private var privateContext: NSManagedObjectContext?
    private var initCallbackBlock: (InitCallbackBlock)?

    init(_ initCallbackBlock: @escaping InitCallbackBlock) {
        super.init()
        self.initializeCoreData()
        self.setInitCallback(initCallbackBlock)
    }

    private func initializeCoreData() {
        guard
            managedObjectContext == nil,
            let modelURL = Bundle.main.url(forResource: "DataModel", withExtension: "momd"),
            let mom = NSManagedObjectModel(contentsOf: modelURL)
            else { return }

        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: mom)

        managedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        privateContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)

        privateContext?.persistentStoreCoordinator = coordinator
        managedObjectContext?.parent = privateContext

        DispatchQueue.global(qos: .background).async {
            guard let psc = self.privateContext?.persistentStoreCoordinator else { return }

            var options = [String: Any]()
            options[NSMigratePersistentStoresAutomaticallyOption] = true
            options[NSInferMappingModelAutomaticallyOption] = true
            options[NSSQLitePragmasOption] = ["journal_mode": "DELETE"]

            let fileManager = FileManager.default
            guard let documentsURL = fileManager.urls(for: FileManager.SearchPathDirectory.documentDirectory, in: FileManager.SearchPathDomainMask.userDomainMask).last else { return }
            let storeURL = documentsURL.appendingPathComponent("DataModel.sqlite")

            do {
                try psc.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: storeURL, options: options)
            } catch {
                fatalError("Error: Adding persistent store.")
            }

            guard let initCallbackBlock = self.initCallbackBlock else { return }

            // "This can probably be called asynchronously but I am a
            // ‘belt and suspenders’ type of guy when it comes to this stuff."
            DispatchQueue.main.sync {
                initCallbackBlock()
            }
        }
    }

    private func setInitCallback(_ initCallbackBlock: @escaping InitCallbackBlock) {
        self.initCallbackBlock = initCallbackBlock
    }

    func save() {
        guard
            let privateContext = privateContext,
            let managedObjectContext = managedObjectContext,
            privateContext.hasChanges == true,
            managedObjectContext.hasChanges == true
            else { return }

        // Since we cannot guarantee that caller is the main thread, we
        // use --performBlockAndWait: against the main context to insure
        // we are talking to it on its own terms.
        managedObjectContext.performAndWait {
            // Once the main context has saved then we move on to the private queue.
            // This queue can be asynchronous without any issues so we call --performBlock:
            // on it and then call save.
            privateContext.perform {
                do {
                    try privateContext.save()
                } catch {
                    fatalError("Error saving.")
                }
            }
        }
    }
}
