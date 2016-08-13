//
//  SaveClipToServer.swift
//  podverse
//
//  Created by Kreon on 1/23/16.
//  Copyright © 2016 Mitchell Downey. All rights reserved.
//

import UIKit

class SaveClipToServer:WebService {
    internal init(clip:Clip, completionBlock: (response: AnyObject) -> Void, errorBlock: (error: NSError?) -> Void) {
        super.init(name:"clips", completionBlock: completionBlock, errorBlock: errorBlock)
        
        
        setHttpMethod(.METHOD_POST)
        addHeaderWithKey("Content-Type", value: "application/json")
        if let idToken = NSUserDefaults.standardUserDefaults().stringForKey("idToken") {
            addHeaderWithKey("Authorization", value: idToken)
        }
        
        addParamWithKey("title", value: clip.title ?? "")
        addParamWithKey("startTime", value: clip.startTime)
        addParamWithKey("endTime", value: clip.endTime)
        addParamWithKey("duration", value: clip.duration ?? 0)

        addParamWithKey("episode", value: [ "title": clip.episode.title ?? "",
                                            "mediaURL": clip.episode.mediaURL ?? "",
                                            "podcast": ["title": clip.episode.podcast.title ?? "",
                                                        "feedURL": clip.episode.podcast.feedURL]
                                          ])
        
    }
}