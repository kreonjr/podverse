//
//  DownloadingEpisodesList.swift
//  podverse
//
//  Created by Kreon on 1/26/16.
//  Copyright © 2016 Mitchell Downey. All rights reserved.
//

import Foundation

final class DLEpisodesList {
    static var shared = DLEpisodesList()
    
    var downloadingEpisodes = [DownloadingEpisode]() {
        didSet {
            dispatch_async(dispatch_get_main_queue()) { 
                NSNotificationCenter.defaultCenter().postNotificationName(Constants.kUpdateDownloadsTable, object: nil)
            }
        }
    }
    
    static func removeDownloadingEpisodeWithMediaURL(mediaURL:String?) {
        // If the episode is currently in the episodeDownloadArray, then delete the episode from the episodeDownloadArray
        if let mediaURL = mediaURL, index = DLEpisodesList.shared.downloadingEpisodes.indexOf({ $0.mediaURL == mediaURL }) {
            DLEpisodesList.shared.downloadingEpisodes.removeAtIndex(index)
        }
    }
}

