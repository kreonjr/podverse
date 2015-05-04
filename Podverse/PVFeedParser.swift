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
    
    var podcast: PodcastModel = PodcastModel()

    var episode: EpisodeModel = EpisodeModel()
    var episodes: [EpisodeModel] = []

    func parsePodcastFeed(feedURL: NSURL) {
        println("hello")
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
            let url = NSURL(fileURLWithPath: imageURLString)
            podcast.imageURL = url!
            if let imgData = NSData(contentsOfURL: url!) {
                podcast.image = UIImage(data: imgData)!
            }
        }
        if info.itunesImage != nil {
            let itunesImageURLString:String = info.itunesImage
            let itunesURL:NSURL = NSURL(string: itunesImageURLString)!
            podcast.itunesImageURL = itunesURL
            let itunesImgData = NSData(contentsOfURL: itunesURL)
            podcast.itunesImage = UIImage(data: itunesImgData!)!
        }
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
        
        episodes.append(episode)
    }
    
    func feedParserDidFinish(parser: MWFeedParser!) {
        podcast.episodes.extend(episodes)
        self.delegate?.didReceiveFeedResults(podcast)
    }
    
    func feedParser(parser: MWFeedParser!, didFailWithError error: NSError!) {
        
    }
    
}