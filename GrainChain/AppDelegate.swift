//
//  AppDelegate.swift
//  GrainChain
//
//  Created by daniel ortiz millan on 06/05/24.
//

import Foundation
import UIKit
import GoogleMaps

class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // Configura tu API key de Google Maps aquí
        GMSServices.provideAPIKey("AIzaSyDav5l5MjkyDYrZOVAeBaxbmgSD2gPBzMo")
        return true
    }
}
