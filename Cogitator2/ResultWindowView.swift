//
//  ResultWindowView.swift
//  Cogitator2
//
//  Created by Danilo Campos on 11/1/23.
//

import SwiftUI

class ResultWindowDelegate: NSObject, NSWindowDelegate {
    
    var windows: [AnyHashable:NSWindow] = [:]
    
    func remove(deadWindow: NSWindow) {
        for (key, window) in windows where window === deadWindow {
            windows[key] = nil
            break
        }
    }
    
    func windowWillClose(_ notification: Notification) {
        if let window = notification.object as? NSWindow {
                        
            remove(deadWindow: window)
        }
    }
}

struct ResultWindowView: View {
    
    var image: Image
    
    static var windowDelegate = ResultWindowDelegate()
    
    static func open(with result: PredictionResult) {
        
        if let window = windowDelegate.windows[result] {
            window.makeKeyAndOrderFront(nil)
        } else {
            
            guard let image = result.image else {
                return
            }
            
            windowDelegate.windows[result] = WindowCreator.newWindow(for: Self(image: image), title: "\(result.sketch?.title ?? "Untitled Sketch") - \(result.date?.shortString ?? "Unknown Date")")
            windowDelegate.windows[result]?.delegate = windowDelegate
        }
    }
    
    static func open(with parameter: Parameter) {
        
        if let window = windowDelegate.windows[parameter] {
            window.makeKeyAndOrderFront(nil)
        } else {
            
            guard let image = parameter.image else {
                return
            }
            
            windowDelegate.windows[parameter] = WindowCreator.newWindow(for: image, title: "Input field: \(parameter.fieldName ?? "unknown field")")
            windowDelegate.windows[parameter]?.delegate = windowDelegate
        }
    }
    
    var body: some View {

                image.resizable()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            
    }
}

