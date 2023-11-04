//
//  PredictionResultListView.swift
//  Cogitator2
//
//  Created by Danilo Campos on 10/28/23.
//

import SwiftUI

struct ActionButton: View {
    let symbolName: String
    let title: String
    let action: () -> Void
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(.windowBackground)
            HStack {
                Image(systemName: symbolName)
                Text(title)
            }
        }
        .onTapGesture {
            action()
        }

        .padding(2)


    }
}

struct PredictionResultCell: View {
    @ObservedObject var predictionResult: PredictionResult
    
    @Environment(\.undoManager) var undoManager


    var body: some View {
        
        VStack {
            
            HStack(alignment: .top) {
                
                if let image = predictionResult.image {
                    image
                        .resizable()
                        .frame(width: 200, height: 200)
                        .onTapGesture(count: 2) {
                            predictionResult.openInWindow()
                        }
                } else {
                    Text("Loading")
                        .onAppear {
                            predictionResult.loadImage()
                        }
                }
                
                VStack(alignment: .leading) {
                    Text(predictionResult.date?.formatted() ?? "No date")
                    
                    Text(predictionResult.prompt?.summary ?? "No summary")
                        .textSelection(.enabled)
                    
                }
                .font(.system(.caption, design: .monospaced))
                

                
            }
            
            HStack {
                ActionButton(symbolName: "clear", title: "Remove") {
                    
                    if let undoManager {
                        PersistenceController.viewContext.undoManager = undoManager
                    }
                    
                    predictionResult.remove()
                }
                
                ActionButton(symbolName: "square.and.arrow.down", title: "Save to Downloads") {
                    predictionResult.saveImageToDownloads()
                }
            }
            .frame(height: 30)
        }
    }
}

struct PredictionResultListView: View {
        
    @FetchRequest private var results: FetchedResults<PredictionResult>
    
    init(sketch: Sketch) {
        let sortDescriptor = NSSortDescriptor(key: "date", ascending: false)
        let predicate: NSPredicate = NSPredicate(format: "sketch == %@", sketch)
        

        _results = FetchRequest(
            entity: PredictionResult.entity(),
            sortDescriptors: [sortDescriptor],
            predicate: predicate
        )
                
    }
    

    
    var body: some View {

        VStack {
            
            Text("Results: \(results.count)")
                .foregroundStyle(.secondary)
            
            List {
                ForEach(results) { result in
                        PredictionResultCell(predictionResult: result)
                        .frame(width: 400)
                    }

                }
            .border(.separator)

            }
            .frame(minWidth: 250, idealWidth: 250)
            .padding(.horizontal)
        }
}

#Preview {
    PredictionResultListView(sketch: Sketch(context: PersistenceController.preview.container.viewContext))
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    
}
