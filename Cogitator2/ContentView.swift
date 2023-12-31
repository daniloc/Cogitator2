//
//  ContentView.swift
//  Cogitator2
//
//  Created by Danilo Campos on 10/26/23.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Sketch.lastEdited, ascending: false)],
        animation: .default)
    private var sketches: FetchedResults<Sketch>
    @State var selectedSketch: Sketch? = nil

    var body: some View {
        NavigationView {
            List(selection: $selectedSketch) {
                ForEach(sketches) { item in
                    NavigationLink {
                        SketchDetailView(sketch: item)
                    } label: {
                        
                        VStack(alignment: .leading) {
                         
                            Text(item.title ?? "Unnamed Sketch")
                            
                            if let date = item.lastEdited {
                                Text(date.shortString)
                            }
                            
                        }
                    }
                }
                .onDelete(perform: deleteItems)

            }
            .background(.windowBackground)
            


            .toolbar {
#if os(iOS)
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
#endif
                ToolbarItem {
                    Button(action: addItem) {
                        Label("Add Item", systemImage: "plus")
                    }
                }
            }
        }
    }

    private func addItem() {
        withAnimation {
            let newItem = Sketch(context: viewContext)
            newItem.lastEdited = Date()
            
            do {
                try viewContext.save()
                selectedSketch = newItem

            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            offsets.map { sketches[$0] }.forEach(viewContext.delete)

            do {
                try viewContext.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
}

#Preview {
    ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
