//
//  Episode.swift
//  
//
//  Created by Mitchell Downey on 7/13/15.
//
//

import Foundation
import CoreData
@objc(Episode)

class Episode: NSManagedObject {
    @NSManaged var downloadComplete: Bool
    @NSManaged var downloadProgress: NSNumber?
    @NSManaged var duration: NSNumber?
    @NSManaged var fileName: String?
    @NSManaged var guid: String?
    @NSManaged var link: String?
    @NSManaged var mediaBytes: NSNumber?
    @NSManaged var mediaType: String?
    @NSManaged var mediaURL: String?
    @NSManaged var playbackPosition: NSNumber?
    @NSManaged var pubDate: NSDate?
    @NSManaged var summary: String?
    @NSManaged var taskIdentifier: NSNumber?
    @NSManaged var taskResumeData: NSData?
    @NSManaged var title: String?
    @NSManaged var uuid: String?
    @NSManaged var clips: NSSet
    @NSManaged var podcast: Podcast
}
