//
//  MediaPlayerViewController.swift
//  podverse
//
//  Created by Mitchell Downey on 6/2/15.
//  Copyright (c) 2015 Mitchell Downey. All rights reserved.
//

import UIKit
import CoreData
import AVFoundation

class MediaPlayerViewController: UIViewController, PVMediaPlayerDelegate {
    
    let makeClipString = "Make Clip"
    let hideClipper = "Hide Clipper"
    let buttonMakeClip: UIButton = UIButton(type : UIButtonType.Custom)
    var clipper:PVClipperViewController?
    
    let pvMediaPlayer = PVMediaPlayer.sharedInstance
    
    var nowPlayingCurrentTimeTimer: NSTimer!
    
    var returnToNowPlaying: Bool! = false
    
    @IBOutlet weak var mediaPlayerImage: UIImageView!
    @IBOutlet weak var podcastTitle: UILabel!
    @IBOutlet weak var episodeTitle: UILabel!
    @IBOutlet weak var currentTime: UILabel!
    @IBOutlet weak var totalTime: UILabel!
    @IBOutlet weak var summary: UITextView!
    
    @IBOutlet weak var playPauseButton: UIButton!
    @IBOutlet weak var skipButton: UIButton!
    @IBOutlet weak var previousButton: UIButton!
    @IBOutlet weak var speedButton: UIButton!
    @IBOutlet weak var audioButton: UIButton!
    
    @IBOutlet weak var nowPlayingSlider: UISlider!
    
    @IBOutlet weak var makeClipContainerView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        pvMediaPlayer.delegate = self
        
        self.view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "dismissKeyboard"))
        self.clipper = ((self.childViewControllers.first as! UINavigationController).topViewController as? PVClipperViewController)
        self.clipper?.totalDuration = Int(pvMediaPlayer.nowPlayingEpisode.duration!)

        // Create and add the Make Clip button to the UI
        buttonMakeClip.frame = CGRectMake(0, 0, 100, 90)
        buttonMakeClip.setTitle(makeClipString, forState: .Normal)
        buttonMakeClip.titleLabel!.font = UIFont(name: "System", size: 18)
        buttonMakeClip.addTarget(self, action: "toggleMakeClipView:", forControlEvents: .TouchUpInside)
        let rightBarButtonMakeClip: UIBarButtonItem = UIBarButtonItem(customView: buttonMakeClip)
        self.navigationItem.setRightBarButtonItems([rightBarButtonMakeClip], animated: false)
        
        makeClipContainerView.hidden = true
        
        // Populate the Media Player UI with the current episode's information
        if let itunesImageData = pvMediaPlayer.nowPlayingEpisode.podcast.itunesImage {
            mediaPlayerImage.image = UIImage(data: itunesImageData)
        } else if let imageData = pvMediaPlayer.nowPlayingEpisode.podcast.imageData {
            mediaPlayerImage.image = UIImage(data: imageData)
        }
        
        podcastTitle?.text = pvMediaPlayer.nowPlayingEpisode.podcast.title
        episodeTitle?.text = pvMediaPlayer.nowPlayingEpisode.title
        if let nowPlayingEpisodeDuration = pvMediaPlayer.nowPlayingEpisode.duration {
            totalTime?.text = PVUtility.convertNSNumberToHHMMSSString(nowPlayingEpisodeDuration) as String
        }
        if let episodeSummary = pvMediaPlayer.nowPlayingEpisode.summary {
            summary?.text = PVUtility.removeHTMLFromString(episodeSummary)
        }
        else {
            summary.text = ""
        }
        
        // Make sure the Play/Pause button displays properly after returning from background
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "setPlayPauseIcon", name: UIApplicationWillEnterForegroundNotification, object: nil)
        
        // If the user is not returning to the Media Player via the Now Playing button, load and start a new episode or clip.
        if returnToNowPlaying != true {
            // Load the Episode into the AVPlayer
            pvMediaPlayer.loadEpisodeMediaFileOrStream(pvMediaPlayer.nowPlayingEpisode)
            
            // If the episode has a playback position, then continue from that point
            if let playbackPosition = pvMediaPlayer.nowPlayingEpisode.playbackPosition {
                PVMediaPlayer.sharedInstance.goToTime(Float64(playbackPosition))
                playPauseButton.setTitle("\u{f04c}", forState: .Normal)
            }
            // Else start playing from the beginning
            else {
                PVMediaPlayer.sharedInstance.playOrPause()
                playPauseButton.setTitle("\u{f04c}", forState: .Normal)
            }
        }
    }
    
    func dismissKeyboard (){
        self.view.endEditing(true)
    }

    @IBAction func sliderTimeChange(sender: UISlider) {
        let currentSliderValue = Float64(sender.value)
        let totalTime = Float64(pvMediaPlayer.nowPlayingEpisode.duration!)
        let resultTime = totalTime * currentSliderValue
        pvMediaPlayer.goToTime(resultTime)
    }

    @IBAction func playPause(sender: AnyObject) {
        // Call playOrPause function, which returns a boolean for isNowPlaying status
        let isNowPlaying = pvMediaPlayer.playOrPause()
        
        if isNowPlaying == true {
            // Change Play/Pause button to Play icon
            playPauseButton.setTitle("\u{f04c}", forState: .Normal)
        } else {
            // Change Play/Pause button to Pause icon
            playPauseButton.setTitle("\u{f04b}", forState: .Normal)
        }
    }
    
    @IBAction func skip(sender: AnyObject) {
    }
    
    @IBAction func previous(sender: AnyObject) {
    }
    
    @IBAction func speed(sender: AnyObject) {
        // TODO: update the Speed icon when rate is changed
        
        let player = pvMediaPlayer.avPlayer
        switch player.rate {
        case 1.0:
            player.rate = 1.25
        case 1.25:
            player.rate = 1.5
        case 1.5:
            player.rate = 2.0
        case 2.0:
            player.rate = 2.5
        case 2.5:
            player.rate = 0.75
        case 0.75:
            player.rate = 0.5
        case 0.5:
            player.rate = 1.0
        default:
            player.rate = 1.0
        }
    }
    
    @IBAction func audio(sender: AnyObject) {
    }
    
    @IBAction func skip1minute(sender: AnyObject) {
        pvMediaPlayer.skipTime(60)
    }

    @IBAction func skip15seconds(sender: AnyObject) {
        pvMediaPlayer.skipTime(15)
    }
    
    @IBAction func previous15seconds(sender: AnyObject) {
        pvMediaPlayer.previousTime(15)
    }
    
    @IBAction func previous1minute(sender: AnyObject) {
        pvMediaPlayer.previousTime(60)
    }
    
    func updateNowPlayingCurrentTime(notification: NSNotification) {
        if let nowPlayingCurrentTime = notification.userInfo?["nowPlayingCurrentTime"] as? Float {
            currentTime?.text = PVUtility.convertNSNumberToHHMMSSString(nowPlayingCurrentTime)
            nowPlayingSlider.value = nowPlayingCurrentTime / Float(pvMediaPlayer.nowPlayingEpisode.duration!)
        }
    }
    
    // TODO: how do I pass the PVMediaPlayer's updateNowPlayingCurrentTimeNotification directly into the selector paramter of the scheduledTimerWithTimeInterval? Creating another function to call the PVMediaPlayer's function seems redundant...
    func updateNowPlayingCurrentTimeNotification() {
        pvMediaPlayer.updateNowPlayingCurrentTimeNotification()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        // Call updateNowPlayingCurrentTime whenever the now playing current time changes
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "updateNowPlayingCurrentTime:", name:
            Constants.kNowPlayingTimeHasChanged, object: nil)
        
        // Start timer to check every half second if the now playing current time has changed
        nowPlayingCurrentTimeTimer = NSTimer.scheduledTimerWithTimeInterval(0.5, target: self, selector: "updateNowPlayingCurrentTimeNotification", userInfo: nil, repeats: true)
        
        // If currentTime != 0.0, then immediately insert the currentTime in its label; else manually set the currentTime label to 00:00.
        if CMTimeGetSeconds(pvMediaPlayer.avPlayer.currentTime()) != 0.0 {
            currentTime?.text = PVUtility.convertNSNumberToHHMMSSString(Float(CMTimeGetSeconds(pvMediaPlayer.avPlayer.currentTime())))
        } else {
            currentTime?.text = "00:00"
        }
        
        setPlayPauseIcon()
    }
    
    func setPlayPauseIcon() {
        // Check if a clip or episode is loaded. If it is, then display either Play or Pause icon.
        if pvMediaPlayer.avPlayer.rate == 1 {
            // If playing, then display Play icon.
            playPauseButton.setTitle("\u{f04c}", forState: .Normal)
        } else {
            // If paused, then display Pause icon.
            playPauseButton.setTitle("\u{f04b}", forState: .Normal)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Stop calling updateNowPlayingCurrentTime whenever the now playing current time changes
        NSNotificationCenter.defaultCenter().removeObserver(self, name: Constants.kNowPlayingTimeHasChanged, object: nil)
        
        // Stop timer that checks every second if the now playing current time has changed
        nowPlayingCurrentTimeTimer.invalidate()
    }
    
    func toggleMakeClipView(sender: UIButton!) {
        makeClipContainerView.hidden = !makeClipContainerView.hidden

        if makeClipContainerView.hidden == true {
            self.view.endEditing(true)
            buttonMakeClip.setTitle(makeClipString, forState: .Normal)
            for viewController in self.childViewControllers {
                if viewController.isKindOfClass(UINavigationController) {
                    (viewController as! UINavigationController).popToRootViewControllerAnimated(false)
                }
            }
        }
        else {
            if let PVClipper = self.clipper {
                PVClipper.startTime = Int(CMTimeGetSeconds(pvMediaPlayer.avPlayer.currentTime()))
                PVClipper.updateUI()
                PVClipper.currentEpisode = pvMediaPlayer.nowPlayingEpisode
            }
            buttonMakeClip.setTitle(hideClipper, forState: .Normal)
        }
    }
    
    func setMediaPlayerVCPlayPauseIcon() {
        setPlayPauseIcon()
    }
}
