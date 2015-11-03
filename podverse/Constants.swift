//
//  Constants.swift
//  podverse
//
//  Created by Mitchell Downey on 7/6/15.
//  Copyright (c) 2015 Mitchell Downey. All rights reserved.
//
import UIKit

struct Constants {

    static let kDownloadHasFinished  = "downloadHasFinished"

    static let kDownloadHasProgressed = "downloadHasProgressed"

    static let kNowPlayingTimeHasChanged = "nowPlayingTimeHasChanged"
    
    static var moc = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext!

}