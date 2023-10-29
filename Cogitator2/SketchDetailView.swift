//
//  SketchDetailView.swift
//  Cogitator2
//
//  Created by Danilo Campos on 10/27/23.
//

import SwiftUI

struct SketchDetailView: View {
    
    @ObservedObject var sketch: Sketch
    @State private var inputSchema: [JSONSchema]?

    
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
            
            ForEach(inputSchema?.indices ?? 0..<0, id: \.self) { index in
                
                if let input = inputSchema?[index] {
                    SchemaFieldView(schemaField: input)
                }
            }
        }
    }
    
    func handleNewSchema(_ newSchema: [JSONSchema]) {

                self.inputSchema = newSchema

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
        .onReceive(sketch.inputSchemaPublisher) { newSchema in
            if let newSchema = newSchema {
                handleNewSchema(newSchema)
            } else {
                inputSchema = []
            }
        }
    }
}

#Preview {
    SketchDetailView(sketch: Sketch(context: PersistenceController.preview.container.viewContext))

    
}
