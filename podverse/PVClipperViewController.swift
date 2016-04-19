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
    
    var boundaryObserver:AnyObject?
    var displayLink: CADisplayLink!
    
    var avPlayer = PVMediaPlayer.sharedInstance.avPlayer
    
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
            endTime = existingClip.endTime.integerValue 
        }
        
        updateUI()
    }
    
    @IBAction func showAddClipDetails(sender: AnyObject) {
        startTime = getStartTimeFromTextFields()
        endTime = getEndTimeFromTextFields()
        
        if endTime <= startTime && endTime != 0 {
            let timingAlert = UIAlertController(title: "Invalid Time", message: "Please update the End Time so it is later than the Start Time.", preferredStyle:.Alert)
            
            timingAlert.addAction(UIAlertAction(title: "OK", style: .Cancel, handler: nil))
            
            self.presentViewController(timingAlert, animated: true, completion: nil)
        } else if endTime == 0 {
            let timingAlert = UIAlertController(title: "Clip End Time", message: "No End Time is set. Press OK to use the end of the episode as the End Time.", preferredStyle:.Alert)
            timingAlert.addAction(UIAlertAction(title: "OK", style: .Default, handler: { (alertAction) -> Void in
                    self.endTime = 0
                    self.performSegueWithIdentifier("show_add_clipTitle", sender: self)
            }))
            
            timingAlert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
            
            self.presentViewController(timingAlert, animated: true, completion: nil)
        } else {
            self.performSegueWithIdentifier("show_add_clipTitle", sender: self)
        }
    }

    func updateUI() {
        // TODO: this should probably be refactored...
        
        let hms = PVUtility.secondsToHoursMinutesSeconds(Int(startTime))
        if hms.0 > 0 {
            startHourTextField.text = "\(hms.0)"
        }

        if hms.0 > 0 && hms.1 == 0 {
            startMinuteTextField.text = "00"
        } else if hms.1 <= 9 && hms.1 > 0 {
            startMinuteTextField.text = "\(hms.1)"
        } else if hms.1 >= 10 {
            startMinuteTextField.text = "\(hms.1)"
        }
        
        if (hms.0 > 0 || hms.1 > 0) && hms.2 == 0 {
            startSecTextField.text = "00"
        } else if hms.2 <= 9 && hms.2 > 0 {
            startSecTextField.text = "0\(hms.2)"
        } else if hms.2 >= 10 {
            startSecTextField.text = "\(hms.2)"
        }
        
        let hms2 = PVUtility.secondsToHoursMinutesSeconds(Int(endTime))
        if hms2.0 > 0 {
            endHourTextField.text = "\(hms2.0)"
        }
        
        if hms2.0 > 0 && hms2.1 == 0 {
            endMinuteTextField.text = "00"
        } else if hms2.1 <= 9 && hms2.1 > 0 {
            endMinuteTextField.text = "\(hms.1)"
        } else if hms2.1 >= 10 {
            endMinuteTextField.text = "\(hms.1)"
        }
        
        if (hms2.0 > 0 || hms2.1 > 0) && hms2.2 == 0 {
            endSecTextField.text = "00"
        } else if hms2.2 <= 9 && hms2.2 > 0 {
            endSecTextField.text = "0\(hms2.2)"
        } else if hms2.2 >= 10 {
            endSecTextField.text = "\(hms2.2)"
        }
    }
    
    func playFromStartTime() {
        let playFromStartTime = Double(getStartTimeFromTextFields())
        PVMediaPlayer.sharedInstance.goToTime(playFromStartTime)
    }
    
    func playFromEndTime() {
        let playFromEndDouble = Double(getEndTimeFromTextFields())
        let playFromEndCMTime = CMTimeMakeWithSeconds(playFromEndDouble, 1)
        let playFromEndValue = NSValue(CMTime: playFromEndCMTime)
        
        self.boundaryObserver = avPlayer.addBoundaryTimeObserverForTimes([playFromEndValue], queue: nil, usingBlock: {
            PVMediaPlayer.sharedInstance.playOrPause()
            if let observer = self.boundaryObserver{
                self.avPlayer.removeTimeObserver(observer)
            }
        })
        
        let playFromEndPreviewDouble = playFromEndDouble - 3
        

        PVMediaPlayer.sharedInstance.goToTime(playFromEndPreviewDouble)
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
