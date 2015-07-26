//
//  PVFeedParser.swift
//  podverse
//
//  Created by Mitchell Downey on 6/4/15.
//  Copyright (c) 2015 Mitchell Downey. All rights reserved.
//

import UIKit
import CoreData

class PVFeedParser: NSObject, MWFeedParserDelegate {
    
    var utility = PVUtility()
    
    var downloader = PVDownloader()
    
    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate?
    
    var moc: NSManagedObjectContext!
    
    var feedURL: NSURL!
    var podcast: Podcast!
    var episode: Episode!
    var onlyMostRecentEpisode: Episode!
    
    var episodeArray: [Episode] = [Episode]()
    
    var returnPodcast: Bool = false
    var returnOnlyLatestEpisode: Bool = false
    
    func parsePodcastFeed(feedURL: NSURL, returnPodcast: Bool, returnOnlyLatestEpisode: Bool, resolve: () -> (), reject: () -> ()) {
        
        // Pass the parser task booleans to the global scope
        self.returnPodcast = returnPodcast
        self.returnOnlyLatestEpisode = returnOnlyLatestEpisode
        
        moc = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext
        
        // Create, configure, and start the feedParser
        var feedParser = MWFeedParser(feedURL: feedURL)
        feedParser.delegate = self
        feedParser.feedParseType = ParseTypeFull
        // TODO: Why asynchronously? Why not synchronously?
        feedParser.connectionType = ConnectionTypeAsynchronously
        feedParser.parse()
        
        // TODO: I don't really understand this part
        var delta: Int64 = 1 * Int64(NSEC_PER_SEC)
        var time = dispatch_time(DISPATCH_TIME_NOW, delta)
        dispatch_after(time, dispatch_get_main_queue(), {
            resolve()
        })
    }
    
    func feedParserDidStart(parser: MWFeedParser!) {
        println("feedParser did start")
    }
    
    func feedParser(parser: MWFeedParser!, didParseFeedInfo info: MWFeedInfo!) {
        
        // If podcast already exists in the database, do not insert new managed object
        let feedURLString = info.url.absoluteString
        let predicate = NSPredicate(format: "feedURL == %@", feedURLString!)
        let podcastSet = CoreDataHelper.fetchEntities("Podcast", managedObjectContext: self.moc, predicate: predicate) as! [Podcast]
        if podcastSet.count > 0 {
            podcast = podcastSet[0]
        }
        else {
            podcast = CoreDataHelper.insertManagedObject("Podcast", managedObjectContext: self.moc) as! Podcast
        }
        
        if let title = info.title { podcast.title = title }

        if let summary = info.summary { podcast.summary = summary }
        
        if let feedURL = info.url { podcast.feedURL = feedURL.absoluteString! }
        
        if let itunesAuthor = info.itunesAuthor { podcast.itunesAuthor = itunesAuthor }
        
        if let image = info.image {
            let imgURL = NSURL(string: image)
            let data = NSData(contentsOfURL: imgURL!)
            self.podcast.image = data
        }
        
        if let itunesImage = info.itunesImage {
            let itunesImgURL = NSURL(string: itunesImage)
            let data = NSData(contentsOfURL: itunesImgURL!)
            self.podcast.itunesImage = data
        }
    
    }
        
    func feedParser(parser: MWFeedParser!, didParseFeedItem item: MWFeedItem!) {
        
        // If episode already exists in the database, do not insert new managed object
        let predicate = NSPredicate(format: "mediaURL == %@", (item.enclosures[0]["url"] as? String)!)
        let episodeSet = CoreDataHelper.fetchEntities("Episode", managedObjectContext: self.moc, predicate: predicate) as! [Episode]
        if episodeSet.count > 0 {
            episode = episodeSet[0]
        }
        else {
            episode = CoreDataHelper.insertManagedObject("Episode", managedObjectContext: self.moc) as! Episode
        }
        
        if let title = item.title { episode.title = title }
        
        if let summary = item.summary { episode.summary = summary }
        
        if let date = item.date { episode.pubDate = date }
        
        if let link = item.link { episode.link = link }
        
        if let enclosures = item.enclosures {
            episode.mediaURL = enclosures[0]["url"] as? String
            episode.mediaType = enclosures[0]["type"] as? String
            episode.mediaBytes = enclosures[0]["length"] as? Int
        }
        
        if let duration = item.duration {
            let durationNSNumber = utility.convertStringToNSNumber(duration)
            episode.duration = durationNSNumber
        }
        
        if let guid = item.guid { episode.guid = guid }
        
        podcast.addEpisodeObject(episode)
        
        episodeArray.append(episode)
        
        if self.returnOnlyLatestEpisode == true {
            parser.stopParsing()
            self.onlyMostRecentEpisode = episode
        }
    
    }
        
    func feedParserDidFinish(parser: MWFeedParser!) {
        println("feed parser has finished!")
        podcast.lastPubDate = episodeArray[0].pubDate
//        didReturnPodcast(podcast)
        moc.save(nil)
        
        if self.returnOnlyLatestEpisode == true {
            let mostRecentEpisodePodcastPredicate = NSPredicate(format: "podcast == %@", podcast)
            let mostRecentSavedEpisodeSet = CoreDataHelper.fetchOnlyEntityWithMostRecentPubDate("Episode", managedObjectContext: self.moc, predicate: mostRecentEpisodePodcastPredicate)
            let mostRecentSavedEpisode = mostRecentSavedEpisodeSet[0] as! Episode
            if self.onlyMostRecentEpisode != mostRecentSavedEpisode {
                self.downloader.startPauseOrResumeDownloadingEpisode(self.onlyMostRecentEpisode, completion: nil)
            }
        }
        
        
    }
    
}
