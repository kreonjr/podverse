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
    
    var parser = PVFeedParser()
    
    var downloader = PVDownloader()
    
    var moc: NSManagedObjectContext!
    
    var isNewEpisode: Bool = false
    
    func subscribeToPodcast(feedURLString: String) {
        if let context = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext {
            moc = context
        }
        
        var feedURL = NSURL(string: feedURLString)
        
        self.parser.parsePodcastFeed(feedURL!, returnPodcast: true, returnOnlyLatestEpisode: false,
            resolve: {
                
                let predicate = NSPredicate(format: "feedURL == %@", feedURL!.absoluteString!)
                let podcastSet = CoreDataHelper.fetchEntities("Podcast", managedObjectContext: self.moc, predicate: predicate) as! [Podcast]

                if podcastSet.count > 0 {
                    let podcast = podcastSet[0]
                    let mostRecentEpisodePodcastPredicate = NSPredicate(format: "podcast == %@", podcast)
                    let mostRecentEpisodeSet = CoreDataHelper.fetchOnlyEntityWithMostRecentPubDate("Episode", managedObjectContext: self.moc, predicate: mostRecentEpisodePodcastPredicate)
                    let mostRecentEpisode = mostRecentEpisodeSet[0] as! Episode
                    
                    self.downloader.startPauseOrResumeDownloadingEpisode(mostRecentEpisode, completion: nil)
                    
                    podcast.isSubscribed = true
                }
        
            },
            reject: {
                // do nothing
            }
        )
    }
}
