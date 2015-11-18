//
//  PVMediaPlayer.swift
//  podverse
//
//  Created by Mitchell Downey on 10/10/15.
//  Copyright © 2015 Mitchell Downey. All rights reserved.
//

import UIKit
import AVFoundation
import MediaPlayer

class PVMediaPlayer: NSObject {
    
    static let sharedInstance = PVMediaPlayer()
    
    var avPlayer = AVPlayer()
    
    var docDirectoryURL: NSURL?
    
    var nowPlayingEpisode: Episode!
    var nowPlayingClip: Clip!
    
    override init() {
        super.init()

        // Enable the media player to continue playing in the background and on the lock screen
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
        
        // Enable the media player to use remote control events
        // Remote control events are overridden in the AppDelegate and set in remoteControlReceivedWithEvent
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
                print("Receiving remote control events")
                UIApplication.sharedApplication().beginReceivingRemoteControlEvents()
        } catch let error as NSError {
                print(error.localizedDescription)
        }
    }
    
    func playOrPause() -> (Bool) {
        if avPlayer.rate == 0 {
            if let clipTitle = self.nowPlayingEpisode.title {
                self.setPlayingInfo(self.nowPlayingEpisode.podcast.title, clipTitle: clipTitle)
            } else {
                self.setPlayingInfo(self.nowPlayingEpisode.podcast.title, clipTitle: "")
            }
            
            avPlayer.play()
            return true

        } else {
            self.setPlayingInfo(self.nowPlayingEpisode.podcast.title, clipTitle: self.nowPlayingEpisode.title!)
            avPlayer.pause()
            return false
        }
    }
    
    func remoteControlReceivedWithEvent(event: UIEvent) {
        if event.type == UIEventType.RemoteControl {
            switch event.subtype {
            case UIEventSubtype.RemoteControlPlay:
                self.playOrPause()
            case UIEventSubtype.RemoteControlPause:
                self.playOrPause()
            case UIEventSubtype.RemoteControlTogglePlayPause:
                self.playOrPause()
            default:
                break
            }
        }
    }
    
    func setPlayingInfo(podcastTitle: String, clipTitle: String) {
        MPNowPlayingInfoCenter.defaultCenter().nowPlayingInfo = [MPMediaItemPropertyArtist: podcastTitle, MPMediaItemPropertyTitle: clipTitle]
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
