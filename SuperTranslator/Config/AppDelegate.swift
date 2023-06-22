//
//  AppDelegate.swift
//  SuperTranslator
//
//  Created by Chaii on 22/06/23.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        self.setWelcomeScreen()
        return true
    }

    private func setWelcomeScreen() {
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.backgroundColor = .white
        let welcomeViewController = WelcomeViewController()
        let navController = UINavigationController(rootViewController: welcomeViewController)
        window?.rootViewController = navController
        window?.makeKeyAndVisible()
    }
}
