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
import OpenAPIKit

public typealias JSONSchema = OpenAPIKit.JSONSchema


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
        observeURL()
        
        if let hostURLString {
            validateURLString(hostURLString)
        }
    }
    
    public override func awakeFromFetch() {
        super.awakeFromFetch()
        
        observeURL()
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
    
    var inputSchemaPublisher: AnyPublisher<[JSONSchema]?, Never> {
        return self.publisher(for: \.inputSchemaData)
            .map { data in
                data.flatMap { try? JSONDecoder().decode([JSONSchema].self, from: $0) }
            }
            .eraseToAnyPublisher()
    }
    
    var inputSchema: [JSONSchema]? {
        get {
            guard let data = self.inputSchemaData else { return nil }
            return try? JSONDecoder().decode([JSONSchema].self, from: data)
        }
        set {
            self.inputSchemaData = try? JSONEncoder().encode(newValue)
        }
    }
    
}
