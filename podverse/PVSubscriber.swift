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
        let feedParser = PVFeedParser(onlyGetMostRecentEpisode: false, shouldSubscribe: true)
        feedParser.delegate = podcastTableDelegate
        feedParser.parsePodcastFeed(feedURLString)
    }
    
    static func unsubscribeFromPodcast(podcast:Podcast, moc:NSManagedObjectContext?) {
        let alsoDelete = PVDeleter.checkIfPodcastShouldBeRemoved(podcast, isUnsubscribing: true)
        podcast.isSubscribed = false

        if alsoDelete {
            PVDeleter.deletePodcast(podcast)
        } 

        CoreDataHelper.saveCoreData(moc, completionBlock:nil)
    }
    
}
