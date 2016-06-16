//
//  ParsingPodcasts.swift
//  podverse
//
//  Created by Mitch on 6/12/16.
//  Copyright © 2016 Mitchell Downey. All rights reserved.
//

import Foundation

final class ParsingPodcastsList {
    static var shared = ParsingPodcastsList()
    var urls = [String]()
    var itemsParsing = 0
    
    func clearParsingPodcastsIfFinished() {
        if itemsParsing == urls.count {
            itemsParsing = 0
            urls.removeAll()
        }
    }
}

