//
//  Book+CoreDataProperties.swift
//  ZarraCoreDataStack
//
//  Created by Pouria Almassi on 15/10/18.
//  Copyright © 2018 The City. All rights reserved.
//
//

import Foundation
import CoreData


extension Book {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Book> {
        return NSFetchRequest<Book>(entityName: "Book")
    }

    @NSManaged public var title: String?
    @NSManaged public var id: UUID?
    @NSManaged public var author: Author?

}
