//
//  PVReachability.swift
//  podverse
//
//  Created by Kreon on 6/4/16.
//  Copyright © 2016 Mitchell Downey. All rights reserved.
//

import Foundation
import Reachability

class PVReachability {
    static let manager = PVReachability()
    var reachability:Reachability!
    
    init (){
        do {
            reachability = try Reachability.reachabilityForInternetConnection()
        }
        catch {
            fatalError("Reachability was not initialized. \nError: \(error)")
        }
        
        reachability.whenReachable = { reachability in
            if !reachability.isReachableViaWiFi() {
                self.pauseDownloadingEpisodesUntilWiFi()
            } else {
                self.resumeDownloadingEpisodes()
            }
            
            if NSUserDefaults.standardUserDefaults().objectForKey("ONE_TIME_LOGIN") != nil && NSUserDefaults.standardUserDefaults().boolForKey("DefaultPlaylistsCreated") == false {
                let playlistManager = PlaylistManager.sharedInstance
                playlistManager.getMyPlaylistsFromServer({
                    playlistManager.createDefaultPlaylists()
                })
            }
        }
        
        reachability.whenUnreachable = { reachability in
            if !reachability.isReachableViaWiFi() {
                self.pauseDownloadingEpisodesUntilWiFi()
            }
            
            dispatch_async(dispatch_get_main_queue(), {
                NSNotificationCenter.defaultCenter().postNotificationName(Constants.kInternetIsUnreachable, object: self, userInfo: nil)
            })
        }
        
        do {
            try reachability.startNotifier()
        } catch {
            print("Unable to start notifier")
        }
    }
    
    func hasInternetConnection() -> Bool {
        return reachability.isReachable() ?? false
    }
    
    func hasWiFiConnection() -> Bool {
        return reachability.isReachableViaWiFi() ?? false
    }
    
    func createInternetConnectionNeededAlert(message: String) -> UIAlertController {
        let connectionNeededAlert = UIAlertController(title: "Internet Connection Needed", message: message, preferredStyle: UIAlertControllerStyle.Alert)
        connectionNeededAlert.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
        connectionNeededAlert.addAction(UIAlertAction(title: "Settings", style: .Default) { (_) -> Void in
            let settingsURL = NSURL(string: UIApplicationOpenSettingsURLString)
            if let url = settingsURL {
                UIApplication.sharedApplication().openURL(url)
            }
        })
        return connectionNeededAlert
    }
    
    // TODO: move to PVDownloader without causing splash screen to hang indefinitely
    func pauseDownloadingEpisodesUntilWiFi() {
        let downloader = PVDownloader.sharedInstance
        downloader.downloadSession.getTasksWithCompletionHandler { dataTasks, uploadTasks, downloadTasks in
            for downloadingEpisode in DLEpisodesList.shared.downloadingEpisodes {
                if let taskIdentifier = downloadingEpisode.taskIdentifier {
                    for episodeDownloadTask in downloadTasks {
                        if episodeDownloadTask.taskIdentifier == taskIdentifier {
                            downloader.pauseOrResumeDownloadingEpisode(downloadingEpisode)
                        }
                    }
                }
            }
        }
    }
    
    // TODO: move to PVDownloader without causing splash screen to hang indefinitely
    func resumeDownloadingEpisodes() {
        let downloader = PVDownloader.sharedInstance
        downloader.downloadSession.getTasksWithCompletionHandler { dataTasks, uploadTasks, downloadTasks in
            for downloadingEpisode in DLEpisodesList.shared.downloadingEpisodes {
                if (downloadingEpisode.taskResumeData != nil || downloadingEpisode.pausedWithoutResumeData == true) && downloadingEpisode.wasPausedByUser == false {
                    downloader.pauseOrResumeDownloadingEpisode(downloadingEpisode)
                }
            }
        }
    }
}