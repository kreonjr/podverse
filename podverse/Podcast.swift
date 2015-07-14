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
    @NSManaged var image: NSData?
    @NSManaged var imageURL: String?
    @NSManaged var itunesAuthor: String?
    @NSManaged var itunesImage: NSData?
    @NSManaged var itunesImageURL: String?
    @NSManaged var lastPubDate: NSDate?
    @NSManaged var summary: String?
    @NSManaged var title: String
    @NSManaged var isSubscribed: NSNumber
    @NSManaged var clips: NSSet
    @NSManaged var episodes: NSSet
    
    func addEpisodeObject(value: Episode) {
        self.mutableSetValueForKey("episodes").addObject(value)
    }

}
