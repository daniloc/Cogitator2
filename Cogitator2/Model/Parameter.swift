//
//  Parameter.swift
//  Cogitator2
//
//  Created by Danilo Campos on 10/29/23.
//

import Foundation
import CoreData
import OpenAPIKit30

@objc(Parameter)
public class Parameter: NSManagedObject, Comparable {
    public static func < (lhs: Parameter, rhs: Parameter) -> Bool {
        
        if rhs.schema?.required == false, lhs.schema?.required == true {
            return true
        }
        
        return lhs.sortIndex < rhs.sortIndex
    }
    
    
    var schema: JSONSchema? {
        get {
            guard let data = self.schemaData else { return nil }
            return try? JSONDecoder().decode(JSONSchema.self, from: data)
        }
        set {
            self.schemaData = try? JSONEncoder().encode(newValue)
        }
    }
}
