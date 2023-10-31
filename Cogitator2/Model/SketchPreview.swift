//
//  PromptPreview.swift
//  Cogitator2
//
//  Created by Danilo Campos on 10/30/23.
//

import CoreData
import OpenAPIKit30

extension Sketch {
    static var previewEntity: Sketch {
        
        let sketch = Sketch(context: PersistenceController.preview.container.viewContext)
        
        guard let file = Bundle.main.url(forResource: "inputSchema", withExtension: "json") else {
            fatalError("Couldn't find json in main bundle.")
        }
        
        do {
            //TODO: Let's find a way to encapsulate this so it doesn't have to be repeated
            let data = try Data(contentsOf: file)
            let decoder = JSONDecoder()
            let apiDoc = try decoder.decode(OpenAPI.Document.self, from: data)
            let derefApiDoc = try? apiDoc.locallyDereferenced().resolved()
            print(derefApiDoc ?? "no deref")
            
            
            derefApiDoc!.components.schemas.forEach { schema in
                
            if schema.key.rawValue == "Input" {
                    
                    var inputValues: [String:JSONSchema] = [:]
                    
                    print(schema.value.objectContext ?? "")
                    
                    schema.value.objectContext?.properties.forEach { property in
                        inputValues[property.key] = property.value
                    }
                    
                        sketch.inputSchema = inputValues

                }
                
            }
        } catch {
            fatalError("Couldn't load data from main bundle:\n\(error)")
        }
        
        return sketch
        
    }
}

