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
    
    func didReturnPodcast(results: Podcast) {
        println("over here now!")
    }
    
    var parser = PVFeedParser()
    
    var downloader = PVDownloader()
    
    var moc: NSManagedObjectContext!
    
    var isNewEpisode: Bool = false
    
    func checkIfNewEpisode(feedURL: NSURL) {
        println("has there been a new episode?")
        self.parser.parsePodcastFeed(feedURL, returnPodcast: false, returnOnlyLatestEpisode: true,
            resolve: {
                
            },
            reject: {
                
            }
        )
    }
    
    func subscribeToPodcast(feedURLString: String) {
        if let context = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext {
            moc = context
        }
        
        var feedURL = NSURL(string: feedURLString)
        
        self.parser.parsePodcastFeed(feedURL!, returnPodcast: true, returnOnlyLatestEpisode: false,
            resolve: {
                
                let predicate = NSPredicate(format: "feedURL == %@", feedURL!.absoluteString!)
                let podcastSet = CoreDataHelper.fetchEntities("Podcast", managedObjectContext: self.moc, predicate: predicate) as! [Podcast]
                let podcast = podcastSet[0]
                    
                let mostRecentEpisodePodcastPredicate = NSPredicate(format: "podcast == %@", podcast)
                let mostRecentEpisodeSet = CoreDataHelper.fetchOnlyEntityWithMostRecentPubDate("Episode", managedObjectContext: self.moc, predicate: mostRecentEpisodePodcastPredicate)
                let mostRecentEpisode = mostRecentEpisodeSet[0] as! Episode
                
                self.downloader.startPauseOrResumeDownloadingEpisode(mostRecentEpisode, tblViewController: nil, completion: nil)
                
                podcast.isSubscribed = true
                println("is subscribed is true")
                
            },
            reject: {
                // do nothing
            }
        )
    }
}
