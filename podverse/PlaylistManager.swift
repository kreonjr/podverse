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
    
    var playlists = [Playlist]()
    var playlistIds:[String] {
        let data:NSData =  NSFileManager.defaultManager().contentsAtPath(Constants.kPlaylistIDPath)!
        do{
            return try NSPropertyListSerialization.propertyListWithData(data, options: NSPropertyListMutabilityOptions.MutableContainersAndLeaves, format: nil) as! [String]
        }catch{
            print(error)
        }
        
        return []
    }
    
    func addPlaylistLocally(playlist:Playlist?) {
        if let playlist = playlist, let playlistId = playlist.playlistId {
            PlaylistManager.saveIDToPlist(playlistId)
            self.playlists.append(playlist)
        }
    }
    
    func addPlaylistByUrlString(urlString: String) {
        let urlComponentArray = urlString.componentsSeparatedByString("/")
        let playlistId = urlComponentArray[4]
        
        if (urlComponentArray[0] == "http:" || urlComponentArray[0] == "https") && (urlComponentArray[1] == "") && (urlComponentArray[2] == "podverse.tv") && (urlComponentArray[3] == "pl") && (playlistId.characters.count == 16) {
                GetPlaylistFromServer(playlistId: playlistId, completionBlock: { (response) -> Void in
                    self.addPlaylistLocally(PlaylistManager.JSONToPlaylist(response))
                }) { (error) -> Void in
                        print("Error y'all \(error?.localizedDescription)")
                }.call()
        } else {
            print("Error: invalid URL")
        }
        
    }
    
    func refreshPlaylists() {
        let dispatchGroup = dispatch_group_create()
        for id in playlistIds {
            dispatch_group_enter(dispatchGroup)
            GetPlaylistFromServer(playlistId: id, completionBlock: { (response) -> Void in
                self.addPlaylistLocally(PlaylistManager.JSONToPlaylist(response))
                dispatch_group_leave(dispatchGroup)
            }) { (error) -> Void in
                    print("Error y'all \(error?.localizedDescription)")
            }.call()
        }
        
        dispatch_group_notify(dispatchGroup, dispatch_get_main_queue()) { () -> Void in
            NSNotificationCenter.defaultCenter().postNotificationName(Constants.refreshPodcastTableDataNotification, object: nil)
        }
    }
    
    static func JSONToPlaylist(JSONDict:Dictionary<String,AnyObject>) -> Playlist? {
        let playlist = Playlist(newTitle: JSONDict["playlistTitle"] as! String, newURL: JSONDict["url"] as? String)
        
        playlist.playlistId = JSONDict["_id"] as? String
        playlist.isPublic = JSONDict["isPublic"]?.boolValue
        if let playlistItems = JSONDict["playlistItems"] as? [Dictionary<String,AnyObject>] {
            playlist.playlistItems = playlistItems
        }
        
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
        
        if let pubDate = clip.episode.pubDate {
            episodeDict["pubDate"] = PVUtility.formatDateToString(pubDate)
        }
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
        if let pubDate = episode.pubDate {
            JSONDict["pubDate"] = PVUtility.formatDateToString(pubDate)
        }
        JSONDict["mediaURL"] = episode.mediaURL
        
        var podcastDict = Dictionary<String,AnyObject>()
        podcastDict["title"] = episode.podcast.title
        podcastDict["imageURL"] = episode.podcast.imageURL
        
        JSONDict["podcast"] = podcastDict
        
        return JSONDict
    }
    
    static func saveIDToPlist(playlistId:String) {
        var saveArray = PlaylistManager.sharedInstance.playlistIds
        if !saveArray.contains(playlistId) {
            saveArray.append(playlistId)
            (saveArray as NSArray).writeToFile(Constants.kPlaylistIDPath, atomically: true)
        }
    }

    static func removeIDFromList(playlistId:String) {
        var idArray = PlaylistManager.sharedInstance.playlistIds
        for (index , id) in idArray.enumerate() {
            if id == playlistId {
                idArray.removeAtIndex(index)
                break
            }
        }
        
        (idArray as NSArray).writeToFile(Constants.kPlaylistIDPath, atomically: true)
    }
    
    func createDefaultPlaylists() {
        // If no playlistIds are saved in the plist, then create the "My Clips" and "My Episodes" playlist
        if PlaylistManager.sharedInstance.playlistIds.count < 1 {
            let myClipsPlaylist = Playlist(newTitle: "My Clips")
            savePlaylist(myClipsPlaylist)
            let myEpisodesPlaylist = Playlist(newTitle: "My Episodes")
            savePlaylist(myEpisodesPlaylist)
        }
    }
    
    func addItemToPlaylist(playlist: Playlist, clip: Clip?, episode: Episode?) {
        if let c = clip, let clipJSON = self.clipToPlaylistItemJSON(c) {
            playlist.playlistItems.append(clipJSON)
        }
        
        if let e = episode, let episodeJSON = self.episodeToPlaylistItemJSON(e)  {
            playlist.playlistItems.append(episodeJSON)
        }
        
        SavePlaylistToServer(playlist: playlist, newPlaylist:(playlist.playlistId == nil), completionBlock: {[unowned self] (response) -> Void in
            playlist.url = response["url"] as? String
            
            NSNotificationCenter.defaultCenter().postNotificationName(Constants.kItemAddedToPlaylistNotification, object: nil)
            }) { (error) -> Void in
                print("Not saved to server. Error: ", error?.localizedDescription)
            }.call()
    }
    
    func savePlaylist(playlist: Playlist) {
        SavePlaylistToServer(playlist: playlist, newPlaylist:(playlist.playlistId == nil), completionBlock: {[unowned self] (response) -> Void in
            
            playlist.playlistId = response["_id"] as? String
            playlist.url = response["url"] as? String
            
            if let playlistId = playlist.playlistId {
                PlaylistManager.saveIDToPlist(playlistId)
                self.addPlaylistLocally(playlist)
            }
            
            NSNotificationCenter.defaultCenter().postNotificationName(Constants.kRefreshAddToPlaylistTableDataNotification, object: nil)
            
            }) { (error) -> Void in
                print("Not saved to server. Error: ", error?.localizedDescription)
            }.call()
    }
    
    
}