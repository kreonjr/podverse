//
//  Clip.swift
//  
//
//  Created by Mitchell Downey on 7/13/15.
//
//

import Foundation
import CoreData
@objc(Clip)

class Clip: NSManagedObject {
    @NSManaged var mediaRefId: String
    @NSManaged var podverseURL: String?
    
    @NSManaged var ownerId: String
    @NSManaged var ownerName: String?

    @NSManaged var title: String?
    @NSManaged var startTime: NSNumber
    @NSManaged var endTime: NSNumber?

    @NSManaged var dateCreated: NSDate?
    @NSManaged var lastUpdated: NSDate?
    
    // TODO: how do we add this enumerator?
    // @NSManaged var sharePermission: NSEnumerator = ["isPublic", "isSharableWithLink", "isPrivate"]
    
    // TODO: I'm not sure what to name this one
    @NSManaged var serverEpisodeId: NSNumber
    
    @NSManaged var episode: Episode
    @NSManaged var playlists: NSSet?
    
    var duration: NSNumber? {
        get {
            var duration: NSNumber?
            
            if let eTime = endTime {
                duration = NSNumber(integer: eTime.integerValue - startTime.integerValue)
            }
            
            return duration
        }
    }
}
