//
//  Parameter.swift
//  Cogitator2
//
//  Created by Danilo Campos on 10/29/23.
//

import Foundation
import CoreData
import OpenAPIKit30
import SwiftUI

@objc(Parameter)
public class Parameter: NSManagedObject, Comparable {
    public static func < (lhs: Parameter, rhs: Parameter) -> Bool {
        
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
    

    
    var dictionary: [String: Any]? {
        guard let fieldName = fieldName, let valueData = valueData, let schema = schema else {
            return nil
        }
        
        var value: Any?
        
        switch schema.value {
        case .string:
            value = String(data: valueData, encoding: .utf8)
        case .integer:
            value = try? JSONDecoder().decode(Int.self, from: valueData)
        case .number:
            value = try? JSONDecoder().decode(Float.self, from: valueData)
        case .boolean:
            value = try? JSONDecoder().decode(Bool.self, from: valueData)
        // Add more cases for other types as needed
        default:
            // Handle unknown types if necessary
            return nil
        }
        
        guard let unwrappedValue = value else {
            return nil
        }
        
        return [fieldName: unwrappedValue]
    }
}

//MARK - Bindings over underlying valueData storage
extension Parameter {
    var stringValue: Binding<String> {
        Binding<String>(
            get: {
                if let data = self.valueData,
                   let str = String(data: data, encoding: .utf8) {
                    return str
                }
                return ""
            },
            set: {
                if let data = $0.data(using: .utf8) {
                    self.valueData = data
                }
            }
        )
    }

    var intValue: Binding<Int> {
        Binding<Int>(
            get: {
                if let data = self.valueData,
                   let int = try? JSONDecoder().decode(Int.self, from: data) {
                    return int
                }
                return 0
            },
            set: {
                if let data = try? JSONEncoder().encode($0) {
                    self.valueData = data
                }
            }
        )
    }

    var floatValue: Binding<Float> {
        Binding<Float>(
            get: {
                if let data = self.valueData,
                   let float = try? JSONDecoder().decode(Float.self, from: data) {
                    return float
                }
                return 0.0
            },
            set: {
                if let data = try? JSONEncoder().encode($0) {
                    self.valueData = data
                }
            }
        )
    }
    
    var boolValue: Binding<Bool> {
        Binding<Bool>(
            get: {
                if let data = self.valueData,
                   let bool = try? JSONDecoder().decode(Bool.self, from: data) {
                    return bool
                }
                return false
            },
            set: {
                if let data = try? JSONEncoder().encode($0) {
                    self.valueData = data
                }
            }
        )
    }
}
