//
//  PVClipper.swift
//  podverse
//
//  Created by Mitchell Downey on 10/10/15.
//  Copyright © 2015 Mitchell Downey. All rights reserved.
//

import UIKit
import CoreData
import MediaPlayer

class PVClipperViewController: UIViewController, UITextFieldDelegate {

    var startTime = 0
    var endTime = 0
    var totalDuration = 0
    var clipDuration = 0
    var currentEpisode:Episode?
    var clip:Clip?
    
    var playFromEndSeconds = 0.0
    var displayLink: CADisplayLink!
    
    @IBOutlet weak var startLabel: UILabel!
    @IBOutlet weak var endLabel: UILabel!
    @IBOutlet weak var startHourTextField: UITextField!
    @IBOutlet weak var startMinuteTextField: UITextField!
    @IBOutlet weak var startSecTextField: UITextField!
    @IBOutlet weak var endHourTextField: UITextField!
    @IBOutlet weak var endMinuteTextField: UITextField!
    @IBOutlet weak var endSecTextField: UITextField!
    
    
    override func viewDidLoad() {
        let startLabelTapGesture = UITapGestureRecognizer(target: self, action: "playFromStartTime")
        startLabel.userInteractionEnabled = true
        startLabel.addGestureRecognizer(startLabelTapGesture)
        
        let endLabelTapGesture = UITapGestureRecognizer(target: self, action: "playFromEndTime")
        endLabel.userInteractionEnabled = true
        endLabel.addGestureRecognizer(endLabelTapGesture)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        if let existingClip = clip {
            startTime = existingClip.startTime.integerValue
            if let clipEndTime = existingClip.endTime?.integerValue {
                endTime = clipEndTime
            }
        }
        
        updateUI()
    }
    
    @IBAction func showAddClipDetails(sender: AnyObject) {
        startTime = getStartTimeFromTextFields()
        endTime = getEndTimeFromTextFields()
        
        if endTime < startTime {
            let timingAlert = UIAlertController(title: "Error", message: "Start time is set before End time. Would you like to set End time to the end of the Episode?", preferredStyle:.Alert)
            timingAlert.addAction(UIAlertAction(title: "Set End Time", style: .Default, handler: { (alertAction) -> Void in

                if let duration = self.currentEpisode?.duration?.integerValue {
                    self.endTime = duration

                    self.performSegueWithIdentifier("show_add_clipTitle", sender: self)
                }
            }))
            
            timingAlert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
            
            self.presentViewController(timingAlert, animated: true, completion: nil)
        }
        else {
            self.performSegueWithIdentifier("show_add_clipTitle", sender: self)
        }
    }

    func updateUI() {
        let hms = PVUtility.secondsToHoursMinutesSeconds(Int(startTime))
        startHourTextField.text = "\(hms.0)"
        startMinuteTextField.text = "\(hms.1)"
        startSecTextField.text = "\(hms.2)"
        
        let hms2 = PVUtility.secondsToHoursMinutesSeconds(Int(endTime))
        endHourTextField.text = "\(hms2.0)"
        endMinuteTextField.text = "\(hms2.1)"
        endSecTextField.text = "\(hms2.2)"
    }
    
    func playFromStartTime() {
        let playFromStartTime = Double(getStartTimeFromTextFields())
        PVMediaPlayer.sharedInstance.goToTime(playFromStartTime)
    }
    
    func playFromEndTime() {
        playFromEndSeconds = Double(getEndTimeFromTextFields() - 3)
        if playFromEndSeconds > 0 {
            PVMediaPlayer.sharedInstance.goToTime(playFromEndSeconds)
            
            // CADisplayLink is apparently the most precise timer we can use. It calls a function every 1/60th of a second.
            displayLink = CADisplayLink(target: self, selector: "pauseIfEndTimeReached")
            
            displayLink.addToRunLoop(NSRunLoop.currentRunLoop(), forMode: NSDefaultRunLoopMode)
        }
    }
    
    func pauseIfEndTimeReached() {
        let nowPlayingCurrentTime = CMTimeGetSeconds(PVMediaPlayer.sharedInstance.avPlayer.currentTime())
        if nowPlayingCurrentTime >= playFromEndSeconds + 3 {
            PVMediaPlayer.sharedInstance.playOrPause()
            displayLink.invalidate()
        }
    }
    
    func getStartTimeFromTextFields() -> Int {
        var startHours = 0
        var startMinutes = 0
        var startSecs = 0
        
        //Start Time
        if let hourText = startHourTextField.text where hourText.characters.count != 0 {
            startHours = Int(hourText)!
        }
        if let minText = startMinuteTextField.text where minText.characters.count != 0 {
            startMinutes = Int(minText)!
        }
        if let secText = startSecTextField.text where secText.characters.count != 0 {
            startSecs = Int(secText)!
        }
        
        return PVUtility.hoursMinutesSecondsToSeconds(startHours, minutes: startMinutes, seconds: startSecs)
    }
    
    func getEndTimeFromTextFields() -> Int {
        var endHours = 0
        var endMinutes = 0
        var endSecs = 0
        
        //End Time
        if let hourText = endHourTextField.text where hourText.characters.count != 0 {
            endHours = Int(hourText)!
        }
        if let minText = endMinuteTextField.text where minText.characters.count != 0 {
            endMinutes = Int(minText)!
        }
        if let secText = endSecTextField.text where secText.characters.count != 0 {
            endSecs = Int(secText)!
        }
        
        return PVUtility.hoursMinutesSecondsToSeconds(endHours, minutes: endMinutes, seconds: endSecs)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "show_add_clipTitle" {
            guard let destinationVC = segue.destinationViewController as? PVClipperAddInfoViewController, let episode = currentEpisode else {
                return
            }
            
            destinationVC.episode = episode
            destinationVC.startTime = startTime
            destinationVC.endTime = endTime
        }
    }
}
