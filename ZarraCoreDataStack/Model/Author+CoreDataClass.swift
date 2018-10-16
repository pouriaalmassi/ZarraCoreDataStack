//
//  Author+CoreDataClass.swift
//  ZarraCoreDataStack
//
//  Created by Pouria Almassi on 15/10/18.
//  Copyright © 2018 The City. All rights reserved.
//
//

import Foundation
import CoreData


public class Author: NSManagedObject {
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        id = UUID()
    }
}
