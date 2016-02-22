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
                playlistItems.append(["title":episode.title ?? "",
                                      "duration":episode.duration ?? 0,
                                      "pubDate": PVUtility.formatDateToString(episode.pubDate) ?? "",
                                      "mediaURL":episode.mediaURL ?? "",
                                      "podcast":["title":episode.podcast.title ?? "",
                                                 "imageURL":episode.podcast.imageURL ?? ""]
                ])
            }
        }
        
        if let clips = clipsArray as? [Clip]{
            for clip in clips {
                let episode = clip.episode
                let podcast = episode.podcast
                
                playlistItems.append(["title": clip.title ?? "",
                                      "duration": clip.duration.integerValue,
                                      "startTime": clip.startTime.integerValue,
                                      "endTime": clip.endTime.integerValue,
                                      "episode":["title": episode.title ?? "",
                                                "mediaURL": episode.mediaURL],
                                      "podcast": ["title": podcast.title ?? "",
                                                  "imageURL": podcast.imageURL ?? ""]
                                                 ])
            }
        }
        
        addParamWithKey("playlistItems", value:playlistItems)
    }
}