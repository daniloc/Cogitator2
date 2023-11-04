//
//  SchemaFieldView.swift
//  Cogitator2
//
//  Created by Danilo Campos on 10/28/23.
//

import SwiftUI
import OpenAPIKit30

struct InputFieldView: View {
    
    @ObservedObject var parameter: Parameter
    
    func intInput(for schema: JSONSchema) -> some View {
        return NumericInputField(value: parameter.intValue, schema: schema)
    }
    
    func floatInput(for schema: JSONSchema) -> some View {
        return NumericInputField(value: parameter.floatValue, schema: schema)
    }
    
    func stringInput(for schema: JSONSchema) -> some View {
        
        return HStack {
            
            TextField(parameter.schema?.defaultValue?.value as? String ?? "", text: parameter.stringValue, axis: .vertical)
                .lineLimit(4)
                .background(.windowBackground)
            
            
            if let format = schema.formatString, format  == Parameter.Formats.URI.rawValue {
                ImageWellView(data: $parameter.imageData)
            } else {
                EmptyView()
            }
            
        }
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
            VStack(alignment: .leading, spacing: .defaultMeasure) {
                
                HStack {
                    Text(parameter.schema?.title ?? "")
                        .fontWeight(.medium)
                    Spacer()
                    Text(parameter.fieldName ?? "")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(Color.orange)
                        .padding(4)
                        .background(.windowBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                    
                }
                
                input(for: schema)
                    .frame(idealWidth: .infinity)
                
                Text(parameter.schema?.description ?? "")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, .defaultMeasure / 2)
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
        VStack(alignment: .leading) {
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
            .background(.windowBackground)
            
            HStack {
                if let minInt = schema.integerContext?.minimum?.value {
                    Text("min: \(minInt),")
                } else if let minFloat = schema.numberContext?.minimum?.value {
                    Text("min: \(String(format: "%.1f", minFloat)),")
                }
                
                if let maxInt = schema.integerContext?.maximum?.value {
                    Text("max: \(maxInt)")
                } else if let maxFloat = schema.numberContext?.maximum?.value {
                    Text("max: \(String(format: "%.1f", maxFloat))")
                }
            }
            .font(.system(.caption, design: .monospaced))
            .foregroundStyle(.tertiary)
        }
    }
}

//#Preview {
//    SchemaFieldView()
//}

extension NSTextView {
    open override var frame: CGRect {
        didSet {
            backgroundColor = .clear
            drawsBackground = true
        }
    }
}
