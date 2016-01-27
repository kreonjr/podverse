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
        dispatch_async(Constants.feedParsingQueue) { () -> Void in
            let feedParser = PVFeedParser(shouldGetMostRecent: false, shouldSubscribe: true)
            feedParser.parsePodcastFeed(feedURLString)
        }
    }
    
    func unsubscribeFromPodcast(podcast:Podcast) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) { () -> Void in
            
        }
    }
}
