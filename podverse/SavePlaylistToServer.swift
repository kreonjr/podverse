//
//  SavePlaylistToServer.swift
//  podverse
//
//  Created by Kreon on 2/21/16.
//  Copyright © 2016 Mitchell Downey. All rights reserved.
//

import Foundation

class SavePlaylistToServer:WebService {
    internal init(playlist:Playlist, completionBlock: (response: Dictionary<String, AnyObject>) -> Void, errorBlock: (error: NSError?) -> Void) {
        super.init(name:"pl", completionBlock: completionBlock, errorBlock: errorBlock)
    
        setHttpMethod(.METHOD_POST)
        addHeaderWithKey("Content-Type", value: "application/json")
        
        addParamWithKey("playlistTitle", value: playlist.title)
        
        let episodesArray = playlist.episodes?.allObjects
        let clipsArray = playlist.clips?.allObjects
        var playlistItems = [Dictionary<String,AnyObject>]()
        
        if let episodes = episodesArray as? [Episode]{
            for episode in episodes {
                let podcast = episode.podcast
                let episodeTitle = episode.title ?? ""
                let duration = episode.duration?.integerValue ?? 0
                let pubDate = PVUtility.formatDateToString(episode.pubDate ?? NSDate())
                let mediaUrl = episode.mediaURL ?? ""
                let podcastTitle = podcast.title ?? ""
                let podcastImageUrl = podcast.imageURL ?? ""
                
                playlistItems.append([ "title": episodeTitle,
                                       "duration": duration,
                                       "pubDate": pubDate,
                                       "mediaURL": mediaUrl,
                                       "podcast": [ "title": podcastTitle,
                                                    "imageURL": podcastImageUrl]
                ])
            }
        }
        
        if let clips = clipsArray as? [Clip]{
            for clip in clips {
                let episode = clip.episode
                let podcast = episode.podcast
                
                let clipTitle = clip.title ?? ""
                let duration = clip.duration.integerValue
                let startTime = clip.startTime.integerValue
                let endTime = clip.endTime.integerValue
                let episodeTitle = episode.title ?? ""
                let episodeURL = episode.mediaURL ?? ""
                let podcastTitle = podcast.title ?? ""
                let podcastImageUrl = podcast.imageURL ?? ""
                
                playlistItems.append(["title": clipTitle,
                    "duration": duration,
                    "startTime": startTime,
                    "endTime": endTime,
                    "episode":["title": episodeTitle,
                        "mediaURL": episodeURL ],
                    "podcast": ["title": podcastTitle,
                        "imageURL": podcastImageUrl]
                ])
            }
        }
        
        addParamWithKey("playlistItems", value:playlistItems)
    }
}