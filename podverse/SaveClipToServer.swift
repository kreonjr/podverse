//
//  SaveClipToServer.swift
//  podverse
//
//  Created by Kreon on 1/23/16.
//  Copyright © 2016 Mitchell Downey. All rights reserved.
//

import Foundation

class SaveClipToServer:WebService {
    internal init(clip:Clip, completionBlock: (response: Dictionary<String, AnyObject>) -> Void, errorBlock: (error: NSError?) -> Void) {
        super.init(name:"c", completionBlock: completionBlock, errorBlock: errorBlock)
        
        setHttpMethod(.METHOD_POST)
        addHeaderWithKey("Content-Type", value: "application/json")
        addParamWithKey("podcast", value: ["name":clip.episode.podcast.title ?? "",
                                           "imageUrl":clip.episode.podcast.imageURL ?? "",
                                            "episode": ["title":clip.episode.title ?? "",
                                                        "pubDate":PVUtility.formatDateToString(clip.episode.pubDate!)],
                                            "clip":["title": clip.title ?? "",
                                                    "startTime": clip.startTime,
                                                    "endTime":clip.endTime!,
                                                    "duration":clip.duration ?? 0]])
    }
}