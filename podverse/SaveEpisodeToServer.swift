//
//  SaveEpisodeToServer.swift
//  podverse
//
//  Created by Creon on 8/16/16.
//  Copyright © 2016 Mitchell Downey. All rights reserved.
//

import UIKit

class SaveEpisodeToServer: WebService {
    internal init(episode:Episode, completionBlock: (response: AnyObject) -> Void, errorBlock: (error: NSError?) -> Void) {
        super.init(name:"clips", completionBlock: completionBlock, errorBlock: errorBlock)
        
        setHttpMethod(.METHOD_POST)
        
        addHeaderWithKey("Content-Type", value: "application/json")
        
        if let idToken = NSUserDefaults.standardUserDefaults().stringForKey("idToken") {
            addHeaderWithKey("Authorization", value: idToken)
        }
        
        if let title = episode.title {
            addParamWithKey("title", value: title)
        }
        
        addParamWithKey("startTime", value: 0)
        
        addParamWithKey("episode", value: [ "title": episode.title ?? "",
                        "mediaURL": episode.mediaURL ?? "",
                        "podcast": ["title": episode.podcast.title ?? "",
                        "feedURL": episode.podcast.feedURL]])
    }
}
