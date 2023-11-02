//
//  WindowCreator.swift
//  Cogitator2
//
//  Created by Danilo Campos on 11/1/23.
//

import SwiftUI
import AppKit

class WindowCreator {
    
    static var lastWindowFrame: NSRect?
    
    static func newWindow<Content: View>(for view: Content, title: String = "New Window") -> NSWindow {
        let initialFrame = NSRect(x: 0, y: 0, width: 512, height: 512)
        let window = NSWindow(
            contentRect: initialFrame,
            styleMask: [.titled, .closable, .resizable, .fullSizeContentView],
            backing: .buffered, defer: false
        )
        
        if let lastFrame = lastWindowFrame {
            let offset: CGFloat = 50  // Adjust as needed
            var newOrigin = NSPoint(x: lastFrame.minX + offset, y: lastFrame.minY - offset)
            
            // Check screen bounds
            let screenFrame = NSScreen.main?.visibleFrame ?? initialFrame
            if newOrigin.x + initialFrame.width > screenFrame.maxX || newOrigin.y - initialFrame.height < screenFrame.minY {
                // Reset position to vertical center if out of bounds
                newOrigin = NSPoint(x: screenFrame.minX + offset, y: screenFrame.midY - initialFrame.height / 2)
            }
            
            window.setFrameOrigin(newOrigin)
        } else {
            window.center()  // Center the window if it's the first one
        }
        
        lastWindowFrame = window.frame  // Store the frame for the next window
        
        window.setFrameAutosaveName(title)
        window.contentView = NSHostingView(rootView: view)
        window.makeKeyAndOrderFront(nil)
        window.aspectRatio = NSSize(width: 1, height: 1)
        window.isReleasedWhenClosed = false
        window.title = title
        
        return window
    }
}
