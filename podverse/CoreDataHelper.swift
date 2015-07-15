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
        let managedObject = NSEntityDescription.insertNewObjectForEntityForName(className as String, inManagedObjectContext: managedObjectContext) as! NSManagedObject
        
        return managedObject
    }
    
    class func fetchEntities (className: NSString, managedObjectContext: NSManagedObjectContext, predicate: NSPredicate?) -> NSArray {
        let fetchRequest = NSFetchRequest()
        let entityDescription = NSEntityDescription.entityForName(className as String, inManagedObjectContext: managedObjectContext)
        
        fetchRequest.entity = entityDescription
        
        if predicate != nil {
            fetchRequest.predicate = predicate!
        }
        
        fetchRequest.returnsObjectsAsFaults = false
        
        let items = managedObjectContext.executeFetchRequest(fetchRequest, error: nil)!
        
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
        
        let mostRecentItemByPubDate = managedObjectContext.executeFetchRequest(fetchRequest, error: nil)!
        
        return mostRecentItemByPubDate
    }
    
}
