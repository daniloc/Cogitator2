//
//  PredictionResult+Parser.swift
//  Cogitator2
//
//  Created by Danilo Campos on 11/4/23.
//

import Foundation
import SwiftUI

extension PredictionResult {
    
    static func parse(content: Any, sketch: Sketch, context: NSManagedObjectContext) throws -> PredictionResult? {
        guard let components = (content as? String)?.components(separatedBy: ",") else {
            throw Sketch.PredictionError.issueParsingResponse(parseError: "Unexpected content in response: \(String(describing: content))")
        }
        
        let fileManager = FileManager.default
        let appSupportDirectory: URL
        
        do {
           appSupportDirectory = try fileManager.url(for: .applicationSupportDirectory,
                                                           in: .userDomainMask,
                                                           appropriateFor: nil,
                                                           create: true)
        } catch {
            throw Sketch.PredictionError.localStorageError(fileError: error.localizedDescription)
        }
        
        if let base64content = components.last,
           let _ = Image(base64String: base64content), //Make sure it parses out into something readable
           let imageData = Data(base64Encoded: base64content),
           let contextSafeSketch = sketch.transferred(to: context) {
            
        let result = PredictionResult(context: context)
            
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
                
                
                if let prompt = sketch.prompt, let clonedPrompt = prompt.duplicate(toContext: context) {
                    result.prompt = clonedPrompt
                }
                
                try context.save()
                
                guard let viewableResult = result.transferred(to: PersistenceController.viewContext) else  {
                    throw Sketch.PredictionError.localStorageError(fileError: "Could not transfer reuslt to view context")
                }
                
                return viewableResult
                
            } catch {
                // Handle the error
                print("Error saving image: \(error)")
                throw Sketch.PredictionError.localStorageError(fileError: error.localizedDescription)
            }
        }
        return nil
    }
}
