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

protocol PVMediaPlayerDelegate {
    func setMediaPlayerVCPlayPauseIcon()
}

class PVMediaPlayer: NSObject {

    static let sharedInstance = PVMediaPlayer()
    
    var avPlayer = AVPlayer()
    
    var docDirectoryURL: NSURL?
    
    var nowPlayingEpisode: Episode!
    var nowPlayingClip: Clip!
    
    var mediaPlayerIsPlaying = false
    
    var delegate: PVMediaPlayerDelegate?
    
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
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "playInterrupted:", name: AVAudioSessionInterruptionNotification, object: AVAudioSession.sharedInstance())
    }
    
    func playForSeconds(startTime:Double, endTime:Double) {
        self.playOrPause()
        avPlayer.seekToTime(CMTime(seconds: startTime, preferredTimescale: 1)) { (seeked) -> Void in
            self.playOrPause()
        }
    }
    
    func playOrPause() -> (Bool) {
        if avPlayer.currentItem != nil {
            self.setPlayingInfo(self.nowPlayingEpisode)
            
            if avPlayer.rate == 0 {
                avPlayer.play()
                mediaPlayerIsPlaying = true
                
                NSNotificationCenter.defaultCenter().addObserver(self, selector: "playerDidFinishPlaying:", name: AVPlayerItemDidPlayToEndTimeNotification, object: avPlayer.currentItem)
                
                return true
                
            } else {
                saveCurrentTimeAsPlaybackPosition()
                avPlayer.pause()
                mediaPlayerIsPlaying = false
                return false
            }
        }
        
        mediaPlayerIsPlaying = false
        return false
    }
    
    func playerDidFinishPlaying(note: NSNotification) {
//        PVDeleter.sharedInstance.deleteEpisode(self.nowPlayingEpisode)
//        
//        //TODO: If the MediaPlayerViewController is currently displayed, then pop to Back page when playerDidFinishPlaying
//        // Possibly helpful http://stackoverflow.com/questions/11637709/get-the-current-displaying-uiviewcontroller-on-the-screen-in-appdelegate-m
    }
    
    func saveCurrentTimeAsPlaybackPosition() {
        if let playingEpisode = self.nowPlayingEpisode {
            playingEpisode.playbackPosition = CMTimeGetSeconds(avPlayer.currentTime())
            CoreDataHelper.saveCoreData(nil)
        }
    }
    
    func remoteControlReceivedWithEvent(event: UIEvent) {
        if event.type == UIEventType.RemoteControl {
            switch event.subtype {
            case UIEventSubtype.RemoteControlPlay:
                self.playOrPause()
                delegate?.setMediaPlayerVCPlayPauseIcon()
                break
            case UIEventSubtype.RemoteControlPause:
                self.playOrPause()
                delegate?.setMediaPlayerVCPlayPauseIcon()
                break
            case UIEventSubtype.RemoteControlTogglePlayPause:
                self.playOrPause()
                delegate?.setMediaPlayerVCPlayPauseIcon()
                break
            default:
                break
            }
        }
    }
    
    func setPlayingInfo(episode: Episode) {
        if nowPlayingEpisode != nil {
            var podcastTitle: String!
            var episodeTitle: String!
            var mpImage: MPMediaItemArtwork!
            var mpDuration: NSNumber!
            var mpElapsedPlaybackTime: NSNumber!
            let mpRate = 1
            
            podcastTitle = self.nowPlayingEpisode.podcast.title
            
            if let eTitle = self.nowPlayingEpisode.title {
                episodeTitle = eTitle
            }
            
            if let podcastiTunesImageData = self.nowPlayingEpisode.podcast.itunesImage {
                let podcastiTunesImage = UIImage(data: podcastiTunesImageData)
                mpImage = MPMediaItemArtwork(image: podcastiTunesImage!)
            } else if let podcastImageData = self.nowPlayingEpisode.podcast.imageData {
                let podcastImage = UIImage(data: podcastImageData)
                mpImage = MPMediaItemArtwork(image: podcastImage!)
            } else {
                // TODO: Replace Blank52 with a square Podverse logo
                mpImage = MPMediaItemArtwork(image: UIImage(named: "Blank52")!)
            }
            
            if let playbackDuration = nowPlayingEpisode.duration {
                mpDuration = playbackDuration
            }
            
            let elapsedPlaybackCMTime = CMTimeGetSeconds(avPlayer.currentTime())
            mpElapsedPlaybackTime = NSNumber(double: elapsedPlaybackCMTime)
            
            MPNowPlayingInfoCenter.defaultCenter().nowPlayingInfo = [MPMediaItemPropertyArtist: podcastTitle, MPMediaItemPropertyTitle: episodeTitle, MPMediaItemPropertyArtwork: mpImage, MPMediaItemPropertyPlaybackDuration: mpDuration, MPNowPlayingInfoPropertyElapsedPlaybackTime: mpElapsedPlaybackTime, MPNowPlayingInfoPropertyPlaybackRate: mpRate]
        }
    }
    
    func goToTime(seconds: Double) {
        let resultTime = CMTimeMakeWithSeconds(seconds, 1)
        avPlayer.pause()
        avPlayer.seekToTime(resultTime)
        saveCurrentTimeAsPlaybackPosition()
        avPlayer.play()
        mediaPlayerIsPlaying = true
    }
    
    func skipTime(seconds: Double) {
        let currentTime = avPlayer.currentTime()
        let timeAdjust = CMTimeMakeWithSeconds(seconds, 1)
        let resultTime = CMTimeAdd(currentTime, timeAdjust)
        avPlayer.pause()
        avPlayer.seekToTime(resultTime)
        saveCurrentTimeAsPlaybackPosition()
        avPlayer.play()
        mediaPlayerIsPlaying = true
    }
    
    func previousTime(seconds: Double) {
        let currentTime = avPlayer.currentTime()
        let timeAdjust = CMTimeMakeWithSeconds(seconds, 1)
        let resultTime = CMTimeSubtract(currentTime, timeAdjust)
        avPlayer.pause()
        avPlayer.seekToTime(resultTime)
        saveCurrentTimeAsPlaybackPosition()
        avPlayer.play()
        mediaPlayerIsPlaying = true
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
        
        self.setPlayingInfo(nowPlayingEpisode)
    }
    
    func playInterrupted(notification: NSNotification) {
        if notification.name == AVAudioSessionInterruptionNotification && notification.userInfo != nil {
            var info = notification.userInfo!
            var intValue: UInt = 0
            
            (info[AVAudioSessionInterruptionTypeKey] as! NSValue).getValue(&intValue)
            
            if let type = AVAudioSessionInterruptionType(rawValue: intValue) {
                switch type {
                case .Began:
                    saveCurrentTimeAsPlaybackPosition()
                    break
                case .Ended:
                    if mediaPlayerIsPlaying == true {
                        playOrPause()
                    }
                    break
                }
            }
        }
    }
}
