//
//  PVDownloader.swift
//  
//
//  Created by Mitchell Downey on 6/20/15.
//
//

import UIKit

class PVDownloader: NSObject, NSURLSessionDelegate, NSURLSessionDownloadDelegate {
   
    var moc: NSManagedObjectContext!
    
    var session: NSURLSession?
    var episodeDownloadArray = [Episode]()
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
        initializeEpisodeDownloadSession()
        
        // If episode is not currently downloading, start or resume the download
        if (episode.isDownloading == false) {
            var downloadSourceURL = NSURL(string: episode.mediaURL! as String)
            
            // If download has not been previously started, start the download
            if (episode.taskIdentifier == -1) {
                episode.downloadTask = self.session?.downloadTaskWithURL(downloadSourceURL!, completionHandler: nil)
                episode.taskIdentifier = episode.downloadTask?.taskIdentifier
                episode.downloadTask!.resume()
                episode.isDownloading = true
            }
                
            // If download was previously started, then was paused, resume the download
            else {
                if (episode.taskResumeData != nil) {
                    episode.downloadTask = self.session?.downloadTaskWithResumeData(episode.taskResumeData!)
                    episode.downloadTask!.resume()
                    episode.taskIdentifier = episode.downloadTask?.taskIdentifier
                    episode.isDownloading = true
                }
            }
            
        // If episode is currently downloading, pause the download, and save resume data for later
        }
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
    
    func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        println("yoohoo")
        if (totalBytesExpectedToWrite == NSURLSessionTransferSizeUnknown) {
            println("Unknown transfer size")
        }
        else {
            NSOperationQueue.mainQueue().addOperationWithBlock() { () in
                var totalProgress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
                println(totalProgress)
                println("NSOperation")
            }
        }
    }
    
    func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didFinishDownloadingToURL location: NSURL) {
        println("done!")
    }
    
    
//    func downloadEpisode(episode: Episode, completion: ((AnyObject) -> Void)!) {
//        moc = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext
//        
//        let episodeMediaURLString = episode.mediaURL
//        
//        let session = NSURLSession()
//        let episodeURL = NSURL(string: episodeMediaURLString)
//
//        let task = session.dataTaskWithURL(episodeURL!, completionHandler: {(data, response, error) -> Void in
//            println("download began")
//            if error != nil {
//                println(error.localizedDescription)
//            } else {
//                if data != nil {
//                    // Get the place to store the downloaded file in app's local memory
//                    let dirPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as! String
//                    
//                    // Name the file with date/time to be unique
//                    var currentDateTime = NSDate()
//                    var formatter = NSDateFormatter()
//                    formatter.dateFormat = "ddMMyyyy-HHmmss"
//                    // TODO: hardcoding .mp3 here would cause a problem for .ogg or other file formats
//                    var fileName = formatter.stringFromDate(currentDateTime) + ".mp3"
//                    var filePath = dirPath.stringByAppendingPathComponent(fileName)
//                    
//                    // Save the file locally with the unique file name as the URL path
//                    let fileManager = NSFileManager.defaultManager()
//                    fileManager.createFileAtPath(filePath, contents: data, attributes: nil)
//                    
//                    episode.downloadedMediaFileURL = fileName
//                    self.moc.save(nil)
//                }
//                println("episode has been downloaded")
//            }
//        })
//        
//        task.resume()
//        
//    }
    
}
