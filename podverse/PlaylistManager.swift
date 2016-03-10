//
//  PlaylistManager.swift
//  podverse
//
//  Created by Kreon on 2/28/16.
//  Copyright © 2016 Mitchell Downey. All rights reserved.
//

import Foundation

final class PlaylistManager: NSObject {
    static let sharedInstance = PlaylistManager()
    
    let playlistQueue = dispatch_queue_create("com.podverese.playlistQueue", DISPATCH_QUEUE_SERIAL)
    var playlists = [Playlist]()
    var playlistIds:[String]!
    
    override init() {
        super.init()
            playlistIds = ["ZGtLrfNC0V8rPoKz"]
    }
    
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
        if let playlist = playlist, let playlistId = playlist.playlistId {
            dispatch_barrier_async(self.playlistQueue, { () -> Void in
                self.playlistIds.append(playlistId)
                self.playlists.append(playlist)
            })
        }
    }
    
    func addPlaylistByUrlString(urlString: String) {
        let urlComponentArray = urlString.componentsSeparatedByString("/")
        let playlistId = urlComponentArray[4]
        
        if (urlComponentArray[0] == "http:" || urlComponentArray[0] == "https") && (urlComponentArray[1] == "") && (urlComponentArray[2] == "podverse.tv") && (urlComponentArray[3] == "pl") && (playlistId.characters.count == 16) {
                GetPlaylistFromServer(playlistId: playlistId, completionBlock: { (response) -> Void in
                    PlaylistManager.sharedInstance.addPlaylist(PlaylistManager.JSONToPlaylist(response))
                    NSNotificationCenter.defaultCenter().postNotificationName(Constants.refreshPodcastTableDataNotification, object: nil)
                    }) { (error) -> Void in
                        print("Error y'all \(error?.localizedDescription)")
                    }.call()
        } else {
            print("Error: invalid URL")
        }
        
    }
    
    func refreshPlaylists() {
        for id in playlistIds {
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
    
    static func playlistToJSON(playlist:Playlist) -> Dictionary<String,AnyObject>? {
        var JSONDict = Dictionary<String,AnyObject>()
        JSONDict["playlistTitle"] = playlist.title
        JSONDict["playlistItems"] = playlist.playlistItems

        return JSONDict
    }
    
    func clipToPlaylistItemJSON(clip:Clip) -> Dictionary<String,AnyObject>? {
        var JSONDict = Dictionary<String,AnyObject>()
        
        JSONDict["title"] = clip.title
        JSONDict["duration"] = clip.duration
        JSONDict["startTime"] = clip.startTime
        JSONDict["endTime"] = clip.endTime
        
        var episodeDict = Dictionary<String,AnyObject>()
        episodeDict["title"] = clip.episode.title
        episodeDict["mediaURL"] = clip.episode.mediaURL
        JSONDict["episode"] = episodeDict
        
        var podcastDict = Dictionary<String,AnyObject>()
        podcastDict["title"] = clip.episode.podcast.title
        podcastDict["imageURL"] = clip.episode.podcast.imageURL
        JSONDict["podcast"] = podcastDict
        
        return JSONDict
    }
    
    func episodeToPlaylistItemJSON(episode:Episode) -> Dictionary<String,AnyObject>? {
        var JSONDict = Dictionary<String,AnyObject>()
        JSONDict["title"] = episode.title
        JSONDict["duration"] = episode.duration
        JSONDict["pubDate"] = episode.pubDate
        JSONDict["mediaURL"] = episode.mediaURL
        
        var podcastDict = Dictionary<String,AnyObject>()
        podcastDict["title"] = episode.podcast.title
        podcastDict["imageURL"] = episode.podcast.imageURL
        
        JSONDict["podcast"] = podcastDict
        
        return JSONDict
    }
    
}