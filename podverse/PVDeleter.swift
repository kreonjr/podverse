//
//  PVDeleter.swift
//  podverse
//
//  Created by Mitchell Downey on 1/14/16.
//  Copyright © 2016 Mitchell Downey. All rights reserved.
//

import UIKit
import CoreData

class PVDeleter: NSObject {    
    
    static func deletePodcast(podcast: Podcast) {
        let episodesToRemove = podcast.episodes.allObjects as! [Episode]
        
        // Delete each episode from the moc, cancel current downloadTask, and remove episode from the episodeDownloadArray
        for var i = 0; i < episodesToRemove.count; i++ {
            deleteEpisode(episodesToRemove[i],completion: nil)
        }

        CoreDataHelper.sharedInstance.deleteItemFromCoreData(podcast)
    }
    
    static func deleteEpisode(episode: Episode, completion:(()->())? ) {
        // Get the downloadSession, and if there is a downloadSession with a matching taskIdentifier as episode's taskIdentifier, then cancel the downloadSession
        let downloadSession = PVDownloader.sharedInstance.downloadSession
        downloadSession.getTasksWithCompletionHandler { dataTasks, uploadTasks, downloadTasks in
            for episodeDownloadTask in downloadTasks {
                if episodeDownloadTask.taskIdentifier == episode.taskIdentifier {
                    episodeDownloadTask.cancel()
                }
            }
        }
        
        // If the episode is currently in the episodeDownloadArray, then delete the episode from the episodeDownloadArray
        if DLEpisodesList.shared.downloadingEpisodes.contains(episode) {
            let episodeDownloadArrayIndex = DLEpisodesList.shared.downloadingEpisodes.indexOf(episode)
            DLEpisodesList.shared.downloadingEpisodes.removeAtIndex(episodeDownloadArrayIndex!)
        }
        
        // If the episode is currently now playing, then remove the now playing episode, and remove the Player button from the navbar using kPlayerHasNoItem
        if let nowPlayingEpisode = PVMediaPlayer.sharedInstance.nowPlayingEpisode {
            if episode == nowPlayingEpisode {
                PVMediaPlayer.sharedInstance.avPlayer.pause()
                PVMediaPlayer.sharedInstance.nowPlayingEpisode = nil
                NSNotificationCenter.defaultCenter().postNotificationName(Constants.kPlayerHasNoItem, object: nil)
            }
        }
        
        //TODO: is the deleteEpisodeFromDiskWithName redundant because of the deleteItemFromCoreData?
        // Delete the episode from CoreData and the disk, and update the UI
        if let fileName = episode.fileName {
            PVUtility.deleteEpisodeFromDiskWithName(fileName)
        }

        CoreDataHelper.sharedInstance.deleteItemFromCoreData(episode)
    }
    
    // TODO: handle removing clips
    
    static func deletePlaylist(playlist:Playlist, deleteFromServer:Bool) {
        
        // Remove Player button if the now playing episode was one of the playlists episodes or clips
        if let nowPlayingEpisode = PVMediaPlayer.sharedInstance.nowPlayingEpisode {
            if let episodes = playlist.episodes {
                if (episodes.contains{$0 as? Episode == nowPlayingEpisode}) {
                    NSNotificationCenter.defaultCenter().postNotificationName(Constants.kPlayerHasNoItem, object: self, userInfo: nil)
                }
            }
        }
        if let nowPlayingClip = PVMediaPlayer.sharedInstance.nowPlayingClip {
            if let clips = playlist.clips {
                if (clips.contains{$0 as? Clip == nowPlayingClip}) {
                    NSNotificationCenter.defaultCenter().postNotificationName(Constants.kPlayerHasNoItem, object: self, userInfo: nil)
                }
            }
        }
        
        for playlistItem in playlist.allItems {
            playlist.removePlaylistItem(playlistItem)
        }
        
        if deleteFromServer == true {
            SavePlaylistToServer(playlist: playlist, newPlaylist:(playlist.playlistId == nil), completionBlock: { (response) -> Void in
                playlist.title = "This playlist has been deleted"
                playlist.url = response["url"] as? String
                CoreDataHelper.sharedInstance.saveCoreData(nil)
                }) { (error) -> Void in
                    print("Not saved to server. Error: ", error?.localizedDescription)
                }.call()
        }
        
        CoreDataHelper.sharedInstance.deleteItemFromCoreData(playlist)
    }
    
    static func deletePlaylistItem(playlist:Playlist, item:AnyObject) {
        // Remove Player button if the now playing episode was one of the playlists episodes or clips
        if let nowPlayingEpisode = PVMediaPlayer.sharedInstance.nowPlayingEpisode {
            if nowPlayingEpisode == item as? Episode {
                NSNotificationCenter.defaultCenter().postNotificationName(Constants.kPlayerHasNoItem, object: self, userInfo: nil)
            }
        }
        if let nowPlayingClip = PVMediaPlayer.sharedInstance.nowPlayingClip {
            if nowPlayingClip == item as? Clip {
                NSNotificationCenter.defaultCenter().postNotificationName(Constants.kPlayerHasNoItem, object: self, userInfo: nil)
            }
        }
        
        playlist.removePlaylistItem(item)
        
        SavePlaylistToServer(playlist: playlist, newPlaylist:(playlist.playlistId == nil), completionBlock: { (response) -> Void in
            playlist.url = response["url"] as? String
            CoreDataHelper.sharedInstance.saveCoreData(nil)
            }) { (error) -> Void in
                print("Not saved to server. Error: ", error?.localizedDescription)
            }.call()
    }
    
    static func checkIfPodcastShouldBeRemoved(podcast: Podcast, isUnsubscribing: Bool) -> Bool {
        var alsoDelete = true
        
        if isUnsubscribing != true {
            if podcast.isSubscribed == true {
                alsoDelete = false
                return alsoDelete
            }
        }
        
        if let allPlaylists = CoreDataHelper.sharedInstance.fetchEntities("Playlist", predicate: nil) as? [Playlist] {
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
    
}