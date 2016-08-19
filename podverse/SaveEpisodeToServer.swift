//
//  SaveEpisodeToServer.swift
//  podverse
//
//  Created by Creon on 8/16/16.
//  Copyright © 2016 Mitchell Downey. All rights reserved.
//

import UIKit

class SaveEpisodeToServer: WebService {
    internal init(episode:Episode, completionBlock: (response: AnyObject) -> Void, errorBlock: (error: NSError?) -> Void) {
        super.init(name:"clips", completionBlock: completionBlock, errorBlock: errorBlock)
        
        setHttpMethod(.METHOD_POST)
        
        addHeaderWithKey("Content-Type", value: "application/json")
        
        if let idToken = NSUserDefaults.standardUserDefaults().stringForKey("idToken") {
            addHeaderWithKey("Authorization", value: idToken)
        }
        
        if let title = episode.title {
            addParamWithKey("title", value: title)
        }
        
        addParamWithKey("startTime", value: 0)
        
        // TODO: this code is repeated on the clip obj in SaveClipToServer,
        // can we make this more DRY?
        var lastBuildDateString: String?
        var lastPubDateString: String?
        var pubDateString: String?
        
        if let lastBuildDate = episode.podcast.lastBuildDate {
            lastBuildDateString = PVUtility.formatDateToString(lastBuildDate)
        }
        
        if let lastPubDate = episode.podcast.lastPubDate {
            lastPubDateString = PVUtility.formatDateToString(lastPubDate)
        }
        
        if let pubDate = episode.pubDate {
            pubDateString = PVUtility.formatDateToString(pubDate)
        }
        
        var podcastAttrs = Dictionary<String,AnyObject>()
        var episodeAttrs = Dictionary<String,AnyObject>()
        
        podcastAttrs["feedURL"] = episode.podcast.feedURL ?? ""
        podcastAttrs["imageURL"] = episode.podcast.imageURL ?? ""
        podcastAttrs["summary"] = episode.podcast.summary ?? ""
        podcastAttrs["title"] = episode.podcast.title ?? ""
        podcastAttrs["author"] = episode.podcast.author ?? ""
        podcastAttrs["lastBuildDate"] = lastBuildDateString ?? ""
        podcastAttrs["lastPubDate"] = lastPubDateString ?? ""
        
        episodeAttrs["mediaURL"] = episode.mediaURL ?? ""
        episodeAttrs["title"] = episode.title ?? ""
        episodeAttrs["summary"] = episode.summary ?? ""
        episodeAttrs["duration"] = episode.duration as? Int ?? ""
        episodeAttrs["guid"] = episode.guid ?? ""
        episodeAttrs["link"] = episode.link ?? ""
        episodeAttrs["mediaBytes"] = episode.mediaBytes as? Int ?? ""
        episodeAttrs["mediaType"] = episode.mediaType ?? ""
        episodeAttrs["pubDate"] = pubDateString ?? ""
        episodeAttrs["podcast"] = podcastAttrs
        
        addParamWithKey("episode", value: episodeAttrs)
    }
}
