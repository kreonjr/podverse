//
//  ClipModel.swift
//  Podverse
//
//  Created by Mitchell Downey on 5/25/15.
//  Copyright (c) 2015 Mitchell Downey. All rights reserved.
//

import Foundation

class ClipModel: NSObject {
    
    var podcast: PodcastModel = PodcastModel()
    var episode: EpisodeModel = EpisodeModel()
    
    var startTime: String = String()
    var endTime: String = String()
    var title: String = String()
    
}