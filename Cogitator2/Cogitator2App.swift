//
//  Cogitator2App.swift
//  Cogitator2
//
//  Created by Danilo Campos on 10/26/23.
//

import SwiftUI

@main
struct Cogitator2App: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
