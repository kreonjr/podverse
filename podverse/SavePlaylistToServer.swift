//
//  SavePlaylistToServer.swift
//  podverse
//
//  Created by Kreon on 2/21/16.
//  Copyright © 2016 Mitchell Downey. All rights reserved.
//

import Foundation

class SavePlaylistToServer:WebService {
    internal init(playlist:Playlist, newPlaylist:Bool = false, completionBlock: (response: Dictionary<String, AnyObject>) -> Void, errorBlock: (error: NSError?) -> Void) {
        
        var name = "pl"
        if let id = playlist.playlistId where newPlaylist == false {
            name += "/\(id)"
        }
        
        super.init(name:name, completionBlock: completionBlock, errorBlock: errorBlock)
    
        if newPlaylist {
            setHttpMethod(.METHOD_POST)
        } else {
            setHttpMethod(.METHOD_PUT)
        }
        
        addHeaderWithKey("Content-Type", value: "application/json")
        
        addParamWithKey("playlistTitle", value: playlist.title)
        
        var playlistItems = [Dictionary<String,AnyObject>]()
        
        if let episodes = playlist.episodes {
            for episode in episodes {
                let episodeJSON = PlaylistManager.sharedInstance.episodeToPlaylistItemJSON(episode as! Episode)
                playlistItems.append(episodeJSON)
                
            }
        }
        
        if let clips = playlist.clips {
            for clip in clips {
                let clipJSON = PlaylistManager.sharedInstance.clipToPlaylistItemJSON(clip as! Clip)
                playlistItems.append(clipJSON)
                
            }
        }
        
        if playlistItems.count > 0 {
            addParamWithKey("playlistItems", value: playlistItems)
        }
        
        if let userId = NSUserDefaults.standardUserDefaults().stringForKey("userId") {
            addParamWithKey("userId", value: userId)
        }
        
    }
}