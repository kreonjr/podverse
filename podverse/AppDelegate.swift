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
import MediaPlayer
import Fabric
import Crashlytics


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    var moc: NSManagedObjectContext! {
        get {
            return self.managedObjectContext
        }
    }
    
    let REFRESH_PODCAST_TIME:Double = 3600
    
    var nowPlayingEpisode: Episode?
    
    var episodeDownloadArray = [Episode]()
    
    var backgroundTransferCompletionHandler: (() -> Void)?
    
    var avPlayer: AVPlayer?
    
    var timer: dispatch_source_t!
    
    override func remoteControlReceivedWithEvent(event: UIEvent?) {
        if let evt = event {
            PVMediaPlayer.sharedInstance.remoteControlReceivedWithEvent(evt)
        }
    }
    
    // This function runs once on app load, then runs in the background every 30 minutes.
    // Check if a new episode is available for a subscribed podcast; if true, download that episode.
    // TODO: shouldn't we check via push notifications? Rather than a timer that continuously runs in the background?
    func startCheckSubscriptionsForNewEpisodesTimer() {
        NSTimer.scheduledTimerWithTimeInterval(REFRESH_PODCAST_TIME, target: self, selector: "refreshPodcastFeed", userInfo: nil, repeats: true)
    }
    
    func refreshPodcastFeed () {
        let podcastArray = CoreDataHelper.fetchEntities("Podcast", managedObjectContext: self.moc, predicate: nil) as! [Podcast]
        for var i = 0; i < podcastArray.count; i++ {
            let feedURL = NSURL(string: podcastArray[i].feedURL)
            
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) { () -> Void in
                let feedParser = PVFeedParser(shouldGetMostRecent: true, shouldSubscribe:false )
                if let feedURLString = feedURL?.absoluteString {
                    feedParser.parsePodcastFeed(feedURLString)
                }
            }
        }
    }

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        
        // Ask for permission for Podverse to use push notifications
        application.registerUserNotificationSettings(UIUserNotificationSettings(forTypes: [.Alert, .Badge], categories: nil))  // types are UIUserNotificationType members
        
        // Add skip or back 15 seconds to the lock screen media player
        let rcc = MPRemoteCommandCenter.sharedCommandCenter()
        
        let skipBackwardIntervalCommand = rcc.skipBackwardCommand
        skipBackwardIntervalCommand.addTarget(self, action: "skipBackwardEvent")
        
        let skipForwardIntervalCommand = rcc.skipForwardCommand
        skipForwardIntervalCommand.addTarget(self, action: "skipForwardEvent")
        
        let pauseCommand = rcc.pauseCommand
        pauseCommand.addTarget(self, action: "playOrPauseEvent")
        let playCommand = rcc.playCommand
        playCommand.addTarget(self, action: "playOrPauseEvent")
        
        // TODO: Currently we are setting taskIdentifier values = nil on app launch. This will probably need to change once we add crash handling for resuming downloads
        let episodeArray = CoreDataHelper.fetchEntities("Episode", managedObjectContext: Constants.moc, predicate: nil) as! [Episode]
        for episode in episodeArray {
            episode.taskIdentifier = nil
        }
        
        startCheckSubscriptionsForNewEpisodesTimer()
        
        Fabric.with([Crashlytics.self])
        return true
    }
    
    func skipBackwardEvent() {
        PVMediaPlayer.sharedInstance.previousTime(15)
    }
    
    func skipForwardEvent() {
        PVMediaPlayer.sharedInstance.skipTime(15)
    }
    
    func playOrPauseEvent() {
        print("remote play or pause happened")
    }
    
    
    
    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
        self.refreshPodcastFeed()
    }

    func applicationDidBecomeActive(application: UIApplication) {
        UIApplication.sharedApplication().applicationIconBadgeNumber = 0
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
        if PVMediaPlayer.sharedInstance.avPlayer.rate == 1 {
            PVMediaPlayer.sharedInstance.saveCurrentTimeAsPlaybackPosition()
        }
        self.saveContext()
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
        var managedObjectContext = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = coordinator
        return managedObjectContext
    }()

    // MARK: - Core Data Saving support
    func saveContext () {
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

