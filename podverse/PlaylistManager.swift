//
//  PlaylistManager.swift
//  podverse
//
//  Created by Kreon on 2/28/16.
//  Copyright © 2016 Mitchell Downey. All rights reserved.
//

import UIKit
import CoreData

protocol PlaylistManagerDelegate {
    func playlistAddedByUrl()
    func itemAddedToPlaylist()
    func didSavePlaylist()
}

final class PlaylistManager {

    static let sharedInstance = PlaylistManager()
    var delegate:PlaylistManagerDelegate?
    
    func addPlaylistByUrlString(urlString: String) {
        var urlComponentArray = urlString.componentsSeparatedByString("/")
        let playlistId = urlComponentArray[4]
        if urlComponentArray[3] == "playlist" {
            urlComponentArray[3] = "pl"
        }
        
        if urlComponentArray[4].characters.contains("#") {
            var idComponentArray = urlComponentArray[4].componentsSeparatedByString("#")
            urlComponentArray[4] = idComponentArray[0]
        }
        
        if (urlComponentArray[0] == "http:" || urlComponentArray[0] == "https:") && (urlComponentArray[1] == "") && (urlComponentArray[2] == "podverse.tv") && (urlComponentArray[3] == "pl") {
                GetPlaylistFromServer(playlistId: playlistId, completionBlock: { (response) -> Void in
                    
                        let moc = CoreDataHelper.sharedInstance.backgroundContext
                        var playlist = CoreDataHelper.retrieveExistingOrCreateNewPlaylist(playlistId, moc:moc)
                    playlist = PlaylistManager.JSONToPlaylist(playlist, JSONDict: response, moc:moc)
                    
                        CoreDataHelper.saveCoreData(moc, completionBlock:{ (finished) in
                            dispatch_async(dispatch_get_main_queue()) {
                                PlaylistManager.sharedInstance.delegate?.playlistAddedByUrl()
                            }
                        })
                }) { (error) -> Void in
                        print("Error y'all \(error?.localizedDescription)")
                }.call()
        } else {
            print("Error: invalid URL")
        }
        
    }
    
    func refreshPlaylists(completion:()->Void) {
        let dispatchGroup = dispatch_group_create()
        let managedObjectContext = CoreDataHelper.sharedInstance.backgroundContext
        let playlists = CoreDataHelper.fetchEntities("Playlist", predicate: nil, moc: managedObjectContext) as! [Playlist]
        for playlist in playlists {
            if let playlistId = playlist.playlistId {
                dispatch_group_enter(dispatchGroup)
                GetPlaylistFromServer(playlistId: playlistId, completionBlock: { (response) -> Void in
                    var playlist = CoreDataHelper.retrieveExistingOrCreateNewPlaylist(playlistId, moc:managedObjectContext)
                    playlist = PlaylistManager.JSONToPlaylist(playlist, JSONDict: response, moc: managedObjectContext)
                    
                    CoreDataHelper.saveCoreData(managedObjectContext, completionBlock:{ (finished) in
                        print("Playlist refreshed")
                        dispatch_group_leave(dispatchGroup)
                    })
                    
                }) { (error) -> Void in
                    print("Error y'all \(error?.localizedDescription)")
                }.call()
            }
        }
        
        dispatch_group_notify(dispatchGroup, dispatch_get_main_queue()) { () -> Void in
            completion()
        }
    }
    
    static func JSONToPlaylist(playlist:Playlist, JSONDict:Dictionary<String,AnyObject>, moc:NSManagedObjectContext) -> Playlist {
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
            if playlistItems.count != playlist.allItems.count {
                playlist.episodes = NSSet()
                playlist.clips = NSSet()
                for playlistItem in playlistItems {
                    var podcast: Podcast!
                    var episode: Episode!
                    
                    // If the episode property has a value, then treat as a clip
                    if playlistItem["episode"] != nil {
                        if let podcastDict = playlistItem["podcast"] {
                            if let feedURLString = podcastDict["feedURL"] as? String {
                                podcast = CoreDataHelper.retrieveExistingOrCreateNewPodcast(feedURLString, moc:moc)
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
                                episode = CoreDataHelper.retrieveExistingOrCreateNewEpisode(mediaUrlString, moc:moc)
                                episode.mediaURL = mediaUrlString
                            } else {
                                break
                            }
                            
                            if let title = episodeDict["title"] as? String {
                                episode.title = title
                            }
                            
                            if let duration = episodeDict["duration"] as? Int {
                                episode.duration = duration
                            }
                            
                            podcast.addEpisodeObject(episode)
                        }
                        
                        // TODO: add a retrieveExistingOrCreateNewClip function and use it below. We'll need to have a unique identifier for clips...
                        let clip = CoreDataHelper.insertManagedObject("Clip", moc:moc) as! Clip
                        
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
                                podcast = CoreDataHelper.retrieveExistingOrCreateNewPodcast(feedURLString, moc:moc)
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
                            episode = CoreDataHelper.retrieveExistingOrCreateNewEpisode(mediaUrlString, moc:moc)
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
        }
        
        return playlist
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
        episodeDict["duration"] = clip.episode.duration
        
        if let pubDate = clip.episode.pubDate {
            episodeDict["pubDate"] = PVUtility.formatDateToString(pubDate)
        }
        JSONDict["episode"] = episodeDict
        
        var podcastDict = Dictionary<String,AnyObject>()
        podcastDict["title"] = clip.episode.podcast.title
        podcastDict["imageURL"] = clip.episode.podcast.imageURL
        podcastDict["feedURL"] = clip.episode.podcast.feedURL

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
        podcastDict["feedURL"] = episode.podcast.feedURL
        
        JSONDict["podcast"] = podcastDict
        
        return JSONDict
    }
    
    func createDefaultPlaylists() {
        // If no playlists are saved, then create the "My Clips" and "My Episodes" playlists
        let moc = CoreDataHelper.sharedInstance.backgroundContext
        let fetchRequest = NSFetchRequest()
        let entityDescription = NSEntityDescription.entityForName("Playlist" as String, inManagedObjectContext: moc)
        fetchRequest.entity = entityDescription
        
        if moc.countForFetchRequest(fetchRequest, error: nil) < 1 {
            let myEpisodesPlaylist = CoreDataHelper.insertManagedObject("Playlist", moc:moc) as! Playlist
            myEpisodesPlaylist.title = Constants.kMyEpisodesPlaylist
            self.savePlaylist(myEpisodesPlaylist, moc:moc)
            
            let myClipsPlaylist = CoreDataHelper.insertManagedObject("Playlist", moc:moc) as! Playlist
            myClipsPlaylist.title = Constants.kMyClipsPlaylist
            self.savePlaylist(myClipsPlaylist, moc:moc)
        }
    }
    
    func addItemToPlaylist(playlist: Playlist, clip: Clip?, episode: Episode?,  moc:NSManagedObjectContext?) {
        if let c = clip {
            playlist.addClipObject(c)
        }
        
        if let e = episode  {
            playlist.addEpisodeObject(e)
        }
        
        SavePlaylistToServer(playlist: playlist, newPlaylist:(playlist.playlistId == nil), completionBlock: { (response) -> Void in
            if let managedObjectContext = moc {
                let playlist = CoreDataHelper.fetchEntityWithID(playlist.objectID, moc: managedObjectContext) as! Playlist
                playlist.url = response["url"] as? String
                CoreDataHelper.saveCoreData(managedObjectContext, completionBlock: { (saved) in
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        NSNotificationCenter.defaultCenter().postNotificationName(Constants.kItemAddedToPlaylistNotification, object: nil)
                        self.delegate?.itemAddedToPlaylist()
                    })
                })
            }
        }) { (error) -> Void in
            print("Not saved to server. Error: ", error?.localizedDescription)
            CoreDataHelper.saveCoreData(moc, completionBlock: nil)
        }.call()
    }
    
    func savePlaylist(playlist: Playlist, moc:NSManagedObjectContext) {
        let playlist = playlist
        SavePlaylistToServer(playlist: playlist, newPlaylist:(playlist.playlistId == nil), completionBlock: { (response) -> Void in
            playlist.playlistId = response["_id"] as? String
            playlist.url = response["url"] as? String
            
                CoreDataHelper.saveCoreData(moc, completionBlock: { (saved) -> Void in
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        self.delegate?.didSavePlaylist()
                    })

                })
            
        }) { (error) -> Void in
            print("Not saved to server. Error: ", error?.localizedDescription)
        }.call()
    }
    
    
}