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
    
    func addEpisodeObject(value: Episode) {
        self.mutableSetValueForKey("episodes").addObject(value)
    }
    
    func addClipObject(value: Clip) {
        self.mutableSetValueForKey("clips").addObject(value)
    }
}
