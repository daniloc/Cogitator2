//
//  UndoManagerDuctTape.swift
//  Cogitator2
//
//  Created by Danilo Campos on 10/31/23.
//

import SwiftUI
import AppKit

extension View {
    func withHostingWindow(_ callback: @escaping (NSWindow?) -> Void) -> some View {
        self.background(HostingWindowFinder(callback: callback))
    }
}

struct HostingWindowFinder: NSViewRepresentable {
    typealias NSViewType = NSView
    
    var callback: (NSWindow?) -> ()
    
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async { [weak view] in
            self.callback(view?.window)
        }
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {
    }
}
