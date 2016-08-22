//
//  SaveClipToServer.swift
//  podverse
//
//  Created by Kreon on 1/23/16.
//  Copyright © 2016 Mitchell Downey. All rights reserved.
//

import UIKit

class SaveClipToServer:WebService {
    internal init(clip:Clip, newClip:Bool = false, completionBlock: (response: AnyObject) -> Void, errorBlock: (error: NSError?) -> Void) {
        
        var name = "clips"
        if newClip != true {
            name += "/\(clip.mediaRefId)"
        }
        
        super.init(name:name, completionBlock: completionBlock, errorBlock: errorBlock)
        
        if newClip == true {
            setHttpMethod(.METHOD_POST)
            
            if let ownerId = NSUserDefaults.standardUserDefaults().stringForKey("userId") {
                addParamWithKey("ownerId", value: ownerId)
            }
        } else {
            setHttpMethod(.METHOD_PUT)
            
            addParamWithKey("ownerId", value: clip.ownerId)
            addParamWithKey("episodeId", value: clip.serverEpisodeId)
        }
        
        addHeaderWithKey("Content-Type", value: "application/json")
        
        if let idToken = NSUserDefaults.standardUserDefaults().stringForKey("idToken") {
            addHeaderWithKey("Authorization", value: idToken)
        }
        
        if let ownerName = NSUserDefaults.standardUserDefaults().stringForKey("userName") {
            addParamWithKey("ownerName", value: ownerName)
        }
        
        
        if let title = clip.title {
            addParamWithKey("title", value: title)
        }
        
        addParamWithKey("startTime", value: clip.startTime)
        
        if let endTime = clip.endTime {
            addParamWithKey("endTime", value: endTime)
        }
        
        // TODO: this code is repeated on the episode obj in SaveEpisodeToServer,
        // can we make this more DRY?
        var lastBuildDateString: String?
        var lastPubDateString: String?
        var pubDateString: String?
        
        if let lastBuildDate = clip.episode.podcast.lastBuildDate {
            lastBuildDateString = PVUtility.formatDateToString(lastBuildDate)
        }
        
        if let lastPubDate = clip.episode.podcast.lastPubDate {
            lastPubDateString = PVUtility.formatDateToString(lastPubDate)
        }
        
        if let pubDate = clip.episode.pubDate {
            pubDateString = PVUtility.formatDateToString(pubDate)
        }
        
        var podcastAttrs = Dictionary<String,AnyObject>()
        var episodeAttrs = Dictionary<String,AnyObject>()
        
        podcastAttrs["feedURL"] = clip.episode.podcast.feedURL ?? ""
        podcastAttrs["imageURL"] = clip.episode.podcast.imageURL ?? ""
        podcastAttrs["summary"] = clip.episode.podcast.summary ?? ""
        podcastAttrs["title"] = clip.episode.podcast.title ?? ""
        podcastAttrs["author"] = clip.episode.podcast.author ?? ""
        podcastAttrs["lastBuildDate"] = lastBuildDateString ?? ""
        podcastAttrs["lastPubDate"] = lastPubDateString ?? ""
        
        episodeAttrs["mediaURL"] = clip.episode.mediaURL ?? ""
        episodeAttrs["title"] = clip.episode.title ?? ""
        episodeAttrs["summary"] = clip.episode.summary ?? ""
        episodeAttrs["duration"] = clip.episode.duration as? Int ?? ""
        episodeAttrs["guid"] = clip.episode.guid ?? ""
        episodeAttrs["link"] = clip.episode.link ?? ""
        episodeAttrs["mediaBytes"] = clip.episode.mediaBytes as? Int ?? ""
        episodeAttrs["mediaType"] = clip.episode.mediaType ?? ""
        episodeAttrs["pubDate"] = pubDateString ?? ""
        episodeAttrs["podcast"] = podcastAttrs
        
        addParamWithKey("episode", value: episodeAttrs)
        
    }
}