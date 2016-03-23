//
//  CoreDataHelper.swift
//  podverse
//
//  Created by Mitchell Downey on 6/2/15.
//  Copyright (c) 2015 Mitchell Downey. All rights reserved.
//

import UIKit
import CoreData

class CoreDataHelper {
    static let sharedInstance = CoreDataHelper()
    
    lazy var applicationDocumentsDirectory: NSURL = {
        let urls = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
        return urls[urls.count-1] 
    }()
    
    lazy var managedObjectModel: NSManagedObjectModel = {
        guard let modelURL = NSBundle.mainBundle().URLForResource("podverse", withExtension: "momd") else {
            fatalError("Error loading model from bundle")
        }

        return NSManagedObjectModel(contentsOfURL: modelURL)!
    }()
    
    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator? = {
        let storeURL = self.applicationDocumentsDirectory.URLByAppendingPathComponent("podverse.sqlite")
        var coordinator: NSPersistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        var error: NSError? = nil
        
        do {
            try coordinator.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: storeURL, options: [NSMigratePersistentStoresAutomaticallyOption: true, NSInferMappingModelAutomaticallyOption: true])
        } catch {
            fatalError("Error migrating store: \(error)")
        }
        
        return coordinator
    }()
    
    lazy var moc: NSManagedObjectContext = {
        let coordinator = self.persistentStoreCoordinator
        var managedObjectContext = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
        managedObjectContext.mergePolicy = NSMergePolicy(mergeType: .MergeByPropertyObjectTrumpMergePolicyType)
        managedObjectContext.persistentStoreCoordinator = coordinator
        return managedObjectContext
    }()
    
    func insertManagedObject(className: String) -> AnyObject {        
        return NSEntityDescription.insertNewObjectForEntityForName(className, inManagedObjectContext: self.moc)
    }
    
    func fetchEntities (className: NSString, predicate: NSPredicate?) -> [AnyObject] {
        let fetchRequest = NSFetchRequest()
        let entityDescription = NSEntityDescription.entityForName(className as String, inManagedObjectContext: self.moc)
        
        fetchRequest.entity = entityDescription
        
        if predicate != nil {
            fetchRequest.predicate = predicate!
        }
        
        fetchRequest.returnsObjectsAsFaults = false
        
        do {
            return try self.moc.executeFetchRequest(fetchRequest)
        } catch {
            print(error)
        }
        
        return []
    }
    
    func fetchOnlyEntityWithMostRecentPubDate (className: String, predicate: NSPredicate?) -> [AnyObject] {
        let fetchRequest = NSFetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "pubDate", ascending: false)]
        fetchRequest.fetchLimit = 1
        
        let entityDescription = NSEntityDescription.entityForName(className, inManagedObjectContext: self.moc)
        
        fetchRequest.entity = entityDescription
        
        if predicate != nil {
            fetchRequest.predicate = predicate!
        }
        
        fetchRequest.returnsObjectsAsFaults = false
        
        do {
            return try self.moc.executeFetchRequest(fetchRequest)
        } catch {
            print(error)
        }

        return []
    }
    
    func retrieveExistingOrCreateNewPodcast(feedUrlString: String) -> Podcast {
        let predicate = NSPredicate(format: "feedURL == %@", feedUrlString)
        let podcastSet = CoreDataHelper.sharedInstance.fetchEntities("Podcast", predicate: predicate) as! [Podcast]
        if podcastSet.count > 0 {
            let podcast = podcastSet[0]
            return podcast
        } else {
            let podcast = CoreDataHelper.sharedInstance.insertManagedObject("Podcast") as! Podcast
            return podcast
        }
    }
    
    func retrieveExistingOrCreateNewEpisode(mediaUrlString: String) -> Episode {
        let predicate = NSPredicate(format: "mediaURL == %@", mediaUrlString)
        let episodeSet = CoreDataHelper.sharedInstance.fetchEntities("Episode", predicate: predicate) as! [Episode]
        if episodeSet.count > 0 {
            let episode = episodeSet[0]
            return episode
        } else {
            let episode = CoreDataHelper.sharedInstance.insertManagedObject("Episode") as! Episode
            return episode
        }
    }
    
    func retrieveExistingOrCreateNewPlaylist(playlistId: String) -> Playlist {
        let predicate = NSPredicate(format: "playlistId == %@", playlistId)
        let playlistSet = CoreDataHelper.sharedInstance.fetchEntities("Playlist", predicate: predicate) as! [Playlist]
        if playlistSet.count > 0 {
            let playlist = playlistSet[0]
            return playlist
        } else {
            let playlist = CoreDataHelper.sharedInstance.insertManagedObject("Playlist") as! Playlist
            return playlist
        }
    }
    
//    func fetchEntityWithID(objectId:NSManagedObjectID) -> AnyObject? {
//        do {
//            return try self.moc.existingObjectWithID(objectId)
//        } catch {
//            print(error)
//        }
//        
//        return nil
//    }
    
    func deleteItemFromCoreData(deleteObject:NSManagedObject) {
        self.moc.deleteObject(deleteObject)
        self.saveCoreData(nil)
    }
    
    func saveCoreData(completionBlock:((saved:Bool)->Void)?) {
        if self.moc.hasChanges {
            do {
                try self.moc.save()
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
