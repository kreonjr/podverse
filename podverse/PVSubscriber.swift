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
    
    var appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate

    var moc: NSManagedObjectContext! {
        get {
            return appDelegate.managedObjectContext
        }
    }
    
    func subscribeToPodcast(feedURLString: String) {
        
        let feedURL = NSURL(string: feedURLString)
        
        PVFeedParser.sharedInstance.parsePodcastFeed(feedURL!, returnPodcast: true, returnOnlyLatestEpisode: false,
            resolve: {
                // After parsePodcastFeed has resolved, then retrieve the newly created podcast object by matching feedURL stored in CoreData, then get the most recent episode for that podcast, and start downloading that episode.
                let predicate = NSPredicate(format: "feedURL == %@", feedURL!.absoluteString)
                let podcastSet = CoreDataHelper.fetchEntities("Podcast", managedObjectContext: self.moc, predicate: predicate) as! [Podcast]
                if podcastSet.count > 0 {
                    let podcast = podcastSet[0]
                    let mostRecentEpisodePodcastPredicate = NSPredicate(format: "podcast == %@", podcast)
                    let mostRecentEpisodeSet = CoreDataHelper.fetchOnlyEntityWithMostRecentPubDate("Episode", managedObjectContext: self.moc, predicate: mostRecentEpisodePodcastPredicate)
                    let mostRecentEpisode = mostRecentEpisodeSet[0] as! Episode
                    PVDownloader.sharedInstance.startDownloadingEpisode(mostRecentEpisode)
                    podcast.isSubscribed = true
                }
        
            },
            reject: {
            }
        )
    }
}
