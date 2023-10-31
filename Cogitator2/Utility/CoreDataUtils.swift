//
//  CoreDataUtils.swift
//  Cogitator2
//
//  Created by Danilo Campos on 10/30/23.
//

import Foundation
import CoreData

extension NSManagedObject {
    
    func transferred(to context: NSManagedObjectContext) -> Self? {
        guard context != self.managedObjectContext else {
            return self
        }
        
        do {
            let transferredObject = try context.existingObject(with: self.objectID) as? Self
            return transferredObject
        } catch {
            return nil
        }
    }
    
    func cloneWithoutRelationships(into context: NSManagedObjectContext) -> Self? {
        guard let entityName = self.entity.name else { return nil }
        
        // Create a new object in the given context
        let newObject = NSEntityDescription.insertNewObject(forEntityName: entityName, into: context)
        
        // Loop through all attributes and copy them to the new object
        for (key, _) in self.entity.attributesByName {
            newObject.setValue(self.value(forKey: key), forKey: key)
        }
        
        return newObject as? Self
    }
}
