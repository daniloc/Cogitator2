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
    @State var urlFieldStatus: FieldStatus?
    @State var predictionStatus: FieldStatus?
    @State var lastResults: [PredictionResult]?
    
    enum FieldStatus: Equatable {
        case normal,
             awaitingData,
             error(detail: String)
    }
    
    func statusLabel(title: String, status: FieldStatus? = nil) -> some View {
        return HStack(spacing: 2) {
            
            if case .error(let detail) = status {
                Group {
                    Image(systemName: "exclamationmark.triangle")
                    Text("\(title): \(detail)")
                    
                }
                .foregroundStyle(.red)
                
            } else {
                Text(title)
                
                if status == .awaitingData {
                    ProgressView()
                        .scaleEffect(0.25)
                }
            }
            
        }
        .frame(height: 20)
        .foregroundStyle(.secondary)
        .font(.caption)
    }
    
    func labeledField(title: String, binding: Binding<String>, status: FieldStatus? = nil) -> some View {
        
        return VStack(alignment: .leading, spacing: .defaultMeasure / 2){
            statusLabel(title: title, status: status)
            TextField(title, text: binding)
        }
    }
    
    func loadSchema() {
        
        Task {
            do {
                urlFieldStatus = .awaitingData
                try await sketch.loadSchema()
                urlFieldStatus = .normal
            } catch Sketch.SchemaValidationError.invalidURL {
                urlFieldStatus = .error(detail: "Invalid URL")
            } catch Sketch.SchemaValidationError.unableToParse(let parseIssue) {
                urlFieldStatus = .error(detail: "Unable to parse OpenAPI document: \(parseIssue)")
            } catch Sketch.SchemaValidationError.unableToConnect(let connectionIssue) {
                urlFieldStatus = .error(detail: "Unable to connect: \(connectionIssue.localizedDescription)")
            }
        }
    }
    
    func requestPrediction() {
        
        Task {
            do {
                predictionStatus = .awaitingData
                
                let results = try await sketch.requestNewPrediction()
                
                self.lastResults = results
                predictionStatus = .normal
                
            } catch {
                predictionStatus = .error(detail: error.localizedDescription)
            }
        }
    }
    
    var predictionStatusLabel: some View {
        
        Group {
            
            if predictionStatus == nil || predictionStatus == .normal {
                statusLabel(title: "Idle.")
            } else if predictionStatus == .awaitingData {
                statusLabel(title: "Awaiting prediction...")
            } else if case .error(let detail) = predictionStatus {
                statusLabel(title: "Prediction error: \(detail)")
            }
        }
    }
    
    var promptEditor: some View {
        Group {
            
            VStack(spacing: .defaultMeasure * 2) {
                
                labeledField(title: "Sketch Name", binding: $sketch.title ?? "Unnamed")
                
                HStack(alignment: .bottom) {
                    labeledField(title: "Host URL", binding: $sketch.hostURLString ?? "http://greatwhite.local:5000", status: urlFieldStatus)
                    Button {
                        loadSchema()
                    } label: {
                        Text("Load Schema")
                    }
                    
                }
                
                if let prompt = sketch.prompt {
                    PromptInputListView(prompt: prompt)
                }
                
                VStack(alignment: .leading){
                    
                    predictionStatusLabel
                    
                    Button {
                        requestPrediction()
                    } label: {
                        
                        HStack {
                            
                            Text("Run Prediction")
                                .frame(maxWidth: .infinity)
                            
                            if predictionStatus == .awaitingData {
                                ProgressView()
                                    .scaleEffect(0.25)
                            }
                        }
                        .frame(height: 30)
                    }
                    .disabled(predictionStatus == .awaitingData)
                    .padding([.bottom, .horizontal], 2)
                    
                }
                
                
                
            }
            .padding(.trailing, .defaultMeasure * 2)
        }
        .onAppear {
            sketch.prompt?.updateOrderedParameters()
        }
        
    }
    
    var body: some View {
        HStack {
            promptEditor
                .frame(minWidth: 500)
            PredictionResultListView(sketch: sketch)
                .frame(width: 475)
        }
        .padding()
        .navigationTitle(sketch.title ?? "")
        .onChange(of: lastResults) { _, newValue in
            
            newValue?.forEach { result in
                result.openInWindow()
            }
            
        }
    }
}

#Preview {
    SketchDetailView(sketch: Sketch.previewEntity)
        .frame(height: 800)
    
}
