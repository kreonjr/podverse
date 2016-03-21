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
    
    var playlists:[Playlist] {
        get {
            return CoreDataHelper.sharedInstance.fetchEntities("Playlist", predicate: nil) as! [Playlist]
        }
    }
    
    func addPlaylistByUrlString(urlString: String) {
        var urlComponentArray = urlString.componentsSeparatedByString("/")
        let playlistId = urlComponentArray[4]
        if urlComponentArray[3] == "playlist" {
            urlComponentArray[3] = "pl"
        }
        
        
        // TODO: This doesn't work properly. If I add a playlist by URL, the playlist items are not successfully grabbed and added to CoreData.
        if (urlComponentArray[0] == "http:" || urlComponentArray[0] == "https") && (urlComponentArray[1] == "") && (urlComponentArray[2] == "podverse.tv") && (urlComponentArray[3] == "pl") && (playlistId.characters.count == 16) {
                GetPlaylistFromServer(playlistId: playlistId, completionBlock: { (response) -> Void in
                    var playlist = CoreDataHelper.sharedInstance.retrieveExistingOrCreateNewPlaylist(playlistId)
                    playlist = PlaylistManager.JSONToPlaylist(response)
                    CoreDataHelper.sharedInstance.saveCoreData(nil)
                }) { (error) -> Void in
                        print("Error y'all \(error?.localizedDescription)")
                }.call()
        } else {
            print("Error: invalid URL")
        }
        
    }
    
    func refreshPlaylists() {
//        playlists = CoreDataHelper.sharedInstance.fetchEntities("Playlist", predicate: nil) as! [Playlist]
//        let dispatchGroup = dispatch_group_create()
//        for playlist in playlists {
//            if let playlistId = playlist.playlistId {
//                dispatch_group_enter(dispatchGroup)
//                GetPlaylistFromServer(playlistId: playlistId, completionBlock: { (response) -> Void in
//                    var playlist = CoreDataHelper.sharedInstance.retrieveExistingOrCreateNewPlaylist(playlistId)
//                    playlist = PlaylistManager.JSONToPlaylist(response)
//                    dispatch_group_leave(dispatchGroup)
//                }) { (error) -> Void in
//                    print("Error y'all \(error?.localizedDescription)")
//                }.call()
//            }
//        }
//        
//        dispatch_group_notify(dispatchGroup, dispatch_get_main_queue()) { () -> Void in
//            NSNotificationCenter.defaultCenter().postNotificationName(Constants.refreshPodcastTableDataNotification, object: nil)
//        }
    }
    
    static func JSONToPlaylist(JSONDict:Dictionary<String,AnyObject>) -> Playlist {
        let playlist = CoreDataHelper.sharedInstance.insertManagedObject("Playlist") as! Playlist
        
        if let title = JSONDict["playlistTitle"] as? String {
            playlist.title = title
        }
        
        if let url = JSONDict["url"] as? String {
            playlist.url = url
        }
        
        if let playlistId = JSONDict["_id"] as? String {
            playlist.playlistId = playlistId
        }
        
        if let isPublic = JSONDict["isPublic"] {
            playlist.isPublic = isPublic.boolValue
        }
        
        if let playlistItems = JSONDict["playlistItems"] as? [Dictionary<String,AnyObject>] {
            
            for playlistItem in playlistItems {
                var podcast: Podcast!
                var episode: Episode!
                var clip: Clip!
                // If the episode property has a value, then treat as a clip
                if playlistItem["episode"] != nil {
                    if let podcastDict = playlistItem["podcast"] {
                        if let feedURLString = podcastDict["feedURL"] as? String {
                            podcast = CoreDataHelper.sharedInstance.retrieveExistingOrCreateNewPodcast(feedURLString)
                            podcast.feedURL = feedURLString
                        } else {
                            break
                        }
                        
                        if let title = podcastDict["title"] as? String {
                            podcast.title = title
                        }
                        
                        if let imageURL = podcastDict["imageURL"] as? String {
                            if podcast.imageURL == nil {
                                podcast.imageURL = imageURL
                            }
                        }
                    }
                    
                    if let episodeDict = playlistItem["episode"] {
                        if let mediaUrlString = episodeDict["mediaURL"] as? String {
                            episode = CoreDataHelper.sharedInstance.retrieveExistingOrCreateNewEpisode(mediaUrlString)
                        } else {
                            break
                        }
                        
                        if let title = episodeDict["title"] as? String {
                            episode.title = title
                        }
                        
                        podcast.addEpisodeObject(episode)
                    }
                    
                    // TODO: add a retrieveExistingOrCreateNewClip function and use it below. We'll need to have a unique identifier for clips...
                    let clip = CoreDataHelper.sharedInstance.insertManagedObject("Clip") as! Clip
                    
                    if let title = playlistItem["title"] as? String {
                        clip.title = title
                    }
                    
                    if let duration = playlistItem["duration"] as? Int {
                        clip.duration = duration
                    }
                    
                    if let startTime = playlistItem["startTime"] as? Int {
                        clip.startTime = startTime
                    }
                    
                    if let endTime = playlistItem["endTime"] as? Int {
                        clip.endTime = endTime
                    }
                    
                    episode.addClipObject(clip)
                    
                    playlist.addClipObject(clip)
                }
                // Else treat as an episode
                else {
                    if let podcastDict = playlistItem["podcast"] {
                        if let feedURLString = podcastDict["feedURL"] as? String {
                            podcast = CoreDataHelper.sharedInstance.retrieveExistingOrCreateNewPodcast(feedURLString)
                            podcast.feedURL = feedURLString
                        } else {
                            break
                        }
                        
                        if let title = podcastDict["title"] as? String {
                            podcast.title = title
                        }
                        
                        if let imageURL = podcastDict["imageURL"] as? String {
                            if podcast.imageURL == nil {
                                podcast.imageURL = imageURL
                            }
                        }
                    }
                    
                    if let mediaUrlString = playlistItem["mediaURL"] as? String {
                        episode = CoreDataHelper.sharedInstance.retrieveExistingOrCreateNewEpisode(mediaUrlString)
                    } else {
                        break
                    }
                    
                    if let title = playlistItem["title"] as? String {
                        episode.title = title
                    }
                    
                    if let duration = playlistItem["duration"] as? Int {
                        episode.duration = duration
                    }
                    
                    podcast.addEpisodeObject(episode)
                    
                    playlist.addEpisodeObject(episode)
                }
            }
        }
        
        return playlist
    }
    
    static func playlistToJSON(playlist:Playlist) -> Dictionary<String,AnyObject>? {
        var JSONDict = Dictionary<String,AnyObject>()
        JSONDict["playlistTitle"] = playlist.title
        JSONDict["playlistItems"] = playlist.playlistItems

        return JSONDict
    }
    
    func clipToPlaylistItemJSON(clip:Clip) -> Dictionary<String,AnyObject> {
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
    
    func episodeToPlaylistItemJSON(episode:Episode) -> Dictionary<String,AnyObject> {
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
    
    func createDefaultPlaylists() {
        // If no playlists are saved, then create the "My Clips" and "My Episodes" playlists
    
        if playlists.count < 1 {
            let myEpisodesPlaylist = CoreDataHelper.sharedInstance.insertManagedObject("Playlist") as! Playlist
            myEpisodesPlaylist.title = Constants.kMyEpisodesPlaylist
            savePlaylist(myEpisodesPlaylist)
            
            let myClipsPlaylist = CoreDataHelper.sharedInstance.insertManagedObject("Playlist") as! Playlist
            myClipsPlaylist.title = Constants.kMyClipsPlaylist
            savePlaylist(myClipsPlaylist)
        }
    }
    
    func addItemToPlaylist(playlist: Playlist, clip: Clip?, episode: Episode?) {
        if let c = clip {
            playlist.addClipObject(c)
            
        }
        
        if let e = episode  {
            playlist.addEpisodeObject(e)
        }
        
        SavePlaylistToServer(playlist: playlist, newPlaylist:(playlist.playlistId == nil), completionBlock: { (response) -> Void in
            playlist.url = response["url"] as? String
            
            CoreDataHelper.sharedInstance.saveCoreData(nil)
            
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                NSNotificationCenter.defaultCenter().postNotificationName(Constants.kItemAddedToPlaylistNotification, object: nil)
            })

            }) { (error) -> Void in
                print("Not saved to server. Error: ", error?.localizedDescription)
            }.call()
    }
    
    func savePlaylist(playlist: Playlist) {
        SavePlaylistToServer(playlist: playlist, newPlaylist:(playlist.playlistId == nil), completionBlock: { (response) -> Void in
            
            playlist.playlistId = response["_id"] as? String
            playlist.url = response["url"] as? String
            
            CoreDataHelper.sharedInstance.saveCoreData(nil)
            
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                NSNotificationCenter.defaultCenter().postNotificationName(Constants.kRefreshAddToPlaylistTableDataNotification, object: nil)
            })
            
            }) { (error) -> Void in
                print("Not saved to server. Error: ", error?.localizedDescription)
            }.call()
    }
    
    
}