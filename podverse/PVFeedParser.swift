//
//  PVFeedParser.swift
//  podverse
//
//  Created by Mitchell Downey on 6/4/15.
//  Copyright (c) 2015 Mitchell Downey. All rights reserved.
//

import UIKit
import CoreData

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
    
    func parsePodcastFeed(feedURL: NSURL, resolve: () -> (), reject: () -> ()) {
        moc = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext
        
        let predicate = NSPredicate(format: "feedURL == %@", feedURL)
        
        let checkIfPodcastAlreadyExists = CoreDataHelper.fetchEntities("Podcast", managedObjectContext: moc, predicate: predicate)
        
        if checkIfPodcastAlreadyExists.count < 1 {
            var feedParser = MWFeedParser(feedURL: feedURL)
            feedParser.delegate = self
            feedParser.feedParseType = ParseTypeFull
            feedParser.connectionType = ConnectionTypeAsynchronously
            feedParser.parse()
            
            // I'm not entirely sure how this Callback/Promise below works
            // but I got it working after reading Mirco Zeiss's post at
            // http://www.mircozeiss.com/swift-for-javascript-developers/
            var delta: Int64 = 1 * Int64(NSEC_PER_SEC)
            var time = dispatch_time(DISPATCH_TIME_NOW, delta)
            dispatch_after(time, dispatch_get_main_queue(), {
                resolve()
            })
        } else {
            println("that podcast is already added!")
        }

    }
    
    func feedParserDidStart(parser: MWFeedParser!) {
        
    }
    
    func feedParser(parser: MWFeedParser!, didParseFeedInfo info: MWFeedInfo!) {

        podcast = CoreDataHelper.insertManagedObject("Podcast", managedObjectContext: moc) as! Podcast
        
        if info.title != nil {
            podcast.title = info.title
        }
        
        if info.summary != nil {
            podcast.summary = info.summary
        }
        
        if info.url != nil {
            podcast.feedURL = info.url.absoluteString!
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
        
        let episode = CoreDataHelper.insertManagedObject("Episode", managedObjectContext: self.moc) as! Episode
        
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
            episode.mediaURL = item.enclosures[0]["url"] as? String
            episode.mediaType = item.enclosures[0]["type"] as? String
            episode.mediaBytes = item.enclosures[0]["length"] as! Int
        }
        
        if item.duration != nil {
            episode.duration = utility.convertStringToNSNumber(item.duration)
        }
        
        if item.guid != nil {
            episode.guid = item.guid
        }
        
        podcast.addEpisodeObject(episode)
        
        episodeArray.append(episode)
        
    }
    
    func feedParserDidFinish(parser: MWFeedParser!) {
        podcast.lastPubDate = episodeArray[0].pubDate
        moc.save(nil)
        self.delegate?.didReceiveFeedResults(podcast)
    }
    
    func feedParser(parser: MWFeedParser!, didFailWithError error: NSError!) {
        
    }
    
}
