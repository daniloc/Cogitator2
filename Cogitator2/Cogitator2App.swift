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
    
    @Environment(\.undoManager) var undoManager


    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .onChange(of: undoManager) { newManager in
                    print("UndoManager changed!")
                    if newManager != nil {
                        print("The new manager is not nil!")
                    } else {
                        print("The new manager is nil!")
                    }
                    PersistenceController.shared.container.viewContext.undoManager = newManager
                }
                .onAppear {
                    if undoManager != nil {
                        print("Got an UndoManager on appear")
                        PersistenceController.shared.container.viewContext.undoManager = undoManager
                    } else {
                        print("This view appeared with no UndoManager!")
                    }
                }

        }


    }
}
