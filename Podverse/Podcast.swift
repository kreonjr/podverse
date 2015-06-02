//
//  PodcastModel.swift
//  Podverse
//
//  Created by Mitchell Downey on 4/27/15.
//  Copyright (c) 2015 Mitchell Downey. All rights reserved.
//

import Foundation
import UIKit

class Podcast: NSObject {
    
    var title: String = String()
    var summary: String? = String()
    var feedURL: NSURL? = NSURL()
    var itunesAuthor: String? = String()
    var lastPubDate: NSDate? = NSDate()

    var imageURL: NSURL? = NSURL()
    var image: UIImage? = UIImage()
    var itunesImageURL: NSURL? = NSURL()
    var itunesImage: UIImage? = UIImage()
    
    var episodes: [Episode] = [Episode]()
    
}
