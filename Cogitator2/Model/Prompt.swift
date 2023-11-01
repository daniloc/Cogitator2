//
//  Prompt+CoreDataClass.swift
//  Cogitator2
//
//  Created by Danilo Campos on 10/26/23.
//
//

import Foundation
import CoreData
import OpenAPIKit30

@objc(Prompt)
public class Prompt: NSManagedObject {
    
    @Published var orderedParameters: [Parameter] = []
    
    public override func awakeFromFetch() {
        super.awakeFromFetch()
        
        updateOrderedParameters()
        
    }
    
    public override func didChangeValue(forKey key: String) {
        super.didChangeValue(forKey: key)
        
        if key == "parameters" {
            updateOrderedParameters()
        }
    }
    
    func updateOrderedParameters() {
        orderedParameters = (parameters?.allObjects as? [Parameter])?.sorted() ?? []
        self.objectWillChange.send()
    }
    
    func existingParameter(for key: String) -> Parameter? {
        for parameter in orderedParameters {
            if parameter.fieldName == key {
                return parameter
            }
        }
        
        return nil
    }
    
    func updateSchema(_ schema: [String:JSONSchema]) {
        
        guard let context = self.managedObjectContext else {
            return
        }
        
        var newParameters: [Parameter] = []
                
        schema.keys.forEach { key in
            let parameter = existingParameter(for: key) ?? Parameter(context: context)
            parameter.schema = schema[key]
            parameter.fieldName = key
            
            if let sortIndex = parameter.schema?.vendorExtensions["x-order"]?.value as? Int {
                
                parameter.sortIndex = Int16(sortIndex)
                newParameters.append(parameter)
            } else {
                print("No sort index found: \(key)")
                
            }
        }
        
        parameters = NSSet(array: newParameters)
        try? managedObjectContext?.save()
    }
    
    var predictionRequestDictionary: [String:Any] {
        
        var dictionary: [String:Any] = [:]
        
        orderedParameters.forEach { parameter in
            if let parameterDictionary = parameter.dictionary
            {
                dictionary.merge(parameterDictionary) { current, _ in
                    
                }
            }
        }
        
        return dictionary
    }
    
    var summary: String {
        var summaryString = ""
        
        for (parameter) in (parameters?.allObjects as! [Parameter]).sorted() {
            
            if let _ = parameter.valueData {
                summaryString += "\(parameter.fieldName ?? ""): \(parameter.stringValue.wrappedValue)\n"
            }
            
        }
        
        return summaryString
    }

}
