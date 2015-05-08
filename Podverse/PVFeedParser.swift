//
//  FeedParser.swift
//  Podverse
//
//  Created by Mitchell Downey on 5/3/15.
//  Copyright (c) 2015 Mitchell Downey. All rights reserved.
//

import Foundation
import UIKit

protocol PVFeedParserProtocol {
    func didReceiveFeedResults(results: PodcastModel)
}

class PVFeedParser : NSObject, MWFeedParserDelegate {
    var delegate: PVFeedParserProtocol?
    
    var utility: PVUtility = PVUtility()
    
    var podcast: PodcastModel = PodcastModel()

    var episode: EpisodeModel = EpisodeModel()
    var episodes: [EpisodeModel] = []

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
        
        podcast = PodcastModel()

        if info.title != nil {
            podcast.title = info.title
        }
        if info.summary != nil {
            podcast.summary = info.summary
        }
        if info.url != nil {
            podcast.feedURL = info.url
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
        
//        var itunesImageURLString: String? = info.itunesImage
//        var itunesImage: UIImage? = UIImage(contentsOfFile: itunesImageURLString!)
//        println(itunesImage)
//        if info.itunesImage != nil {
//            
//            let itunesURL : NSURL? = NSURL(string: itunesImageURLString)
//            podcast.itunesImageURL = itunesURL!
//            if let imgData = NSData(contentsOfURL: itunesURL!) {
//                podcast.itunesImage = UIImage(data: imgData)!
//            }
//        } else {
//            var image: UIImage? = podcast.image
//            podcast.itunesImage = UIImage()
//            podcast.itunesImageURL = NSURL()
//        }
    }
    
    func feedParser(parser: MWFeedParser!, didParseFeedItem item: MWFeedItem!) {
        episode = EpisodeModel()
        
        if item.title != nil {
            episode.title = item.title
        }
        if item.summary != nil {
            episode.summary = item.summary
        }
        if item.date != nil {
            episode.pubDate = item.date
        }
        if item.duration != nil {
            let durationString = item.duration
            let duration = utility.convertStringToNSTimeInterval(durationString)
            println(duration)
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