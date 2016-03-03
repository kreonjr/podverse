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
    
    let REFRESH_PODCAST_TIME:Double = 3600
    
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
        NSTimer.scheduledTimerWithTimeInterval(REFRESH_PODCAST_TIME, target: self, selector: "refreshPodcastFeeds", userInfo: nil, repeats: true)
    }
    
    func refreshPodcastFeeds () {
        let podcastArray = CoreDataHelper.sharedInstance.fetchEntities("Podcast", predicate: nil) as! [Podcast]
        for var i = 0; i < podcastArray.count; i++ {
            let feedURL = NSURL(string: podcastArray[i].feedURL)
            
            let feedParser = PVFeedParser(shouldGetMostRecent: true, shouldSubscribe:false )
            if let feedURLString = feedURL?.absoluteString {
                feedParser.parsePodcastFeed(feedURLString)
            }
        }
    }

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        
        // Alert the user to enable background notifications
        // TODO: Shouldn't this be moved to somewhere like the AppDelegate?
        let registerUserNotificationSettings = UIApplication.instancesRespondToSelector("registerUserNotificationSettings:")
        if registerUserNotificationSettings {
            let types: UIUserNotificationType = [.Alert , .Sound]
            UIApplication.sharedApplication().registerUserNotificationSettings(UIUserNotificationSettings(forTypes: types, categories: nil))
        }
        
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
        let episodeArray = CoreDataHelper.sharedInstance.fetchEntities("Episode", predicate: nil) as! [Episode]
        for episode in episodeArray {
            episode.taskIdentifier = nil
        }
        
        for episode:Episode in DLEpisodesList.shared.downloadingEpisodes {
            PVDownloader.sharedInstance.startDownloadingEpisode(episode)
        }
    
        self.refreshPodcastFeeds()
        PlaylistManager.sharedInstance.refreshPlaylists()
        
        startCheckSubscriptionsForNewEpisodesTimer()
        
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
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
        self.refreshPodcastFeeds()
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
        
        CoreDataHelper.sharedInstance.saveCoreData(nil)
    }
}

