//
//  Playlist.swift
//

import Foundation
import CoreData
@objc(Playlist)

class Playlist: NSManagedObject {
    @NSManaged var playlistItems: [Dictionary<String,AnyObject>]
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
    
    var totalItems:Int {
        get {
            return self.allItems.count

        }
    }
    
    func addEpisodeObject(value: Episode) {
        self.mutableSetValueForKey("episodes").addObject(value)
    }
    
    func addClipObject(value: Clip) {
        self.mutableSetValueForKey("clips").addObject(value)
    }
}
