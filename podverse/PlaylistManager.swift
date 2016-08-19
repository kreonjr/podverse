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

// Retrieve the mediaRef for an episode, THEN add the mediaRefId to the playlist and save to the server
//    static func retrieveEpisodeMediaRefId(episode:Episode, completionBlock:((mediaRefId: String)->Void)?) -> String {
//        
//    }
    
    static func JSONToPlaylist(playlist:Playlist, JSONDict:Dictionary<String,AnyObject>, moc:NSManagedObjectContext) -> Playlist {
        
        if let id = JSONDict["id"] as? String {
            playlist.id = id
        }
        
        if let title = JSONDict["title"] as? String {
            playlist.title = title
        }
        
        if let dateCreated = JSONDict["dateCreated"] as? String {
            playlist.dateCreated = PVUtility.formatStringToDate(dateCreated)
        }
        
        if let lastUpdated = JSONDict["lastUpdated"] as? String {
            playlist.lastUpdated = PVUtility.formatStringToDate(lastUpdated)
        }
        
        //        Save as enum somehow
        //        if let sharePermission = JSONDict["sharePermission"] as? String {
        //            playlist.sharePermission = sharePermission
        //        }
        
        if let isMyEpisodes = JSONDict["isMyEpisodes"] as? Bool {
            playlist.isMyEpisodes = isMyEpisodes
        }
        
        if let isMyClips = JSONDict["isMyClips"] as? Bool {
            playlist.isMyClips = isMyClips
        }
        
        if let podverseURL = JSONDict["podverseURL"] as? String {
            playlist.podverseURL = podverseURL
        }
        
        if let playlistItems = JSONDict["mediaRefs"] as? [Dictionary<String,AnyObject>] {
            if playlistItems.count != playlist.allItems.count {
                
                playlist.episodes = NSSet()
                playlist.clips = NSSet()
                for playlistItem in playlistItems {
                    var podcast: Podcast!
                    var episode: Episode!
                    
                    // If the playlistItem has a zero startTime and no endTime, then handle as an episode
                    if playlistItem["startTime"] as? Int == 0 && playlistItem["endTime"] as? String == nil {
                        
                        guard let e = playlistItem["episode"] as? Dictionary<String,AnyObject> else {
                            break
                        }
                        
                        guard let p = e["podcast"] as? Dictionary<String,AnyObject> else {
                            break
                        }
                        
                        guard let mediaURL = e["mediaURL"] as? String else {
                            break
                        }
                        
                        guard let feedURL = p["feedURL"] as? String else {
                            break
                        }
                        
                        episode = CoreDataHelper.retrieveExistingOrCreateNewEpisode(mediaURL, moc:moc)
                        
                        episode.mediaURL = mediaURL
                        
                        if let title = e["title"] as? String {
                            episode.title = title
                        }
                        
                        if let summary = e["summary"] as? String {
                            episode.summary = summary
                        }
                        
                        if let duration = e["duration"] as? Int {
                            episode.duration = duration
                        }
                        
                        if let guid = e["guid"] as? String {
                            episode.guid = guid
                        }
                        
                        if let link = e["link"] as? String {
                            episode.link = link
                        }
                        
                        if let mediaBytes = e["mediaBytes"] as? Int {
                            episode.mediaBytes = mediaBytes
                        }
                        
                        if let mediaType = e["mediaType"] as? String {
                            episode.mediaType = mediaType
                        }
                        
                        if let pubDate = e["pubDate"] as? String {
                            episode.pubDate = PVUtility.formatStringToDate(pubDate)
                        }
                        
                        podcast = CoreDataHelper.retrieveExistingOrCreateNewPodcast(feedURL, moc:moc)

                        podcast.feedURL = feedURL

                        if let imageURL = p["imageURL"] as? String {
                            podcast.imageURL = imageURL
                        }
                        
                        if let summary = p["summary"] as? String {
                            podcast.summary = summary
                        }
                        
                        if let title = p["title"] as? String {
                            podcast.title = title
                        }
                        
                        if let author = p["author"] as? String {
                            podcast.author = author
                        }
                        
                        if let lastBuildDate = p["lastBuildDate"] as? String {
                            podcast.lastBuildDate = PVUtility.formatStringToDate(lastBuildDate)
                        }
                        
                        if let lastPubDate = p["lastPubDate"] as? String {
                            podcast.lastPubDate = PVUtility.formatStringToDate(lastPubDate)
                        }

                        podcast.addEpisodeObject(episode)

                        playlist.addEpisodeObject(episode)
                    }
                        
                    // Else handle playlistItem as a clip
                    else {
                        
                        if let episodeDict = playlistItem["episode"] as? Dictionary<String,AnyObject> {
                            
                            if let podcastDict = episodeDict["podcast"] as? Dictionary<String,AnyObject> {
                                
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
                        
                        if let mediaRefId = playlistItem["id"] as? String {
                            
                            let clip = CoreDataHelper.retrieveExistingOrCreateNewClip(mediaRefId, moc: moc)
                            
                            clip.mediaRefId = mediaRefId
                            
                            if let startTime = playlistItem["startTime"] as? Int {
                                clip.startTime = startTime
                            }
                            
                            if let endTime = playlistItem["endTime"] as? Int {
                                clip.endTime = endTime
                            }
                            
                            if let title = playlistItem["title"] as? String {
                                clip.title = title
                            }
                            
                            if let ownerId = playlistItem["ownerId"] as? String {
                                clip.ownerId = ownerId
                            }
                            
                            if let dateCreated = playlistItem["dateCreated"] as? String {
                                clip.dateCreated = PVUtility.formatStringToDate(dateCreated)
                            }
                            
                            if let lastUpdated = playlistItem["lastUpdated"] as? String {
                                clip.lastUpdated = PVUtility.formatStringToDate(lastUpdated)
                            }
                            
                            episode.addClipObject(clip)
                            
                            playlist.addClipObject(clip)
                            
                        }
                    
                    }
                }
            }
        }
        
        return playlist
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
        if let userId = NSUserDefaults.standardUserDefaults().stringForKey("userId") {
    GetPlaylistsByUserIdFromServer(userId: userId, completionBlock: { (response) -> Void in
        
        let dispatchGroup = dispatch_group_create()
        guard let playlistsArray = response as? [Dictionary<String,AnyObject>] else {
            return
        }
        
        for playlistDict in playlistsArray {
            if let playlistId = playlistDict["id"] as? String {
                dispatch_group_enter(dispatchGroup)
                let moc = CoreDataHelper.sharedInstance.backgroundContext
                var playlist = CoreDataHelper.retrieveExistingOrCreateNewPlaylist(playlistId, moc: moc)
                playlist = PlaylistManager.JSONToPlaylist(playlist, JSONDict: playlistDict, moc: moc)
                CoreDataHelper.saveCoreData(moc, completionBlock:{ (finished) in
                    dispatch_group_leave(dispatchGroup)
                })
            }
        }
        dispatch_group_notify(dispatchGroup, dispatch_get_main_queue()) { () -> Void in
            completion()
        }
    }) { (error) -> Void in
        // TODO: add error handling
        print(error)
    }.call()
}
    }
    
    func addItemToPlaylist(playlist: Playlist, clip: Clip?, episode: Episode?,  moc:NSManagedObjectContext?) {
        if let c = clip {
            playlist.addClipObject(c)
            savePlaylistToServer(playlist, mediaRefId: c.mediaRefId, moc: moc)
        }
        else if let e = episode {
            SaveEpisodeToServer(episode: e, completionBlock: { (response) in
                guard let mRefId = response["id"] as? String else {
                    return
                }
                
                playlist.addEpisodeObject(e)
                self.savePlaylistToServer(playlist, mediaRefId: mRefId, moc: moc)
            }, errorBlock: { (error) in
                print("Not saved to server. Error: ", error?.localizedDescription)
            }).call()
        }
    }
    
    func savePlaylistToServer(playlist:Playlist, mediaRefId:String, moc:NSManagedObjectContext?) {
        SavePlaylistToServer(playlist: playlist, newPlaylist:(playlist.id == nil), addMediaRefId: mediaRefId, completionBlock: { (response) -> Void in
            if let managedObjectContext = moc {
                var playlist = CoreDataHelper.fetchEntityWithID(playlist.objectID, moc: managedObjectContext) as! Playlist
                guard let dictResponse = response as? Dictionary<String,AnyObject> else {
                    return
                }
                
                if let userId = NSUserDefaults.standardUserDefaults().stringForKey("userId") {
                    playlist.ownerId = userId
                }
                
                playlist = self.syncLocalPlaylistFieldsWithResponse(playlist, dictResponse: dictResponse)
                
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
        var playlist = playlist
        SavePlaylistToServer(playlist: playlist, newPlaylist:(playlist.id == nil), addMediaRefId: nil, completionBlock: { (response) -> Void in
            guard let dictResponse = response as? Dictionary<String,AnyObject> else {
                return
            }
            
            if let userId = NSUserDefaults.standardUserDefaults().stringForKey("userId") {
                playlist.ownerId = userId
            }
            
            playlist = self.syncLocalPlaylistFieldsWithResponse(playlist, dictResponse: dictResponse)
            
            CoreDataHelper.saveCoreData(moc, completionBlock: { (saved) -> Void in
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    self.delegate?.didSavePlaylist()
                })
            })
            
        }) { (error) -> Void in
            print("Not saved to server. Error: ", error?.localizedDescription)
        }.call()
    }
    
    func syncLocalPlaylistFieldsWithResponse(playlist: Playlist, dictResponse: Dictionary<String,AnyObject>) -> Playlist {
        
        // Save all the response fields to the local playlist for good measure
        
        if let id = dictResponse["id"] as? String {
            playlist.id = id
        }
        
        if let title = dictResponse["title"] as? String {
            playlist.title = title
        }

        if let dateCreated = dictResponse["dateCreated"] as? String {
            playlist.dateCreated = PVUtility.formatStringToDate(dateCreated)
        }
        
        if let lastUpdated = dictResponse["lastUpdated"] as? String {
            playlist.lastUpdated = PVUtility.formatStringToDate(lastUpdated)
        }

//        Save as enum somehow
//        if let sharePermission = dictResponse["sharePermission"] as? String {
//            playlist.sharePermission = sharePermission
//        }
        
        if let isMyEpisodes = dictResponse["isMyEpisodes"] as? Bool {
            playlist.isMyEpisodes = isMyEpisodes.boolValue
        }

        if let isMyClips = dictResponse["isMyClips"] as? Bool {
            playlist.isMyClips = isMyClips.boolValue
        }
        
        if let podverseURL = dictResponse["podverseURL"] as? String {
            playlist.podverseURL = podverseURL
        }
        
        return playlist
    }
    
    
}