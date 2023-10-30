//
//  SketchDetailView.swift
//  Cogitator2
//
//  Created by Danilo Campos on 10/27/23.
//

import SwiftUI

struct SketchDetailView: View {
    
    @ObservedObject var sketch: Sketch
    @State private var inputSchema: [Parameter] = []

    
    func labeledField(title: String, binding: Binding<String>) -> some View {
        
        return VStack(alignment: .leading, spacing: .defaultMeasure / 2){
            Text(title)
                .foregroundStyle(.secondary)
                .font(.caption)
            TextField(title, text: binding)
        }
    }
    
    var inputList: some View {
        List {
            
            ForEach(inputSchema) { parameter in
                
                InputFieldView(parameter: parameter)
            }
        }
    }
    
    func handleNewSchema(_ newSchema: [Parameter]) {
        self.inputSchema = newSchema.sorted()
        
    }
    
    var body: some View {
        Group {
            
            VStack(spacing: .defaultMeasure * 2) {

                labeledField(title: "Sketch Name", binding: $sketch.title ?? "Unnamed")
                
                labeledField(title: "Host URL", binding: $sketch.hostURLString ?? "http://greatwhite.local:5000")
                
                inputList
            }
        }
        .padding()
        .navigationTitle(sketch.title ?? "")
        .onReceive(sketch.prompt!.parameters.publisher) { _ in
            if let newSchema = sketch.prompt?.keyedParameters.values {
                handleNewSchema(Array(newSchema))
            } else {
                inputSchema = []
            }
        }
    }
}

#Preview {
    SketchDetailView(sketch: Sketch(context: PersistenceController.preview.container.viewContext))

    
}
