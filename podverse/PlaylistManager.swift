//
//  PlaylistManager.swift
//  podverse
//
//  Created by Kreon on 2/28/16.
//  Copyright © 2016 Mitchell Downey. All rights reserved.
//

import Foundation

final class PlaylistManager {
    static let sharedInstance = PlaylistManager()
    
    let playlistQueue = dispatch_queue_create("com.podverese.playlistQueue", DISPATCH_QUEUE_SERIAL)
    private var playlists = [Playlist]()
    
    var playlistsArray:[Playlist] {
        get {
            var playlistsTemp = [Playlist]()
           dispatch_sync(playlistQueue) { () -> Void in
                playlistsTemp = self.playlists
           }
            
            return playlistsTemp
        }
    }
    
    func addPlaylist(playlist:Playlist?) {
        if let playlist = playlist {
            dispatch_barrier_async(self.playlistQueue, { () -> Void in
                self.playlists.append(playlist)
            })
        }
    }
    
    static func refreshPlaylists() {
        let ids = ["WAmf3QdoZvXIo7pY","ZbQC1HIs9L0tvyY4","ZGtLrfNC0V8rPoKz"]
        
        for id in ids {
            GetPlaylistFromServer(playlistId: id, completionBlock: { (response) -> Void in
                PlaylistManager.sharedInstance.addPlaylist(PlaylistManager.JSONToPlaylist(response))
            }) { (error) -> Void in
                    print("Error y'all \(error?.localizedDescription)")
            }.call()
        }
    }
    
    static func JSONToPlaylist(JSONDict:Dictionary<String,AnyObject>) -> Playlist? {
        let playlist = Playlist(newTitle: JSONDict["playlistTitle"] as! String, newURL: JSONDict["url"] as! String)
        
        playlist.playlistId = JSONDict["id"] as? String
        playlist.isPublic = JSONDict["isPublic"]?.boolValue
        playlist.playlistItems = JSONDict["playlistItems"] as? [Dictionary<String,AnyObject>]
        
        return playlist
    }
}