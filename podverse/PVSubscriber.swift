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
        if let playlists = CoreDataHelper.sharedInstance.fetchEntities("Playlist", predicate: nil) as? [Playlist] {
            podcast.isSubscribed = false
            
            var alsoDelete = true
            
   outerLoop: for playlist in playlists {
                for item in playlist.allItems {
                    if let episode = item as? Episode {
                        for podcastEpisode in podcast.episodes {
                            if (podcastEpisode as! Episode) == episode {
                                alsoDelete = false
                                break outerLoop
                            }
                        }
                    }
                    else if let clip = item as? Clip {
                        for podcastEpisode in podcast.episodes.allObjects {
                            for podcastClip in (podcastEpisode as! Episode).clips {
                                if clip == (podcastClip as! Clip) {
                                    alsoDelete = false
                                    break outerLoop
                                }
                            }
                        }
                    }
                }
            }
            
            if alsoDelete {
                PVDeleter.deletePodcast(podcast)
            }
        }
    }
    
}
