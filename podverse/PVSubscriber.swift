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
        dispatch_async(Constants.feedParsingQueue) {
            let feedParser = PVFeedParser(onlyGetMostRecentEpisode: false, shouldSubscribe: true)
            feedParser.delegate = podcastTableDelegate
            feedParser.parsePodcastFeed(feedURLString)
        }
    }
    
    static func unsubscribeFromPodcast(podcast:Podcast) {
        let alsoDelete = PVDeleter.checkIfPodcastShouldBeRemoved(podcast.objectID, isUnsubscribing: true)
        podcast.isSubscribed = false
        
        CoreDataHelper.saveCoreData(podcast.managedObjectContext, completionBlock: { completed in
            if alsoDelete {
                PVDeleter.deletePodcast(podcast.objectID)
            }
        })
    }
    
}
