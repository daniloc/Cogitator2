//
//  SketchDetailView.swift
//  Cogitator2
//
//  Created by Danilo Campos on 10/27/23.
//

import SwiftUI

struct PromptInputListView: View {
    @ObservedObject var prompt: Prompt
    
    var body: some View {
        List {
            
            ForEach(prompt.orderedParameters) { parameter in
                InputFieldView(parameter: parameter)
            }
        }
        .border(.separator)
    }
}

struct SketchDetailView: View {
    
    @ObservedObject var sketch: Sketch
    
    func labeledField(title: String, binding: Binding<String>) -> some View {
        
        return VStack(alignment: .leading, spacing: .defaultMeasure / 2){
            Text(title)
                .foregroundStyle(.secondary)
                .font(.caption)
            TextField(title, text: binding)
        }
    }
    
    var promptEditor: some View {
        Group {
            
            VStack(spacing: .defaultMeasure * 2) {

                labeledField(title: "Sketch Name", binding: $sketch.title ?? "Unnamed")
                
                HStack(alignment: .bottom) {
                    labeledField(title: "Host URL", binding: $sketch.hostURLString ?? "http://greatwhite.local:5000")
                    Button {
                        sketch.loadSchema()
                    } label: {
                        Text("Load Schema")
                    }

                }
                
                if let prompt = sketch.prompt {
                    PromptInputListView(prompt: prompt)
                }
                
                Button {
                    sketch.requestNewPrediction()
                } label: {
                    Text("Run Prediction")
                        .frame(maxWidth: .infinity)
                }

            }
            .padding(.trailing, .defaultMeasure * 2)
        }
        .onAppear {
            sketch.prompt?.updateOrderedParameters()
        }

    }
    
    var body: some View {
        HSplitView {
            promptEditor
                .frame(minWidth: 500)
            PredictionResultListView(sketch: sketch)


        }
        .padding()
        .navigationTitle(sketch.title ?? "")
    }
}

#Preview {
    SketchDetailView(sketch: Sketch.previewEntity)
        .frame(height: 800)
    
}
