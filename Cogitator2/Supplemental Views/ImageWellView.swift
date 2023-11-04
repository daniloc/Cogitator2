//
//  ImageWellView.swift
//  Cogitator2
//
//  Created by Danilo Campos on 11/4/23.
//

import SwiftUI

struct ImageWellView: View {
    
    @Binding var data: Data?
    
    func loadImage(from providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }
        
        provider.loadDataRepresentation(forTypeIdentifier: "public.image") { droppedData, error in
            if let droppedData {
               data = droppedData
            }
        }
        
        return true
    }
    
    var image: NSImage? {
        
        guard let data else {
            return nil
        }
        
        return NSImage(data: data)
    }
    
    var borderShape: some Shape {
        return RoundedRectangle(cornerRadius: 8)
    }
    
    var borderSyle: StrokeStyle {
        return StrokeStyle(dash: [5, 3])
    }
    
    var body: some View {
        HStack {
            if let image {
                
                Button {
                    data = nil
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.borderless)
                
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: 50, maxHeight: 50)
                    .clipShape(borderShape)
                


            } else {
                Image(systemName: "photo")
                    .foregroundColor(.secondary)
                    .frame(width: 50, height: 50 )
                    .overlay(borderShape
                        .stroke(style: borderSyle))
                    .clipShape(borderShape)

            }
        }
        .onDrop(of: ["public.image"], isTargeted: nil) { providers, _ in
            loadImage(from: providers)
        }
    }
}
