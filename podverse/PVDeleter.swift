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
    
    static func deletePlaylistItem(playlist:Playlist, item:AnyObject) {
        playlist.removePlaylistItem(item)
        
        //TODO: Server playlist item deletion
    }
    
}