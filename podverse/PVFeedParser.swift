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
        dispatch_async(Constants.reentrantAvoidanceQueue){
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
        
        downloadedEpisodes = Array(podcast.episodes.allObjects)
    }
    
    func feedParser(parser: FeedParser, didParseItem item: FeedItem) {
        //Do not parse episode if it does not contain feedEnclosures.
        if item.feedEnclosures.count <= 0 {
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
        
        newEpisode.taskIdentifier = nil
        
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
                CoreDataHelper.deleteItemFromCoreData(newEpisode,completionBlock: nil)
                break
            }
        }
        
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
                
                let mostRecentEpisodeArray = CoreDataHelper.fetchOnlyEntityWithMostRecentPubDate("Episode", managedObjectContext: Constants.moc, predicate: podcastPredicate)
                
                if mostRecentEpisodeArray.count > 0 {
                    if let latestEpisodeInRSSFeed = latestEpisodeInFeed {
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
        
        CoreDataHelper.saveCoreData(nil)
        
        delegate?.feedParsingComplete()
        print("feed parser has finished!")
    }
    
}
