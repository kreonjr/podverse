//
//  PVDownloader.swift
//  
//
//  Created by Mitchell Downey on 6/20/15.
//
//

import UIKit
import CoreData

class PVDownloader: NSObject, NSURLSessionDelegate, NSURLSessionDownloadDelegate {

    static let sharedInstance = PVDownloader()
    var appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    var docDirectoryURL: NSURL?
    var downloadSession: NSURLSession!
    let reachability = PVReachability.manager
        
    override init() {
        super.init()
        
        let sessionConfiguration = NSURLSessionConfiguration.backgroundSessionConfigurationWithIdentifier("podverse.download.episodes")
        
        var URLs = NSFileManager().URLsForDirectory(NSSearchPathDirectory.DocumentDirectory, inDomains: NSSearchPathDomainMask.UserDomainMask)
        docDirectoryURL = URLs[0]
        
        // Initialize the session configuration, then create the session
        sessionConfiguration.HTTPMaximumConnectionsPerHost = 3
        sessionConfiguration.allowsCellularAccess = false
        
        downloadSession = NSURLSession(configuration: sessionConfiguration, delegate: self, delegateQueue: nil)
    }
    
    func startDownloadingEpisode (episode: Episode) {        
        episode.downloadComplete = false
        if let downloadSourceStringURL = episode.mediaURL, let downloadSourceURL = NSURL(string: downloadSourceStringURL) {
            let downloadTask = downloadSession.downloadTaskWithURL(downloadSourceURL)
            episode.taskIdentifier = NSNumber(integer:downloadTask.taskIdentifier)

            let downloadingEpisode = DownloadingEpisode(episode:episode)
            if !DLEpisodesList.shared.downloadingEpisodes.contains(downloadingEpisode) {
                DLEpisodesList.shared.downloadingEpisodes.append(downloadingEpisode)
                incrementBadge()
            }
            // If downloadingEpisode already exists then update it with the new taskIdentifier
            else {
                if let matchingDLEpisode = DLEpisodesList.shared.downloadingEpisodes.find({ $0 == downloadingEpisode })  {
                    matchingDLEpisode.taskIdentifier = episode.taskIdentifier?.integerValue
                }
            }
            
            let task = self.beginBackgroundTask()
            downloadTask.resume()
            self.endBackgroundTask(task)
            
            self.postPauseOrResumeNotification(downloadTask.taskIdentifier, pauseOrResume: "Downloading")
        }
    }
    
    // TODO: this should probably be refactored someday.
    func pauseOrResumeDownloadingEpisode(episode: DownloadingEpisode) {
        // If the episode has already downloaded, then do nothing
        if (episode.downloadComplete == true) {
            episode.taskIdentifier = nil
        }
        // Else if the episode download is paused, then resume the download
        else if let downloadTaskResumeData = episode.taskResumeData {
            let downloadTask = downloadSession.downloadTaskWithResumeData(downloadTaskResumeData)
            episode.taskIdentifier = downloadTask.taskIdentifier
            episode.taskResumeData = nil
            episode.wasPausedByUser = false
            downloadTask.resume()
            self.postPauseOrResumeNotification(downloadTask.taskIdentifier, pauseOrResume: "Downloading")
        }
        else if episode.pausedWithoutResumeData == true {
            episode.pausedWithoutResumeData = false
            let moc = CoreDataHelper.sharedInstance.managedObjectContext
            if let episodeObjectID = episode.managedEpisodeObjectID {
                if let nsManagedEpisode = CoreDataHelper.fetchEntityWithID(episodeObjectID, moc: moc) as? Episode {
                    startDownloadingEpisode(nsManagedEpisode)
                }
            }
        }
        // Else if the episode has a taskIdentifier, then pause the download if it has already begun
        else if let taskIdentifier = episode.taskIdentifier {
            downloadSession.getTasksWithCompletionHandler { dataTasks, uploadTasks, downloadTasks in
                for episodeDownloadTask in downloadTasks {
                    if episodeDownloadTask.taskIdentifier == taskIdentifier {
                        episodeDownloadTask.cancelByProducingResumeData() { resumeData in
                            if (resumeData != nil) {
                                episode.taskResumeData = resumeData
                                if self.reachability.hasWiFiConnection() == true {
                                    episode.wasPausedByUser = true
                                    self.postPauseOrResumeNotification(taskIdentifier, pauseOrResume: "Paused")
                                }
                                else {
                                    self.postPauseOrResumeNotification(taskIdentifier, pauseOrResume: "Connect to WiFi")
                                }
                                episode.taskIdentifier = nil
                            } else {
                                episode.pausedWithoutResumeData = true
                                if self.reachability.hasWiFiConnection() == true {
                                    episode.wasPausedByUser = true
                                    self.postPauseOrResumeNotification(taskIdentifier, pauseOrResume: "Paused")
                                }
                                else {
                                    self.postPauseOrResumeNotification(taskIdentifier, pauseOrResume: "Connect to WiFi")
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    func postPauseOrResumeNotification(taskIdentifier: NSNumber, pauseOrResume: String) {
        // Get the corresponding episode object by its taskIdentifier value
        if let episodeDownloadIndex = DLEpisodesList.shared.downloadingEpisodes.indexOf({$0.taskIdentifier == taskIdentifier.integerValue}) {
            if episodeDownloadIndex < DLEpisodesList.shared.downloadingEpisodes.count {
                let episode = DLEpisodesList.shared.downloadingEpisodes[episodeDownloadIndex]
                
                let downloadHasPausedOrResumedUserInfo:[NSObject:AnyObject] = ["mediaUrl":episode.mediaURL ?? "", "pauseOrResume": pauseOrResume ?? ""]
                
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    NSNotificationCenter.defaultCenter().postNotificationName(Constants.kDownloadHasPausedOrResumed, object: self, userInfo: downloadHasPausedOrResumedUserInfo)
                })
            }
        }
    }
    
    func URLSession(session: NSURLSession, task: NSURLSessionTask, didCompleteWithError error: NSError?) {
        //TODO: Handle erroring out he downloading proccess
//        if let episodeDownloadIndex = DLEpisodesList.shared.downloadingEpisodes.indexOf({$0.taskIdentifier == task.taskIdentifier}) {
//            let episode = DLEpisodesList.shared.downloadingEpisodes[episodeDownloadIndex]
//            
//            if let resumeData = error?.userInfo[NSURLSessionDownloadTaskResumeData] as? NSData {
//                episode.taskResumeData = resumeData
//            }
//        }
    }
    
    func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        
        if (totalBytesExpectedToWrite == NSURLSessionTransferSizeUnknown) {
            print("Unknown transfer size")
        }
        else {
            // Get the corresponding episode object by its taskIdentifier value
            if let episodeDownloadIndex = DLEpisodesList.shared.downloadingEpisodes.indexOf({$0.taskIdentifier == downloadTask.taskIdentifier}) {
                let episode = DLEpisodesList.shared.downloadingEpisodes[episodeDownloadIndex]
                episode.totalBytesWritten = Float(totalBytesWritten)
                episode.totalBytesExpectedToWrite = Float(totalBytesExpectedToWrite)
                
                let downloadHasProgressedUserInfo:[NSObject:AnyObject] = ["mediaUrl":episode.mediaURL ?? "",
                    "totalBytes": Double(totalBytesExpectedToWrite),
                    "currentBytes": Double(totalBytesWritten)]
                
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    NSNotificationCenter.defaultCenter().postNotificationName(Constants.kDownloadHasProgressed, object: self, userInfo: downloadHasProgressedUserInfo)
                })
            }
        }
    }
    
    func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didFinishDownloadingToURL location: NSURL) {

        let fileManager = NSFileManager.defaultManager()
        print("did finish downloading")
        let moc = CoreDataHelper.sharedInstance.backgroundContext
        // Get the corresponding episode object by its taskIdentifier value
        if let downloadingEpisode = DLEpisodesList.shared.downloadingEpisodes.find({$0.taskIdentifier == downloadTask.taskIdentifier}) {
            
            guard let mediaUrl =  downloadingEpisode.mediaURL else {
                return
            }
            
            let predicate = NSPredicate(format: "mediaURL == %@", mediaUrl)
            guard let episode = CoreDataHelper.fetchEntities("Episode", predicate: predicate, moc: moc).first as? Episode else {
                return
            }
            
            var mp3OrOggFileExtension = ".mp3"
            
            if ((episode.mediaURL?.hasSuffix(".ogg")) == true) {
                mp3OrOggFileExtension = ".ogg"
            }
            
            // If file is already downloaded for this episode, remove the old file before saving the new one
            if let fileName = episode.fileName {
                var URLs = NSFileManager().URLsForDirectory(NSSearchPathDirectory.DocumentDirectory, inDomains: NSSearchPathDomainMask.UserDomainMask)
                self.docDirectoryURL = URLs[0]
                let destinationURL = self.docDirectoryURL?.URLByAppendingPathComponent(fileName)
                
                if let destination = destinationURL, let path = destination.path {
                    do {
                        try fileManager.removeItemAtPath(path)
                    } catch {
                        print(error)
                    }
                }
            }
            
            // TODO: why must we add .mp3 or .ogg to the end of the file name in order for the media player to play the file? What would happen if a downloaded file is not actually an .mp3 or .ogg?
            let destinationFilename = NSUUID().UUIDString + mp3OrOggFileExtension
            let destinationURL = self.docDirectoryURL?.URLByAppendingPathComponent(destinationFilename)
            
            do {
                if let destination = destinationURL {
                    try fileManager.copyItemAtURL(location, toURL: destination)
                    
                    episode.downloadComplete = true

                    episode.taskResumeData = nil
                    
                    // Add the file destination to the episode object for playback and retrieval
                    episode.fileName = destinationFilename
                    
                    // Reset the episode.downloadTask to nil before saving, or the app will crash
                    episode.taskIdentifier = nil
                    
                    for downloadingEpisode in DLEpisodesList.shared.downloadingEpisodes where episode.mediaURL == downloadingEpisode.mediaURL {
                        downloadingEpisode.downloadComplete = true
                        downloadingEpisode.taskIdentifier = nil
                    }
                    
                    var episodeTitle = ""
                    if let title = episode.title {
                        episodeTitle = title
                    }
                    
                    let podcastTitle = episode.podcast.title
                    // Save the downloadedMediaFileDestination with the object
                    CoreDataHelper.saveCoreData(moc, completionBlock: { (saved) -> Void in
                        let downloadHasFinishedUserInfo = ["episode":episode]
                        
                        dispatch_async(dispatch_get_main_queue(), {[weak self] () -> Void in
                            guard let strongSelf = self else {
                                return
                            }
                            
                            NSNotificationCenter.defaultCenter().postNotificationName(Constants.kDownloadHasFinished, object: strongSelf, userInfo: downloadHasFinishedUserInfo)
                            
                            // TODO: When a download finishes and Podverse is in the background, two localnotifications show in the UI. Why are we receiving two instead of one, when only one notification is getting scheduled below?
                            let notification = UILocalNotification()
                            notification.applicationIconBadgeNumber = UIApplication.sharedApplication().applicationIconBadgeNumber + 1
                            notification.alertBody = podcastTitle + " - " + episodeTitle // text that will be displayed in the notification
                            notification.alertAction = "open"
                            notification.soundName = UILocalNotificationDefaultSoundName // play default sound
                            UIApplication.sharedApplication().presentLocalNotificationNow(notification)
                            
                            strongSelf.decrementBadge()
                        })
                    })
                }
            } catch {
                print(error)
            }
        }
    }
    
    func executeIfBackground(synchronousFunction: () -> ()) {
        
    }
    
    
    func beginBackgroundTask() -> UIBackgroundTaskIdentifier {
        return UIApplication.sharedApplication().beginBackgroundTaskWithExpirationHandler({})
    }

    func endBackgroundTask(taskID: UIBackgroundTaskIdentifier) {
        UIApplication.sharedApplication().endBackgroundTask(taskID)
    }
    
    private func incrementBadge() {
        dispatch_async(dispatch_get_main_queue(), {
            if let tabBarCntrl = self.appDelegate.window?.rootViewController as? UITabBarController {
                if let badgeValue = tabBarCntrl.tabBar.items?[TabItems.Downloads.getIndex()].badgeValue, badgeInt = Int(badgeValue) {
                    tabBarCntrl.tabBar.items?[TabItems.Downloads.getIndex()].badgeValue = "\(badgeInt + 1)"
                }
                else {
                    tabBarCntrl.tabBar.items?[TabItems.Downloads.getIndex()].badgeValue = "1"
                }
            }
        })
    }
    
    private func decrementBadge() {
        if let tabBarCntrl = self.appDelegate.window?.rootViewController as? UITabBarController {
            if let badgeValue = tabBarCntrl.tabBar.items?[TabItems.Downloads.getIndex()].badgeValue, badgeInt = Int(badgeValue) {
                tabBarCntrl.tabBar.items?[TabItems.Downloads.getIndex()].badgeValue = "\(badgeInt - 1)"
                if tabBarCntrl.tabBar.items?[TabItems.Downloads.getIndex()].badgeValue == "0" {
                    tabBarCntrl.tabBar.items?[TabItems.Downloads.getIndex()].badgeValue = nil
                }
            }
        }
    }
}
