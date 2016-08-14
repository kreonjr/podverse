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
    @NSManaged var id: String
    @NSManaged var podverseURL: String?
    
    @NSManaged var ownerId: String?

    @NSManaged var title: String?
    @NSManaged var startTime: NSNumber
    @NSManaged var endTime: NSNumber?

    @NSManaged var dateCreated: NSDate?
    @NSManaged var lastUpdated: NSDate?
    
    // TODO: how do we add this enumerator?
    // @NSManaged var sharePermission: NSEnumerator = ["isPublic", "isSharableWithLink", "isPrivate"]
    
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
