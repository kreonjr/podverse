//
//  MediaPlayer.swift
//  Podverse
//
//  Created by Mitchell Downey on 5/10/15.
//  Copyright (c) 2015 Mitchell Downey. All rights reserved.
//

import UIKit
import AVFoundation

class MediaPlayerViewController: UIViewController {
    
    var utility: PVUtility = PVUtility()
    
    var podcast: PodcastModel = PodcastModel()
    var episode: EpisodeModel = EpisodeModel()
    
    var playerPosition = CMTimeMake(5, 1)
    
    @IBOutlet weak var image: UIImageView!
    @IBOutlet weak var podcastTitle: UILabel!
    @IBOutlet weak var episodeTitle: UILabel!
    @IBOutlet weak var duration: UILabel!
    @IBOutlet weak var summary: UITextView!
    
    @IBOutlet weak var makeClipViewTime: MakeClipViewController!
    @IBOutlet weak var makeClipViewTitle: MakeClipViewController!
    @IBOutlet weak var makeClipViewShare: MakeClipViewController!
    
    @IBOutlet weak var makeClipViewTimeStart: UITextField!
    @IBOutlet weak var makeClipViewTimeEnd: UITextField!
    
    @IBOutlet weak var makeClipViewTitleField: UITextView!
    
    @IBOutlet weak var makeClipViewShareTitle: UILabel!
    
    @IBOutlet weak var makeClipViewShareDuration: UILabel!

    @IBOutlet weak var makeClipViewShareButton: UIButton!
    
    @IBOutlet weak var makeClipButtonNextSaveDone: UIButton!
    var makeClipButtonState: Int = 0
    
    @IBOutlet weak var makeClipButtonCancelBackEdit: UIButton!
    
    @IBOutlet weak var pausePlay: UIButton!
    
    var avPlayer = AVPlayer()
    
    @IBAction func stop(sender: AnyObject) {
        avPlayer.pause()
        avPlayer.seekToTime(CMTimeMake(0, 1))
        pausePlay.setTitle("Play", forState: UIControlState.Normal)
    }
    
    @IBAction func restart(sender: AnyObject) {
        avPlayer.seekToTime(CMTimeMake(0, 1))
        avPlayer.play()
        pausePlay.setTitle("Pause", forState: UIControlState.Normal)
    }
    
    @IBAction func pausePlay(sender: AnyObject) {
        if avPlayer.rate == 0 {
            avPlayer.play()
            pausePlay.setTitle("Pause", forState: UIControlState.Normal)
        } else {
            avPlayer.pause()
            pausePlay.setTitle("Play", forState: UIControlState.Normal)
        }
    }
    
    @IBAction func makeClipNextSaveDone(sender: AnyObject) {
        makeClipButtonState++
        if makeClipButtonState == 2 {
            displayMakeClipViewTitle(sender as! UIButton)
            makeClipButtonNextSaveDone.setTitle("Save", forState: .Normal)
            makeClipButtonCancelBackEdit.setTitle("Back", forState: .Normal)
        } else if makeClipButtonState == 3 {
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
    
    func saveClipTime(sender: UIButton!) {
        
    }
    
    func displayMakeClipViewTitle(sender: UIButton!) {
        makeClipViewTime.hidden = false
        makeClipViewTitle.hidden = false
        makeClipViewShare.hidden = true
    }
    
    func saveClipTitle(sender: UIButton!) {
        
    }
    
    func displayMakeClipViewShare(sender: UIButton!) {
        makeClipViewTime.hidden = false
        makeClipViewTitle.hidden = false
        makeClipViewShare.hidden = false
    }
    
    func saveClipShare(sender: UIButton!) {
        
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        makeClipViewTime.hidden = true
        makeClipViewTitle.hidden = true
        makeClipViewShare.hidden = true
        
        let url = episode.mediaURL
        avPlayer = AVPlayer(URL: url)
        
        image?.image = podcast.image
        podcastTitle?.text = podcast.title
        episodeTitle?.text = episode.title
        duration?.text = utility.convertNSTimeIntervalToHHMMSSString(episode.duration!) as String
        summary?.text = utility.removeHTMLFromString(episode.summary!)
        
        createMakeClipButton()
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    
    // MARK: - Navigation
    // In a storyboard-based application, you will often want to do a little preparation before navigation
//    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
//        if segue.identifier == "Make Clip" {
//            self.navigationController?.modalPresentationStyle = UIModalPresentationStyle.CurrentContext
//            let viewController: MakeClipViewController = self.storyboard?.instantiateViewControllerWithIdentifier("Make Clip") as! MakeClipViewController
//        }
//    }
//    

}
