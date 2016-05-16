//
//  UIViewController+MediaPlayerUI.swift
//  podverse
//
//  Created by Kreon on 5/8/16.
//  Copyright © 2016 Mitchell Downey. All rights reserved.
//

import UIKit

extension UIViewController {
    // If there is a now playing episode or clip, add Now Playing button to nav bar
    func addPlayerNavButton() {
        if PVMediaPlayer.sharedInstance.nowPlayingEpisode != nil || PVMediaPlayer.sharedInstance.nowPlayingClip != nil {
            navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Player", style: .Plain, target: self, action: #selector(segueToNowPlaying(_:)))
        }
        else {
            navigationItem.rightBarButtonItem = nil
        }
    }
    
    // If there is not a now playing episode or clip, remove Now Playing button from nav bar if present
    func removePlayerNavButton() {
        if PVMediaPlayer.sharedInstance.nowPlayingEpisode == nil && PVMediaPlayer.sharedInstance.nowPlayingClip == nil {
            navigationItem.rightBarButtonItem = nil
        }
    }
    
    func segueToNowPlaying(sender: UIBarButtonItem) {
        self.performSegueWithIdentifier("To Now Playing", sender: nil)
    }
}


