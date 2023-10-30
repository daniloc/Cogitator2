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
    
    var keyedParameters: [String:Parameter] = [:]
    
    func updateSchema(_ schema: [String:JSONSchema]) {
        
        guard let context = self.managedObjectContext else {
            return
        }
        
        var updatedSchema: [String:Parameter] = [:]
        
        schema.keys.forEach { key in
            var parameter = keyedParameters[key] ?? Parameter(context: context)
            updatedSchema[key] = parameter
            parameter.schema = schema[key]
            parameter.fieldName = key
            
            if let sortIndex = parameter.schema?.vendorExtensions["x-order"]?.value as? Int {
                
                parameter.sortIndex = Int16(sortIndex)
            } else {
                print("No sort index found: \(key)")
                
                updatedSchema[key] = nil
            }
        }
        
        keyedParameters = updatedSchema
        parameters = NSSet(array: Array(updatedSchema.values))
        try? managedObjectContext?.save()
    }

}
