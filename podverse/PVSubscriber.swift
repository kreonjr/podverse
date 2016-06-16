//
//  PVSubscriber.swift
//  podverse
//
//  Created by Mitchell Downey on 7/19/15.
//  Copyright (c) 2015 Mitchell Downey. All rights reserved.
//

import UIKit
import CoreData

class PVSubscriber {

    static func subscribeToPodcast(feedURLString: String, podcastTableDelegate:PodcastsTableViewController?) {
        ParsingPodcastsList.shared.urls.append(feedURLString)
        if let ptd = podcastTableDelegate {
            ptd.updateParsingActivity()
        }
        
        dispatch_async(Constants.feedParsingQueue) {
            let feedParser = PVFeedParser(onlyGetMostRecentEpisode: false, shouldSubscribe: true)
            feedParser.delegate = podcastTableDelegate
            feedParser.parsePodcastFeed(feedURLString)
        }
    }
    
    static func unsubscribeFromPodcast(podcastID:NSManagedObjectID, completionBlock:(()->Void)?) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            let moc = CoreDataHelper.sharedInstance.backgroundContext
            let podcast = CoreDataHelper.fetchEntityWithID(podcastID, moc: moc) as! Podcast
            let alsoDelete = PVDeleter.checkIfPodcastShouldBeRemoved(podcast, isUnsubscribing: true, moc:moc)
            podcast.isSubscribed = false
            
            CoreDataHelper.saveCoreData(moc, completionBlock: { completed in
                if alsoDelete {
                    PVDeleter.deletePodcast(podcast.objectID, completionBlock: {
                        completionBlock?()
                    })
                }
                else {
                    let episodesToRemove = podcast.episodes.allObjects as! [Episode]
                    // Delete each episode from the moc, cancel current downloadTask, and remove episode from the episodeDownloadArray
                    for episode in episodesToRemove {
                        let episodeToRemove = CoreDataHelper.fetchEntityWithID(episode.objectID, moc: moc) as! Episode
                        PVDeleter.deleteEpisode(episodeToRemove.objectID)
                    }
                    completionBlock?()
                }
            })
        }
    }
    
}
