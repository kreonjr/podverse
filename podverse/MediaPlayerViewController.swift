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

class MediaPlayerViewController: UIViewController {
    
    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    
    var moc: NSManagedObjectContext! {
        get {
            return appDelegate.managedObjectContext
        }
    }
    
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
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "updateNowPlayingCurrentTime:", name: kNowPlayingTimeHasChanged, object: nil)
        
        // Start timer to check every second if the now playing current time has changed
        nowPlayingCurrentTimeTimer = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: "updateNowPlayingCurrentTimeNotification", userInfo: nil, repeats: true)
        
        // If currentTime != 0.0, then immediately insert the currentTime in its label; else manually set the currentTime label to 00:00.
        if CMTimeGetSeconds(pvMediaPlayer.avPlayer.currentTime()) != 0.0 {
            currentTime?.text = PVUtility.convertNSNumberToHHMMSSString(Float(CMTimeGetSeconds(pvMediaPlayer.avPlayer.currentTime())))
        } else {
            currentTime?.text = "00:00"
        }
        
        // Check if a clip or episode is loaded. If it is, then display either Play or Pause icon.
        if pvMediaPlayer.avPlayer.rate == 1 {
            // If playing, then display Play icon.
            playPauseButton.setTitle("\u{f04c}", forState: .Normal)
        } else {
            // If paused, then display Pause icon.
            playPauseButton.setTitle("\u{f04b}", forState: .Normal)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Create and add the Make Clip button to the UI
        let buttonMakeClip: UIButton = UIButton(type : UIButtonType.System)
        buttonMakeClip.frame = CGRectMake(0, 0, 90, 90)
        buttonMakeClip.setTitle("Make Clip", forState: UIControlState.Normal)
        buttonMakeClip.addTarget(self, action: "toggleMakeClipView:", forControlEvents: .TouchUpInside)
        let rightBarButtonMakeClip: UIBarButtonItem = UIBarButtonItem(customView: buttonMakeClip)
        self.navigationItem.setRightBarButtonItems([rightBarButtonMakeClip], animated: true)
        
        // Hide the Make Clip menu when the Media Player first loads
        makeClipViewTime.hidden = true
        makeClipViewTitle.hidden = true
        makeClipViewShare.hidden = true
        
        // Populate the Media Player UI with the current episode's information
        if let imageData = pvMediaPlayer.nowPlayingEpisode.podcast.imageData {
            mediaPlayerImage.image = UIImage(data: imageData)
        }
        else if let itunesImageData = pvMediaPlayer.nowPlayingEpisode.podcast.itunesImage {
            mediaPlayerImage.image = UIImage(data: itunesImageData)
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
        
        // If the user is not returning to the Media Player via the Now Playing button, load and start a new episode or clip.
        if returnToNowPlaying != true {
            // Load the Episode into the AVPlayer
            pvMediaPlayer.loadEpisodeMediaFileOrStream(pvMediaPlayer.nowPlayingEpisode)
            
            // TODO: Load the Clip into the AVPlayer
            
            pvMediaPlayer.avPlayer.play()
            playPauseButton.setTitle("\u{f04c}", forState: .Normal)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Stop calling updateNowPlayingCurrentTime whenever the now playing current time changes
        NSNotificationCenter.defaultCenter().removeObserver(self, name: kNowPlayingTimeHasChanged, object: nil)
        
        // Stop timer that checks every second if the now playing current time has changed
        nowPlayingCurrentTimeTimer.invalidate()
    }
    
    
    
    // TODO: Make Clip features are below. They should probably be decoupled from the MediaPlayerViewController.
    var newClip: Clip!
    
    @IBOutlet weak var makeClipViewTime: UIView!
    @IBOutlet weak var makeClipViewTimeStartButton: UIButton!
    @IBOutlet weak var makeClipViewTimeStart: UITextField!
    @IBOutlet weak var makeClipViewTimeEndButton: UIButton!
    @IBOutlet weak var makeClipViewTimeEnd: UITextField!
    
    @IBOutlet weak var makeClipViewTitle: UIView!
    @IBOutlet weak var makeClipViewTitleField: UITextView!
    
    @IBOutlet weak var makeClipViewShare: UIView!
    @IBOutlet weak var makeClipViewShareTitle: UILabel!
    @IBOutlet weak var makeClipViewShareDuration: UILabel!
    @IBOutlet weak var makeClipViewShareButton: UIButton!
    
    var makeClipButtonState: Int = 0
    @IBOutlet weak var makeClipButtonNextSaveDone: UIButton!
    @IBOutlet weak var makeClipButtonCancelBackEdit: UIButton!
    
    @IBAction func makeClipNextSaveDone(sender: AnyObject) {
        makeClipButtonState++
        if makeClipButtonState == 2 {
            displayMakeClipViewTitle(sender as! UIButton)
            makeClipButtonNextSaveDone.setTitle("Save", forState: .Normal)
            makeClipButtonCancelBackEdit.setTitle("Back", forState: .Normal)
        } else if makeClipButtonState == 3 {
            saveClip(sender as! UIButton)
            displayMakeClipViewShare(sender as! UIButton)
            makeClipButtonNextSaveDone.setTitle("Done", forState: .Normal)
            makeClipButtonCancelBackEdit.setTitle("Edit", forState: .Normal)
        } else if makeClipButtonState == 4 {
            closeMakeClipView(sender as! UIButton)
            makeClipButtonNextSaveDone.setTitle("Next", forState: .Normal)
            makeClipButtonCancelBackEdit.setTitle("Cancel", forState: .Normal)
            makeClipButtonState = 0
        }
    }
    
    @IBAction func makeClipCancelBackEdit(sender: AnyObject) {
        makeClipButtonState--
        if makeClipButtonState == 0 {
            closeMakeClipView(sender as! UIButton)
        } else if makeClipButtonState == 1 {
            displayMakeClipViewTime(sender as! UIButton)
            makeClipButtonNextSaveDone.setTitle("Next", forState: .Normal)
            makeClipButtonCancelBackEdit.setTitle("Cancel", forState: .Normal)
        } else if makeClipButtonState == 2 {
            displayMakeClipViewTime(sender as! UIButton)
            makeClipButtonNextSaveDone.setTitle("Next", forState: .Normal)
            makeClipButtonCancelBackEdit.setTitle("Cancel", forState: .Normal)
            makeClipButtonState = 1
        }
    }
    
    func closeMakeClipView(sender: UIButton!) {
        newClip = CoreDataHelper.insertManagedObject("Clip", managedObjectContext: self.moc) as! Clip
        makeClipViewTime.hidden = true
        makeClipViewTitle.hidden = true
        makeClipViewShare.hidden = true
    }
    
    func toggleMakeClipView(sender: UIButton!) {
        if makeClipButtonState == 0 {
            makeClipButtonState = 1
            displayMakeClipViewTime(sender as UIButton!)
        } else if makeClipButtonState == 1 || makeClipButtonState == 2 || makeClipButtonState == 3 {
            closeMakeClipView(sender as UIButton!)
            makeClipButtonState = 0
            makeClipButtonNextSaveDone.setTitle("Next", forState: .Normal)
            makeClipButtonCancelBackEdit.setTitle("Cancel", forState: .Normal)
        }
    }
    
    func displayMakeClipViewTime(sender: UIButton!) {
        makeClipViewTime.hidden = false
        makeClipViewTitle.hidden = true
        makeClipViewShare.hidden = true
    }
    
    func saveClip(sender: UIButton!) {
    }
    
    func displayMakeClipViewTitle(sender: UIButton!) {
        makeClipViewTime.hidden = false
        makeClipViewTitle.hidden = false
        makeClipViewShare.hidden = true
    }
    
    func displayMakeClipViewShare(sender: UIButton!) {
        makeClipViewTime.hidden = false
        makeClipViewTitle.hidden = false
        makeClipViewShare.hidden = false
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the current object to the new view controller.
    }
    */

}
