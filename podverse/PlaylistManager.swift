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
                    guard let dictResponse = response as? Dictionary<String,AnyObject> else {
                        return
                    }
                    let moc = CoreDataHelper.sharedInstance.backgroundContext
                    var playlist = CoreDataHelper.retrieveExistingOrCreateNewPlaylist(playlistId, moc:moc)
                playlist = PlaylistManager.JSONToPlaylist(playlist, JSONDict: dictResponse, moc:moc)
                
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
        // TODO: there is redundancy when we always run getMyPlaylistsFromServer then run refreshPlaylists in the completionBlock. getMyPlaylistsFromServer will ensure the playlists the user has created are synced and up-to-date locally on the device, whereas refreshPlaylists will ensure that ALL playlists (including other people's who the user is subscribed to) are up-to-date locally on the device. This means the user will always have their own playlists refreshed twice.
        getMyPlaylistsFromServer({
            let dispatchGroup = dispatch_group_create()
            let managedObjectContext = CoreDataHelper.sharedInstance.backgroundContext
            let playlists = CoreDataHelper.fetchEntities("Playlist", predicate: nil, moc: managedObjectContext) as! [Playlist]
            for playlist in playlists {
                if let id = playlist.id {
                    dispatch_group_enter(dispatchGroup)
                    GetPlaylistFromServer(playlistId: id, completionBlock: { (response) -> Void in
                        guard let dictResponse = response as? Dictionary<String,AnyObject> else {
                            return
                        }
                        var playlist = CoreDataHelper.retrieveExistingOrCreateNewPlaylist(id, moc:managedObjectContext)
                        playlist = PlaylistManager.JSONToPlaylist(playlist, JSONDict: dictResponse, moc: managedObjectContext)
                        
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

        })
    }
    
    static func JSONToPlaylist(playlist:Playlist, JSONDict:Dictionary<String,AnyObject>, moc:NSManagedObjectContext) -> Playlist {
        if let title = JSONDict["playlistTitle"] as? String {
            playlist.title = title
        }
        
        if let podverseURL = JSONDict["podverseURL"] as? String {
            playlist.podverseURL = podverseURL
        }
        
        if let playlistId = JSONDict["_id"] as? String {
            playlist.id = playlistId
        }
        
//        if let isPublic = JSONDict["isPublic"] {
//            playlist.isPublic = isPublic.boolValue
//        }
        
        if let isMyEpisodes = JSONDict["isMyEpisodes"] {
            playlist.isMyEpisodes = isMyEpisodes.boolValue
        }
        
        if let isMyClips = JSONDict["isMyClips"] {
            playlist.isMyClips = isMyClips.boolValue
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
                            episode.mediaURL = mediaUrlString
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
        
        if let userId = NSUserDefaults.standardUserDefaults().stringForKey("userId") {
            let myEpisodesPredicate = NSPredicate(format: "isMyEpisodes == %@", true)
            let myEpisodesArray = CoreDataHelper.fetchEntities("Playlist", predicate: myEpisodesPredicate, moc:moc) as! [Playlist]
            if myEpisodesArray.count < 1 {
                let myEpisodesPlaylist = CoreDataHelper.insertManagedObject("Playlist", moc:moc) as! Playlist
                myEpisodesPlaylist.title = Constants.kMyEpisodesPlaylist
                myEpisodesPlaylist.isMyEpisodes = true
                myEpisodesPlaylist.ownerId = userId
                self.savePlaylist(myEpisodesPlaylist, moc:moc)
            }
            
            let myClipsPredicate = NSPredicate(format: "isMyClips == %@", true)
            let myClipsArray = CoreDataHelper.fetchEntities("Playlist", predicate: myClipsPredicate, moc:moc) as! [Playlist]
            if myClipsArray.count < 1 {
                let myClipsPlaylist = CoreDataHelper.insertManagedObject("Playlist", moc:moc) as! Playlist
                myClipsPlaylist.title = Constants.kMyClipsPlaylist
                myClipsPlaylist.isMyClips = true
                myClipsPlaylist.ownerId = userId
                self.savePlaylist(myClipsPlaylist, moc:moc)
            }
            
            NSUserDefaults.standardUserDefaults().setBool(true, forKey: "DefaultPlaylistsCreated")
        }
    }
    
    func getMyPlaylistsFromServer(completion:()->Void) {
        // TODO
        //        if let userId = NSUserDefaults.standardUserDefaults().stringForKey("userId") {
//            GetPlaylistsByUserIdFromServer(userId: userId, completionBlock: { (response) -> Void in
//                
//                let dispatchGroup = dispatch_group_create()
//                guard let playlistsArray = response as? [Dictionary<String,AnyObject>] else {
//                    return
//                }
//                
//                for playlistDict in playlistsArray {
//                    if let playlistId = playlistDict["_id"] as? String {
//                        dispatch_group_enter(dispatchGroup)
//                        let moc = CoreDataHelper.sharedInstance.backgroundContext
//                        var playlist = CoreDataHelper.retrieveExistingOrCreateNewPlaylist(playlistId, moc: moc)
//                        playlist = PlaylistManager.JSONToPlaylist(playlist, JSONDict: playlistDict, moc: moc)
//                        CoreDataHelper.saveCoreData(moc, completionBlock:{ (finished) in
//                            dispatch_group_leave(dispatchGroup)
//                        })
//                    }
//                }
//                dispatch_group_notify(dispatchGroup, dispatch_get_main_queue()) { () -> Void in
//                    completion()
//                }
//            }) { (error) -> Void in
//                // TODO: add error handling
//                print(error)
//            }.call()
//        }
    }
    
    func addItemToPlaylist(playlist: Playlist, clip: Clip?, episode: Episode?,  moc:NSManagedObjectContext?) {
        if let c = clip {
            playlist.addClipObject(c)
        }
        
        if let e = episode  {
            playlist.addEpisodeObject(e)
        }
        
        SavePlaylistToServer(playlist: playlist, newPlaylist:(playlist.id == nil), completionBlock: { (response) -> Void in
            if let managedObjectContext = moc {
                let playlist = CoreDataHelper.fetchEntityWithID(playlist.objectID, moc: managedObjectContext) as! Playlist
                guard let dictResponse = response as? Dictionary<String,AnyObject> else {
                    return
                }
                
                playlist.podverseURL = dictResponse["podverseURL"] as? String
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
        SavePlaylistToServer(playlist: playlist, newPlaylist:(playlist.id == nil), completionBlock: { (response) -> Void in
            guard let dictResponse = response as? Dictionary<String,AnyObject> else {
                return
            }
            playlist.id = dictResponse["id"] as? String
            playlist.podverseURL = dictResponse["podverseURL"] as? String
            
            if let userId = NSUserDefaults.standardUserDefaults().stringForKey("userId") {
                playlist.ownerId = userId
            }
            
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