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
        guard let privateContext = privateContext else {
            return
        }
        guard let managedObjectContext = managedObjectContext else {
            return
        }
        guard privateContext.hasChanges || managedObjectContext.hasChanges else {
            return
        }

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

    // Domain specific functionality

    // MARK: - Create

    @discardableResult
    func createAuthor(with name: String) -> Author? {
        guard let privateContext = privateContext else { return nil }
        var createdAuthor: Author? // hacky
        privateContext.performAndWait { [weak self] in
            let author = Author(context: privateContext)
            author.name = name
            createdAuthor = author
            self?.save()
        }
        return createdAuthor
    }

    func createBook(with title: String, author: Author) {
        guard let privateContext = privateContext else { return }
        privateContext.performAndWait { [weak self] in
            let book = Book(context: privateContext)
            book.title = title
            book.author = author
            book.authorId = author.id
            self?.save()
        }
    }

    // MARK: - Read

    private func objects<T>(from entity: String, sortDescriptor: NSSortDescriptor, fetchLimit: Int? = nil) -> [T] {
        guard
            let managedObjectContext = managedObjectContext,
            let privateContext = privateContext
            else { return [] }

        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entity)
        let entityDescription = NSEntityDescription.entity(forEntityName: entity, in: managedObjectContext)

        fetchRequest.entity = entityDescription
        fetchRequest.sortDescriptors = [sortDescriptor]
        if let fetchLimit = fetchLimit { fetchRequest.fetchLimit = fetchLimit }

        do {
            guard let objects = try privateContext.fetch(fetchRequest) as? [T] else { return [] }
            return objects
        } catch {
            print("Error fetching")
            return []
        }
    }

    func authors(_ limit: Int? = nil) -> [Author] {
        let sortDescriptor = NSSortDescriptor(key: "name", ascending: true)
        return objects(from: "Author", sortDescriptor: sortDescriptor, fetchLimit: limit)
    }

    func books(_ limit: Int? = nil) -> [Book] {
        let sortDescriptor = NSSortDescriptor(key: "title", ascending: true)
        return objects(from: "Book", sortDescriptor: sortDescriptor, fetchLimit: limit)
    }
    
    func books(by author: Author) -> [Book] {
        guard
            let id: UUID = author.id,
            let privateContext = privateContext
            else {
                return []
        }
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Book")
        fetchRequest.entity = Book.entity()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "title", ascending: true)]
        fetchRequest.predicate = NSPredicate(format: "%K == %@", "authorId", id as CVarArg)
        
        do {
            guard let books = try privateContext.fetch(fetchRequest) as? [Book] else { return [] }
            return books
        } catch {
            print("Error fetching")
            return []
        }
    }
}
