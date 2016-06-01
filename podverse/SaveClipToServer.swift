//
//  SaveClipToServer.swift
//  podverse
//
//  Created by Kreon on 1/23/16.
//  Copyright © 2016 Mitchell Downey. All rights reserved.
//

import UIKit

class SaveClipToServer:WebService {
    internal init(clip:Clip, completionBlock: (response: Dictionary<String, AnyObject>) -> Void, errorBlock: (error: NSError?) -> Void) {
        super.init(name:"c", completionBlock: completionBlock, errorBlock: errorBlock)
        
        let userId = NSUserDefaults.standardUserDefaults().stringForKey("userEmail")
        
        setHttpMethod(.METHOD_POST)
        addHeaderWithKey("Content-Type", value: "application/json")
        addParamWithKey("podcast", value: ["title":clip.episode.podcast.title ?? "",
                                           "imageURL":clip.episode.podcast.imageURL ?? ""])
        addParamWithKey("episode", value: ["title":clip.episode.title ?? "",
                                           "pubDate":PVUtility.formatDateToString(clip.episode.pubDate!),
                                           "mediaURL":clip.episode.mediaURL ?? "",
                                           "duration": clip.episode.duration ?? 0])
        addParamWithKey("clip", value: ["title":clip.title ?? "",
                                        "startTime":clip.startTime,
                                        "endTime":clip.endTime,
                                        "duration":clip.duration ?? 0,
                                        "userId":userId ?? ""])
    }
}