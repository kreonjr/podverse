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
    var moc: NSManagedObjectContext
    
    init() {
        // This resource is the same name as your xcdatamodeld contained in your project.
        guard let modelURL = NSBundle.mainBundle().URLForResource("podverse", withExtension: "momd") else {
            fatalError("Error loading model from bundle")
        }
        // The managed object model for the application. It is a fatal error for the application not to be able to find and load its model.
        guard let mom = NSManagedObjectModel(contentsOfURL: modelURL) else {
            fatalError("Error initializing mom from: \(modelURL)")
        }
        
        let psc = NSPersistentStoreCoordinator(managedObjectModel: mom)
        self.moc = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
        self.moc.persistentStoreCoordinator = psc
        
        // TODO to review: I added the line below to address the "merge conflict" issues that would happen when subscribing to many podcasts rapidly. I think it tells Core Data to always save the newest object when a merge conflict exists...anyway after adding this line, I could not reproduce the merge conflict issue again.
        // Reference: http://stackoverflow.com/questions/4405912/iphone-coredata-error-nsmergeconflict-for-nsmanagedobject
        self.moc.mergePolicy = NSMergePolicy(mergeType: NSMergePolicyType.MergeByPropertyObjectTrumpMergePolicyType)
        
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
    }
    
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
        else {
            if let completion = completionBlock {
                completion(saved:true)
            }
        }
    }
}
