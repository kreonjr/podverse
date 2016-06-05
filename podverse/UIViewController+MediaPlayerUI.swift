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
    func playerNavButton() -> UIBarButtonItem? {
        if (PVMediaPlayer.sharedInstance.nowPlayingEpisode != nil || PVMediaPlayer.sharedInstance.nowPlayingClip != nil) {
                let playerButton = UIBarButtonItem(title: "Player", style: .Plain, target: self, action: #selector(segueToNowPlaying))
                
                return playerButton
        }
        return nil
    }
    
    // If there is not a now playing episode or clip, remove Now Playing button from nav bar if present
    func removePlayerNavButton() {
        if PVMediaPlayer.sharedInstance.nowPlayingEpisode == nil && PVMediaPlayer.sharedInstance.nowPlayingClip == nil {
            navigationItem.rightBarButtonItems = []
        }
    }
    
    func segueToNowPlaying() {
        self.performSegueWithIdentifier(Constants.TO_PLAYER_SEGUE_ID, sender: nil)
    }
}


