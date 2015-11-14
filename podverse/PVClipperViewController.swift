//
//  PVClipper.swift
//  podverse
//
//  Created by Mitchell Downey on 10/10/15.
//  Copyright © 2015 Mitchell Downey. All rights reserved.
//

import UIKit
import CoreData

class PVClipperViewController: UIViewController, UITextFieldDelegate {

    var startTime = 0
    var endTime = 0
    var totalDuration = 0
    var clipDuration = 0
    var currentEpisode:Episode?
    
    @IBOutlet weak var startHourTextField: UITextField!
    @IBOutlet weak var startMinuteTextField: UITextField!
    @IBOutlet weak var startSecTextField: UITextField!
    @IBOutlet weak var endHourTextField: UITextField!
    @IBOutlet weak var endMinuteTextField: UITextField!
    @IBOutlet weak var endSecTextField: UITextField!
    
    @IBAction func showAddClipDetails(sender: AnyObject) {
        self.performSegueWithIdentifier("show_add_clipTitle", sender: self)
    }

    func updateUI() {
        let hms = PVUtility.secondsToHoursMinutesSeconds(Int(startTime))
        startHourTextField.text = "\(hms.0)"
        startMinuteTextField.text = "\(hms.1)"
        startSecTextField.text = "\(hms.2)"
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "show_add_clipTitle" {
            let clip:Clip = (CoreDataHelper.insertManagedObject("Clip", managedObjectContext: Constants.moc) as! Clip)

            if let episode = currentEpisode {
                clip.episode = episode
                clip.podcast = episode.podcast
                
                if let duration = episode.duration {
                    endTime = duration.integerValue
                }
            }
            
            var startHours = 0
            var startMinutes = 0
            var startSecs = 0
            var endHours = 0
            var endMinutes = 0
            var endSecs = 0
            
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
            
            startTime = PVUtility.hoursMinutesSecondsToSeconds(startHours, minutes: startMinutes, seconds: startSecs)
            
            //Start Time
            if let hourText = endHourTextField.text where hourText.characters.count != 0 {
                endHours = Int(hourText)!
            }
            if let minText = endMinuteTextField.text where minText.characters.count != 0 {
                endMinutes = Int(minText)!
            }
            if let secText = endSecTextField.text where secText.characters.count != 0 {
                endSecs = Int(secText)!
            }
            
            let customEndTime = PVUtility.hoursMinutesSecondsToSeconds(endHours, minutes: endMinutes, seconds: endSecs)
            endTime = (customEndTime == 0) ? endTime : customEndTime
            clip.startTime = NSNumber(integer:startTime)
            clip.endTime = NSNumber(integer: endTime)
            clip.duration = NSNumber(integer:endTime - startTime)
            
            (segue.destinationViewController as! PVClipperAddInfoViewController).clip = clip
        }
    }

}
