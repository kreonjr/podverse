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
        
        if self.currentPath == "/rss/channel/item" {
            self.delegate?.feedParser?(self, didParseItem: self.currentFeedItem)
            self.currentFeedItem = nil
            
            // check for max items
            self.feedItemsParsed++
            if (self.feedItemsParsed >= self.maxFeedsToParse) { // parse up to maxFeedsToParse
                self.successfullyCloseParsingAfterMaxItemsFound()
            }
        }
        else if self.currentPath == "/rss/channel/image/url"{
            self.currentFeedChannel?.channelLogoURL = self.currentElementContent
        }
        else if self.currentPath == "/rss/channel/item/itunes:duration" {
            // if the : is present, then the duration is in hh:mm:ss
            if self.currentElementContent.containsString(":") {
                self.currentFeedItem?.duration = PVUtility.convertHHMMSSStringToNSNumber(self.currentElementContent);
            }
            // else the duration is an integer in seconds
            else {
                if let durationInteger = Int(self.currentElementContent) {
                    self.currentFeedItem?.duration = NSNumber(integer: durationInteger)
                }
            }
        }
        else if self.currentPath == "/rss/channel/lastBuildDate" {
            self.currentFeedChannel?.channelDateOfLastChange = NSDate(fromString: self.currentElementContent, format: .ISO8601)
        }
        else if self.currentPath == "/rss/channel/pubDate" {
            self.currentFeedItem?.feedPubDate = NSDate(fromString: self.currentElementContent, format: .ISO8601)
        }
        
        
        
        super.parseEndOfRSS2Element(elementName, qualifiedName: qName)
    }
}