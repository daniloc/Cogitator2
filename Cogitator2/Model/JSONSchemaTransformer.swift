//
//  JSONSchemaTransformer.swift
//  Cogitator2
//
//  Created by Danilo Campos on 10/28/23.
//

import Foundation
import CoreData
import OpenAPIKit  // Adjust this import to match your project setup.

@objc(JSONSchemaTransformer)
class JSONSchemaTransformer: ValueTransformer {
    
    static let name = NSValueTransformerName(rawValue: String(describing: JSONSchemaTransformer.self))
    
    override class func transformedValueClass() -> AnyClass {
        return NSData.self
    }
    
    override class func allowsReverseTransformation() -> Bool {
        return true
    }
    
    override func transformedValue(_ value: Any?) -> Any? {
        guard let jsonSchema = value as? JSONSchema else { return nil }
        let encoder = JSONEncoder()
        return try? encoder.encode(jsonSchema)
    }
    
    override func reverseTransformedValue(_ value: Any?) -> Any? {
        guard let data = value as? Data else { return nil }
        let decoder = JSONDecoder()
        return try? decoder.decode(JSONSchema.self, from: data)
    }
}
