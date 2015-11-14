//
//  PVMediaPlayer.swift
//  podverse
//
//  Created by Mitchell Downey on 10/10/15.
//  Copyright © 2015 Mitchell Downey. All rights reserved.
//

import UIKit
import AVFoundation

class PVMediaPlayer: NSObject {

    static let sharedInstance = PVMediaPlayer()
    
    var avPlayer = AVPlayer()
    
    var docDirectoryURL: NSURL?
    
    var nowPlayingEpisode: Episode!
    var nowPlayingClip: Clip!
    
    func playOrPause() -> (Bool) {
        
        // Make sure the media player will keep playing in the background and on the lock screen
        // TODO: should this be somewhere else?
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
            do {
                try AVAudioSession.sharedInstance().setActive(true)
            } catch let error as NSError {
                print(error.localizedDescription)
            }
        } catch let error as NSError {
            print(error.localizedDescription)
        }
        
        if avPlayer.rate == 0 {
            avPlayer.play()
            return true

        } else {
            avPlayer.pause()
            return false
        }
    }
    
    func goToTime(seconds: Float64) {
        let resultTime = CMTimeMakeWithSeconds(seconds, 1)
        avPlayer.pause()
        avPlayer.seekToTime(resultTime)
        avPlayer.play()
    }
    
    func skipTime(seconds: Float64) {
        let currentTime = avPlayer.currentTime()
        let timeAdjust = CMTimeMakeWithSeconds(seconds, 1)
        let resultTime = CMTimeAdd(currentTime, timeAdjust)
        avPlayer.pause()
        avPlayer.seekToTime(resultTime)
        avPlayer.play()
    }
    
    func previousTime(seconds: Float64) {
        let currentTime = avPlayer.currentTime()
        let timeAdjust = CMTimeMakeWithSeconds(seconds, 1)
        let resultTime = CMTimeSubtract(currentTime, timeAdjust)
        avPlayer.pause()
        avPlayer.seekToTime(resultTime)
        avPlayer.play()
    }
    
    func updateNowPlayingCurrentTimeNotification() {
        let nowPlayingCurrentTime = CMTimeGetSeconds(avPlayer.currentTime())
        let nowPlayingTimeHasChangedUserInfo = ["nowPlayingCurrentTime":nowPlayingCurrentTime]
        NSNotificationCenter.defaultCenter().postNotificationName(Constants.kNowPlayingTimeHasChanged, object: self, userInfo: nowPlayingTimeHasChangedUserInfo)
    }
    
    func loadEpisodeMediaFileOrStream(episode: Episode) {
        nowPlayingEpisode = episode
        
        if episode.fileName != nil {
            var URLs = NSFileManager().URLsForDirectory(NSSearchPathDirectory.DocumentDirectory, inDomains: NSSearchPathDomainMask.UserDomainMask)
            self.docDirectoryURL = URLs[0]
            
            if let fileName = episode.fileName, let destinationURL = self.docDirectoryURL?.URLByAppendingPathComponent(fileName) {
                let playerItem = AVPlayerItem(URL: destinationURL)
                avPlayer = AVPlayer(playerItem: playerItem)
            }
        } else {
            if let urlString = episode.mediaURL, let url = NSURL(string: urlString) {
                avPlayer = AVPlayer(URL:url)
            }
        }
    }
}
