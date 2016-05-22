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
import CoreData


enum PlayingSpeed {
    case Quarter, Half, ThreeQuarts, Regular, TimeAndQuarter, TimeAndHalf, Double, DoubleAndHalf
    
    var speedText:String {
        get {
            switch self {
            case .Quarter:
                return "X .25"
            case .Half:
                return "X .5"
            case .ThreeQuarts:
                return "X .75"
            case .Regular:
                return ""
            case .TimeAndQuarter:
                return "X 1.25"
            case .TimeAndHalf:
                return "X 1.5"
            case .Double:
                return "X 2"
            case .DoubleAndHalf:
                return "X 2.5"
            }
        }
    }
    
    var speedVaue:Float {
        get {
            switch self {
            case .Quarter:
                return 0.25
            case .Half:
                return 0.5
            case .ThreeQuarts:
                return 0.75
            case .Regular:
                return 1
            case .TimeAndQuarter:
                return 1.25
            case .TimeAndHalf:
                return 1.5
            case .Double:
                return 2
            case .DoubleAndHalf:
                return 2.5
            }
        }
    }
}

protocol PVMediaPlayerDelegate {
    func setMediaPlayerVCPlayPauseIcon()
    func episodeFinishedPlaying(currentEpisode:Episode)
    func clipFinishedPlaying(currentClip:Clip)
}

class PVMediaPlayer {

    static let sharedInstance = PVMediaPlayer()
    var avPlayer = AVPlayer()
    var docDirectoryURL: NSURL?
    var nowPlayingEpisode: Episode!
    var nowPlayingClip: Clip!
    var mediaPlayerIsPlaying = false
    var delegate: PVMediaPlayerDelegate?
    var boundaryObserver:AnyObject?
    var moc:NSManagedObjectContext!
    
    init() {

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
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(PVMediaPlayer.playInterrupted(_:)), name: AVAudioSessionInterruptionNotification, object: AVAudioSession.sharedInstance())
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(PVMediaPlayer.headphonesWereUnplugged(_:)), name: AVAudioSessionRouteChangeNotification, object: AVAudioSession.sharedInstance())
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(PVMediaPlayer.playerDidFinishPlaying), name: AVPlayerItemDidPlayToEndTimeNotification, object: avPlayer.currentItem)
        
        moc = CoreDataHelper.sharedInstance.backgroundContext
    }
    
    @objc func headphonesWereUnplugged(notification: NSNotification) {
        if let info = notification.userInfo {
            if let reasonKey = info[AVAudioSessionRouteChangeReasonKey] as? UInt {
                let reason = AVAudioSessionRouteChangeReason(rawValue: reasonKey)
                if reason == AVAudioSessionRouteChangeReason.OldDeviceUnavailable {
                    // Headphones were unplugged and AVPlayer has paused, so set the Play/Pause icon to Pause
                    dispatch_async(dispatch_get_main_queue()) {
                        self.delegate?.setMediaPlayerVCPlayPauseIcon()
                    }
                }
            }
        }
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
                self.delegate?.setMediaPlayerVCPlayPauseIcon()
                return true
                
            } else {
                saveCurrentTimeAsPlaybackPosition()
                avPlayer.pause()
                mediaPlayerIsPlaying = false
                self.delegate?.setMediaPlayerVCPlayPauseIcon()
                return false
            }
        }
        self.delegate?.setMediaPlayerVCPlayPauseIcon()
        mediaPlayerIsPlaying = false
        return false
    }
    
    @objc func playerDidFinishPlaying() {
        if nowPlayingClip == nil {
            self.delegate?.episodeFinishedPlaying(nowPlayingEpisode)   
        } else {
            self.delegate?.clipFinishedPlaying(nowPlayingClip)
        }
    }
    
    func saveCurrentTimeAsPlaybackPosition() {
        if let playingEpisode = self.nowPlayingEpisode {
            playingEpisode.playbackPosition = CMTimeGetSeconds(avPlayer.currentTime())
            
            CoreDataHelper.saveCoreData(playingEpisode.managedObjectContext, completionBlock:nil)
        }
    }
    
    func remoteControlReceivedWithEvent(event: UIEvent) {
        if event.type == UIEventType.RemoteControl {
            if nowPlayingEpisode != nil || nowPlayingClip != nil {
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
    }
    
    func setPlayingInfo(episode: Episode) {
        if nowPlayingEpisode != nil {
            var podcastTitle: String!
            var episodeTitle: String!
            var mpImage: MPMediaItemArtwork!
            var mpDuration: NSNumber!
            var mpElapsedPlaybackTime: NSNumber!
            let mpRate = avPlayer.rate
            
            podcastTitle = self.nowPlayingEpisode.podcast.title
            
            if let eTitle = self.nowPlayingEpisode.title {
                episodeTitle = eTitle
            }
            
            // Use full-size image for setPlayingInfo / MPNowPlayingInfoCenter
            if let podcastiTunesImageData = self.nowPlayingEpisode.podcast.itunesImage {
                let podcastiTunesImage = UIImage(data: podcastiTunesImageData)
                mpImage = MPMediaItemArtwork(image: podcastiTunesImage!)
            } else if let podcastImageData = self.nowPlayingEpisode.podcast.imageData {
                let podcastImage = UIImage(data: podcastImageData)
                mpImage = MPMediaItemArtwork(image: podcastImage!)
            } else {
                mpImage = MPMediaItemArtwork(image: UIImage(named: "PodverseIcon")!)
            }
            
            if let playbackDuration = nowPlayingEpisode.duration {
                mpDuration = playbackDuration
            }
            
            let elapsedPlaybackCMTime = CMTimeGetSeconds(avPlayer.currentTime())
            mpElapsedPlaybackTime = NSNumber(double: elapsedPlaybackCMTime)
            
            MPNowPlayingInfoCenter.defaultCenter().nowPlayingInfo = [MPMediaItemPropertyArtist: podcastTitle, MPMediaItemPropertyTitle: episodeTitle, MPMediaItemPropertyArtwork: mpImage, MPMediaItemPropertyPlaybackDuration: mpDuration, MPNowPlayingInfoPropertyElapsedPlaybackTime: mpElapsedPlaybackTime, MPNowPlayingInfoPropertyPlaybackRate: mpRate]
        }
    }
    
    func clearPlayingInfo() {
        MPNowPlayingInfoCenter.defaultCenter().nowPlayingInfo = nil
    }
    
    func goToTime(seconds: Double) {
        let resultTime = CMTimeMakeWithSeconds(seconds, 1)
        let currentRate = avPlayer.rate
        avPlayer.pause()
        avPlayer.seekToTime(resultTime)
        saveCurrentTimeAsPlaybackPosition()
        avPlayer.rate = currentRate
        avPlayer.play()
        mediaPlayerIsPlaying = true
        self.delegate?.setMediaPlayerVCPlayPauseIcon()
    }
    
    func skipTime(seconds: Double) {
        let currentTime = avPlayer.currentTime()
        let timeAdjust = CMTimeMakeWithSeconds(seconds, 1)
        let resultTime = CMTimeAdd(currentTime, timeAdjust)
        let currentRate = avPlayer.rate
        avPlayer.pause()
        avPlayer.seekToTime(resultTime)
        saveCurrentTimeAsPlaybackPosition()
        avPlayer.play()
        avPlayer.rate = currentRate
        mediaPlayerIsPlaying = true
    }
    
    func previousTime(seconds: Double) {
        let currentTime = avPlayer.currentTime()
        let timeAdjust = CMTimeMakeWithSeconds(seconds, 1)
        let resultTime = CMTimeSubtract(currentTime, timeAdjust)
        let currentRate = avPlayer.rate
        avPlayer.pause()
        avPlayer.seekToTime(resultTime)
        saveCurrentTimeAsPlaybackPosition()
        avPlayer.play()
        avPlayer.rate = currentRate
        mediaPlayerIsPlaying = true
    }
    
    func updateNowPlayingCurrentTimeNotification() {
        let nowPlayingCurrentTime = CMTimeGetSeconds(avPlayer.currentTime())
        let nowPlayingTimeHasChangedUserInfo = ["nowPlayingCurrentTime":nowPlayingCurrentTime]
        NSNotificationCenter.defaultCenter().postNotificationName(Constants.kNowPlayingTimeHasChanged, object: self, userInfo: nowPlayingTimeHasChangedUserInfo)
    }
    
    func loadEpisodeDownloadedMediaFileOrStreamAndPlay(episodeID: NSManagedObjectID) {
        nowPlayingEpisode = CoreDataHelper.fetchEntityWithID(episodeID, moc: moc) as! Episode
        nowPlayingClip = nil
        
        if nowPlayingEpisode.fileName != nil {
            var URLs = NSFileManager().URLsForDirectory(NSSearchPathDirectory.DocumentDirectory, inDomains: NSSearchPathDomainMask.UserDomainMask)
            self.docDirectoryURL = URLs[0]
            
            if let fileName = nowPlayingEpisode.fileName, let destinationURL = self.docDirectoryURL?.URLByAppendingPathComponent(fileName) {
                let playerItem = AVPlayerItem(URL: destinationURL)
                avPlayer = AVPlayer(playerItem: playerItem)
            }
        } else {
            if let urlString = nowPlayingEpisode.mediaURL, let url = NSURL(string: urlString) {
                avPlayer = AVPlayer(URL:url)
            }
        }
        
        // If the episode has a playback position, then continue from that point, else play from the beginning
        if let playbackPosition = nowPlayingEpisode.playbackPosition {
            goToTime(Double(playbackPosition))
        } else {
            playOrPause()
        }
        
        self.setPlayingInfo(nowPlayingEpisode)
    }
    
    func loadClipDownloadedMediaFileOrStreamAndPlay(clipID: NSManagedObjectID) {
        nowPlayingClip = CoreDataHelper.fetchEntityWithID(clipID, moc: moc) as! Clip
        nowPlayingEpisode = CoreDataHelper.fetchEntityWithID(nowPlayingClip.episode.objectID, moc: moc) as! Episode
        
//        if nowPlayingEpisode.fileName != nil {
//            var URLs = NSFileManager().URLsForDirectory(NSSearchPathDirectory.DocumentDirectory, inDomains: NSSearchPathDomainMask.UserDomainMask)
//            self.docDirectoryURL = URLs[0]
//            
//            if let fileName = nowPlayingEpisode.fileName, let destinationURL = self.docDirectoryURL?.URLByAppendingPathComponent(fileName) {
//                let playerItem = AVPlayerItem(URL: destinationURL)
//                avPlayer = AVPlayer(playerItem: playerItem)
//                
//                let endTime = CMTimeMakeWithSeconds(Double(clip.endTime!), 1)
//                let endTimeValue = NSValue(CMTime: endTime)
//                self.boundaryObserver = avPlayer.addBoundaryTimeObserverForTimes([endTimeValue], queue: nil, usingBlock: {
//                    self.playOrPause()
//                    if let observer = self.boundaryObserver{
//                        self.avPlayer.removeTimeObserver(observer)
//                    }
//                })
//                
//                goToTime(Double(clip.startTime))
//            }
//        } else {
            PVClipStreamer.sharedInstance.streamClip(nowPlayingClip)
            playOrPause()
//        }
        
        self.setPlayingInfo(nowPlayingEpisode)
    }
    
    @objc func playInterrupted(notification: NSNotification) {
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
