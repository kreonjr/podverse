//
//  Playlist.swift
//

import Foundation
import CoreData
@objc(Playlist)

class Playlist: NSManagedObject {
    
    @NSManaged var id:String?
    @NSManaged var slug: String?
    @NSManaged var podverseURL: String?
    
    @NSManaged var ownerId:String
    
    @NSManaged var title: String?
    
    @NSManaged var dateCreated: NSDate?
    @NSManaged var lastUpdated: NSDate?
    
    // TODO: how do we add this enumerator?
    // @NSManaged var sharePermission: NSEnumerator = ["isPublic", "isSharableWithLink", "isPrivate"]
    
    @NSManaged var isMyEpisodes: Bool
    @NSManaged var isMyClips: Bool

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
        
        let alsoDeletePodcast = PVDeleter.checkIfPodcastShouldBeRemoved(episode.podcast, isUnsubscribing: false, moc:episode.managedObjectContext)
        
        if alsoDeletePodcast {
            PVDeleter.deletePodcast(episode.podcast.objectID, completionBlock: nil)
        }
        
    }
    
    private func removeClipObject(clip: Clip) {
        self.mutableSetValueForKey("clips").removeObject(clip)
        
        let alsoDeletePodcast = PVDeleter.checkIfPodcastShouldBeRemoved(clip.episode.podcast, isUnsubscribing: false, moc:clip.managedObjectContext)
        
        if alsoDeletePodcast {
            PVDeleter.deletePodcast(clip.episode.podcast.objectID, completionBlock: nil)
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
