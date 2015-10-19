//
//  CustomFeedParser.swift
//  podverse
//
//  Created by Kreon on 10/18/15.
//  Copyright © 2015 Mitchell Downey. All rights reserved.
//

import Foundation

class CustomFeedParser:FeedParser {
    override func parseEndOfRSS2Element(elementName: String, qualifiedName qName: String!) {
        if self.currentPath == "/rss/channel/image/url"{
            self.currentFeedChannel.channelLogoURL = self.currentElementContent
        }
        
        super.parseEndOfRSS2Element(elementName, qualifiedName: qName)
    }
}