//
//  DownloadingEpisode.swift
//  podverse
//
//  Created by Kreon on 4/10/16.
//  Copyright © 2016 Mitchell Downey. All rights reserved.
//

import Foundation

final class DownloadingEpisode:Equatable {
    var title:String?
    var taskIdentifier:Int?
    var downloadComplete:Bool?
    var mediaURL: String?
    var imageData:NSData?
    
    init(episode:Episode) {
        title = episode.title
        taskIdentifier = episode.taskIdentifier?.integerValue
        downloadComplete = episode.downloadComplete
        mediaURL = episode.mediaURL
        imageData = episode.podcast.imageData ?? episode.podcast.itunesImage
    }
}

func == (lhs: DownloadingEpisode, rhs: DownloadingEpisode) -> Bool {
    return lhs.mediaURL == rhs.mediaURL
}