//
//  PVFeedParser.swift
//  podverse
//
//  Created by Mitchell Downey on 6/4/15.
//  Copyright (c) 2015 Mitchell Downey. All rights reserved.
//

import UIKit
import CoreData

class PVFeedParser: NSObject, FeedParserDelegate {
    var appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    
    var moc: NSManagedObjectContext! {
        get {
            return appDelegate.managedObjectContext
        }
    }
    
    var feedURL: NSURL!
    var podcast: Podcast!
    var episode: Episode!
    
    var shouldGetMostRecentEpisode: Bool
    var shouldSubscribeToPodcast: Bool
    var episodeAlreadySaved: Bool?
    var latestEpisodeInFeed: Episode?
    
    init(shouldGetMostRecent:Bool, shouldSubscribe:Bool) {
        shouldGetMostRecentEpisode = shouldGetMostRecent
        shouldSubscribeToPodcast = shouldSubscribe
    }
    
    func parsePodcastFeed(feedURLString: String) {
        // Create, configure, and start the feedParser
        let feedParser = CustomFeedParser(feedURL: feedURLString)
        feedParser.delegate = self
        feedParser.parsingType = .Full

        feedParser.parse()
        
        print("feedParser did start")
    }
    
    func feedParser(parser: FeedParser, didParseChannel channel: FeedChannel) {
        if let feedURLString = channel.channelURL {
            let predicate = NSPredicate(format: "feedURL == %@", feedURLString)
            let podcastSet = CoreDataHelper.fetchEntities("Podcast", managedObjectContext: self.moc, predicate: predicate) as! [Podcast]
            if podcastSet.count > 0 {
                podcast = podcastSet[0]
            }
            else {
                podcast = CoreDataHelper.insertManagedObject("Podcast", managedObjectContext: self.moc) as! Podcast
            }
        }
        
        if let title = channel.channelTitle {
            podcast.title = title
        }
        
        if let summary = channel.channelDescription {
            podcast.summary = summary
        }
        
        if let feedURL = channel.channelLink {
            podcast.feedURL = feedURL
        }
        
        //Look into maybe adding it in the library manually
        //if let itunesAuthor = channel.itunesAuthor { podcast.itunesAuthor = itunesAuthor }
        if let imageUrlString = channel.channelLogoURL, let imageUrl = NSURL(string:imageUrlString) {
            self.podcast.imageData = NSData(contentsOfURL: imageUrl)
        }
        
        if let lastModifiedDate = channel.channelDateOfLastChange {
            self.podcast.lastPubDate = lastModifiedDate
        }
        
        podcast.isSubscribed = self.shouldSubscribeToPodcast
    }
    
    func feedParser(parser: FeedParser, didParseItem item: FeedItem) {
    
        // If episode already exists in the database, do not insert new episode, instead update existing episode
        var predicate = NSPredicate()
        if item.feedEnclosures.count > 0 {
            if item.feedEnclosures[0].url.characters.count > 0 {
                predicate = NSPredicate(format: "mediaURL == %@", item.feedEnclosures[0].url)
            }
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
        
        // Retrieve parsed values from item and add values to their respective episode properties
        if let title = item.feedTitle { episode.title = title }
        if let summary = item.feedContent { episode.summary = summary }
        if let date = item.feedPubDate { episode.pubDate = date }
        if let link = item.feedLink { episode.link = link }
        
        //TODO: Add duration to feedItem
        //episode.duration = item
        episode.mediaURL = item.feedEnclosures[0].url
        episode.mediaType = item.feedEnclosures[0].type
        episode.mediaBytes = NSNumber(integer: item.feedEnclosures[0].length)
        if let guid = item.feedIdentifier { episode.guid = guid }
        
        // If episode is not already saved, then add episode to the podcast object
        if episodeAlreadySaved == false {
            podcast.addEpisodeObject(episode)
        }
        
        // If only parsing for the latest episode, stop parsing after parsing the first episode.
        if shouldGetMostRecentEpisode == true {
            latestEpisodeInFeed = episode
            parser.abortParsing()
        }
        
    }
    
    func feedParserParsingAborted(parser: FeedParser) {
        // If the parser is only returning the latest episode, then if the podcast's latest episode returned is not the same as the latest episode saved locally, parse the entire feed again, then download and save the latest episode
        

        if self.shouldGetMostRecentEpisode == true {
            if let newestFeedEpisode = latestEpisodeInFeed {
                let podcastPredicate = NSPredicate(format: "podcast == %@", podcast)
                let mostRecentEpisode = CoreDataHelper.fetchOnlyEntityWithMostRecentPubDate("Episode", managedObjectContext: self.moc, predicate: podcastPredicate)[0] as! Episode
                
                    if latestEpisodeInFeed != mostRecentEpisode {
                        shouldGetMostRecentEpisode = false
                        PVDownloader.sharedInstance.startDownloadingEpisode(newestFeedEpisode)
                        parsePodcastFeed(podcast.feedURL)
                    }
            }
        } else {
            print("no newer episode available, don't download")
        }
        
        // Save the parsed podcast and episode information
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            do {
                try self.moc.save()
            } catch {
                print(error)
            }
        }
        
    }
    
    func feedParser(parser: FeedParser, successfullyParsedURL url: String) {
        
        // If subscribing to a podcast, then get the latest episode and begin downloading
        if shouldSubscribeToPodcast == true {
            let podcastPredicate = NSPredicate(format: "podcast == %@", podcast)
            let mostRecentEpisode = CoreDataHelper.fetchOnlyEntityWithMostRecentPubDate("Episode", managedObjectContext: self.moc, predicate: podcastPredicate)[0] as! Episode
            PVDownloader.sharedInstance.startDownloadingEpisode(mostRecentEpisode)
        }
        
        // Save the parsed podcast and episode information
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            do {
                try self.moc.save()
            } catch {
                print(error)
            }
        }
        
        print("feed parser has finished!")
    }
    
}
