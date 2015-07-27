//
//  MediaPlayerViewController.swift
//  podverse
//
//  Created by Mitchell Downey on 6/2/15.
//  Copyright (c) 2015 Mitchell Downey. All rights reserved.
//

import UIKit
import AVFoundation
import CoreData

class MediaPlayerViewController: UIViewController {
    
    var utility = PVUtility()
    
    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    
    var avPlayer: AVPlayer!
    
    var moc: NSManagedObjectContext!
    
    var selectedEpisode: Episode!
    var selectedClip: Clip!
    
    var startDownloadedEpisode: Bool! = false
    var startStreamingEpisode: Bool! = false
    
    var docDirectoryURL: NSURL?
    
    var newClip: Clip!
    
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
    
    @IBAction func sliderTimeChange(sender: UISlider) {
        let currentSliderValue = Float64(sender.value)
        let totalTime = Float64(selectedEpisode.duration!)
        let resultTime = CMTimeMakeWithSeconds(totalTime * currentSliderValue, 1)
        avPlayer.seekToTime(resultTime, completionHandler: { (result: Bool) -> Void in
            // forcing avPlayer to play() regardless of result value
                self.avPlayer.play()
            // if avPlayer is not playing for some reason,
            // change playPauseButton to pause icon
            if self.avPlayer.rate == 0 {
                self.playPauseButton.setTitle("\u{f04b}", forState: .Normal)
            }

        })
    }

    @IBAction func playPause(sender: AnyObject) {
        if avPlayer.rate == 0 {
            avPlayer.play()
            playPauseButton.setTitle("\u{f04c}", forState: .Normal)
        } else {
            avPlayer.pause()
            playPauseButton.setTitle("\u{f04b}", forState: .Normal)
        }
        appDelegate.nowPlayingEpisode = selectedEpisode
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
        let currentTime = avPlayer.currentTime()
        let timeAdjust = CMTimeMakeWithSeconds(60, 1)
        let resultTime = CMTimeAdd(currentTime, timeAdjust)
        avPlayer.pause()
        avPlayer.seekToTime(resultTime)
        avPlayer.play()
    }

    @IBAction func skip15seconds(sender: AnyObject) {
        let currentTime = avPlayer.currentTime()
        let timeAdjust = CMTimeMakeWithSeconds(15, 1)
        let resultTime = CMTimeAdd(currentTime, timeAdjust)
        avPlayer.pause()
        avPlayer.seekToTime(resultTime)
        avPlayer.play()
    }
    
    @IBAction func previous15seconds(sender: AnyObject) {
        let currentTime = avPlayer.currentTime()
        let timeAdjust = CMTimeMakeWithSeconds(15, 1)
        let resultTime = CMTimeSubtract(currentTime, timeAdjust)
        avPlayer.pause()
        avPlayer.seekToTime(resultTime)
        avPlayer.play()
    }
    
    @IBAction func previous1minute(sender: AnyObject) {
        let currentTime = avPlayer.currentTime()
        let timeAdjust = CMTimeMakeWithSeconds(60, 1)
        let resultTime = CMTimeSubtract(currentTime, timeAdjust)
        avPlayer.pause()
        avPlayer.seekToTime(resultTime)
        avPlayer.play()
    }
    
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
    
    func updateCurrentTimeDisplay() {
        let time = NSNumber(double: CMTimeGetSeconds(avPlayer.currentTime()))
        
        currentTime?.text = utility.convertNSNumberToHHMMSSString(time)
        
        let floatCurrentTime = Float(time)
        let floatTotalTime = Float(selectedEpisode.duration!)
        
        nowPlayingSlider.value = floatCurrentTime / floatTotalTime
    }
    
    func createMakeClipButton () {
        //--- Add Custom Left Bar Button Item/s --//
        // thanks to Naveen Sharma
        // http://iostechsolutions.blogspot.com/2014/11/swift-add-custom-right-bar-button-item.html
        
        let buttonMakeClip: UIButton = UIButton.buttonWithType(UIButtonType.Custom) as! UIButton
        buttonMakeClip.frame = CGRectMake(0, 0, 90, 90)
        buttonMakeClip.setTitle("Make Clip", forState: UIControlState.Normal)
        buttonMakeClip.addTarget(self, action: "toggleMakeClipView:", forControlEvents: .TouchUpInside)
        var rightBarButtonMakeClip: UIBarButtonItem = UIBarButtonItem(customView: buttonMakeClip)
        
        self.navigationItem.setRightBarButtonItems([rightBarButtonMakeClip], animated: true)
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
//        newClip.startTime = utility.convertStringToNSNumber(makeClipViewTimeStart.text)
//        newClip.endTime = utility.convertStringToNSNumber(makeClipViewTimeEnd.text)
//        newClip.title = makeClipViewTitleField.text
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
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let context = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext {
            moc = context
        }
        
        var dirPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as! String
        
        var newClip = CoreDataHelper.insertManagedObject(NSStringFromClass(Clip), managedObjectContext: self.moc) as! Clip
        
        createMakeClipButton()
        
        makeClipViewTime.hidden = true
        makeClipViewTitle.hidden = true
        makeClipViewShare.hidden = true
        
        var imageData = selectedEpisode.podcast.image
        var itunesImageData = selectedEpisode.podcast.itunesImage
        
        if imageData != nil {
            var image = UIImage(data: imageData!)
            mediaPlayerImage.image = image
        }
        else if itunesImageData != nil {
            var itunesImage = UIImage(data: itunesImageData!)
            mediaPlayerImage.image = itunesImage
            
                
        }
        
        podcastTitle?.text = selectedEpisode.podcast.title
        
        episodeTitle?.text = selectedEpisode.title
        
        totalTime?.text = utility.convertNSNumberToHHMMSSString(selectedEpisode.duration!) as String
        
        summary?.text = utility.removeHTMLFromString(selectedEpisode.summary!)
        
        if appDelegate.avPlayer != nil && appDelegate.nowPlayingEpisode == selectedEpisode {
            avPlayer = appDelegate.avPlayer!
            
            if avPlayer.rate == 1 {
                playPauseButton.setTitle("\u{f04c}", forState: .Normal)
            } else {
                playPauseButton.setTitle("\u{f04b}", forState: .Normal)
            }
            
            appDelegate.nowPlayingEpisode = selectedEpisode
        } else {
            
            // if the player is playing in the background, but a different episode was selected, reinit the player
            if appDelegate.avPlayer != nil {
                // TODO: I am worried this may be causing memory leak, with appDelegate.avPlayers not actually
                // being removed with the = nil, and resulting in multiple avPlayers being instantiated and
                // staying in the background
                appDelegate.avPlayer!.pause()
                appDelegate.avPlayer = nil
            }
            
            let url: NSURL!
            
            if selectedEpisode.downloadedMediaFileDestination != nil {
                var URLs = NSFileManager().URLsForDirectory(NSSearchPathDirectory.DocumentDirectory, inDomains: NSSearchPathDomainMask.UserDomainMask)
                self.docDirectoryURL = URLs[0] as? NSURL
                var destinationURL = self.docDirectoryURL?.URLByAppendingPathComponent(selectedEpisode.fileName!)
                
                var checkValidation = NSFileManager.defaultManager()
                
                var playerItem = AVPlayerItem(URL: destinationURL!)
                url = destinationURL
                appDelegate.avPlayer = AVPlayer(playerItem: playerItem)
                avPlayer = appDelegate.avPlayer
            } else {
                url = NSURL(string: selectedEpisode.mediaURL!)
                appDelegate.avPlayer = AVPlayer(URL: url)
                avPlayer = appDelegate.avPlayer
            }
            
            appDelegate.nowPlayingEpisode = selectedEpisode
            
        }

        avPlayer.addPeriodicTimeObserverForInterval(CMTimeMakeWithSeconds(1,1), queue: dispatch_get_main_queue()) { (CMTime) -> Void in
            self.updateCurrentTimeDisplay()
        }
        
        if startStreamingEpisode == true || startDownloadedEpisode == true {
            avPlayer.play()
            playPauseButton.setTitle("\u{f04c}", forState: .Normal)
        }
        
        var error: NSError?
        var success = AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayAndRecord, withOptions: .DefaultToSpeaker, error: &error)
        
        if !success {
            NSLog("Failed to set audio session category. Error: \(error)")
        }
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
