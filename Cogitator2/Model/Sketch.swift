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
        
    }
    
    public override class func didChangeValue(forKey key: String) {
        super.didChangeValue(forKey: key)
        
        print("There's some changing happening")
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
            
            try? self.validateURLString()
        }
    }
    
    func validateURLString() throws {
        guard let hostURLString,
              let _ = URL(string: hostURLString) else {
            urlState = .invalid
            print("Bad url")
            throw(SchemaValidationError.invalidURL)
        }
        
        urlState = .valid
        print("Valid URL")
        
    }
    
    enum SchemaValidationError: Error {
        case invalidURL,
         unableToConnect(connectionError: Error),
         unableToParse(parseError: Error)
    }
    
    enum PredictionError: Error {
        case unableToConnect(connectionError: Error),
             issueParsingResponse(parseError: Error),
             issueAtServer(serverError: String),
        invalidRequest,
             localStorageError(fileError: Error)
    }
    
    func loadSchema() async throws {
        
        try validateURLString()
        try await client.loadSchema(url: URL(string: hostURLString!)!, sketch: self)
        
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
    
    func requestNewPrediction() async throws -> [PredictionResult] {
        try validateURLString()
        return try await client.predict(with: self)
    }
    
    
}
