//
//  DownloadingEpisode.swift
//  podverse
//
//  Created by Kreon on 4/10/16.
//  Copyright © 2016 Mitchell Downey. All rights reserved.
//

import Foundation
import CoreData

final class DownloadingEpisode:Equatable {
    var title:String?
    var taskIdentifier:Int?
    var downloadComplete:Bool?
    var mediaURL: String?
    var imageThumbData:NSData?
    var taskResumeData:NSData?
    var totalBytesWritten:Float?
    var totalBytesExpectedToWrite:Float?
    var podcastRSSFeedURL:String?
    var wasPausedByUser:Bool?
    var pausedWithoutResumeData:Bool?
    var managedEpisodeObjectID:NSManagedObjectID?
    
    var progress: Float {
        get {
            if let currentBytes = totalBytesWritten, let totalBytes = totalBytesExpectedToWrite {
                    return currentBytes / totalBytes
            } else {
                return Float(0)
            }
        }
    }
    
    var formattedTotalBytesDownloaded: String {
        get {
            if let currentBytes = totalBytesWritten, let totalBytes = totalBytesExpectedToWrite {
                // Format the total bytes into a human readable KB or MB number
                let dataFormatter = NSByteCountFormatter()
                
                let formattedCurrentBytesDownloaded = dataFormatter.stringFromByteCount(Int64(currentBytes))
                let formattedTotalFileBytes = dataFormatter.stringFromByteCount(Int64(totalBytes))
                
                if progress == 1.0 {
                    return formattedTotalFileBytes
                } else {
                    return "\(formattedCurrentBytesDownloaded) / \(formattedTotalFileBytes)"
                }
            } else {
                return ""
            }
        }
    }
    
    init(episode:Episode) {
        title = episode.title
        taskIdentifier = episode.taskIdentifier?.integerValue
        downloadComplete = episode.downloadComplete
        mediaURL = episode.mediaURL
        imageThumbData = episode.podcast.imageThumbData
        podcastRSSFeedURL = episode.podcast.feedURL
        wasPausedByUser = false
        pausedWithoutResumeData = false
        managedEpisodeObjectID = episode.objectID
    }
}

func == (lhs: DownloadingEpisode, rhs: DownloadingEpisode) -> Bool {
    return lhs.mediaURL == rhs.mediaURL
}