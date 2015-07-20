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
    
    func checkIfNewEpisode() {
        println("has there been a new episode?")
        println("testing git commit tracking")
    }
    
//    func subscribeToPodcast(feedURLString: String) {
//        var feedURL = NSURL(string: feedURLString)
//        self.parser.parsePodcastFeed(feedURL!, willSave: true,
//            resolve: {
//                let predicate = NSPredicate(format: "feedURL == %@", feedURL!.absoluteString!)
//                let podcastSet = CoreDataHelper.fetchEntities("Podcast", managedObjectContext: self.moc, predicate: predicate) as! [Podcast]
//                
//                let podcast = podcastSet[0]
//                
//                let mostRecentEpisodePodcastPredicate = NSPredicate(format: "podcast == %@", podcast)
//                let mostRecentEpisodeSet = CoreDataHelper.fetchOnlyEntityWithMostRecentPubDate("Episode", managedObjectContext: self.moc, predicate: mostRecentEpisodePodcastPredicate)
//                
//                let mostRecentEpisode = mostRecentEpisodeSet[0] as! Episode
//                
//                self.downloader.startOrPauseDownloadingEpisode(mostRecentEpisode, tblViewController: nil, completion: nil)
//                
//                podcast.isSubscribed = true
//            },
//            reject: {
//                // do nothing
//            }
//        )
//    }
}
