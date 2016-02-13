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

    static let kNowPlayingTimeHasChanged = "nowPlayingTimeHasChanged"
    
    static let kPlayerHasNoItem = "playerHasNoItem"
    
    static let moc = CoreDataHelper.sharedInstance.moc

    static let saveQueue = dispatch_queue_create("MOC_SERIAL_SAVE_QUEUE", DISPATCH_QUEUE_SERIAL)
    
    static let feedParsingQueue = dispatch_queue_create("FEED_PARSER_QUEUE", DISPATCH_QUEUE_SERIAL);

    static let refreshPodcastTableDataNotification = "refreshPodcastTableDataNotification"
}