//
//  Podcast.swift
//  
//
//  Created by Mitchell Downey on 7/13/15.
//
//

import Foundation
import CoreData
@objc(Podcast)

class Podcast: NSManagedObject {

    @NSManaged var feedURL: String
    @NSManaged var imageData: NSData?
    @NSManaged var imageThumbData: NSData?
    @NSManaged var imageURL: String?
    @NSManaged var itunesAuthor: String?
    @NSManaged var itunesImage: NSData?
    @NSManaged var itunesImageURL: String?
    @NSManaged var lastBuildDate: NSDate?
    @NSManaged var lastPubDate: NSDate?
    @NSManaged var summary: String?
    @NSManaged var title: String
    @NSManaged var isSubscribed: Bool
    @NSManaged var episodes: NSSet
    var totalClips:Int {
        get {
            var totalClips = 0
            for episode in episodes.allObjects as! [Episode] {
                totalClips += episode.clips.allObjects.count
            }
            
            return totalClips
        }
    }
    
    func addEpisodeObject(value: Episode) {
        self.mutableSetValueForKey("episodes").addObject(value)
    }
    
    func removeEpisodeObject(value: Episode) {
        self.mutableSetValueForKey("episodes").removeObject(value)
    }
}
