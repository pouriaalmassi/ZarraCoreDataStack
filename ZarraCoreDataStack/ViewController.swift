//
//  ViewController.swift
//  ZarraCoreDataStack
//
//  Created by Pouria Almassi on 15/10/18.
//  Copyright © 2018 The City. All rights reserved.
//

import UIKit

final class ViewController: UIViewController {
    private var persistenceController: PersistenceController!

    func configure(_ persistenceController: PersistenceController) {
        self.persistenceController = persistenceController
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Mark: - Create

        guard let philipKDick = persistenceController.createAuthor(with: "Philip K. Dick") else { return }
        guard let bretEastonEllis = persistenceController.createAuthor(with: "Bret Easton Ellis") else { return }
        persistenceController.createBook(with: "Less Than Zero", author: bretEastonEllis)
        persistenceController.createBook(with: "American Psycho", author: bretEastonEllis)
        persistenceController.createBook(with: "Faith of Our Fathers", author: philipKDick)

        // Mark: - Read

        persistenceController.authors().forEach { author in
            print("\(author.name!)")
            if let booksSet = author.books {
                booksSet.forEach { book in
                    print("- \(book.title!)")
                }
            }
        }

        // Get specific author and books
        let booksByBretEastonEllis: [Book] = persistenceController.books(by: bretEastonEllis)
        print("Number of books by Bret Easton Ellis: \(booksByBretEastonEllis.count)")
        print("========================================")

        // Mark: - Update

        philipKDick.setValue("Philip Kindred Dick", forKey: "name")
        persistenceController.save()
        print("Updated name: \(philipKDick.name!)")
        print("========================================")

        // Mark: - Delete

        print("Number of authors before delete: \(persistenceController.authors().count)")
        let allBooks = persistenceController.books()
        print("Number of books before delete: \(String(describing: allBooks.count))")

        guard let anAuthor = persistenceController.authors().first else { return }
        print("Delete author: \(anAuthor.name!)")

        persistenceController.delete(anAuthor) { [weak self] in
            print("Number of authors after delete: \(String(describing: self?.persistenceController.authors().count))")
            let allBooks = self?.persistenceController.books()
            print("Number of books after delete: \(String(describing: allBooks?.count))")
            assert(allBooks!.count < 3, "Total number of books after delete should be less than total initially added.")
        }
    }
}
