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

    static func subscribeToPodcast(feedURLString: String) {
        dispatch_async(Constants.feedParsingQueue) { () -> Void in
            let feedParser = PVFeedParser(shouldGetMostRecent: false, shouldSubscribe: true)
            feedParser.parsePodcastFeed(feedURLString)
        }
    }
    
    static func unsubscribeFromPodcast(podcast:Podcast) {
        let alsoDelete = PVDeleter.checkIfPodcastShouldBeRemoved(podcast, isUnsubscribing: true)
        
        if alsoDelete {
            PVDeleter.deletePodcast(podcast)
        } else {
            dispatch_async(Constants.feedParsingQueue) { () -> Void in
                podcast.isSubscribed = false
                CoreDataHelper.sharedInstance.saveCoreData(nil)
            }
        }
    }
    
}
