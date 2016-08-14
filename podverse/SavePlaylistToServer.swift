//
//  SavePlaylistToServer.swift
//  podverse
//
//  Created by Kreon on 2/21/16.
//  Copyright © 2016 Mitchell Downey. All rights reserved.
//

import Foundation

class SavePlaylistToServer:WebService {
    internal init(playlist:Playlist, newPlaylist:Bool = false, completionBlock: (response: AnyObject) -> Void, errorBlock: (error: NSError?) -> Void) {
        
        var name = "playlists"
        if let id = playlist.id where newPlaylist == false {
            name += "/\(id)"
        }
        
        super.init(name:name, completionBlock: completionBlock, errorBlock: errorBlock)
    
        if newPlaylist {
            setHttpMethod(.METHOD_POST)
        } else {
            setHttpMethod(.METHOD_PUT)
        }
        
        addHeaderWithKey("Content-Type", value: "application/json")
        
        if let idToken = NSUserDefaults.standardUserDefaults().stringForKey("idToken") {
            addHeaderWithKey("Authorization", value: idToken)
        }

        if let ownerId = NSUserDefaults.standardUserDefaults().stringForKey("userId") {
            addParamWithKey("ownerId", value: ownerId)
        }
        
        addParamWithKey("title", value: playlist.title)
        
        if let slug = playlist.slug {
            addParamWithKey("slug", value: slug)
        }
        
        if let dateCreated = playlist.dateCreated {
            addParamWithKey("dateCreated", value: dateCreated)
            
            if let lastUpdated = playlist.lastUpdated {
                addParamWithKey("lastUpdated", value: lastUpdated)
            } else {
                let date = NSDate().toString()
                addParamWithKey("lastUpdated", value: date)
            }
        } else {
            let date = NSDate().toString()
            addParamWithKey("dateCreated", value: date)
        }
        
//        var playlistItems = [Dictionary<String,AnyObject>]()
//        
//        if let episodes = playlist.episodes {
//            for episode in episodes {
//                let episodeJSON = PlaylistManager.sharedInstance.episodeToPlaylistItemJSON(episode as! Episode)
//                playlistItems.append(episodeJSON)
//                
//            }
//        }
//        
//        if let clips = playlist.clips {
//            for clip in clips {
//                let clipJSON = PlaylistManager.sharedInstance.clipToPlaylistItemJSON(clip as! Clip)
//                playlistItems.append(clipJSON)
//                
//            }
//        }
//        
//        if playlistItems.count > 0 {
//            addParamWithKey("playlistItems", value: playlistItems)
//        }
//        
//        if let userId = NSUserDefaults.standardUserDefaults().stringForKey("userId") {
//            addParamWithKey("userId", value: userId)
//        }
//        
//        if playlist.isMyEpisodes {
//            addParamWithKey("isMyEpisodes", value: playlist.isMyEpisodes)
//        }
//        
//        if playlist.isMyClips {
//            addParamWithKey("isMyClips", value: playlist.isMyClips)
//        }
        
    }
}