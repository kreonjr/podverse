//
//  PVFeedParser.swift
//  podverse
//
//  Created by Mitchell Downey on 6/4/15.
//  Copyright (c) 2015 Mitchell Downey. All rights reserved.
//

import UIKit
import CoreData

protocol PVFeedParserDelegate {
   func feedParsingComplete()
}

class PVFeedParser: NSObject, FeedParserDelegate {
    var appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    
    var feedURL: String!
    var podcast: Podcast!
    
    var shouldGetMostRecentEpisode: Bool
    var shouldSubscribeToPodcast: Bool
    var latestEpisodeInFeed: Episode?
    var downloadedEpisodes = []
    var delegate:PVFeedParserDelegate?
    
    init(shouldGetMostRecent:Bool, shouldSubscribe:Bool) {
        shouldGetMostRecentEpisode = shouldGetMostRecent
        shouldSubscribeToPodcast = shouldSubscribe
    }
    
    func parsePodcastFeed(feedURLString: String) {
        // Parse podcast feeds on the reentrantAvoidanceQueue in order to prevent the "NSXMLParser does not support reentrant parsing" issue.
        let reentrantAvoidanceQueue = dispatch_queue_create("reentrantAvoidanceQueue", DISPATCH_QUEUE_SERIAL);
        dispatch_async(reentrantAvoidanceQueue){
            self.feedURL = feedURLString
            let feedParser = CustomFeedParser(feedURL: feedURLString)
            feedParser.delegate = self
            feedParser.parsingType = .Full
            feedParser.parse()
            print("feedParser did start")
        }
    }
    
    func feedParser(parser: FeedParser, didParseChannel channel: FeedChannel) {
        if let feedURLString = channel.channelURL {
            let predicate = NSPredicate(format: "feedURL == %@", feedURLString)
            let podcastSet = CoreDataHelper.fetchEntities("Podcast", managedObjectContext: Constants.moc, predicate: predicate) as! [Podcast]
            if podcastSet.count > 0 {
                podcast = podcastSet[0]
            }
            else {
                podcast = CoreDataHelper.insertManagedObject("Podcast", managedObjectContext: Constants.moc) as! Podcast
            }
        }
        
        if let title = channel.channelTitle {
            podcast.title = title
        }
        
        if let summary = channel.channelDescription {
            podcast.summary = summary
        }
        
        podcast.feedURL = feedURL
        
        //Look into maybe adding it in the library manually

        if let imageUrlString = channel.channelLogoURL, let imageUrl = NSURL(string:imageUrlString) {
            self.podcast.imageURL = imageUrl.absoluteString
            self.podcast.imageData = NSData(contentsOfURL: imageUrl)
        }
        
        if let iTunesImageUrlString = channel.channeliTunesLogoURL, let itunesImageUrl = NSURL(string:iTunesImageUrlString) {
            self.podcast.itunesImageURL = itunesImageUrl.absoluteString
            self.podcast.itunesImage = NSData(contentsOfURL: itunesImageUrl)
        }
        
        if let lastBuildDate = channel.channelLastBuildDate {
            self.podcast.lastBuildDate = lastBuildDate
        }
        
        if let lastPubDate = channel.channelLastPubDate {
            self.podcast.lastPubDate = lastPubDate
        }
        
        podcast.isSubscribed = self.shouldSubscribeToPodcast
        
        downloadedEpisodes = Array(podcast.episodes)
    }
    
    func feedParser(parser: FeedParser, didParseItem item: FeedItem) {
        if item.feedEnclosures.count <= 0 {
            //Do not parse episode if it does not contain feedEnclosures.
            return
        }
        var episodeAlreadySaved = false
        let newEpisode = CoreDataHelper.insertManagedObject("Episode", managedObjectContext: Constants.moc) as! Episode
        
        // Retrieve parsed values from item and add values to their respective episode properties
        if let title = item.feedTitle { newEpisode.title = title }
        if let summary = item.feedContent { newEpisode.summary = summary }
        if let date = item.feedPubDate { newEpisode.pubDate = date }
        if let link = item.feedLink { newEpisode.link = link }
        if let duration = item.duration { newEpisode.duration = duration }
        
        newEpisode.mediaURL = item.feedEnclosures[0].url
        newEpisode.mediaType = item.feedEnclosures[0].type
        newEpisode.mediaBytes = NSNumber(integer: item.feedEnclosures[0].length)
        if let guid = item.feedIdentifier { newEpisode.guid = guid }
        
        // If only parsing for the latest episode, stop parsing after parsing the first episode.
        if shouldGetMostRecentEpisode == true {
            latestEpisodeInFeed = newEpisode
            parser.abortParsing()
        }
        
        // If episode already exists in the database, do not insert new episode, instead update existing episode
        for var existingEpisode in downloadedEpisodes {
            if newEpisode.mediaURL == existingEpisode.mediaURL {
                existingEpisode = newEpisode
                episodeAlreadySaved = true
                //Remove the created entity from core data if it already exists
                CoreDataHelper.removeManagedObjectFromClass("Episode", managedObjectContext: Constants.moc, object: newEpisode)
                break
            }
        }
        
        // TODO: I'm not sure why I need to do this to get the rest of the app to work. By setting the taskIdentifier = nil it allows for checking whether the taskIdentifier is nil or not in other places in the app.
        newEpisode.taskIdentifier = nil
        
        // If episode is not already saved, then add episode to the podcast object
        if !episodeAlreadySaved {
            podcast.addEpisodeObject(newEpisode)
        }
    }
    
    func feedParserParsingAborted(parser: FeedParser) {
        
        // If podcast is nil, then the RSS feed was invalid for the parser, and we should return out of successfullyParsedURL
        if podcast == nil {
            delegate?.feedParsingComplete()
            return
        }
        
        // If the parser is only returning the latest episode, then if the podcast's latest episode returned is not the same as the latest episode saved locally, parse the entire feed again, then download and save the latest episode
        if self.shouldGetMostRecentEpisode == true {
            if let newestFeedEpisode = latestEpisodeInFeed {
                let podcastPredicate = NSPredicate(format: "podcast == %@", podcast)
                // TODO: BUGGY - the most recent pub date is not a reliable way to check if the 1st episode in the current feed is newer than the 1st episode in the feed stored in CoreData. One way to fix this would be to fix the FeedParser issues that are preventing some podcast and episode date/time information from being grabbed successfully.
                
                let mostRecentEpisodeArray = CoreDataHelper.fetchOnlyEntityWithMostRecentPubDate("Episode", managedObjectContext: Constants.moc, predicate: podcastPredicate)
                
                if mostRecentEpisodeArray.count > 0 {
                    if let latestEpisodeInRSSFeed = latestEpisodeInFeed {
                        // TODO: BUGGY - this conditional will always be TRUE in the case of Dan Carlin's podcasts. Our parser is not correctly grabbing the pubDate of the episodes, and the default behavior of the FeedParser is to return the current date/time is a valid pubDate format is not found.
                        if latestEpisodeInRSSFeed.pubDate != mostRecentEpisodeArray[0].pubDate {
                            shouldGetMostRecentEpisode = false
                            PVDownloader.sharedInstance.startDownloadingEpisode(newestFeedEpisode)
                            parsePodcastFeed(podcast.feedURL)
                        }
                    }
                }
                
            }
        } else {
            print("no newer episode available, don't download")
        }
        
        // Save the parsed podcast and episode information
        // TODO: Do we actually want this save to happen when the podcast feed parser is aborted? I think
//        dispatch_async(dispatch_get_main_queue()) { () -> Void in
//            do {
//                try Constants.moc.save()
//            } catch {
//                print(error)
//            }
//        }
        
    }
    
    func feedParser(parser: FeedParser, successfullyParsedURL url: String) {
        
        // If podcast is nil, then the RSS feed was invalid for the parser, and we should return out of successfullyParsedURL
        if podcast == nil {
           delegate?.feedParsingComplete()
            return
        }
        
        // If subscribing to a podcast, then get the latest episode and begin downloading
        if shouldSubscribeToPodcast == true {
            let podcastPredicate = NSPredicate(format: "podcast == %@", podcast)
            let latestEpisodeArray = CoreDataHelper.fetchOnlyEntityWithMostRecentPubDate("Episode", managedObjectContext: Constants.moc, predicate: podcastPredicate)
            
            // If there is an episode in the array, then download the episode
            if latestEpisodeArray.count > 0 {
                PVDownloader.sharedInstance.startDownloadingEpisode(latestEpisodeArray[0] as! Episode)
            }
        }
        
        // Save the parsed podcast and episode information
        do {
            try Constants.moc.save()
        } catch {
            print(error)
        }
        
        delegate?.feedParsingComplete()
        print("feed parser has finished!")
    }
    
}
