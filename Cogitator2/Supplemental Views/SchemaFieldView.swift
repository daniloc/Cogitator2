//
//  SchemaFieldView.swift
//  Cogitator2
//
//  Created by Danilo Campos on 10/28/23.
//

import SwiftUI
import OpenAPIKit

struct SchemaFieldView: View {
    
    let schemaField: JSONSchema
    
    var body: some View {
        Text(schemaField.title ?? "")
    }
}

//#Preview {
//    SchemaFieldView()
//}
