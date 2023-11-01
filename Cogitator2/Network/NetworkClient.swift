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
    
    func loadSchema(url: URL, sketch: Sketch) async throws {
        
        self.baseURL = url
        
        let jsonDocumentURL = url.appending(path: "/openapi.json")
        let jsonData: Data
        
        do {
            jsonData = try await URLSession.shared.data(from: jsonDocumentURL).0
        } catch {
            print("Error loading schema data: \(error)")
            throw Sketch.SchemaValidationError.unableToConnect(connectionError: error)
        }
        
        let decoder = JSONDecoder()
        let derefApiDoc: DereferencedDocument
        
        do {
            
            let apiDoc = try decoder.decode(OpenAPI.Document.self, from: jsonData)
            let derefApiDoc = try apiDoc.locallyDereferenced().resolved()
            
            derefApiDoc.components.schemas.forEach { schema in
                
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
            print("Error parsing schema: \(error)")
            throw Sketch.SchemaValidationError.unableToParse(parseError: error)
        }
        
    }
    
    func handle(output: [Any], for sketch: Sketch) throws {
        let fileManager = FileManager.default
        let appSupportDirectory: URL
        
        do {
           appSupportDirectory = try fileManager.url(for: .applicationSupportDirectory,
                                                           in: .userDomainMask,
                                                           appropriateFor: nil,
                                                           create: true)
        } catch {
            throw Sketch.PredictionError.localStorageError(fileError: error)
        }
        
        PersistenceController.saveViewContextLoggingErrors()
        let backgroundContext = PersistenceController.newBackgroundContext()
        
        try output.forEach { content in
            let components = (content as! String).components(separatedBy: ",")
            
            if let base64content = components.last,
               let _ = Image(base64String: base64content), //Make sure it parses out into something readable
               let imageData = Data(base64Encoded: base64content),
               let contextSafeSketch = sketch.transferred(to: backgroundContext) {
                
                let result = PredictionResult(context: backgroundContext)
                
                // Create a unique file name
                let fileName = UUID().uuidString + ".png"
                let fileURL = appSupportDirectory.appendingPathComponent(fileName)
                
                do {
                    // Write to file
                    try imageData.write(to: fileURL)
                    
                    // Save file URL in Core Data object
                    result.imageFileURL = fileURL.absoluteString
                    
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
                    
                    try backgroundContext.save()
                    
                } catch {
                    // Handle the error
                    print("Error saving image: \(error)")
                    throw Sketch.PredictionError.localStorageError(fileError: error)
                }
            }
        }
        
    }
    
    func predict(with sketch: Sketch) async throws {
        
        PersistenceController.saveViewContextLoggingErrors()
        
        if predictionEndpointURL == nil,
           let hostURLString = sketch.hostURLString
        {
            baseURL = URL(string: hostURLString)
        }
        
        if baseURL == nil {
            throw Sketch.PredictionError.invalidRequest
        }
        
        guard let url = self.predictionEndpointURL,
              let prompt = sketch.prompt,
              prompt.predictionRequestDictionary.values.count > 0
        else {
            throw Sketch.PredictionError.invalidRequest
        }
        
        do {
            
            let wrappedParams = ["input": prompt.predictionRequestDictionary]
            let inputData = try JSONSerialization.data(withJSONObject: wrappedParams, options: [])
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.httpBody = inputData
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                print("statusCode: \(httpResponse.statusCode)")
                

                
                do {
                    let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                    
                    if httpResponse.statusCode >= 400 {
                        throw Sketch.PredictionError.issueAtServer(serverError: String(describing: json))
                    }
                    
                    if let output = json?["output"] as? [Any] {
                        try self.handle(output: output, for: sketch)
                    } else if let output = json?["output"] as? String {
                        try self.handle(output: [output], for: sketch)
                    }
                    
                } catch {
                    print("Error during JSON serialization: \(error)")
                    throw Sketch.PredictionError.issueParsingResponse(parseError: error)
                }
            }
            
        } catch {
            print("Connection error: \(error)")
            throw Sketch.PredictionError.unableToConnect(connectionError: error)
        }
        
    }
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
