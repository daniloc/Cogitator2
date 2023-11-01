//
//  NetworkClient.swift
//  Cogitator
//
//  Created by Danilo Campos on 5/6/23.
//

import Foundation
import OpenAPIKit30
import SwiftUI

class NetworkClient: ObservableObject {
    
    var baseURL: URL?
    var predictionEndpointPath = "predictions"
    var predictionEndpointURL: URL? {
        return self.baseURL?.appending(component: predictionEndpointPath)
    }
    
    enum SchemaKeys: String {
        case Input
    }
    
    init() {
    }
    
    func loadSchema(url: URL, sketch: Sketch) {
        
        self.baseURL = url
        
        let jsonDocumentURL = url.appending(path: "/openapi.json")
        
        Task {
            
            do {
                let jsonData = try await URLSession.shared.data(from: jsonDocumentURL).0

                let decoder = JSONDecoder()
                let apiDoc = try decoder.decode(OpenAPI.Document.self, from: jsonData)
                let derefApiDoc = try? apiDoc.locallyDereferenced().resolved()
                print(derefApiDoc ?? "no deref")
                
                
                derefApiDoc!.components.schemas.forEach { schema in
                    
                    if schema.key.rawValue == SchemaKeys.Input.rawValue {
                        
                        var inputValues: [String:JSONSchema] = [:]
                        
                        print(schema.value.objectContext ?? "")
                        
                        schema.value.objectContext?.properties.forEach { property in
                            inputValues[property.key] = property.value
                        }
                        
                        DispatchQueue.main.sync {
                            sketch.inputSchema = inputValues
                            PersistenceController.saveViewContextLoggingErrors()
                        }

                    }
                    
                }
                
            } catch {
                print(error)
            }
            
        }
    }
    
    func handle(output: [Any], for sketch: Sketch) {
        //TODO: Let's add some proper error handling here, this should throw instead of returning silently
        let fileManager = FileManager.default
        let appSupportDirectory = try? fileManager.url(for: .applicationSupportDirectory,
                                                       in: .userDomainMask,
                                                       appropriateFor: nil,
                                                       create: true)
        
        guard let directory = appSupportDirectory else { return }
        
        try? sketch.managedObjectContext?.save()
        
        let backgroundContext = PersistenceController.newBackgroundContext()
        
        output.forEach { content in
            let components = (content as! String).components(separatedBy: ",")
            
            if let base64content = components.last,
               let _ = Image(base64String: base64content), //Make sure it parses out into something readable
               let imageData = Data(base64Encoded: base64content),
               let contextSafeSketch = sketch.transferred(to: backgroundContext) {
                
                let result = PredictionResult(context: backgroundContext)
                
                // Create a unique file name
                let fileName = UUID().uuidString + ".png"
                let fileURL = directory.appendingPathComponent(fileName)
                
                do {
                    // Write to file
                    try imageData.write(to: fileURL)
                    
                    // Save file URL in Core Data object
                    result.imageFileURL = fileURL.absoluteString
                    
                    // Link the PredictionResult to the Sketch if needed
                    contextSafeSketch.addToResults(result)
                    contextSafeSketch.lastEdited = .now
                    result.date = .now
                    
                    if let prompt = sketch.prompt {
                        result.prompt = prompt.cloneWithoutRelationships(into: backgroundContext)
                        
                        prompt.orderedParameters.forEach { parameter in
                                
                            if let clonedParameter = parameter.cloneWithoutRelationships(into: backgroundContext) {
                                
                                result.prompt?.addToParameters(clonedParameter)
                            }
                        }
                    }
                    
                } catch {
                    // Handle the error
                    print("Error saving image: \(error)")
                }
            }
        }
        
        do {
            try backgroundContext.save()
        } catch {
            print("Error saving context: \(error)")
        }

    }
    
    func predict(with sketch: Sketch) {
        
        PersistenceController.saveViewContextLoggingErrors()
        
        if predictionEndpointURL == nil, let hostURLString = sketch.hostURLString {
            baseURL = URL(string: hostURLString)
        }
        
        //TODO: Let's add some proper error handling here, this should throw instead of returning silently
        guard let url = self.predictionEndpointURL,
              let prompt = sketch.prompt,
            prompt.predictionRequestDictionary.values.count > 0
        else {
            return
        }
        
        do {
            
            let wrappedParams = ["input": prompt.predictionRequestDictionary]
            
            let data = try JSONSerialization.data(withJSONObject: wrappedParams, options: [])

            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.httpBody = data
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                guard let data = data
                        
                else {
                    print("No data in response: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    print("statusCode: \(httpResponse.statusCode)")
                    
                    do {
                        let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                        
                        if let output = json?["output"] as? [Any] {
                            self.handle(output: output, for: sketch)
                        } else if let output = json?["output"] as? String {
                            self.handle(output: [output], for: sketch)
                        }
                        
                    } catch {
                        print("Error during JSON serialization: \(error)")
                    }
                }
                
            }
            
            task.resume()
        } catch {
            print("Error: \(error)")
        }
        
    }
//    private var responsesFileURL: URL {
//        let tmpDir = FileManager.default.temporaryDirectory
//        return tmpDir.appendingPathComponent("responses.json")
//    }
//    
//    func saveResponses() {
//        let encoder = JSONEncoder()
//        do {
//            let data = try encoder.encode(responses)
//            try data.write(to: responsesFileURL)
//        } catch {
//            print("Failed to save responses: \(error)")
//        }
//    }
//    
//    func loadResponses() {
//        do {
//            let data = try Data(contentsOf: responsesFileURL)
//            let decoder = JSONDecoder()
//            responses = try decoder.decode([PredictionResponse].self, from: data)
//        } catch {
//            print("Failed to load responses: \(error)")
//        }
//    }
//    
//    func removeResponse(response: PredictionResponse) {
//        responses.removeAll { $0.id == response.id }
//        saveResponses()
//    }
}

extension Data {
    
    func printJson() {
        do {
            let json = try JSONSerialization.jsonObject(with: self, options: [])
            let data = try JSONSerialization.data(withJSONObject: json, options: .prettyPrinted)
            guard let jsonString = String(data: data, encoding: .utf8) else {
                print("Inavlid data")
                return
            }
            print(jsonString)
        } catch {
            print("Error: \(error.localizedDescription)")
        }
    }
}

extension Image {
    init?(base64String: String) {
        guard let data = Data(base64Encoded: base64String) else { return nil }
#if os(macOS)
        guard let image = NSImage(data: data) else { return nil }
        self.init(nsImage: image)
#elseif os(iOS)
        guard let image = UIImage(data: data) else { return nil }
        self.init(uiImage: image)
#else
        return nil
#endif
    }
}
