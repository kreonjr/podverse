//
//  CoreDataHelper.swift
//  podverse
//
//  Created by Mitchell Downey on 6/2/15.
//  Copyright (c) 2015 Mitchell Downey. All rights reserved.
//

import UIKit
import CoreData

class CoreDataHelper:NSObject {
    let storeName = "podverse"
    let storeFilename = "podverse.sqlite"
    
    static let sharedInstance = CoreDataHelper()
    
    var applicationDocumentsDirectory: NSURL {
        get {
            // The directory the application uses to store the Core Data store file. This code uses a directory named "me.iascchen.MyTTT" in the application's documents Application Support directory.
            let urls = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
            return urls[urls.count-1]
        }
    }
    
    override init() {
        super.init()
        let modelURL = NSBundle.mainBundle().URLForResource(self.storeName, withExtension: "momd")!
        self.managedObjectModel = NSManagedObjectModel(contentsOfURL: modelURL)!
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        let url = self.applicationDocumentsDirectory.URLByAppendingPathComponent(self.storeFilename)
        let failureReason = "There was an error creating or loading the application's saved data."
        do {
            try coordinator.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: url, options: nil)
        } catch {
            // Report any error we got.
            var dict = [String: AnyObject]()
            dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data"
            dict[NSLocalizedFailureReasonErrorKey] = failureReason
            
            dict[NSUnderlyingErrorKey] = error as NSError
            let wrappedError = NSError(domain: "YOUR_ERROR_DOMAIN", code: 9999, userInfo: dict)
            // Replace this with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog("Unresolved error \(wrappedError), \(wrappedError.userInfo)")
            abort()
        }
        
        persistentStoreCoordinator = coordinator
    }
    
    var managedObjectModel: NSManagedObjectModel!
    var persistentStoreCoordinator: NSPersistentStoreCoordinator!
    
    var managedObjectContext: NSManagedObjectContext {
        get {
            // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.) This property is optional since there are legitimate error conditions that could cause the creation of the context to fail.
            let coordinator = self.persistentStoreCoordinator
            let managedObjectContext = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
            managedObjectContext.persistentStoreCoordinator = coordinator
            managedObjectContext.mergePolicy = NSMergePolicy(mergeType: NSMergePolicyType.MergeByPropertyObjectTrumpMergePolicyType)
            return managedObjectContext
        }
    }
    
    // Returns the background object context for the application.
    // You can use it to process bulk data update in background.
    // If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
    
    var backgroundContext: NSManagedObjectContext {
        get {
            // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.) This property is optional since there are legitimate error conditions that could cause the creation of the context to fail.
            let coordinator = self.persistentStoreCoordinator
            let backgroundContext = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
            backgroundContext.persistentStoreCoordinator = coordinator
            backgroundContext.mergePolicy = NSMergePolicy(mergeType: NSMergePolicyType.MergeByPropertyObjectTrumpMergePolicyType)
            return backgroundContext
        }
    }

    static func insertManagedObject(className: String, moc:NSManagedObjectContext?) -> NSManagedObject? {
        guard let moc = moc else {
            return nil
        }
        
        return NSEntityDescription.insertNewObjectForEntityForName(className, inManagedObjectContext: moc)
    }
    
    static func fetchEntities(className: String, predicate: NSPredicate?, moc:NSManagedObjectContext?) -> [AnyObject] {
        if let moc = moc {
            let fetchRequest = NSFetchRequest()
            let entityDescription = NSEntityDescription.entityForName(className as String, inManagedObjectContext: moc)
            
            fetchRequest.entity = entityDescription
            fetchRequest.predicate = predicate
            fetchRequest.returnsObjectsAsFaults = false
            
            do {
                return try moc.executeFetchRequest(fetchRequest)
            } catch {
                print(error)
            }
        }
        
        return []
    }
    
    static func fetchOnlyEntityWithMostRecentPubDate(className: String, predicate: NSPredicate?, moc:NSManagedObjectContext?) -> [AnyObject] {
        if let moc = moc {
            let fetchRequest = NSFetchRequest()
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "pubDate", ascending: false)]
            fetchRequest.fetchLimit = 1
            
            let entityDescription = NSEntityDescription.entityForName(className, inManagedObjectContext: moc)
            
            fetchRequest.entity = entityDescription
            fetchRequest.predicate = predicate
            fetchRequest.returnsObjectsAsFaults = false
            
            do {
                return try moc.executeFetchRequest(fetchRequest)
            } catch {
                print(error)
            }
        }

        return []
    }
    
    static func retrieveExistingOrCreateNewPodcast(feedUrlString: String, moc:NSManagedObjectContext) -> Podcast {
        let predicate = NSPredicate(format: "feedURL == %@", feedUrlString)
        let podcastSet = CoreDataHelper.fetchEntities("Podcast", predicate: predicate, moc:moc) as! [Podcast]
        if podcastSet.count > 0 {
            return podcastSet[0]
        } else {
            return CoreDataHelper.insertManagedObject("Podcast", moc:moc) as! Podcast
        }
    }
    
    static func retrieveExistingOrCreateNewEpisode(mediaUrlString: String, moc:NSManagedObjectContext) -> Episode {
        let predicate = NSPredicate(format: "mediaURL == %@", mediaUrlString)
        let episodeSet = CoreDataHelper.fetchEntities("Episode", predicate: predicate,moc: moc) as! [Episode]
        if episodeSet.count > 0 {
            return episodeSet[0]
        } else {
            return CoreDataHelper.insertManagedObject("Episode", moc:moc) as! Episode
        }
    }
    
    static func retrieveExistingOrCreateNewClip(mediaRefId: String, moc:NSManagedObjectContext) -> Clip {
        let predicate = NSPredicate(format: "mediaRefId == %@", mediaRefId)
        let clipSet = CoreDataHelper.fetchEntities("Clip", predicate: predicate,moc: moc) as! [Clip]
        if clipSet.count > 0 {
            return clipSet[0]
        } else {
            return CoreDataHelper.insertManagedObject("Clip", moc:moc) as! Clip
        }
    }
    
    static func retrieveExistingOrCreateNewPlaylist(playlistId: String, moc:NSManagedObjectContext?) -> Playlist {
        let predicate = NSPredicate(format: "id == %@", playlistId)
        let playlistSet = CoreDataHelper.fetchEntities("Playlist", predicate: predicate, moc:moc) as! [Playlist]
        if playlistSet.count > 0 {
            return playlistSet[0]
        } else {
            return CoreDataHelper.insertManagedObject("Playlist", moc:moc) as! Playlist
        }
    }
    
    static func fetchEntityWithID(objectId:NSManagedObjectID, moc:NSManagedObjectContext) -> AnyObject? {
        do {
            return try moc.existingObjectWithID(objectId)
        } catch {
            print(error)
        }
        
        return nil
    }
    
    static func deleteItemFromCoreData(deleteObject:NSManagedObject, moc:NSManagedObjectContext?) {
        guard let moc = moc else {
            print("Missing managed Object Context")
            return
        }
        
        moc.deleteObject(deleteObject)
    }
    
    static func saveCoreData(moc:NSManagedObjectContext?, completionBlock:((saved:Bool)->Void)?) {
        if let moc = moc {
            do {
                try moc.save()
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
        else {
            if let completion = completionBlock {
                completion(saved:true)
            }
        }
    }
}
