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
    
    var body: some View {
        VStack {
            Text(parameter.schema?.title ?? "")
            Text(parameter.fieldName ?? "")
            Text(parameter.schema?.description ?? "")
        }
    }
}

//#Preview {
//    SchemaFieldView()
//}
