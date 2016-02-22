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
    let buttonMakeClip = UIButton(type : UIButtonType.Custom)
    var clipper:PVClipperViewController?
    
    let addToList = "Add to List"
    let buttonAddToList = UIButton(type: UIButtonType.Custom)
    
    let pvMediaPlayer = PVMediaPlayer.sharedInstance
    
    var nowPlayingCurrentTimeTimer: NSTimer!
    
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
        
        // If no nowPlaying episode or clip exists, then nav back out of MediaPlayerVC
        if pvMediaPlayer.nowPlayingEpisode == nil && pvMediaPlayer.nowPlayingClip == nil {
            self.navigationController?.popViewControllerAnimated(true)
        }
        
        pvMediaPlayer.delegate = self
        
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .Plain, target: nil, action: nil)
        
        self.view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "dismissKeyboard"))
        self.clipper = ((self.childViewControllers.first as! UINavigationController).topViewController as? PVClipperViewController)
        
        if let duration = pvMediaPlayer.nowPlayingEpisode.duration {
            self.clipper?.totalDuration = Int(duration)
        }

        buttonMakeClip.frame = CGRectMake(0, 0, 100, 90)
        buttonMakeClip.setTitle(makeClipString, forState: .Normal)
        buttonMakeClip.titleLabel!.font = UIFont(name: "System", size: 18)
        buttonMakeClip.addTarget(self, action: "toggleMakeClipView:", forControlEvents: .TouchUpInside)
        let rightBarButtonMakeClip: UIBarButtonItem = UIBarButtonItem(customView: buttonMakeClip)
        
        makeClipContainerView.hidden = true
        
        buttonAddToList.frame = CGRectMake(0, 0, 100, 90)
        buttonAddToList.setTitle(addToList, forState: .Normal)
        buttonAddToList.titleLabel!.font = UIFont(name: "System", size: 18)
        buttonAddToList.addTarget(self, action: "addNowPlayingToList", forControlEvents: .TouchUpInside)
        let rightBarButtonAddToList: UIBarButtonItem = UIBarButtonItem(customView: buttonAddToList)
        
        self.navigationItem.setRightBarButtonItems([rightBarButtonMakeClip, rightBarButtonAddToList], animated: false)
        
        // Populate the Media Player UI with the current episode's information
        if let itunesImageData = pvMediaPlayer.nowPlayingEpisode.podcast.itunesImage {
            mediaPlayerImage.image = UIImage(data: itunesImageData)
        } else if let imageData = pvMediaPlayer.nowPlayingEpisode.podcast.imageData {
            mediaPlayerImage.image = UIImage(data: imageData)
        }
        
        podcastTitle?.text = pvMediaPlayer.nowPlayingEpisode.podcast.title
        episodeTitle?.text = pvMediaPlayer.nowPlayingEpisode.title
        
        if let nowPlayingClip = pvMediaPlayer.nowPlayingClip {
            totalTime?.text = PVUtility.convertNSNumberToHHMMSSString(nowPlayingClip.duration) as String
        }
        else {
            totalTime?.text = PVUtility.convertNSNumberToHHMMSSString(pvMediaPlayer.nowPlayingEpisode.duration!) as String
        }
        
        // TODO: wtf? Why do I have to set scrollEnabled = to false and then true? If I do not, then the summary UITextView has extra black space on the bottom, and the UITextView is not scrollable.
        summary?.scrollEnabled = false
        summary?.scrollEnabled = true
        if let episodeSummary = pvMediaPlayer.nowPlayingEpisode.summary {
            summary?.text = PVUtility.removeHTMLFromString(episodeSummary)
        }
        else {
            summary.text = ""
        }
        
        // Make sure the Play/Pause button displays properly after returning from background
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "setPlayPauseIcon", name: UIApplicationWillEnterForegroundNotification, object: nil)
        
        setPlayPauseIcon()
    }
    
    func dismissKeyboard (){
        self.view.endEditing(true)
    }

    @IBAction func sliderTimeChange(sender: UISlider) {
        let currentSliderValue = Float64(sender.value)
        var totalTime: Float64 = 0.0
        
        if let clip = pvMediaPlayer.nowPlayingClip {
            totalTime = Float64(clip.duration)
        } else {
            if let duration = pvMediaPlayer.nowPlayingEpisode.duration {
                totalTime = Float64(duration)
            }
        }
        
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
            
            let totalTime: Float
            
            if let clip = pvMediaPlayer.nowPlayingClip {
                totalTime = Float(clip.duration)
            } else {
                totalTime = Float(pvMediaPlayer.nowPlayingEpisode.duration!)
            }
            
            nowPlayingSlider.value = nowPlayingCurrentTime / totalTime
        }
    }
    
    // TODO: how do I pass the PVMediaPlayer's updateNowPlayingCurrentTimeNotification directly into the selector paramter of the scheduledTimerWithTimeInterval? Creating another function to call the PVMediaPlayer's function seems redundant...
    func updateNowPlayingCurrentTimeNotification() {
        pvMediaPlayer.updateNowPlayingCurrentTimeNotification()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        // If loading the MediaPlayerVC when with no currentItem in the avPlayer, then nav back a page. Else load the MediaPlayerVC with the current item and related info.
        if pvMediaPlayer.avPlayer.currentItem == nil {
            self.navigationController?.popViewControllerAnimated(true)
        } else {
            // Call updateNowPlayingCurrentTime whenever the now playing current time changes
            if pvMediaPlayer.avPlayer.currentItem != nil {
                
            }
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
    
    func addNowPlayingToList() {
        self.performSegueWithIdentifier("Add to Playlist", sender: nil)
    }
    
    func setMediaPlayerVCPlayPauseIcon() {
        setPlayPauseIcon()
    }
    
    func episodeFinishedPlaying(currentEpisode: Episode) {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: Constants.kNowPlayingTimeHasChanged, object: nil)
        pvMediaPlayer.clearPlayingInfo()
        pvMediaPlayer.nowPlayingEpisode = nil
        
        NSNotificationCenter.defaultCenter().postNotificationName(Constants.kPlayerHasNoItem, object: nil)
        
        PVDeleter.sharedInstance.deleteEpisode(currentEpisode,completion: nil)
        
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            self.navigationController?.popViewControllerAnimated(true)
        })
    }
    
    func clipFinishedPlaying(currentClip: Clip) {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: Constants.kNowPlayingTimeHasChanged, object: nil)
        pvMediaPlayer.clearPlayingInfo()
        pvMediaPlayer.nowPlayingClip = nil
        
        NSNotificationCenter.defaultCenter().postNotificationName(Constants.kPlayerHasNoItem, object: nil)
        
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            self.navigationController?.popViewControllerAnimated(true)
        })
    }
    
    
    // MARK: - Navigation
//    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
////        if segue.identifier == "Add to Playlist" {
////            let addToPlaylistViewController = segue.destinationViewController as! AddToPlaylistViewController
////            addToPlaylistViewController.hidesBottomBarWhenPushed = true
////        }
//    }
}
