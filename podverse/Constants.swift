//
//  Constants.swift
//  podverse
//
//  Created by Mitchell Downey on 7/6/15.
//  Copyright (c) 2015 Mitchell Downey. All rights reserved.
//
import UIKit
import CoreData

enum TabItems:Int {
    case Podcasts = 0, Playlists, Find, Downloads, Settings
    
    func getIndex() -> Int {
        switch self {
        case .Podcasts:
            return 0
        case .Playlists:
            return 1
        case .Find:
            return 2
        case .Downloads:
            return 3
        case .Settings:
            return 4
        }
    }
}

struct Constants {

    static let kDownloadHasFinished  = "downloadHasFinished"

    static let kDownloadHasProgressed = "downloadHasProgressed"
    
    static let kDownloadHasPausedOrResumed = "downloadHasPausedOrResumed"
    
    static let kLastPlayingEpisodeURL = "lastPlayingEpisodeURL"
    
    static let kUnsubscribeFromPodcast = "unsubscribeFromPodcast"
    
    static let kUpdateDownloadsTable = "updateDownloadTable"

    static let kNowPlayingTimeHasChanged = "nowPlayingTimeHasChanged"
    
    static let kPlayerHasNoItem = "playerHasNoItem"
    
    static let feedParsingQueue = dispatch_queue_create("FEED_PARSER_QUEUE", DISPATCH_QUEUE_SERIAL);
    
    static let kRefreshAddToPlaylistTableDataNotification = "refreshPodcastTableDataNotification"
    
    static let kItemAddedToPlaylistNotification = "itemAddedToPlaylistNotificiation"
    
    static let kMyClipsPlaylist = "My Clips"
    
    static let kMyEpisodesPlaylist = "My Episodes"
    
    static let kUserId = "userId"
    
    static let kInternetIsUnreachable = "internetIsUnreachable"
    
    static let kWiFiIsUnreachable = "wiFiIsUnreachable"
    
    static let rootPath = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, .UserDomainMask, true)[0]
    
    static let TO_PLAYER_SEGUE_ID = "To Now Playing"
}