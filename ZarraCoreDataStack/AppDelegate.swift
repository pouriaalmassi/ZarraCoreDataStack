//
//  AppDelegate.swift
//  ZarraCoreDataStack
//
//  Created by Pouria Almassi on 15/10/18.
//  Copyright © 2018 The City. All rights reserved.
//

import UIKit

@UIApplicationMain
final class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    private var persistenceController: PersistenceController?

    // MARK: - UIApplicationDelegate

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        persistenceController = PersistenceController { [weak self] in
            self?.completeUserInterface()
        }
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        persistenceController?.save()
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        persistenceController?.save()
    }

    func applicationWillTerminate(_ application: UIApplication) {
        persistenceController?.save()
    }

    // MARK: - Core Data

    private func completeUserInterface() {
        // Application code goes here
        // Finally, we decide where the rest of the User Interface code goes.
        // If we had a temporary user interface set up to handle migrations, etc.,
        // then we would be switching it out here for the full interface and continuing on.
        guard let persistenceController = persistenceController else { return }

        window = UIWindow(frame: UIScreen.main.bounds)

        let vc = ViewController()
        vc.configure(persistenceController)

        window?.rootViewController = vc
        window?.backgroundColor = .white
        window?.makeKeyAndVisible()
    }
}

