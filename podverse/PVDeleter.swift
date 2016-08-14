//
//  PVDeleter.swift
//  podverse
//
//  Created by Mitchell Downey on 1/14/16.
//  Copyright © 2016 Mitchell Downey. All rights reserved.
//

import UIKit
import CoreData

class PVDeleter {
    
    static func deletePodcast(podcastID: NSManagedObjectID, completionBlock:(()->Void)?) {
        let moc = CoreDataHelper.sharedInstance.backgroundContext
        let podcast = CoreDataHelper.fetchEntityWithID(podcastID, moc: moc) as! Podcast
        let episodesToRemove = podcast.episodes.allObjects as! [Episode]
        
        // Delete each episode from the moc, cancel current downloadTask, and remove episode from the episodeDownloadArray
        for episode in episodesToRemove {
            let episodeToRemove = CoreDataHelper.fetchEntityWithID(episode.objectID, moc: moc) as! Episode
            PVDeleter.deleteEpisode(episodeToRemove.objectID)
        }

        CoreDataHelper.deleteItemFromCoreData(podcast, moc: moc)
        
        CoreDataHelper.saveCoreData(moc) { (saved) in
            completionBlock?()
        }
    }
    
    static func deleteEpisode(episodeID: NSManagedObjectID) {
        let moc = CoreDataHelper.sharedInstance.backgroundContext
        let episode = CoreDataHelper.fetchEntityWithID(episodeID, moc: moc) as! Episode
        
        // Get the downloadSession, and if there is a downloadSession with a matching taskIdentifier as episode's taskIdentifier, then cancel the downloadSession
        let episodePodcastFeedURL = episode.podcast.feedURL
        let downloadSession = PVDownloader.sharedInstance.downloadSession
        downloadSession.getTasksWithCompletionHandler { dataTasks, uploadTasks, downloadTasks in
            for episodeDownloadTask in downloadTasks {
                if  let _ = DLEpisodesList.shared.downloadingEpisodes.find({ $0.taskIdentifier == episodeDownloadTask.taskIdentifier && $0.podcastRSSFeedURL == episodePodcastFeedURL })  {
                    episodeDownloadTask.cancel()
                }
            }
        }

        // If the episode is currently in the episodeDownloadArray, then delete the episode from the episodeDownloadArray
        DLEpisodesList.removeDownloadingEpisodeWithMediaURL(episode.mediaURL)
        
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            if let tabBarCntrl = (UIApplication.sharedApplication().delegate as! AppDelegate).window?.rootViewController as? UITabBarController {
                if let badgeValue = tabBarCntrl.tabBar.items?[TabItems.Downloads.getIndex()].badgeValue, badgeInt = Int(badgeValue) {
                    tabBarCntrl.tabBar.items?[TabItems.Downloads.getIndex()].badgeValue = "\(badgeInt - 1)"
                    if tabBarCntrl.tabBar.items?[TabItems.Downloads.getIndex()].badgeValue == "0" {
                        tabBarCntrl.tabBar.items?[TabItems.Downloads.getIndex()].badgeValue = nil
                    }
                }
            }
            
            // If the episode is currently now playing, then remove the now playing episode, and remove the Player button from the navbar using kPlayerHasNoItem
            if let nowPlayingEpisode = PVMediaPlayer.sharedInstance.nowPlayingEpisode {
                if episode.objectID == nowPlayingEpisode.objectID {
                    PVMediaPlayer.sharedInstance.avPlayer.pause()
                    PVMediaPlayer.sharedInstance.nowPlayingEpisode = nil
                    NSUserDefaults.standardUserDefaults().removeObjectForKey(Constants.kLastPlayingEpisodeURL)
                    
                    NSNotificationCenter.defaultCenter().postNotificationName(Constants.kPlayerHasNoItem, object: nil)
                }
            }
        })
        
        // Delete the episode from CoreData and the disk, and update the UI
        if let fileName = episode.fileName {
            PVUtility.deleteEpisodeFromDiskWithName(fileName)
            episode.fileName = nil
        }
        
        // If the episode or a clip from the episode is currently a playlistItem in a local playlist, then do not delete the episode item from Core Data
        if checkIfEpisodeShouldBeRemoved(episode) == true {
            CoreDataHelper.deleteItemFromCoreData(episode, moc: moc)
        }
        
        CoreDataHelper.saveCoreData(moc, completionBlock: nil)
    }
    
    // TODO: handle removing clips
    
    static func deletePlaylist(playlist:Playlist, deleteFromServer:Bool) {
        
        // Remove Player button if the now playing episode was one of the playlists episodes or clips
        if let nowPlayingEpisode = PVMediaPlayer.sharedInstance.nowPlayingEpisode {
            if let episodes = playlist.episodes?.allObjects as? [Episode] {
                if (episodes.contains{$0.objectID == nowPlayingEpisode.objectID}) {
                    PVMediaPlayer.sharedInstance.avPlayer.pause()
                    PVMediaPlayer.sharedInstance.nowPlayingEpisode = nil
                    
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        NSNotificationCenter.defaultCenter().postNotificationName(Constants.kPlayerHasNoItem, object: nil)
                    })
                }
            }
        }
        if let nowPlayingClip = PVMediaPlayer.sharedInstance.nowPlayingClip {
            if let clips = playlist.clips?.allObjects as? [Clip] {
                if (clips.contains{$0.objectID == nowPlayingClip.objectID}) {
                    PVMediaPlayer.sharedInstance.avPlayer.pause()
                    PVMediaPlayer.sharedInstance.nowPlayingClip = nil
                    
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        NSNotificationCenter.defaultCenter().postNotificationName(Constants.kPlayerHasNoItem, object: nil)
                    })
                }
            }
        }
        
        for playlistItem in playlist.allItems {
            playlist.removePlaylistItem(playlistItem)
        }
        
        if deleteFromServer == true {
            SavePlaylistToServer(playlist: playlist, completionBlock: { (response) -> Void in
                playlist.title = "This playlist has been deleted"
                playlist.podverseURL = response["podverseURL"] as? String
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    CoreDataHelper.saveCoreData(playlist.managedObjectContext, completionBlock: nil)
                })
                
                }) { (error) -> Void in
                    print("Not saved to server. Error: ", error?.localizedDescription)
                }.call()
        }
        
        CoreDataHelper.deleteItemFromCoreData(playlist, moc:playlist.managedObjectContext)
        
        CoreDataHelper.saveCoreData(playlist.managedObjectContext, completionBlock: nil)
    }
    
    static func deletePlaylistItem(playlist:Playlist, item:AnyObject) {
        // Remove Player button if the now playing episode was one of the playlists episodes or clips
        if let nowPlayingEpisode = PVMediaPlayer.sharedInstance.nowPlayingEpisode {
            if nowPlayingEpisode.objectID == (item as? Episode)?.objectID {
                PVMediaPlayer.sharedInstance.avPlayer.pause()
                PVMediaPlayer.sharedInstance.nowPlayingEpisode = nil
                
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    NSNotificationCenter.defaultCenter().postNotificationName(Constants.kPlayerHasNoItem, object: nil)
                })
            }
        }
        if let nowPlayingClip = PVMediaPlayer.sharedInstance.nowPlayingClip {
            if nowPlayingClip.objectID == (item as? Clip)?.objectID {
                PVMediaPlayer.sharedInstance.avPlayer.pause()
                PVMediaPlayer.sharedInstance.nowPlayingClip = nil
                
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    NSNotificationCenter.defaultCenter().postNotificationName(Constants.kPlayerHasNoItem, object: nil)
                })
            }
        }
        
        playlist.removePlaylistItem(item)
        
        SavePlaylistToServer(playlist: playlist, newPlaylist:(playlist.id == nil), completionBlock: { (response) -> Void in
            playlist.podverseURL = response["podverseURL"] as? String
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                CoreDataHelper.saveCoreData(playlist.managedObjectContext, completionBlock: nil)
            })
        }) { (error) -> Void in
                print("Not saved to server. Error: ", error?.localizedDescription)
        }.call()
    }
    
    static func checkIfPodcastShouldBeRemoved(podcast: Podcast, isUnsubscribing: Bool, moc:NSManagedObjectContext?) -> Bool {
        guard let moc = moc else {
            return true
        }
        
        var alsoDelete = true
        
        if isUnsubscribing != true {
            if podcast.isSubscribed == true {
                alsoDelete = false
                return alsoDelete
            }
        }
        
        if let allPlaylists = CoreDataHelper.fetchEntities("Playlist", predicate: nil, moc:moc) as? [Playlist] {
            outerLoop: for playlist in allPlaylists {
                for item in playlist.allItems {
                    if let episode = item as? Episode {
                        for podcastEpisode in podcast.episodes {
                            if (podcastEpisode as! Episode) == episode {
                                alsoDelete = false
                                break outerLoop
                            }
                        }
                    }
                    else if let clip = item as? Clip {
                        for podcastEpisode in podcast.episodes.allObjects {
                            for podcastClip in (podcastEpisode as! Episode).clips {
                                if clip == (podcastClip as! Clip) {
                                    alsoDelete = false
                                    break outerLoop
                                }
                            }
                        }
                    }
                }
            }
        }
        
        return alsoDelete
    }
    
    static func checkIfEpisodeShouldBeRemoved(episode: Episode) -> Bool {
        let moc = CoreDataHelper.sharedInstance.managedObjectContext
        var alsoDelete = true
        
        if episode.podcast.isSubscribed == true {
            alsoDelete = false
            return alsoDelete
        }
        
        if let allPlaylists = CoreDataHelper.fetchEntities("Playlist", predicate: nil, moc: moc) as? [Playlist] {
            outerLoop: for playlist in allPlaylists {
                for item in playlist.allItems {
                    if let episode = item as? Episode {
                        for ep in episode.podcast.episodes {
                            if (ep as! Episode) == episode {
                                alsoDelete = false
                                break outerLoop
                            }
                        }
                    }
                    else if let clip = item as? Clip {
                        for ep in episode.podcast.episodes {
                            for cl in (ep as! Episode).clips {
                                if clip == (cl as! Clip) {
                                    alsoDelete = false
                                    break outerLoop
                                }
                            }
                        }
                    }
                }
            }
        }
        
        return alsoDelete
    }
    
}