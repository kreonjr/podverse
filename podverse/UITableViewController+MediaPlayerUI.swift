//
//  UITableViewController+MediaPlayerUI.swift
//  podverse
//
//  Created by Kreon on 5/8/16.
//  Copyright © 2016 Mitchell Downey. All rights reserved.
//

import UIKit

extension UITableViewController {
    // If there is a now playing episode or clip, add Now Playing button to nav bar
    override func playerNavButton() -> UIBarButtonItem? {
        if let navigationRightBarItems = navigationItem.rightBarButtonItems {
            if (PVMediaPlayer.sharedInstance.nowPlayingEpisode != nil || PVMediaPlayer.sharedInstance.nowPlayingClip != nil) && navigationRightBarItems.count < 2 {
                let playerButton = UIBarButtonItem(title: "Player", style: .Plain, target: self, action: #selector(segueToNowPlaying))
                
                return playerButton
            }
        }
        return nil
    }
    
    // If there is not a now playing episode or clip, remove Now Playing button from nav bar if present
    override func removePlayerNavButton() {
        if PVMediaPlayer.sharedInstance.nowPlayingEpisode == nil && PVMediaPlayer.sharedInstance.nowPlayingClip == nil {
            navigationItem.rightBarButtonItems = []
        }
    }
    
    override func segueToNowPlaying() {
        self.performSegueWithIdentifier(Constants.TO_PLAYER_SEGUE_ID, sender: nil)
    }
}


