//
//  SchemaFieldView.swift
//  Cogitator2
//
//  Created by Danilo Campos on 10/28/23.
//

import SwiftUI
import OpenAPIKit30

struct InputFieldView: View {
    
    let parameter: Parameter
    
    func intInput(for schema: JSONSchema) -> some View {
        return NumericInputField(value: parameter.intValue, schema: schema)
    }
    
    func floatInput(for schema: JSONSchema) -> some View {
        return NumericInputField(value: parameter.floatValue, schema: schema)
    }
    
    func stringInput(for schema: JSONSchema) -> some View {
        return TextField(schema.defaultValue?.value as? String ?? "", text: parameter.stringValue)
    }
    
    func boolInput(for schema: JSONSchema) -> some View {
        return Toggle(schema.defaultValue?.value as? String ?? "", isOn: parameter.boolValue)
    }
    
    func input(for schema: JSONSchema) -> some View {
        
        return Group {
            
            if schema.isNumber {
                floatInput(for: schema)
            }
            
            if schema.isInteger {
                intInput(for: schema)
            }
            
            if schema.isString {
                stringInput(for: schema)
            }
            
            if schema.isBoolean {
                boolInput(for: schema)
            }
            
        }
    }
    
    var body: some View {
        
        if let schema = parameter.schema {
            VStack(alignment: .leading) {

                    Text(parameter.schema?.title ?? "")

                
                Text(parameter.fieldName ?? "")
                input(for: schema)
                    .frame(idealWidth: .infinity)
                Text(parameter.schema?.description ?? "")
            }       
        }
    }
}

protocol NumericInput: LosslessStringConvertible, CustomStringConvertible {}

extension Int: NumericInput {}
extension Float: NumericInput {}

struct NumericInputField<T: NumericInput>: View {
    @Binding var value: T
    let schema: JSONSchema
    
    var placeholderText: String {
        guard let defaultValue = schema.defaultValue?.value  else {
            return ""
        }
        
        return String(describing: defaultValue)
    }
    
    var body: some View {
        VStack {
            TextField(placeholderText, text: Binding(
                get: {
                    
                    if let intValue = value as? Int, intValue == 0 {
                        return ""
                    } else if let floatValue = value as? Float, floatValue == 0.0 {
                        return ""
                    }
                    return String(describing: value)
                },
                set: { if let newValue = T($0) { value = newValue } }
            ))
            
            HStack {
                if let minInt = schema.integerContext?.minimum?.value {
                    Text("min: \(minInt)")
                } else if let minFloat = schema.numberContext?.minimum?.value {
                    Text("min: \(String(format: "%.1f", minFloat))")
                }
                
                if let maxInt = schema.integerContext?.maximum?.value {
                    Text("max: \(maxInt)")
                } else if let maxFloat = schema.numberContext?.maximum?.value {
                    Text("max: \(String(format: "%.1f", maxFloat))")
                }
            }
        }
    }
}

//#Preview {
//    SchemaFieldView()
//}
