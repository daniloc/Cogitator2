//
//  ResultWindowView.swift
//  Cogitator2
//
//  Created by Danilo Campos on 11/1/23.
//

import SwiftUI

class ResultWindowDelegate: NSObject, NSWindowDelegate {
    
    var windows: [PredictionResult:NSWindow] = [:]
    
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
    
    @ObservedObject var result: PredictionResult
    
    static var windowDelegate = ResultWindowDelegate()
    
    static func open(with result: PredictionResult) {
        
        if let window = windowDelegate.windows[result] {
            window.makeKeyAndOrderFront(nil)
        } else {
            windowDelegate.windows[result] = WindowCreator.newWindow(for: Self(result: result), title: "\(result.sketch?.title ?? "Untitled Sketch") - \(result.date?.shortString ?? "Unknown Date")")
            windowDelegate.windows[result]?.delegate = windowDelegate
        }
    }
    
    var body: some View {
        Group {
            if let image = result.image {
                image.resizable()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
}

