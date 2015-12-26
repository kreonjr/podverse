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
        
        // TODO: This maxFeedsToParse should probably be limited in some way. Such as, only retrieve the last 100 episodes, but return the next 100 episodes if the user scrolls to the bottom of the EpisodesTableView. 
        // Also, for some reason the maxFeedsToParse will only return half the number of episodes maxFeedsToParse we set. So 100 would actually result in 50 episodes.
        self.maxFeedsToParse = 5000
        
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
        else if self.currentPath == "/rss/channel/itunes:image" {
            let currentAttributes = self.currentElementAttributes
            if let channeliTunesLogoURL = currentAttributes["href"] {
                self.currentFeedChannel?.channeliTunesLogoURL = channeliTunesLogoURL as? String
            }
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
            self.currentFeedChannel?.channelLastBuildDate = NSDate(fromString: self.currentElementContent, format: .RFC822)
        }
        else if self.currentPath == "/rss/channel/pubDate" {
            self.currentFeedChannel?.channelLastPubDate = NSDate(fromString: self.currentElementContent, format: .RFC822)
        }
        
        
        
        super.parseEndOfRSS2Element(elementName, qualifiedName: qName)
    }
}