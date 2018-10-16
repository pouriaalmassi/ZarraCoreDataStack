//
//  Author+CoreDataProperties.swift
//  ZarraCoreDataStack
//
//  Created by Pouria Almassi on 15/10/18.
//  Copyright © 2018 The City. All rights reserved.
//
//

import Foundation
import CoreData


extension Author {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Author> {
        return NSFetchRequest<Author>(entityName: "Author")
    }

    @NSManaged public var name: String?
    @NSManaged public var id: UUID?
    @NSManaged public var books: Set<Book>?
}

// MARK: Generated accessors for books
extension Author {

    @objc(addBooksObject:)
    @NSManaged public func addToBooks(_ value: Book)

    @objc(removeBooksObject:)
    @NSManaged public func removeFromBooks(_ value: Book)

    @objc(addBooks:)
    @NSManaged public func addToBooks(_ values: NSSet)

    @objc(removeBooks:)
    @NSManaged public func removeFromBooks(_ values: NSSet)

}
