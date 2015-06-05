//
//  PVFeedParser.swift
//  podverse
//
//  Created by Mitchell Downey on 6/4/15.
//  Copyright (c) 2015 Mitchell Downey. All rights reserved.
//

import UIKit

protocol PVFeedParserProtocol {
    func didReceiveFeedResults(results: Podcast)
}

class PVFeedParser: NSObject, MWFeedParserDelegate {
    var delegate: PVFeedParserProtocol?
    
    var utility = PVUtility()
    
    var moc: NSManagedObjectContext!
    
    var podcast: Podcast!
    var episode: Episode!
    
    var episodeArray: [Episode] = [Episode]()
    
    func parsePodcastFeed(feedURL: NSURL) {
        var feedParser = MWFeedParser(feedURL: feedURL)
        feedParser.delegate = self
        feedParser.feedParseType = ParseTypeFull
        feedParser.connectionType = ConnectionTypeAsynchronously
        feedParser.parse()
    }
    
    func feedParserDidStart(parser: MWFeedParser!) {
        moc = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext
    }
    
    func feedParser(parser: MWFeedParser!, didParseFeedInfo info: MWFeedInfo!) {
        
        podcast = CoreDataHelper.insertManagedObject(NSStringFromClass(Podcast), managedObjectContext: moc) as! Podcast
        
        if info.title != nil {
            podcast.title = info.title
        }
        
        if info.summary != nil {
            podcast.summary = info.summary
        }
        
        if info.url != nil {
            podcast.feedURL = info.url.absoluteString
        }
        
        if info.itunesAuthor != nil {
            podcast.itunesAuthor = info.itunesAuthor
        }
        
        if info.image != nil {
            podcast.imageURL = info.image
            let url = NSURL(string: info.image)
            if let imgData = NSData(contentsOfURL: url!) {
                podcast.image = imgData
            }
        }
        
        if info.itunesImage != nil {
            podcast.itunesImageURL = info.itunesImage
            let url = NSURL(string: info.itunesImage)
            if let imgData = NSData(contentsOfURL: url!) {
                podcast.itunesImage = imgData
            }
        }
        
    }
    
    func feedParser(parser: MWFeedParser!, didParseFeedItem item: MWFeedItem!) {
        
        let episode = CoreDataHelper.insertManagedObject(NSStringFromClass(Episode), managedObjectContext: self.moc) as! Episode
        
        if item.title != nil {
            episode.title = item.title
        }
        
        if item.summary != nil {
            episode.summary = item.summary
        }
        
        if item.date != nil {
            episode.pubDate = item.date
        }
        
        if item.link != nil {
            episode.link = item.link
        }
        
        if item.enclosures != nil {
            episode.mediaURL = item.enclosures[0]["url"] as! String
            episode.mediaType = item.enclosures[0]["type"] as! String
            episode.mediaBytes = item.enclosures[0]["length"] as! Int
        }
        
        if item.duration != nil {
            episode.duration = utility.convertStringToNSTimeInterval(item.duration)
        }
        
        episodeArray.append(episode)
//        println(episodeArray)
        
    }
    
    func feedParserDidFinish(parser: MWFeedParser!) {
        
        // TODO: I have no idea what's going on with this double as statement...
//        podcast.episodes = episodes as NSObject as! Set<NSObject>
//        podcast.lastPubDate = episodes[0].pubDate
        self.delegate?.didReceiveFeedResults(podcast)
    
    }
    
    func feedParser(parser: MWFeedParser!, didFailWithError error: NSError!) {
        
    }
    
}
