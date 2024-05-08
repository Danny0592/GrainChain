//
//  GrainChainApp.swift
//  GrainChain
//
//  Created by daniel ortiz millan on 06/05/24.
//

import SwiftUI

@main
struct GrainChainApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
