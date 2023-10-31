//
//  ImageSaver.swift
//  Cogitator
//
//  Created by Danilo Campos on 9/30/23.
//

import Foundation
import CoreGraphics
import AppKit

struct ImageSaver {
    func save(cgImage: CGImage, as filename: String) {
        let directory = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first!
        let fileURL = directory.appendingPathComponent(filename)
        
        #if os(macOS)
        let nsImage = NSImage(cgImage: cgImage, size: CGSize(width: cgImage.width, height: cgImage.height))
        guard let tiffData = nsImage.tiffRepresentation else { return }
        let imageRep = NSBitmapImageRep(data: tiffData)
        guard let pngData = imageRep?.representation(using: .png, properties: [:]) else { return }
        #elseif os(iOS)
        let uiImage = UIImage(cgImage: cgImage)
        guard let pngData = uiImage.pngData() else { return }
        #endif
        
        do {
            try pngData.write(to: fileURL)
        } catch {
            print("Unable to save image: \(error)")
        }
    }
}
