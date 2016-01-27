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
    static let sharedInstance = CoreDataHelper()
    var moc: NSManagedObjectContext
    
    override init() {
        // This resource is the same name as your xcdatamodeld contained in your project.
        guard let modelURL = NSBundle.mainBundle().URLForResource("podverse", withExtension: "momd") else {
            fatalError("Error loading model from bundle")
        }
        // The managed object model for the application. It is a fatal error for the application not to be able to find and load its model.
        guard let mom = NSManagedObjectModel(contentsOfURL: modelURL) else {
            fatalError("Error initializing mom from: \(modelURL)")
        }
        
        let psc = NSPersistentStoreCoordinator(managedObjectModel: mom)
        self.moc = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
        self.moc.persistentStoreCoordinator = psc
        
        dispatch_async(Constants.saveQueue) {
            let urls = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
            let docURL = urls[urls.endIndex-1]
            /* The directory the application uses to store the Core Data store file.
            This code uses a file named "DataModel.sqlite" in the application's documents directory.
            */
            let storeURL = docURL.URLByAppendingPathComponent("podverse.sqlite")
            do {
                try psc.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: storeURL, options: [NSMigratePersistentStoresAutomaticallyOption: true, NSInferMappingModelAutomaticallyOption: true])
            } catch {
                fatalError("Error migrating store: \(error)")
            }
        }
        
        super.init()
    }
    
    func insertManagedObject(className: NSString, managedObjectContext: NSManagedObjectContext) -> AnyObject {
        let managedObject = NSEntityDescription.insertNewObjectForEntityForName(className as String, inManagedObjectContext: managedObjectContext) 
        
        return managedObject
    }
    
    func fetchEntities (className: NSString, managedObjectContext: NSManagedObjectContext, predicate: NSPredicate?) -> NSArray {
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
    
    func fetchOnlyEntityWithMostRecentPubDate (className: NSString, managedObjectContext: NSManagedObjectContext, predicate: NSPredicate?) -> NSArray {
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
    
    func deleteItemFromCoreData(deleteObject:NSManagedObject, completionBlock:(()->Void)?) {
        dispatch_async(Constants.saveQueue) { () -> Void in
            self.moc.deleteObject(deleteObject)
            if let completion = completionBlock {
                completion()
            }
        }
    }
    
    static func saveCoreData(completionBlock:((saved:Bool)->Void)?) {
        if Constants.moc.hasChanges {
            do {
                try Constants.moc.save()
                if let completion = completionBlock {
                    completion(saved:true)
                }
            }
            catch {
                if let completion = completionBlock {
                    completion(saved:false)
                }
                print(error)
            }
        }
    }
}
