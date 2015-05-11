//
//  EpisodeModel.swift
//  Podverse
//
//  Created by Mitchell Downey on 4/27/15.
//  Copyright (c) 2015 Mitchell Downey. All rights reserved.
//

import UIKit

class EpisodeModel: NSObject {

    var title: String = String()
    var summary: String? = String()
    var pubDate: NSDate? = NSDate()
    var duration: NSTimeInterval? = NSTimeInterval()
    var link: NSURL? = NSURL()
    
    var mediaURL: NSURL? = NSURL() // URL to the media file
    var mediaType: String? = String() // type of media file, e.g. mp3 or ogg
    var mediaBytes: Int? = Int() // size of the media file in bytes
    
}
