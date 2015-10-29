//
//  PVSubscriber.swift
//  podverse
//
//  Created by Mitchell Downey on 7/19/15.
//  Copyright (c) 2015 Mitchell Downey. All rights reserved.
//

import UIKit
import CoreData

class PVSubscriber: NSObject {
    
    static let sharedInstance = PVSubscriber()
    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    var moc: NSManagedObjectContext! {
        get {
            return appDelegate.managedObjectContext
        }
    }
    
    func subscribeToPodcast(feedURLString: String) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) { () -> Void in
            let feedParser = PVFeedParser(shouldGetMostRecent: false, shouldSubscribe: true)
            feedParser.parsePodcastFeed(feedURLString)
        }
    }
    
    func unsubscribeFromPodcast(podcast:Podcast) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) { () -> Void in
            let episodeToRemovePredicate = NSPredicate(format: "podcast == %@", podcast)
            let episodeToRemoveArray = CoreDataHelper.fetchEntities("Episode", managedObjectContext: self.moc, predicate: episodeToRemovePredicate)
            
            // Get the downloadSession and the downloadTasks, and make downloadTasks available to parent
            let downloadSession = PVDownloader.sharedInstance.downloadSession
            var downloadTasksArray = [NSURLSessionDownloadTask]()
            downloadSession.getTasksWithCompletionHandler { dataTasks, uploadTasks, downloadTasks in
                downloadTasksArray = downloadTasks
            }
            
            // Delete each episode from the moc, cancel current downloadTask, and remove episode from the episodeDownloadArray
            for var i = 0; i < episodeToRemoveArray.count; i++ {
                let episodeToRemove = episodeToRemoveArray[i] as! Episode
                if let fileName = episodeToRemove.fileName {
                    PVUtility.deleteEpisodeFromDiskWithName(fileName)
                }
                
                self.moc.deleteObject(episodeToRemove)
                
                // If the episodeToRemove is currently downloading, then retrieve and cancel the download
                if episodeToRemove.taskIdentifier != nil {
                    for episodeDownloadTask in downloadTasksArray {
                        if episodeDownloadTask.taskIdentifier == episodeToRemove.taskIdentifier {
                            episodeDownloadTask.cancel()
                        }
                    }
                }
                
                // If the episodeToRemove is in the episodeDownloadArray, then remove the episodeToRemove from the episodeDownloadArray
                if self.appDelegate.episodeDownloadArray.contains(episodeToRemove) {
                    let episodeDownloadArrayIndex = self.appDelegate.episodeDownloadArray.indexOf(episodeToRemove)
                    self.appDelegate.episodeDownloadArray.removeAtIndex(episodeDownloadArrayIndex!)
                }
                
                // If the episodeToRemove is currently now playing, then remove the now playing episode, and remove the Player button from the navbar
                if let nowPlayingEpisode = PVMediaPlayer.sharedInstance.nowPlayingEpisode {
                    if episodeToRemove == nowPlayingEpisode {
                        PVMediaPlayer.sharedInstance.avPlayer.pause()
                        PVMediaPlayer.sharedInstance.nowPlayingEpisode = nil
                    }
                }
                
            }
            
            // Delete podcast from CoreData, then update UI
            self.moc.deleteObject(podcast)
            // Save
            do {
                try self.moc.save()
                print("podcast and it's episodes deleted")
            } catch let error as NSError {
                print(error)
            }
        }
    }
}
