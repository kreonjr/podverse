//
//  PVDownloader.swift
//  
//
//  Created by Mitchell Downey on 6/20/15.
//
//

import UIKit

class PVDownloader: NSObject, NSURLSessionDelegate, NSURLSessionDownloadDelegate {
    
    // TODO: DOWNLOAD RESUME FEATURE IS CURRENTLY NOT WORKING :(

    // TODO: WHAT IF I HIT DOWNLOAD SEVERAL TIMES RAPIDLY?
    
    // TODO: DOWNLOAD/PLAY ICON DOES NOT REFRESH AFTER DOWNLOAD FINISHED
    
    var moc = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext!
    
    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    
    var session: NSURLSession?
    var docDirectoryURL: NSURL?
    
    func initializeEpisodeDownloadSession() {
        // Get the appropriate local storage directory and assign it to docDirectoryURL
        var URLs = NSFileManager().URLsForDirectory(NSSearchPathDirectory.DocumentDirectory, inDomains: NSSearchPathDomainMask.UserDomainMask)
        self.docDirectoryURL = URLs[0] as? NSURL
        
        // Initialize the session configuration, then create the session
        var sessionConfiguration = NSURLSessionConfiguration.backgroundSessionConfigurationWithIdentifier("fm.podverse")
        sessionConfiguration.HTTPMaximumConnectionsPerHost = 5
        self.session = NSURLSession(configuration: sessionConfiguration, delegate: self, delegateQueue: nil)
    }
    
    func startOrPauseDownloadingEpisode(episode: Episode, tblViewController: UITableViewController, completion: ((AnyObject) -> Void)!) {
        // If the session does not already exist, initialize the session
        if (self.session?.configuration.identifier != "fm.podverse") {
            initializeEpisodeDownloadSession()
        }
        
        // If the episode is not already downloaded, then start, resume, or pause the download
        if (episode.fileName == nil) {
            appDelegate.episodeDownloadArray.append(episode)
            
            // If episode is not currently downloading, start or resume the download
            if (episode.isDownloading == false) {
                var downloadSourceURL = NSURL(string: episode.mediaURL! as String)
                // If download has not been previously started, start the download
                if (episode.taskIdentifier == -1) {
                    var downloadTask = self.session?.downloadTaskWithURL(downloadSourceURL!, completionHandler: nil)
                    episode.taskIdentifier = downloadTask!.taskIdentifier
                    downloadTask!.resume()
                    episode.isDownloading = true
                }
                    
                // If download was previously started, then was paused, resume the download
                else {
                    if (episode.taskResumeData != nil) {
                        var downloadTask = self.session?.downloadTaskWithResumeData(episode.taskResumeData!)
                        downloadTask!.resume()
                        episode.taskIdentifier = episode.downloadTask?.taskIdentifier
                        episode.isDownloading = true
                    }
                }
            }
                
            // If episode is currently downloading, pause the download, and save resume data for later
            else {
                episode.downloadTask?.cancelByProducingResumeData() { resumeData in
                    if (resumeData != nil) {
                        episode.taskResumeData = resumeData
                    }
                    episode.isDownloading = false
                }
                tblViewController.tableView.reloadData()
            }
        }
    }
    
    func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        
        if (totalBytesExpectedToWrite == NSURLSessionTransferSizeUnknown) {
            println("Unknown transfer size")
        }
        else {
            // Get the corresponding episode object by its taskIdentifier value
            var episodeDownloadIndex = self.getDownloadingEpisodeIndexWithTaskIdentifier(downloadTask.taskIdentifier)
            var episode = appDelegate.episodeDownloadArray[episodeDownloadIndex]
            
            var totalProgress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
            episode.downloadProgress = Float(totalProgress)
            
            let downloadHasProgressedUserInfo = ["episode":episode]
            
            NSNotificationCenter.defaultCenter().postNotificationName(kDownloadHasProgressed, object: self, userInfo: downloadHasProgressedUserInfo)

        }
    }
    
    func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didFinishDownloadingToURL location: NSURL) {
        var error: NSError?
        var fileManager = NSFileManager.defaultManager()
        
        // Get the corresponding episode object by its taskIdentifier value
        var episodeDownloadIndex = self.getDownloadingEpisodeIndexWithTaskIdentifier(downloadTask.taskIdentifier)
        var episode = appDelegate.episodeDownloadArray[episodeDownloadIndex]
        
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

            // Reset the episode.download to nil before saving, or the app will crash
            episode.downloadTask = nil
            
            // Save the downloadedMediaFileDestination with the object
            self.moc.save(&error)
            
            //
            let downloadHasFinishedUserInfo = ["episode":episode]
            
            NSNotificationCenter.defaultCenter().postNotificationName(kDownloadHasFinished, object: self, userInfo: downloadHasFinishedUserInfo)

        }
        

    }
    
    func URLSessionDidFinishEventsForBackgroundURLSession(session: NSURLSession) {
        self.session?.getTasksWithCompletionHandler { (dataTasks, uploadTasks, downloadTasks) -> Void in
            if (downloadTasks.count == 0) {
                if (self.appDelegate.backgroundTransferCompletionHandler != nil) {
                    var completionHandler: (() -> Void)? = self.appDelegate.backgroundTransferCompletionHandler
                    
                    self.appDelegate.backgroundTransferCompletionHandler = nil
                    
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
        for (var i = 0; i < appDelegate.episodeDownloadArray.count; i++) {
            var episode = appDelegate.episodeDownloadArray[i]
            if (episode.taskIdentifier! == taskIdentifier) {
                index = i
                break
            }
        }
        return index
    }
    
}
