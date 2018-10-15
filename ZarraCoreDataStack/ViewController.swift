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

        //persistenceController.save()
//        print("!")
    }
}

