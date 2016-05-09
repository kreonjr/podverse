//
//  Constants.swift
//  podverse
//
//  Created by Mitchell Downey on 7/6/15.
//  Copyright (c) 2015 Mitchell Downey. All rights reserved.
//
import UIKit
import CoreData

struct Constants {

    static let kDownloadHasFinished  = "downloadHasFinished"

    static let kDownloadHasProgressed = "downloadHasProgressed"
    
    static let kDownloadHasPausedOrResumed = "downloadHasPausedOrResumed"
    
    static let kUpdateDownloadsTable = "updateDownloadTable"

    static let kNowPlayingTimeHasChanged = "nowPlayingTimeHasChanged"
    
    static let kPlayerHasNoItem = "playerHasNoItem"
    
    static let kClipperWillDisplay = "clipperWillDisplay"
    
    static let feedParsingQueue = dispatch_queue_create("FEED_PARSER_QUEUE", DISPATCH_QUEUE_SERIAL);
    
    static let kRefreshAddToPlaylistTableDataNotification = "refreshPodcastTableDataNotification"
    
    static let kItemAddedToPlaylistNotification = "itemAddedToPlaylistNotificiation"
    
    static let kMyClipsPlaylist = "My Clips"
    
    static let kMyEpisodesPlaylist = "My Episodes"
    
    static let rootPath = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, .UserDomainMask, true)[0]
    
    static var SERVER_AUTHORIZATION_KEY:String {
        get {
            if let plistPath = NSBundle.mainBundle().pathForResource("ServerKey", ofType: "plist"), let dict = NSDictionary(contentsOfFile: plistPath), key = dict["ServerKey"] as? String {
                return key
            }
            else {
                return ""
            }
        }
    }
}