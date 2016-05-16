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
    
    
    var backgroundTransferCompletionHandler: (() -> Void)?
    
    var avPlayer: AVPlayer?
    
    var timer: dispatch_source_t!
    
    override func remoteControlReceivedWithEvent(event: UIEvent?) {
        if let evt = event {
            PVMediaPlayer.sharedInstance.remoteControlReceivedWithEvent(evt)
        }
    }

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        UIApplication.sharedApplication().statusBarStyle = .LightContent
        
        UINavigationBar.appearance().translucent = false
        UINavigationBar.appearance().barTintColor = UIColor(red: 41.0/255.0, green: 104.0/255.0, blue: 177.0/255.0, alpha: 1.0)
        //        UINavigationBar.appearance().barTintColor = UIColor(red: 28.0/255.0, green: 28.0/255.0, blue: 28.0/255.0, alpha: 1.0)
        UINavigationBar.appearance().tintColor = UIColor.whiteColor()
        UINavigationBar.appearance().titleTextAttributes = [NSForegroundColorAttributeName: UIColor.whiteColor(), NSFontAttributeName: UIFont.boldSystemFontOfSize(17.0)]
        
        // Alert the user to enable background notifications
        // TODO: Shouldn't this be moved to somewhere like the AppDelegate?
        let registerUserNotificationSettings = UIApplication.instancesRespondToSelector(#selector(UIApplication.registerUserNotificationSettings(_:)))
        if registerUserNotificationSettings {
            let types: UIUserNotificationType = [.Alert , .Sound]
            UIApplication.sharedApplication().registerUserNotificationSettings(UIUserNotificationSettings(forTypes: types, categories: nil))
        }
        
        // Ask for permission for Podverse to use push notifications
        application.registerUserNotificationSettings(UIUserNotificationSettings(forTypes: [.Alert, .Badge], categories: nil))  // types are UIUserNotificationType members
        
        // Add skip or back 15 seconds to the lock screen media player
        let rcc = MPRemoteCommandCenter.sharedCommandCenter()
        
        let skipBackwardIntervalCommand = rcc.skipBackwardCommand
        skipBackwardIntervalCommand.addTarget(self, action: #selector(AppDelegate.skipBackwardEvent))
        
        let skipForwardIntervalCommand = rcc.skipForwardCommand
        skipForwardIntervalCommand.addTarget(self, action: #selector(AppDelegate.skipForwardEvent))
        
        let pauseCommand = rcc.pauseCommand
        pauseCommand.addTarget(self, action: #selector(AppDelegate.playOrPauseEvent))
        let playCommand = rcc.playCommand
        playCommand.addTarget(self, action: #selector(AppDelegate.playOrPauseEvent))
        
        if NSUserDefaults.standardUserDefaults().boolForKey("AppHasLaunchedOnce") == false {
            NSUserDefaults.standardUserDefaults().setBool(true, forKey: "AppHasLaunchedOnce")
            PlaylistManager.sharedInstance.createDefaultPlaylists()
        }
        
        // Currently we are setting taskIdentifier values = nil on app launch. This wipes CoreData references to downloadingEpisodes that did not complete before the app was last closed or crashed.
        let moc = CoreDataHelper.sharedInstance.managedObjectContext
        let episodeArray = CoreDataHelper.fetchEntities("Episode", predicate: nil, moc: moc) as! [Episode]
        for episode in episodeArray {
            episode.taskIdentifier = nil
        }
        CoreDataHelper.saveCoreData(moc, completionBlock: nil)
                        
        Fabric.with([Crashlytics.self])
        return true
    }
    
    func skipBackwardEvent() {
        PVMediaPlayer.sharedInstance.previousTime(15)
        PVMediaPlayer.sharedInstance.setPlayingInfo(PVMediaPlayer.sharedInstance.nowPlayingEpisode)
    }
    
    func skipForwardEvent() {
        PVMediaPlayer.sharedInstance.skipTime(15)
        PVMediaPlayer.sharedInstance.setPlayingInfo(PVMediaPlayer.sharedInstance.nowPlayingEpisode)
    }
    
    func playOrPauseEvent() {
        print("remote play or pause happened")
    }
    
    func applicationDidEnterBackground(application: UIApplication) {
        // If the app has entered the background, then it may be the case that the device has locked, and we should update the MPNowPlayingInfoCenter with the latest information.
        if let nowPlayingEpisode = PVMediaPlayer.sharedInstance.nowPlayingEpisode {
            PVMediaPlayer.sharedInstance.setPlayingInfo(nowPlayingEpisode)
        }
        
         UIApplication.sharedApplication().applicationIconBadgeNumber = 0
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
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
        
         UIApplication.sharedApplication().applicationIconBadgeNumber = 0
    }
}

