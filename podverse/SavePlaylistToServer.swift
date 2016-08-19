//
//  SavePlaylistToServer.swift
//  podverse
//
//  Created by Kreon on 2/21/16.
//  Copyright © 2016 Mitchell Downey. All rights reserved.
//

import Foundation

class SavePlaylistToServer:WebService {
    internal init(playlist:Playlist, newPlaylist:Bool = false, addMediaRefId: String?, completionBlock: (response: AnyObject) -> Void, errorBlock: (error: NSError?) -> Void) {
        
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
        
        if let title = playlist.title {
            addParamWithKey("title", value: title)   
        }

//        Pass enum to servier
//        if let sharePermission = playlist.sharePermission {
//            addParamWithKey("")
//        }
        
        addParamWithKey("isMyEpisodes", value: playlist.isMyEpisodes)
        
        addParamWithKey("isMyClips", value: playlist.isMyClips)
        
        if let mediaRefId = addMediaRefId {
            addParamWithKey("playlistItems", value: [mediaRefId])
        }

    }
}