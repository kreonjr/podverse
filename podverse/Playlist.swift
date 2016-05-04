//
//  Playlist.swift
//

import Foundation
import CoreData
@objc(Playlist)

class Playlist: NSManagedObject {
    @NSManaged var title: String
    @NSManaged var url: String?
    @NSManaged var isPublic: Bool
    @NSManaged var lastUpdated: NSDate?
    @NSManaged var playlistId:String?

    @NSManaged var episodes: NSSet?
    @NSManaged var clips: NSSet?
    
    var allItems: [AnyObject] {
        get {
            var allItemsArray: [AnyObject] = []
            if let episodes = episodes {
                for episode in episodes {
                    allItemsArray.append(episode)
                }
            }
            if let clips = clips {
                for clip in clips {
                    allItemsArray.append(clip)
                }
            }
            
            return allItemsArray
        }
    }
    
    func addEpisodeObject(value: Episode) {
        self.mutableSetValueForKey("episodes").addObject(value)
    }
    
    func addClipObject(value: Clip) {
        self.mutableSetValueForKey("clips").addObject(value)
    }
    
    private func removeEpisodeObject(episode: Episode) {
        self.mutableSetValueForKey("episodes").removeObject(episode)
        
        let alsoDeletePodcast = PVDeleter.checkIfPodcastShouldBeRemoved(episode.podcast, isUnsubscribing: false)
        
        if alsoDeletePodcast {
            PVDeleter.deletePodcast(episode.podcast)
        }
        
    }
    
    private func removeClipObject(value: Clip) {
        self.mutableSetValueForKey("clips").removeObject(value)
        
        let alsoDeletePodcast = PVDeleter.checkIfPodcastShouldBeRemoved(value.episode.podcast, isUnsubscribing: false)
        
        if alsoDeletePodcast {
            PVDeleter.deletePodcast(value.episode.podcast)
        }
    }
    
    func removePlaylistItem(value: AnyObject) {
        
        
        if let episode = value as? Episode {
            removeEpisodeObject(episode)
        }
        else if let clip = value as? Clip {
            removeClipObject(clip)
        }
        else {
            print("Object not a playlist item")
        }
    }
    

}
