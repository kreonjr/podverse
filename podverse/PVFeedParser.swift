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
        
    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate?
    
    var moc: NSManagedObjectContext!
    
    var feedURL: NSURL!
    var podcast: Podcast!
    var episode: Episode!
    var mostRecentEpisodeInFeed: Episode!
    var mostRecentEpisodeSaved: Episode!
    
    var episodeArray: [Episode] = [Episode]()
    
    var returnPodcast: Bool!
    var returnOnlyLatestEpisode: Bool!
    var episodeAlreadySaved: Bool?
    
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
        
        // TODO: WTF? I don't really understand this part, but I found it in a tutorial
        // TODO: parsing needs to move off the main thread
        // TODO: Important: https://github.com/mwaterfall/MWFeedParser/issues/78
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
        
        // If podcast already exists in the database, do not insert new podcast, instead update existing podcast
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
            if let data = NSData(contentsOfURL: imgURL!) {
                self.podcast.image = data
            }
        }
        
        if let itunesImage = info.itunesImage {
            let itunesImgURL = NSURL(string: itunesImage)
            if let data = NSData(contentsOfURL: itunesImgURL!) {
                self.podcast.itunesImage = data
            }
        }
        
        let mostRecentEpisodeSavedPodcastPredicate = NSPredicate(format: "podcast == %@", podcast)
        let mostRecentEpisodeSavedSet = CoreDataHelper.fetchOnlyEntityWithMostRecentPubDate("Episode", managedObjectContext: self.moc, predicate: mostRecentEpisodeSavedPodcastPredicate)
        if mostRecentEpisodeSavedSet.count > 0 {
            self.mostRecentEpisodeSaved = mostRecentEpisodeSavedSet[0] as! Episode
        }

    }
        
    func feedParser(parser: MWFeedParser!, didParseFeedItem item: MWFeedItem!) {
        
        // If episode already exists in the database, do not insert new episode, instead update existing episode
        // TODO: Is there one field we can reliably check for matching episodes that will never error out?
        var predicate = NSPredicate()
        
        // TODO: There's got to be a more elegant way of checking if item.enclosures[0]["url"] exists...
        if item.enclosures != nil {
            if item.enclosures[0]["url"] != nil {
                predicate = NSPredicate(format: "mediaURL == %@", (item.enclosures[0]["url"] as? String)!)
            }
        }
        else if item.date != nil {
            predicate = NSPredicate(format: "pubDate == %@", (item.date))
        }
        
        let episodeSet = CoreDataHelper.fetchEntities("Episode", managedObjectContext: self.moc, predicate: predicate) as! [Episode]
        if episodeSet.count > 0 {
            episode = episodeSet[0]
            episodeAlreadySaved = true
        }
        else {
            episode = CoreDataHelper.insertManagedObject("Episode", managedObjectContext: self.moc) as! Episode
            episodeAlreadySaved = false
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
            let durationNSNumber = PVUtility.convertStringToNSNumber(duration)
            episode.duration = durationNSNumber
        }
        
        if let guid = item.guid { episode.guid = guid }
        
        episodeArray.append(episode)
        
        if episodeAlreadySaved == false {
            podcast.addEpisodeObject(episode)
        }
        
        if self.returnOnlyLatestEpisode == true {
            self.mostRecentEpisodeInFeed = episode
            parser.stopParsing()
        }
    
    }
        
    func feedParserDidFinish(parser: MWFeedParser!) {
        
        // Set the podcast.lastPubDate equal to the newest episode's pubDate
        podcast.lastPubDate = episodeArray[0].pubDate
        
        // If the parser is only returning the latest episode, then if the podcast's latest episode returned
        // is not the same as the latest episode saved locally, parse the entire feed again,
        // then download and save the latest episode
        if self.returnOnlyLatestEpisode == true {
            if self.mostRecentEpisodeInFeed != self.mostRecentEpisodeSaved {
                let feedURL = NSURL(string: podcast.feedURL)
                self.parsePodcastFeed(feedURL!, returnPodcast: true, returnOnlyLatestEpisode: false,
                    resolve: {
                        PVDownloader.sharedInstance.startPauseOrResumeDownloadingEpisode(self.mostRecentEpisodeInFeed, completion: nil)
                    },
                    reject: {
                        
                    }
                )
                
            } else {
                println("no newer episode available, don't download")
            }
        }
        
        // Save the parsed podcast and episode information
        moc.save(nil)
        
        println("feed parser has finished!")
        
    }
    
}
