//
//  Sketch+CoreDataClass.swift
//  Cogitator2
//
//  Created by Danilo Campos on 10/26/23.
//
//

import Foundation
import CoreData
import Combine
import OpenAPIKit30

public typealias JSONSchema = OpenAPIKit30.JSONSchema


@objc(Sketch)
public class Sketch: NSManagedObject {
    
    enum URLState {
        case valid,
        invalid,
        notSet
    }
    
    
    var urlObservation: AnyCancellable?
    var urlState: URLState = .notSet
    
    
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        
        self.title = "New Sketch"
        self.hostURLString = "http://greatwhite.local:5000"
        addPrompt()
        observeURL()
        
        if let hostURLString {
            validateURLString(hostURLString)
        }
    }
    
    public override func awakeFromFetch() {
        super.awakeFromFetch()
        
        addPrompt()
        observeURL()
    }
    
    func addPrompt() {
        if prompt == nil, let context = self.managedObjectContext {
            prompt = Prompt(context: context)
        }
    }
    
    func observeURL() {
        self.urlObservation = self.publisher(for: \.hostURLString).sink {
            
            guard let string = $0 else {
                return
            }
            
            self.validateURLString(string)
        }
    }
    
    func validateURLString(_ string: String) {
        guard let url = URL(string: string) else {
            urlState = .invalid
            print("Bad url")
            return
        }
        
        urlState = .valid
        client.loadSchema(url: url, sketch: self)
        print("Valid URL")
    }

    var client: NetworkClient = NetworkClient()
    
    var inputSchema: [String:JSONSchema]? {
        get {
            guard let data = self.inputSchemaData else { return nil }
            return try? JSONDecoder().decode([String:JSONSchema].self, from: data)
        }
        set {
            self.inputSchemaData = try? JSONEncoder().encode(newValue)
            
            if let schema = newValue {
                prompt?.updateSchema(schema)
            }
        }
    }
    
    
}
