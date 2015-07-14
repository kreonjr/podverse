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

    @NSManaged var endTime: NSNumber?
    @NSManaged var startTime: NSNumber
    @NSManaged var title: String?
    @NSManaged var episode: Episode
    @NSManaged var podcast: Podcast

}
