//
//  FeedParser.swift
//  Podverse
//
//  Created by Mitchell Downey on 5/3/15.
//  Copyright (c) 2015 Mitchell Downey. All rights reserved.
//

import Foundation
import UIKit
import CoreData

protocol PVFeedParserProtocol {
    func didReceiveFeedResults(results: Podcast)
}

class PVFeedParser : NSObject, MWFeedParserDelegate {
    var delegate: PVFeedParserProtocol?
    
    var utility: PVUtility = PVUtility()
    
    var podcast: Podcast = Podcast()

    var episode: Episode = Episode()
    var episodes: [Episode] = []

    func parsePodcastFeed(feedURL: NSURL) {
        var feedParser: MWFeedParser = MWFeedParser(feedURL: feedURL)
        feedParser.delegate = self
        feedParser.feedParseType = ParseTypeFull
        feedParser.connectionType = ConnectionTypeAsynchronously
        feedParser.parse()
    }
    
    func feedParserDidStart(parser: MWFeedParser!) {
        episodes = []
    }
    
    func feedParser(parser: MWFeedParser!, didParseFeedInfo info: MWFeedInfo!) {
        
        podcast = Podcast()

        if info.title != nil {
            podcast.title = info.title
        }
        if info.summary != nil {
            podcast.summary = info.summary
        }
        if info.url != nil {
            podcast.feedURL = info.url
        }
        if info.itunesAuthor != nil {
            podcast.itunesAuthor = info.itunesAuthor
        }
        if info.image != nil {
            let imageURLString: String = info.image
            let url : NSURL? = NSURL(string: imageURLString)
            podcast.imageURL = url!
            if let imgData = NSData(contentsOfURL: url!) {
                podcast.image = UIImage(data: imgData)!
            }
        } else {
            podcast.image =  UIImage()
            podcast.imageURL = NSURL()
        }
        if info.itunesImage != nil {
            let itunesImageURLString: String = info.itunesImage
            let itunesURL : NSURL? = NSURL(string: itunesImageURLString)
            podcast.itunesImageURL = itunesURL!
            if let itunesImgData = NSData(contentsOfURL: itunesURL!) {
                podcast.image = UIImage(data: itunesImgData)!
            }
        } else {
            podcast.itunesImage =  UIImage()
            podcast.itunesImageURL = NSURL()
        }

//        TODO: mitch's foray with Core Data below
//        let appDel: AppDelegate = (UIApplication.sharedApplication().delegate as! AppDelegate)
//        let context: NSManagedObjectContext = appDel.managedObjectContext!
//        let podcastData: NSManagedObject = NSEntityDescription.insertNewObjectForEntityForName("Podcasts", inManagedObjectContext: context) as! NSManagedObject
//
//        println(podcastData)
//        
//        podcastData.setValue(podcast.title, forKey: "title")
//        podcastData.setValue(podcast.summary, forKey: "summary")
//        podcastData.setValue(podcast.feedURL?.absoluteString, forKey: "feedURL")
//        podcastData.setValue(podcast.itunesAuthor, forKey: "itunesAuthor")
//        podcastData.setValue(UIImageJPEGRepresentation(podcast.image, 1), forKey: "image")
//        podcastData.setValue(podcast.imageURL?.absoluteString, forKey: "imageURL")
//        podcastData.setValue(UIImageJPEGRepresentation(podcast.itunesImage, 1), forKey: "itunesImage")
//        podcastData.setValue(podcast.itunesImageURL?.absoluteString, forKey: "itunesImageURL")
//        
//        println(podcastData)
//        
//        let request = NSFetchRequest(entityName: "Podcasts")
//        request.returnsObjectsAsFaults = false
//        
//        var results: NSArray = context.executeFetchRequest(request, error: nil)!
//        
//        if results.count > 0 {
//            for res in results {
//                println(res)
//                println("woohoo")
//            }
//        } else {
//            println("No results returned")
//        }
        
//        newPodcast.setValue("Test Title", forkey: "title")
//        newPodcast.setValue("Test Summary", forKey: "summary")
//        
//        context.save(nil)

    }
    
    func feedParser(parser: MWFeedParser!, didParseFeedItem item: MWFeedItem!) {
        episode = Episode()
        
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
            episode.link = NSURL(string: item.link)
        }
        if item.enclosures != nil {
            var mediaURLString = item.enclosures[0]["url"] as! String
            var mediaURL: NSURL = NSURL(string: mediaURLString)!
            episode.mediaURL = mediaURL
            
            var mediaType = item.enclosures[0]["type"] as! String
            episode.mediaType = mediaType
            
            var mediaBytes = item.enclosures[0]["length"] as! Int
            episode.mediaBytes = mediaBytes
        }
        if item.duration != nil {
            let durationString = item.duration
            let duration = utility.convertStringToNSTimeInterval(durationString)
            episode.duration = duration
        }
        
        episodes.append(episode)
    }
    
    func feedParserDidFinish(parser: MWFeedParser!) {
        podcast.episodes.extend(episodes)
        podcast.lastPubDate = episodes[0].pubDate
        self.delegate?.didReceiveFeedResults(podcast)
    }
    
    func feedParser(parser: MWFeedParser!, didFailWithError error: NSError!) {
        
    }
    
}