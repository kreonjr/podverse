//
//  PVFeedParser.swift
//  podverse
//
//  Created by Mitchell Downey on 6/4/15.
//  Copyright (c) 2015 Mitchell Downey. All rights reserved.
//

import UIKit
import CoreData

@objc protocol PVFeedParserDelegate {
   func feedParsingComplete(feedURL:String?)
   optional func feedParsingStarted()
   optional func feedParserChannelParsed()
}

class PVFeedParser: NSObject, FeedParserDelegate {
    var feedURL: String!
    var currentPodcast: Podcast? = nil
    
    var onlyGetMostRecent: Bool
    var shouldSubscribeToPodcast: Bool
    var shouldFollowPodcast: Bool
    var shouldDownloadMostRecentEpisode = false
    var shouldParseChannel = false
    var latestEpisodePubDate:NSDate?
    var delegate:PVFeedParserDelegate?
    let moc = CoreDataHelper.sharedInstance.backgroundContext
    let parsingPodcasts = ParsingPodcastsList.shared
    
    init(onlyGetMostRecentEpisode:Bool, shouldSubscribe:Bool, shouldFollow:Bool, shouldParseChannelOnly:Bool) {
        onlyGetMostRecent = onlyGetMostRecentEpisode
        shouldFollowPodcast = shouldFollow
        shouldSubscribeToPodcast = shouldSubscribe
        shouldParseChannel = shouldParseChannelOnly
    }
    
    func parsePodcastFeed(feedURLString: String) {
        if shouldParseChannel {
            dispatch_async(Constants.channelInfoFeedParsingQueue) {
                self.feedURL = feedURLString
                let feedParser = CustomFeedParser(feedURL: feedURLString)
                feedParser.delegate = self
                // This apparently does nothing. The 3rd party FeedParser automatically sets the parsingType to .Full...
                feedParser.parsingType = .ChannelOnly
                feedParser.parse()
                print("feedParser did start")
            }
        } else {
            dispatch_async(Constants.feedParsingQueue) {
                self.feedURL = feedURLString
                let feedParser = CustomFeedParser(feedURL: feedURLString)
                feedParser.delegate = self
                feedParser.parsingType = .Full
                feedParser.parse()
                print("feedParser did start")
                dispatch_async(dispatch_get_main_queue()) { () -> Void in
                    self.delegate?.feedParsingStarted?()
                }
            }
        }
    }
    
    func feedParser(parser: FeedParser, didParseChannel channel: FeedChannel) {
        let podcast:Podcast!

        if let feedURLString = channel.channelURL {
            let predicate = NSPredicate(format: "feedURL == %@", feedURLString)
            let podcastSet = CoreDataHelper.fetchEntities("Podcast", predicate: predicate, moc:moc) as! [Podcast]
            
            if podcastSet.count > 0 {
                podcast = podcastSet.first
            }
            else {
                podcast = CoreDataHelper.insertManagedObject("Podcast", moc:moc) as! Podcast
            }
        }
        else {
            return
        }
        
        if let title = channel.channelTitle {
            podcast.title = title
        }
        
        if let summary = channel.channelDescription {
            podcast.summary = summary
        }
        
        if let iTunesAuthor = channel.channeliTunesAuthor {
            podcast.author = iTunesAuthor
        }
        
        if let podcastLink = channel.channelLink {
            podcast.link = podcastLink
        }
        
        podcast.feedURL = feedURL
        
        //Look into maybe adding it in the library manually

        if let imageUrlString = channel.channelLogoURL, let imageUrl = NSURL(string:imageUrlString) {
            podcast.imageURL = imageUrl.absoluteString
            podcast.imageData = NSData(contentsOfURL: imageUrl)
        }
        
        if let iTunesImageUrlString = channel.channeliTunesLogoURL, let itunesImageUrl = NSURL(string:iTunesImageUrlString) {
            podcast.itunesImageURL = itunesImageUrl.absoluteString
            podcast.itunesImage = NSData(contentsOfURL: itunesImageUrl)
        }
        
        if let downloadedImageData = podcast.imageData {
            podcast.imageThumbData = PVImageManipulator.resizeImageData(downloadedImageData)
        } else if let downloadedImageData = podcast.itunesImage {
            podcast.imageThumbData = PVImageManipulator.resizeImageData(downloadedImageData)
        }
        
        if let lastBuildDate = channel.channelLastBuildDate {
            podcast.lastBuildDate = lastBuildDate
        }
        
        if let lastPubDate = channel.channelLastPubDate {
            podcast.lastPubDate = lastPubDate
        }
        
        if let categories = channel.channelCategory {
            podcast.categories = categories
        }
        
        if self.shouldSubscribeToPodcast {
            podcast.isSubscribed = true
            podcast.isFollowed = true
        }
        
        if self.shouldFollowPodcast {
            podcast.isSubscribed = false
            podcast.isFollowed = true
        }
        
        currentPodcast = podcast
        
        CoreDataHelper.saveCoreData(moc, completionBlock: { completed in
            dispatch_async(dispatch_get_main_queue()) { () -> Void in
                // If only parsing for the latest episode, do not reload the PodcastTableVC after the channel is parsed. This will prevent PodcastTableVC UI from reloading and sticking unnecessarily.
                if self.onlyGetMostRecent != true {
                    self.delegate?.feedParserChannelParsed?()
                }
            }
        })
    }
    
    func feedParser(parser: FeedParser, didParseItem item: FeedItem) {
        // This hack is put in to prevent parsing items unnecessarily. Ideally this would be handled by setting feedParser.parsingType to .ChannelOnly, but the 3rd party FeedParser does not let us override the .parsingType I think...
        if self.shouldParseChannel {
            return
        }
        
        guard let podcast = currentPodcast else {
            // If podcast is nil, then the RSS feed was invalid for the parser, and we should return out of successfullyParsedURL
            return
        }
        
        //Do not parse episode if it does not contain feedEnclosures.
        if item.feedEnclosures.count <= 0 {
            return
        }
        
        let newEpisode = CoreDataHelper.insertManagedObject("Episode", moc:moc) as! Episode
        
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
        if onlyGetMostRecent == true {
            latestEpisodePubDate = newEpisode.pubDate
            CoreDataHelper.deleteItemFromCoreData(newEpisode, moc: moc)
            parser.abortParsing()
            return
        }
        
        // If episode already exists in the database, do not insert new episode
        if podcast.episodes.allObjects.contains({ $0.mediaURL == newEpisode.mediaURL }) {
            CoreDataHelper.deleteItemFromCoreData(newEpisode, moc: moc)
        }
        else {
            podcast.addEpisodeObject(newEpisode)
            CoreDataHelper.saveCoreData(moc) {[weak self] (saved) -> Void in
                guard let strongSelf = self else {
                    return
                }
                
                if strongSelf.shouldDownloadMostRecentEpisode == true {
                    PVDownloader.sharedInstance.startDownloadingEpisode(newEpisode)
                    strongSelf.shouldDownloadMostRecentEpisode = false
                }
            }
        }
    }
    
    func feedParserParsingAborted(parser: FeedParser) {
        parsingPodcasts.itemsParsing += 1
        parsingPodcasts.clearParsingPodcastsIfFinished()
        
        guard let podcast = currentPodcast else {
            // If podcast is nil, then the RSS feed was invalid for the parser, and we should return out of successfullyParsedURL

            dispatch_async(dispatch_get_main_queue()) { () -> Void in
                self.delegate?.feedParsingComplete(nil)
            }
            
            return
        }
        
        // If the parser is only returning the latest episode, then if the podcast's latest episode returned is not the same as the latest episode saved locally, parse the entire feed again, then download and save the latest episode
        if let latestEpisodePubDateInRSSFeed = latestEpisodePubDate where self.onlyGetMostRecent == true {
            let podcastPredicate = NSPredicate(format: "podcast == %@", podcast)
            let mostRecentEpisodeArray = CoreDataHelper.fetchOnlyEntityWithMostRecentPubDate("Episode", predicate: podcastPredicate, moc:moc) as! [Episode]
            
            if let mostRecentPubDate = mostRecentEpisodeArray.first?.pubDate where latestEpisodePubDateInRSSFeed.compare(mostRecentPubDate) != .OrderedSame {
                self.onlyGetMostRecent = false
                self.shouldDownloadMostRecentEpisode = true
                self.parsePodcastFeed(podcast.feedURL)
            }
            else {
                dispatch_async(dispatch_get_main_queue()) { () -> Void in
                    self.delegate?.feedParsingComplete(podcast.feedURL)
                }
            }
        } else {
            print("no newer episode available, don't download")
        }
    }
    
    func feedParser(parser: FeedParser, successfullyParsedURL url: String) {
        parsingPodcasts.itemsParsing += 1
        parsingPodcasts.clearParsingPodcastsIfFinished()
        
        guard let podcast = currentPodcast else {
            return
        }
        
        // If subscribing to a podcast, then get the latest episode and begin downloading
        if shouldSubscribeToPodcast == true {
            let podcastPredicate = NSPredicate(format: "podcast == %@", podcast)
            let latestEpisodeArray = CoreDataHelper.fetchOnlyEntityWithMostRecentPubDate("Episode", predicate: podcastPredicate, moc:self.moc)
            
            if latestEpisodeArray.count > 0 {
                if let latestEpisode = latestEpisodeArray[0] as? Episode {
                    if latestEpisode.downloadComplete != true {
                        PVDownloader.sharedInstance.startDownloadingEpisode(latestEpisode)
                    }
                }
            }
        }

        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            self.delegate?.feedParsingComplete(podcast.feedURL)
        }
        print("feed parser has finished!")
    }
    
}
