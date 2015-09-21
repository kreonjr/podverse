//
//  AppDelegate.swift
//  podverse
//
//  Created by Mitchell Downey on 6/2/15.
//  Copyright (c) 2015 Mitchell Downey. All rights reserved.
//

import UIKit
import CoreData
import AVFoundation
import ReachabilitySwift

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    var moc: NSManagedObjectContext!
    
    var avPlayer: AVPlayer?
    
    var subscriber = PVSubscriber()
        
    var parser = PVFeedParser()
    
    var nowPlayingEpisode: Episode?
    
    var episodeDownloadArray = [Episode]()
        
    var iTunesSearchPodcastArray = [SearchResultPodcast]()
    
    var iTunesSearchPodcastFeedURLArray: [NSURL] = []
    
    var backgroundTransferCompletionHandler: (() -> Void)?
    
    var timer: dispatch_source_t!
    
    var internetReach: Reachability?
    
    // This function runs once on app load, then runs in the background every 30 minutes.
    // Check if a new episode is available for a subscribed podcast; if true, download that episode.
    // TODO: make sure this is running in the background, even when app is not in the foreground
    // TODO: can we allow resolve / reject to be optional? Allow nil as a parameter?
    func startCheckSubscriptionsForNewEpisodesTimer() {
        
        // TODO: Should I or should I not be using dispatch_get_main_queue here?
        timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_main_queue())
        
        dispatch_source_set_timer(timer, DISPATCH_TIME_NOW, 600 * NSEC_PER_SEC, 1 * NSEC_PER_SEC)
        
        dispatch_source_set_event_handler(timer) {
            
            let podcastArray = CoreDataHelper.fetchEntities("Podcast", managedObjectContext: self.moc, predicate: nil) as! [Podcast]
            
            for var i = 0; i < podcastArray.count; i++ {
                let feedURL = NSURL(string: podcastArray[i].feedURL)
                self.parser.parsePodcastFeed(feedURL!, returnPodcast: false, returnOnlyLatestEpisode: true,
                    resolve: {
                        
                    }, reject: {
                        
                    }
                )
            }
            
        }
        
        dispatch_resume(timer)
        
    }
    
    // TODO: What does the completionHandler do?
    func application(application: UIApplication, handleEventsForBackgroundURLSession identifier: String, completionHandler: () -> Void) {
        self.backgroundTransferCompletionHandler = completionHandler
    }
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        
        if let context = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext {
            self.moc = context
        }
        
        application.registerUserNotificationSettings(UIUserNotificationSettings(forTypes: [.Alert, .Badge], categories: nil))  // types are UIUserNotificationType members
        
        // On app launch, clear the taskIdentifier of any episodes that previously did not finish downloading, and resume downloading
        let firstPredicate = NSPredicate(format: "isDownloading != false")
        let secondPredicate = NSPredicate(format: "taskResumeData != nil")
        let predicate = NSCompoundPredicate(type: NSCompoundPredicateType.OrPredicateType, subpredicates: [firstPredicate, secondPredicate])
        
        self.episodeDownloadArray = CoreDataHelper.fetchEntities("Episode", managedObjectContext: self.moc, predicate: predicate) as! [Episode]
        
        print("did finish")
        
        for var i = 0; i < self.episodeDownloadArray.count; i++ {
            self.episodeDownloadArray[i].taskIdentifier = nil
        }

        startCheckSubscriptionsForNewEpisodesTimer()

//        NSNotificationCenter.defaultCenter().addObserver(self, selector: "reachabilityChanged:", name: ReachabilityChangedNotification, object: nil)
//        
//        // Instantiate the Reachability object
//        internetReach = Reachability.reachabilityForInternetConnection()
//        // Run startNotifier so Reachability constantly listens for changes to the internet connection
//        internetReach?.startNotifier()
//        
//        if internetReach != nil {
//            self.statusChangedWithReachability(internetReach!)
//        }
        
        return true
    }
    
    func statusChangedWithReachability(currentReachabilityStatus: Reachability) {
        let networkStatus = currentReachabilityStatus.currentReachabilityStatus
        
        if networkStatus.description == "WiFi" {
            // WiFi is enabled
            // TODO: Add resume all downloads function when WiFi is enabled
            reachabilityStatus = kReachableWithWIFI
        }
        else if networkStatus.description == "Cellular" {
            // Cellular data is enabled
            // TODO: Add pause all downloads function when Cellular is enabled
            reachabilityStatus = kReachableWithWWAN
        }
        else {
            // No internet access is enabled
            // TODO: Add pause all downloads function when No Internet is enabled
            reachabilityStatus = kNotReachable
        }
        
        NSNotificationCenter.defaultCenter().postNotificationName("ReachStatusChanged", object: nil)
    }
    
    func reachabilityChanged(notification: NSNotification) {
        print("Reachability Status Changed")
        reachability = notification.object as? Reachability
        self.statusChangedWithReachability(reachability!)
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {

    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
        self.saveContext()
        
        // Stop listening for Reachability changes when the app is terminated
        // TODO: do we instead want the ReachabilityChangedNotification to continue running in the background after the app is terminated?
        NSNotificationCenter.defaultCenter().removeObserver(self, name: ReachabilityChangedNotification, object: nil)
    }

    // MARK: - Core Data stack

    lazy var applicationDocumentsDirectory: NSURL = {
        // The directory the application uses to store the Core Data store file. This code uses a directory named "fm.podverse.podverse" in the application's documents Application Support directory.
        let urls = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
        return urls[urls.count-1]
    }()

    lazy var managedObjectModel: NSManagedObjectModel = {
        // The managed object model for the application. This property is not optional. It is a fatal error for the application not to be able to find and load its model.
        let modelURL = NSBundle.mainBundle().URLForResource("podverse", withExtension: "momd")!
        return NSManagedObjectModel(contentsOfURL: modelURL)!
    }()

    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator? = {
        // The persistent store coordinator for the application. This implementation creates and return a coordinator, having added the store for the application to it. This property is optional since there are legitimate error conditions that could cause the creation of the store to fail.
        // Create the coordinator and store
        var coordinator: NSPersistentStoreCoordinator? = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        let url = self.applicationDocumentsDirectory.URLByAppendingPathComponent("podverse.sqlite")
        var error: NSError? = nil
        var failureReason = "There was an error creating or loading the application's saved data."
        do {
            try coordinator!.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: url, options: [NSMigratePersistentStoresAutomaticallyOption: true, NSInferMappingModelAutomaticallyOption: true])
        } catch var error1 as NSError {
            error = error1
            coordinator = nil
            // Report any error we got.
            var dict = [String: AnyObject]()
            dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data"
            dict[NSLocalizedFailureReasonErrorKey] = failureReason
            dict[NSUnderlyingErrorKey] = error
            error = NSError(domain: "YOUR_ERROR_DOMAIN", code: 9999, userInfo: dict)
            // Replace this with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog("Unresolved error \(error), \(error!.userInfo)")
            abort()
        } catch {
            fatalError()
        }
        
        return coordinator
    }()

    lazy var managedObjectContext: NSManagedObjectContext? = {
        // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.) This property is optional since there are legitimate error conditions that could cause the creation of the context to fail.
        let coordinator = self.persistentStoreCoordinator
        if coordinator == nil {
            return nil
        }
        var managedObjectContext = NSManagedObjectContext()
        managedObjectContext.persistentStoreCoordinator = coordinator
        return managedObjectContext
    }()

    // MARK: - Core Data Saving support

    func saveContext () {
        if let moc = self.managedObjectContext {
            if moc.hasChanges {
                do {
                    try moc.save()
                } catch {
                    print(error)
                    
                    // Replace this implementation with code to handle the error appropriately.
                    // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
//                    NSLog("Unresolved error \(error), \(error.userInfo)")
                    abort()
                }
            }
        }
    }

}

