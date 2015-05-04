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
    var feedURL: NSURL = NSURL()
    var episodes: [EpisodeModel] = [EpisodeModel]()
    var imageURL: NSURL = NSURL()
    var image: UIImage = UIImage()
    var itunesImageURL: NSURL = NSURL()
    var itunesImage: UIImage = UIImage()
    
}
