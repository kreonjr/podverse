//
//  PodcastModel.swift
//  Podverse
//
//  Created by Mitchell Downey on 4/27/15.
//  Copyright (c) 2015 Mitchell Downey. All rights reserved.
//

import UIKit

class PodcastModel: NSObject {
    
    var title: String = String()
    var summary: String = String()
    var url: String = String()
    var episodes: [EpisodeModel] = [EpisodeModel]()
    var image: String = String()
    
}
