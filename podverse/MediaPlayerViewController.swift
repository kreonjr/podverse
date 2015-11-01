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
    
    let makeClipString = "Make Clip"
    let hideClipper = "Hide Clipper"
    let buttonMakeClip: UIButton = UIButton(type : UIButtonType.System)
    var secondsArray = [String]()
    var minutesArray = [String]()
    var hoursArray = [String]()
    var clipper:PVClipperViewController?
    
    @IBOutlet weak var timePickerToolBar: UIToolbar!
    var pickerData: [[String]] = [[String]]()
    
    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    
    var moc: NSManagedObjectContext! {
        get {
            return appDelegate.managedObjectContext
        }
    }
    
    let pvMediaPlayer = PVMediaPlayer.sharedInstance
    
    var nowPlayingCurrentTimeTimer: NSTimer!
    
    var returnToNowPlaying: Bool! = false
    
    @IBOutlet weak var timePicker: UIPickerView!
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
        
        for i in 1...60 {
            secondsArray.append("\(i)")
            minutesArray.append("\(i)")
        }
        for i in 1...24 {
            hoursArray.append("\(i)")
        }
        pickerData = [hoursArray,minutesArray,secondsArray]
        
        self.clipper = ((self.childViewControllers.first as! UINavigationController).topViewController as? PVClipperViewController)
        self.clipper?.delegate = self
        timePicker.hidden = true
        timePickerToolBar.hidden = true
        
        // Create and add the Make Clip button to the UI
        buttonMakeClip.frame = CGRectMake(0, 0, 90, 90)
        buttonMakeClip.setTitle(makeClipString, forState: .Normal)
        buttonMakeClip.addTarget(self, action: "toggleMakeClipView:", forControlEvents: .TouchUpInside)
        let rightBarButtonMakeClip: UIBarButtonItem = UIBarButtonItem(customView: buttonMakeClip)
        self.navigationItem.setRightBarButtonItems([rightBarButtonMakeClip], animated: true)
        
        makeClipContainerView.hidden = true
        
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
    
    func toggleMakeClipView(sender: UIButton!) {
        makeClipContainerView.hidden = !makeClipContainerView.hidden

        if makeClipContainerView.hidden == true {
            buttonMakeClip.setTitle(makeClipString, forState: .Normal)
            for viewController in self.childViewControllers {
                if viewController.isKindOfClass(UINavigationController) {
                    (viewController as! UINavigationController).popToRootViewControllerAnimated(false)
                }
            }
        }
        else {
            if let PVClipper = self.clipper {
                PVClipper.startTime = CMTimeGetSeconds(pvMediaPlayer.avPlayer.currentTime())
                PVClipper.updateUI()
            }
            buttonMakeClip.setTitle(hideClipper, forState: .Normal)
        }
    }
}

extension MediaPlayerViewController:UIPickerViewDataSource, UIPickerViewDelegate,ClipperDelegate {
    func showTimePicker() {
        self.parentViewController?.view.addSubview(timePicker)
    }
    
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return 3
    }
    
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return pickerData[component].count
    }
    
    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        let timeValue = pickerData[component][row]
        switch component {
        case 0:
            return "Hour: " + timeValue
        case 1:
            return "Min: " + timeValue
        case 2:
            return "Sec: " + timeValue
        default:
            return timeValue
        }
    }
    
    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        // This method is triggered whenever the user makes a change to the picker selection.
        // The parameter named row and component represents what was selected.
    }
    
    func displayTimePicker() {
        timePicker.hidden = false
        timePickerToolBar.hidden = false
    }
    
    @IBAction func timeChosen(sender: AnyObject) {
        timePicker.hidden = true
        timePickerToolBar.hidden = true
    }
}
