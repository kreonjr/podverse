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
    
    var moc: NSManagedObjectContext!
    
    var podcast: Podcast!
    var episode: Episode!
    
    var searchResultPodcast: SearchResultPodcast!
    
    var episodeArray: [Episode] = [Episode]()
    
    var willSave: Bool = false
    
    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    
    func parsePodcastFeed(feedURL: NSURL, willSave: Bool, resolve: () -> (), reject: () -> ()) {
        
        if (willSave == false) {
            
            self.willSave = willSave
            var feedParser = MWFeedParser(feedURL: feedURL)
            feedParser.delegate = self
            feedParser.feedParseType = ParseTypeInfoOnly
            feedParser.connectionType = ConnectionTypeSynchronously
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

    }
    
    func feedParserDidStart(parser: MWFeedParser!) {
        println("I started")
    }
    
    func feedParser(parser: MWFeedParser!, didParseFeedInfo info: MWFeedInfo!) {
        
        if willSave == true {
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
                let imageURLString = info.image
                var imgURL: NSURL = NSURL(string: imageURLString!)!
                let request: NSURLRequest = NSURLRequest(URL: imgURL)
                NSURLConnection.sendAsynchronousRequest(
                    request, queue: NSOperationQueue.mainQueue(),
                    completionHandler: {(response: NSURLResponse!,data: NSData!,error: NSError!) -> Void in
                        if error == nil {
                            self.podcast.image = data
                        } else {
                            println(error)
                        }
                })
                
            }
            
            if info.itunesImage != nil {
                let imageURLString = info.itunesImage
                var imgURL: NSURL = NSURL(string: imageURLString!)!
                let request: NSURLRequest = NSURLRequest(URL: imgURL)
                NSURLConnection.sendAsynchronousRequest(
                    request, queue: NSOperationQueue.mainQueue(),
                    completionHandler: {(response: NSURLResponse!,data: NSData!,error: NSError!) -> Void in
                        if error == nil {
                            self.podcast.itunesImage = data
                        } else {
                            println(error)
                        }
                })
            }
            
        }
        else {
            
            searchResultPodcast = SearchResultPodcast()
            
            if info.title != nil {
                println(info)
                println(info.title)
                searchResultPodcast.title = info.title
            }
            
            if info.summary != nil {
                searchResultPodcast.summary = info.summary
            }
            
            if info.image != nil {
                let imageURLString = info.image
                var imgURL: NSURL = NSURL(string: imageURLString!)!
                let request: NSURLRequest = NSURLRequest(URL: imgURL)
                NSURLConnection.sendAsynchronousRequest(
                    request, queue: NSOperationQueue.mainQueue(),
                    completionHandler: {(response: NSURLResponse!,data: NSData!,error: NSError!) -> Void in
                        if error == nil {
                            self.searchResultPodcast.image = data
                        } else {
                            println(error)
                        }
                })
                
            }
            
            if info.itunesImage != nil {
                let imageURLString = info.itunesImage
                var imgURL: NSURL = NSURL(string: imageURLString!)!
                let request: NSURLRequest = NSURLRequest(URL: imgURL)
                NSURLConnection.sendAsynchronousRequest(
                    request, queue: NSOperationQueue.mainQueue(),
                    completionHandler: {(response: NSURLResponse!,data: NSData!,error: NSError!) -> Void in
                        if error == nil {
                            self.searchResultPodcast.itunesImage = data
                        } else {
                            println(error)
                        }
                })
            }
            
        }
        
    }
    
    func feedParser(parser: MWFeedParser!, didParseFeedItem item: MWFeedItem!) {
        
        if willSave == true {
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
        
    }
    
    func feedParserDidFinish(parser: MWFeedParser!) {
        println("hey")
        if willSave == true {
            podcast.lastPubDate = episodeArray[0].pubDate
            moc.save(nil)
        } else {
            appDelegate.iTunesSearchPodcastArray.append(searchResultPodcast)
        }
        
    }
    
    func feedParser(parser: MWFeedParser!, didFailWithError error: NSError!) {
        println(error)
    }
    
}
