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
    
    // TODO: DOWNLOAD RESUME FEATURE IS CURRENTLY NOT WORKING :(

    // TODO: WHAT IF I HIT DOWNLOAD SEVERAL TIMES RAPIDLY?
    
    var moc: NSManagedObjectContext!
    
    var appDelegate: AppDelegate?
    
    var docDirectoryURL: NSURL?
    
    func initializeEpisodeDownloadSession() {
        
        // Get the appropriate local storage directory and assign it to docDirectoryURL
        var URLs = NSFileManager().URLsForDirectory(NSSearchPathDirectory.DocumentDirectory, inDomains: NSSearchPathDomainMask.UserDomainMask)
        self.docDirectoryURL = URLs[0] as? NSURL
        
        // Initialize the session configuration, then create the session
        var sessionConfiguration = NSURLSessionConfiguration.backgroundSessionConfigurationWithIdentifier("fm.podverse.episode.downloads")
        sessionConfiguration.HTTPMaximumConnectionsPerHost = 5
        self.appDelegate!.episodeDownloadSession = NSURLSession(configuration: sessionConfiguration, delegate: self, delegateQueue: nil)
        
    }
    
    func startPauseOrResumeDownloadingEpisode(episode: Episode, completion: ((AnyObject) -> Void)!) {
        
        self.moc = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext
        
        appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate?
        
        // If the session does not already exist, initialize the session
        
        if self.appDelegate!.episodeDownloadSession == nil {
            initializeEpisodeDownloadSession()
        }
        
        // If the episode has already downloaded, then do nothing
        if (episode.downloadComplete == true) {
            // do nothing
            println("do nothing")
        }
        // Else if the episode is currently downloading, and it has a taskIdentifer, then pause the download
        else if episode.isDownloading == true && episode.taskIdentifier != 0 {
            println("else if currently downloading and has task identifier")
            episode.downloadTask?.cancelByProducingResumeData() { resumeData in
                if (resumeData != nil) {
                    episode.taskResumeData = resumeData
                    episode.isDownloading = false
                    self.moc.save(nil)
                }
            }
        }
        // Else if the episode download is paused, then resume the download
        else if episode.taskResumeData != nil {
            println("else if is paused")
            var downloadTask = self.appDelegate!.episodeDownloadSession!.downloadTaskWithResumeData(episode.taskResumeData!)
            episode.taskIdentifier = episode.downloadTask?.taskIdentifier
            episode.isDownloading = true
            self.moc.save(nil)
            downloadTask.resume()
        }
        // Else start or restart the download
        else {
            println("else start or restart download")
            episode.downloadProgress = 0
            var downloadSourceURL = NSURL(string: episode.mediaURL! as String)
            var downloadTask = self.appDelegate!.episodeDownloadSession!.downloadTaskWithURL(downloadSourceURL!, completionHandler: nil)
            episode.taskIdentifier = downloadTask.taskIdentifier
            episode.isDownloading = true
            
            if !contains(appDelegate!.episodeDownloadArray, episode) {
                appDelegate!.episodeDownloadArray.append(episode)
            }
            
            self.moc.save(nil)
            
            downloadTask.resume()
        }
        
        
    }
    
    func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        
        if (totalBytesExpectedToWrite == NSURLSessionTransferSizeUnknown) {
            println("Unknown transfer size")
        }
        else {
            // Get the corresponding episode object by its taskIdentifier value
            var episodeDownloadIndex = self.getDownloadingEpisodeIndexWithTaskIdentifier(downloadTask.taskIdentifier)
            var episode = appDelegate!.episodeDownloadArray[episodeDownloadIndex]
            
            var totalProgress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
            
            // TODO: A crash happened at this line below when I downloaded many NPR PlanetMoney episodes rapidly. "Thread 26: EXC_BAD_ACCESS(code=1, address=0x10)
            // The app then would freeze whenever I reopened it. I also could not see the NPR PlanetMoney episodes on the main page when I reopened it.
            episode.downloadProgress = Float(totalProgress)
            episode.mediaBytes = Float(totalBytesExpectedToWrite)
            
            let downloadHasProgressedUserInfo = ["episode":episode]
            
            NSNotificationCenter.defaultCenter().postNotificationName(kDownloadHasProgressed, object: self, userInfo: downloadHasProgressedUserInfo)

        }
    }
    
    func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didFinishDownloadingToURL location: NSURL) {
        var error: NSError?
        var fileManager = NSFileManager.defaultManager()
        
        println("did finish downloading")
        
        // Get the corresponding episode object by its taskIdentifier value
        var episodeDownloadIndex = self.getDownloadingEpisodeIndexWithTaskIdentifier(downloadTask.taskIdentifier)
        var episode = appDelegate!.episodeDownloadArray[episodeDownloadIndex]
        
        // If file is already downloaded for this episode, remove the old file before saving the new one
        if (episode.fileName != nil) {
            var URLs = NSFileManager().URLsForDirectory(NSSearchPathDirectory.DocumentDirectory, inDomains: NSSearchPathDomainMask.UserDomainMask)
            self.docDirectoryURL = URLs[0] as? NSURL
            var destinationURL = self.docDirectoryURL?.URLByAppendingPathComponent(episode.fileName!)
            fileManager.removeItemAtPath(destinationURL!.path!, error: &error)
        }
        
        // Specify a unique file name and path where the file will stored permanently
        var currentDateTime = NSDate()
        var formatter = NSDateFormatter()
        formatter.dateFormat = "ddMMyyyy-HHmmss"
        var destinationFilename = formatter.stringFromDate(currentDateTime)
        var destinationURL = self.docDirectoryURL?.URLByAppendingPathComponent(destinationFilename)
        
        var success = fileManager.copyItemAtURL(location, toURL: destinationURL!, error: &error)

        if (success) {
            episode.isDownloading = false
            episode.downloadComplete = true
            episode.taskIdentifier = -1
            episode.taskResumeData = nil
            
            // Add the file destination to the episode object for playback and retrieval
            episode.fileName = destinationFilename

            // Reset the episode.downloadTask to nil before saving, or the app will crash
            episode.downloadTask = nil
            
            // Save the downloadedMediaFileDestination with the object
            self.moc.save(&error)
            
            //
            let downloadHasFinishedUserInfo = ["episode":episode]
            
            NSNotificationCenter.defaultCenter().postNotificationName(kDownloadHasFinished, object: self, userInfo: downloadHasFinishedUserInfo)

        }
        

    }
    
    func URLSessionDidFinishEventsForBackgroundURLSession(session: NSURLSession) {
        self.appDelegate!.episodeDownloadSession!.getTasksWithCompletionHandler { (dataTasks, uploadTasks, downloadTasks) -> Void in
            if (downloadTasks.count == 0) {
                if (self.appDelegate!.backgroundTransferCompletionHandler != nil) {
                    var completionHandler: (() -> Void)? = self.appDelegate!.backgroundTransferCompletionHandler
                    
                    self.appDelegate!.backgroundTransferCompletionHandler = nil
                    
                    NSOperationQueue.mainQueue().addOperationWithBlock() {
                        completionHandler?()
                        
                        var localNotification = UILocalNotification()
                        localNotification.alertBody = "All files have been downloaded!"
                        
                        UIApplication.sharedApplication().presentLocalNotificationNow(localNotification)
                    }
                }
            }
            
        }
    }
    
    func getDownloadingEpisodeIndexWithTaskIdentifier(taskIdentifier: Int) -> Int {
        var index = 0

        for (var i = 0; i < appDelegate!.episodeDownloadArray.count; i++) {
            var episode = appDelegate!.episodeDownloadArray[i]

            if (episode.taskIdentifier! == taskIdentifier) {
                index = i
                break
            }

        }
        return index
    }
    
}
