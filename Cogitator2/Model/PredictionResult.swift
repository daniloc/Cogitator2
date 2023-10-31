//
//  PredictionResult+CoreDataClass.swift
//  Cogitator2
//
//  Created by Danilo Campos on 10/26/23.
//
//

import Foundation
import CoreData
import SwiftUI

@objc(PredictionResult)
public class PredictionResult: NSManagedObject {
    
    @Published var image: Image? = nil
    var imageData: Data? = nil
    
    public override func willChangeValue(forKey key: String) {
        super.willChangeValue(forKey: key)
        if key == "imageFileURL" {
            loadImage()
        }
    }
    
    public override func awakeFromFetch() {
        super.awakeFromFetch()
        
        loadImage()
    }
    
    func remove() {
        
        
        if  let imageFileURL,
            let path = URL(string: imageFileURL) {
            deleteImageFile(from: path)
        }
        managedObjectContext?.undoManager?.setActionName("Delete Prediction Result")
        self.managedObjectContext?.delete(self)
        PersistenceController.saveViewContextLoggingErrors()
    }
    
    
    
    func deleteImageFile(from originalPath: URL) -> Result<URL, Error> {
        let fileManager = FileManager.default
        
        // Get the Caches directory
        guard let cacheDirectory = try? fileManager.url(for: .cachesDirectory,
                                                        in: .userDomainMask,
                                                        appropriateFor: nil,
                                                        create: false) else {
            return .failure(NSError(domain: "Couldn't locate cache directory", code: 1))
        }
        
        // Create a new path in the Caches directory
        let cachePath = cacheDirectory.appendingPathComponent(originalPath.lastPathComponent)
        
        do {
            // Copy the image to the Caches directory
            try fileManager.copyItem(at: originalPath, to: cachePath)
            
            // Delete the original image
            try fileManager.removeItem(at: originalPath)
            
            return .success(cachePath)
        } catch let error {
            return .failure(error)
        }
    }
    
    func saveImageToDownloads() {
        guard let imageData,
              let nsImage = NSImage(data: imageData),
              let cgImage = nsImage.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd-HHmmss"
        let dateString = dateFormatter.string(from: Date())
        let filename = "\(sketch?.title ?? "Unnamed Sketch")-\(dateString).png"
        
        ImageSaver().save(cgImage: cgImage, as: filename)
    }
    
    func loadImage() {
        guard image == nil,
              let urlString = self.imageFileURL,
              let url = URL(string: urlString)
        else {
            return
        }
        
        DispatchQueue.global(qos: .background).async {
            do {
                let data = try Data(contentsOf: url)
                self.loadImageFromData(data: data)
            } catch {
                // Handle or log error
                print("Error loading image: \(error)")
                
                // Attempt to load from cache
                self.loadImageFromCache(fileName: url.lastPathComponent)
            }
        }
    }
    
    private func loadImageFromData(data: Data) {
#if os(macOS)
        if let nsImage = NSImage(data: data) {
            DispatchQueue.main.async {
                self.image = Image(nsImage: nsImage)
                self.imageData = data
                self.objectWillChange.send()
            }
        }
#else
        if let uiImage = UIImage(data: data) {
            DispatchQueue.main.async {
                self.image = Image(uiImage: uiImage)
            }
        }
#endif
    }
    
    private func loadImageFromCache(fileName: String) {
        guard let cacheDirectory = try? FileManager.default.url(for: .cachesDirectory,
                                                                in: .userDomainMask,
                                                                appropriateFor: nil,
                                                                create: false) else {
            print("Couldn't locate cache directory")
            return
        }
        
        let cachePath = cacheDirectory.appendingPathComponent(fileName)
        
        do {
            let data = try Data(contentsOf: cachePath)
            self.loadImageFromData(data: data)
        } catch {
            print("Error loading image from cache: \(error)")
        }
    }
    
}

