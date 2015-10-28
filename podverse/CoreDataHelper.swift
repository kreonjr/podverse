//
//  CoreDataHelper.swift
//  podverse
//
//  Created by Mitchell Downey on 6/2/15.
//  Copyright (c) 2015 Mitchell Downey. All rights reserved.
//

import UIKit
import CoreData

class CoreDataHelper: NSObject {

    class func insertManagedObject(className: NSString, managedObjectContext: NSManagedObjectContext) -> AnyObject {
        let managedObject = NSEntityDescription.insertNewObjectForEntityForName(className as String, inManagedObjectContext: managedObjectContext) 
        
        return managedObject
    }
    
    class func removeManagedObjectFromClass(className:String, managedObjectContext: NSManagedObjectContext, object:NSManagedObject) {
        managedObjectContext.deleteObject(object)
    }
    
    class func fetchEntities (className: NSString, managedObjectContext: NSManagedObjectContext, predicate: NSPredicate?) -> NSArray {
        let fetchRequest = NSFetchRequest()
        let entityDescription = NSEntityDescription.entityForName(className as String, inManagedObjectContext: managedObjectContext)
        
        fetchRequest.entity = entityDescription
        
        if predicate != nil {
            fetchRequest.predicate = predicate!
        }
        
        fetchRequest.returnsObjectsAsFaults = false
        
        var items = NSArray()
        do {
            items = try managedObjectContext.executeFetchRequest(fetchRequest)
        } catch {
            print(error)
        }

        return items
        
    }
    
    class func fetchOnlyEntityWithMostRecentPubDate (className: NSString, managedObjectContext: NSManagedObjectContext, predicate: NSPredicate?) -> NSArray {
        let fetchRequest = NSFetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "pubDate", ascending: false)]
        fetchRequest.fetchLimit = 1
        
        let entityDescription = NSEntityDescription.entityForName(className as String, inManagedObjectContext: managedObjectContext)
        
        fetchRequest.entity = entityDescription
        
        if predicate != nil {
            fetchRequest.predicate = predicate!
        }
        
        fetchRequest.returnsObjectsAsFaults = false
        
        var mostRecentItemByPubDate = NSArray()
        do {
            mostRecentItemByPubDate = try managedObjectContext.executeFetchRequest(fetchRequest)
        } catch {
            print(error)
        }

        return mostRecentItemByPubDate

    }
    
}
