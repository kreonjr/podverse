//
//  PVPlaylister.swift
//  podverse
//
//  Created by Mitchell Downey on 1/31/16.
//  Copyright © 2016 Mitchell Downey. All rights reserved.
//

import UIKit
import CoreData

class PVPlaylister: NSObject {
    
    static let sharedInstance = PVPlaylister()
    
    var mySavedPodcastsPlaylist:Playlist?
    var mySavedEpisodesPlaylist:Playlist?
    var mySavedClipsPlaylist:Playlist?
    var allPlaylists: [Playlist]?
    
    override init() {
        super.init()
        mySavedPodcastsPlaylist = retrieveSavedPodcastsPlaylist()
        mySavedEpisodesPlaylist = retrieveSavedEpisodesPlaylist()
        mySavedClipsPlaylist = retrieveSavedClipsPlaylist()
        allPlaylists = retrieveAllPlaylists()
    }
    
    func addPodcastToPlaylist(podcast: Podcast) {
        if let playlist = mySavedPodcastsPlaylist {
            playlist.lastUpdated = NSDate()
            playlist.addPodcastObject(podcast)
            CoreDataHelper.saveCoreData(nil)
        }
    }
    
    func addEpisodeToPlaylist(episode: Episode) {
        if let playlist = mySavedEpisodesPlaylist {
            playlist.lastUpdated = NSDate()
            playlist.addEpisodeObject(episode)
            CoreDataHelper.saveCoreData(nil)
        }
    }
    
    func addClipToPlaylist(clip: Clip) {
        if let playlist = mySavedClipsPlaylist {
            playlist.lastUpdated = NSDate()
            playlist.addClipObject(clip)
            CoreDataHelper.saveCoreData(nil)
        }
    }
    
    func retrieveSavedPodcastsPlaylist() -> Playlist {
        let predicate = NSPredicate(format: "title == %@", "My Saved Podcasts")
        let playlistSet = CoreDataHelper.sharedInstance.fetchEntities("Playlist", managedObjectContext: Constants.moc, predicate: predicate) as! [Playlist]
        
        if playlistSet.count > 0 {
            return playlistSet[0]
        } else {
            let playlist = CoreDataHelper.sharedInstance.insertManagedObject("Playlist", managedObjectContext: Constants.moc) as! Playlist
            playlist.title = "My Saved Podcasts"
            CoreDataHelper.saveCoreData(nil)
            return playlist
        }
    }
    
    func retrieveSavedEpisodesPlaylist() -> Playlist {
        let predicate = NSPredicate(format: "title == %@", "My Saved Episodes")
        let playlistSet = CoreDataHelper.sharedInstance.fetchEntities("Playlist", managedObjectContext: Constants.moc, predicate: predicate) as! [Playlist]
        
        if playlistSet.count > 0 {
            return playlistSet[0]
        } else {
            let playlist = CoreDataHelper.sharedInstance.insertManagedObject("Playlist", managedObjectContext: Constants.moc) as! Playlist
            playlist.title = "My Saved Episodes"
            CoreDataHelper.saveCoreData(nil)
            return playlist
        }
    }
    
    func retrieveSavedClipsPlaylist() -> Playlist {
        let predicate = NSPredicate(format: "title == %@", "My Saved Clips")
        let playlistSet = CoreDataHelper.sharedInstance.fetchEntities("Playlist", managedObjectContext: Constants.moc, predicate: predicate) as! [Playlist]
        
        if playlistSet.count > 0 {
            return playlistSet[0]
        } else {
            let playlist = CoreDataHelper.sharedInstance.insertManagedObject("Playlist", managedObjectContext: Constants.moc) as! Playlist
            playlist.title = "My Saved Clips"
            CoreDataHelper.saveCoreData(nil)
            return playlist
        }
    }
    
    func retrieveAllPlaylists() -> [Playlist] {
        let playlistSet = CoreDataHelper.sharedInstance.fetchEntities("Playlist", managedObjectContext: Constants.moc, predicate: nil) as! [Playlist]
        return playlistSet
    }

}
