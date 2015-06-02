//
//  ClipModel.swift
//  Podverse
//
//  Created by Mitchell Downey on 5/25/15.
//  Copyright (c) 2015 Mitchell Downey. All rights reserved.
//

import Foundation

class Clip: NSObject {
    
    var podcast: Podcast = Podcast()
    var episode: Episode = Episode()
    
    var startTime: String = String()
    var endTime: String = String()
    var title: String = String()
    
}