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

    var appDelegate = (UIApplication.sharedApplication().delegate as! AppDelegate)
    func subscribeToPodcast(feedURLString: String) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) { () -> Void in
            let feedParser = PVFeedParser(shouldGetMostRecent: false, shouldSubscribe: true)
            feedParser.parsePodcastFeed(feedURLString)
        }
    }
    
    func unsubscribeFromPodcast(podcast:Podcast) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) { () -> Void in
            let episodesToRemove = podcast.episodes.allObjects as! [Episode]
            
            // Get the downloadSession and the downloadTasks, and make downloadTasks available to parent
            let downloadSession = PVDownloader.sharedInstance.downloadSession
            var downloadTasksArray = [NSURLSessionDownloadTask]()
            downloadSession.getTasksWithCompletionHandler { dataTasks, uploadTasks, downloadTasks in
                downloadTasksArray = downloadTasks
            }
            
            // Delete each episode from the moc, cancel current downloadTask, and remove episode from the episodeDownloadArray
            for var i = 0; i < episodesToRemove.count; i++ {
                let episodeToRemove = episodesToRemove[i]
                if let fileName = episodeToRemove.fileName {
                    PVUtility.deleteEpisodeFromDiskWithName(fileName)
                }
                
                CoreDataHelper.deleteItemFromCoreData(episodeToRemove, completionBlock: { () -> Void in
                    CoreDataHelper.saveCoreData(nil)
                })

                
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
            
            CoreDataHelper.deleteItemFromCoreData(podcast, completionBlock: { () -> Void in
                CoreDataHelper.saveCoreData(nil)
            })
        }
    }
}
