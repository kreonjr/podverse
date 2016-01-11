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

    var appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    
    var docDirectoryURL: NSURL?
    var downloadSession: NSURLSession!
    
    static let sharedInstance = PVDownloader()
    
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
        episode.downloadProgress = 0
        if let downloadSourceStringURL = episode.mediaURL, let downloadSourceURL = NSURL(string: downloadSourceStringURL) {
            let downloadTask = downloadSession.downloadTaskWithURL(downloadSourceURL)
            episode.taskIdentifier = NSNumber(integer:downloadTask.taskIdentifier)
            
            if !appDelegate.episodeDownloadArray.contains(episode) {
                appDelegate.episodeDownloadArray.append(episode)
            }
            
            CoreDataHelper.saveCoreData(nil)
            let task = beginBackgroundTask()
            downloadTask.resume()
            endBackgroundTask(task)
        }
    }
    
    func pauseOrResumeDownloadingEpisode(episode: Episode) {
        // If the episode has already downloaded, then do nothing
        if (episode.downloadComplete == true) {
            // do nothing
        }
        // Else if the episode download is paused, then resume the download
        else if episode.taskResumeData != nil {
            if let downloadTaskResumeData = episode.taskResumeData {
                let downloadTask = downloadSession.downloadTaskWithResumeData(downloadTaskResumeData)
                episode.taskIdentifier = NSNumber(integer:downloadTask.taskIdentifier)
                episode.taskResumeData = nil
                
                CoreDataHelper.saveCoreData(nil)
                
                downloadTask.resume()
            }
        }
        // Else if the episode is currently downloading, then pause the download
        else if let taskIdentifier = episode.taskIdentifier {
            downloadSession.getTasksWithCompletionHandler { dataTasks, uploadTasks, downloadTasks in
                for episodeDownloadTask in downloadTasks {
                    if episodeDownloadTask.taskIdentifier == taskIdentifier.integerValue {
                        episodeDownloadTask.cancelByProducingResumeData() {resumeData in
                            if (resumeData != nil) {
                                episode.taskResumeData = resumeData
                                episode.taskIdentifier = nil
                                CoreDataHelper.saveCoreData(nil)
                            }
                        }
                    }
                }
            }
        }
        // Else start or restart the download
        else {
          startDownloadingEpisode(episode)
        }
    }
    
    func URLSession(session: NSURLSession, task: NSURLSessionTask, didCompleteWithError error: NSError?) {
        if let episodeDownloadIndex = getDownloadingEpisodeIndexWithTaskIdentifier(task.taskIdentifier) {
            let episode = appDelegate.episodeDownloadArray[episodeDownloadIndex.integerValue]
            
            if let resumeData = error?.userInfo[NSURLSessionDownloadTaskResumeData] as? NSData {
                episode.taskResumeData = resumeData
                CoreDataHelper.saveCoreData(nil)
            }
        }
    }
    
    func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        
        if (totalBytesExpectedToWrite == NSURLSessionTransferSizeUnknown) {
            print("Unknown transfer size")
        }
        else {
            // Get the corresponding episode object by its taskIdentifier value
            if let episodeDownloadIndex = getDownloadingEpisodeIndexWithTaskIdentifier(downloadTask.taskIdentifier) {
                if episodeDownloadIndex.integerValue < appDelegate.episodeDownloadArray.count {
                    let episode = appDelegate.episodeDownloadArray[episodeDownloadIndex.integerValue]
                    
                    let totalProgress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
                    
                    episode.downloadProgress = Float(totalProgress)
                    episode.mediaBytes = Float(totalBytesExpectedToWrite)
                    
                    // TODO: Should we call a moc.save() within the didWriteData?
                    
                    // TODO: Is this Notification actually doing anything? I don't see the downloadHasProgressed notification getting used anywhere...
                    let downloadHasProgressedUserInfo = ["episode":episode]
                    
                    NSNotificationCenter.defaultCenter().postNotificationName(Constants.kDownloadHasProgressed, object: self, userInfo: downloadHasProgressedUserInfo)
                }
            }
        }
    }
    
    func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didFinishDownloadingToURL location: NSURL) {

        let fileManager = NSFileManager.defaultManager()
        
        print("did finish downloading")
        
        // Get the corresponding episode object by its taskIdentifier value
        if let episodeDownloadIndex = getDownloadingEpisodeIndexWithTaskIdentifier(downloadTask.taskIdentifier) {
            let episode = appDelegate.episodeDownloadArray[episodeDownloadIndex.integerValue]
            
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
            
            // Specify a unique file name and path where the file will stored permanently
            let currentDateTime = NSDate()
            let formatter = NSDateFormatter()
            formatter.dateFormat = "ddMMyyyy-HHmmss"
            // TODO: why must we add .mp3 or .ogg to the end of the file name in order for the media player to play the file? What would happen if a downloaded file is not actually an .mp3 or .ogg?
            let destinationFilename = formatter.stringFromDate(currentDateTime) + mp3OrOggFileExtension
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
                    
                    // Save the downloadedMediaFileDestination with the object
                    do {
                        try Constants.moc.save()
                    } catch {
                        print(error)
                    }
                    
                    let downloadHasFinishedUserInfo = ["episode":episode]
                    
                    NSNotificationCenter.defaultCenter().postNotificationName(Constants.kDownloadHasFinished, object: self, userInfo: downloadHasFinishedUserInfo)
                    let notification = UILocalNotification()
                    notification.applicationIconBadgeNumber = UIApplication.sharedApplication().applicationIconBadgeNumber + 1
                    notification.alertBody = "Episode Downloaded" // text that will be displayed in the notification
                    notification.alertAction = "open"
                    notification.soundName = UILocalNotificationDefaultSoundName // play default sound
                    UIApplication.sharedApplication().scheduleLocalNotification(notification)
                }
            } catch {
                print(error)
            }
        }
    }
    
    func URLSessionDidFinishEventsForBackgroundURLSession(session: NSURLSession) {
        downloadSession.getTasksWithCompletionHandler { (dataTasks, uploadTasks, downloadTasks) -> Void in
            if (downloadTasks.count == 0) {
                if (self.appDelegate.backgroundTransferCompletionHandler != nil) {
                    let completionHandler: (() -> Void)? = self.appDelegate.backgroundTransferCompletionHandler
                    
                    self.appDelegate.backgroundTransferCompletionHandler = nil
                    
                    NSOperationQueue.mainQueue().addOperationWithBlock() {
                        completionHandler?()
                        
                        let localNotification = UILocalNotification()
                        localNotification.alertBody = "All files have been downloaded!"
                        
                        UIApplication.sharedApplication().presentLocalNotificationNow(localNotification)
                    }
                }
            }
            
        }
    }
    
    func getDownloadingEpisodeIndexWithTaskIdentifier(taskIdentifier: Int) -> NSNumber? {
        for (index,episode) in appDelegate.episodeDownloadArray.enumerate() {
            if taskIdentifier == episode.taskIdentifier?.integerValue {
                return NSNumber(integer: index)
            }
        }
        
        return nil
    }
    
    func executeIfBackground(synchronousFunction: () -> ()) {
        
    }
    
    
    func beginBackgroundTask() -> UIBackgroundTaskIdentifier {
        return UIApplication.sharedApplication().beginBackgroundTaskWithExpirationHandler({})
    }

    func endBackgroundTask(taskID: UIBackgroundTaskIdentifier) {
        UIApplication.sharedApplication().endBackgroundTask(taskID)
    }
    
    
    
}
