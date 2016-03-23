//
//  DownloadingEpisodesList.swift
//  podverse
//
//  Created by Kreon on 1/26/16.
//  Copyright © 2016 Mitchell Downey. All rights reserved.
//

import Foundation

struct DLEpisodesList {
    static var shared = DLEpisodesList()
    
    var downloadingEpisodes = [Episode]() {
        didSet {
            dispatch_async(dispatch_get_main_queue()) { () -> Void in
                NSNotificationCenter.defaultCenter().postNotificationName(Constants.kUpdateDownloadsTable, object: nil)
            }
        }
    }
}