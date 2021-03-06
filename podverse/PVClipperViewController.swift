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
    let reachability = PVReachability.manager
    
    @IBOutlet weak var startLabel: UILabel!
    @IBOutlet weak var endLabel: UILabel!
    @IBOutlet weak var startHourTextField: UITextField!
    @IBOutlet weak var startMinuteTextField: UITextField!
    @IBOutlet weak var startSecTextField: UITextField!
    @IBOutlet weak var endHourTextField: UITextField!
    @IBOutlet weak var endMinuteTextField: UITextField!
    @IBOutlet weak var endSecTextField: UITextField!
    
    var currentTextField: UITextField?
    
    var textFieldLimitLength = 2
    
    override func viewDidLoad() {
        startHourTextField.tag = 1
        startMinuteTextField.tag = 2
        startSecTextField.tag = 3
        endHourTextField.tag = 4
        endMinuteTextField.tag = 5
        endSecTextField.tag = 6
        
        startHourTextField.delegate = self
        startMinuteTextField.delegate = self
        startSecTextField.delegate = self
        endHourTextField.delegate = self
        endMinuteTextField.delegate = self
        endSecTextField.delegate = self
        
        addKeyboardToolbar()
        
        let startLabelTapGesture = UITapGestureRecognizer(target: self, action: #selector(PVClipperViewController.playFromStartTime))
        startLabel.userInteractionEnabled = true
        startLabel.addGestureRecognizer(startLabelTapGesture)
        
        let endLabelTapGesture = UITapGestureRecognizer(target: self, action: #selector(PVClipperViewController.playFromEndTime))
        endLabel.userInteractionEnabled = true
        endLabel.addGestureRecognizer(endLabelTapGesture)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        if let existingClip = clip {
            startTime = existingClip.startTime.integerValue
            if let eTime = existingClip.endTime {
                endTime = eTime.integerValue
            }
        }
        
        updateUI()
    }
    
    @IBAction func showAddClipDetails(sender: AnyObject) {
        if !reachability.hasInternetConnection() {
            showInternetNeededAlert("Connect to WiFi or cellular data to make a clip.")
            return
        }
        
        startTime = getStartTimeFromTextFields()
        endTime = getEndTimeFromTextFields()
        
        if endTime <= startTime && endTime != 0 {
            let timingAlert = UIAlertController(title: "Invalid Time", message: "Please update the End Time so it is later than the Start Time.", preferredStyle:.Alert)
            
            timingAlert.addAction(UIAlertAction(title: "OK", style: .Cancel, handler: nil))
            
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
            endMinuteTextField.text = "\(hms2.1)"
        } else if hms2.1 >= 10 {
            endMinuteTextField.text = "\(hms2.1)"
        }
        
        if (hms2.0 > 0 || hms2.1 > 0) && hms2.2 == 0 {
            endSecTextField.text = "00"
        } else if hms2.2 <= 9 && hms2.2 > 0 {
            endSecTextField.text = "0\(hms2.2)"
        } else if hms2.2 >= 10 {
            endSecTextField.text = "\(hms2.2)"
        }
    }
    
    func textFieldShouldBeginEditing(textField: UITextField) -> Bool {
        currentTextField = textField
        return true
    }
    
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        guard let text = textField.text else { return true }
        let newLength = text.characters.count + string.characters.count - range.length
        return newLength <= textFieldLimitLength
    }
    
    func navToInitialTextField() {
        if let startHours = self.view.viewWithTag(1) as? UITextField, let startHoursText = startHours.text, let startHoursInt = Int(startHoursText) {
            if startHoursInt > 0 {
                let firstResponder = self.view.viewWithTag(1)
                firstResponder?.becomeFirstResponder()
                return
            }
        }
        if let startMinutes = self.view.viewWithTag(2) as? UITextField, let startMinutesText = startMinutes.text, let startMinutesInt = Int(startMinutesText) {
            if startMinutesInt > 0 {
                let firstResponder = self.view.viewWithTag(2)
                firstResponder?.becomeFirstResponder()
                return
            }
        }
        if let startSeconds = self.view.viewWithTag(3) as? UITextField, let startSecondsText = startSeconds.text, let startSecondsInt = Int(startSecondsText) {
            if startSecondsInt > 0 {
                let firstResponder = self.view.viewWithTag(3)
                firstResponder?.becomeFirstResponder()
                return
            }
        }
    }
    
    func navToTextField(sender:UIButton) {
        var navIncrement: Int?
        if sender.tag == 12 {
            navIncrement = -1
        } else if sender.tag == 13 {
            navIncrement = 1
        }
        
        if let inc = navIncrement, let currentField = currentTextField {
            let navToTag = currentField.tag + inc
            if let nextResponder = currentField.superview!.viewWithTag(navToTag) {
                nextResponder.becomeFirstResponder()
            } else if let nextResponder = currentField.superview!.superview!.viewWithTag(navToTag) {
                nextResponder.becomeFirstResponder()
            } else {
                self.performSegueWithIdentifier("show_add_clipTitle", sender: self)
            }
        }
    }
    
    // TODO: this monstrosity needs refactoring
    func incrementTextField(sender:UIButton) {
        var increment: Int?
        if sender.tag == 14 {
            increment = -1
        } else if sender.tag == 15 {
            increment = 1
        }
        
        if let inc = increment, let currentField = currentTextField {
            let currentValue = returnCurrentValueFromTextField(currentField)
            var newValueString: String!
            let adjacentValue: Int!
            
            if (currentValue == 1 && inc == -1) && (currentField.tag == 1 || currentField.tag == 4) {
                newValueString = String()
            } else if currentValue == 0 && inc == -1 {
                if currentField.tag == 1 || currentField.tag == 4 {
                    newValueString = String()
                } else if currentField.tag == 2 {
                    if let adjacentTextField = self.view.viewWithTag(1) as? UITextField {
                        adjacentValue = returnCurrentValueFromTextField(adjacentTextField)
                        if adjacentValue > 0 {
                            newValueString = String(59)
                            adjacentTextField.text = String(adjacentValue - 1)
                        } else {
                            newValueString = String()
                        }
                    }
                } else if currentField.tag == 3 {
                    if let adjacentTextField = self.view.viewWithTag(2) as? UITextField {
                        adjacentValue = returnCurrentValueFromTextField(adjacentTextField)
                        if adjacentValue > 0 {
                            newValueString = String(59)
                            adjacentTextField.text = String(adjacentValue - 1)
                        } else {
                            newValueString = String()
                        }
                    }
                } else if currentField.tag == 5 {
                    if let adjacentTextField = self.view.viewWithTag(4) as? UITextField {
                        adjacentValue = returnCurrentValueFromTextField(adjacentTextField)
                        if adjacentValue > 0 {
                            newValueString = String(59)
                            adjacentTextField.text = String(adjacentValue - 1)
                        } else {
                            newValueString = String()
                        }
                    }
                } else if currentField.tag == 6 {
                    if let adjacentTextField = self.view.viewWithTag(5) as? UITextField {
                        adjacentValue = returnCurrentValueFromTextField(adjacentTextField)
                        if adjacentValue > 0 {
                            newValueString = String(59)
                            adjacentTextField.text = String(adjacentValue - 1)
                        } else {
                            newValueString = String()
                        }
                    }
                }
            } else if currentValue == 59 && inc == 1 {
                if currentField.tag == 1 || currentField.tag == 4 {
                    newValueString = String(currentValue + 1)
                } else if currentField.tag == 2 {
                    if let adjacentTextField = self.view.viewWithTag(1) as? UITextField {
                        adjacentValue = returnCurrentValueFromTextField(adjacentTextField)
                        adjacentTextField.text = String(adjacentValue + 1)
                    }
                    newValueString = String(00)
                } else if currentField.tag == 3 {
                    if let adjacentTextField = self.view.viewWithTag(2) as? UITextField {
                        adjacentValue = returnCurrentValueFromTextField(adjacentTextField)
                        adjacentTextField.text = String(adjacentValue + 1)
                    }
                    newValueString = String(00)
                } else if currentField.tag == 5 {
                    if let adjacentTextField = self.view.viewWithTag(4) as? UITextField {
                        adjacentValue = returnCurrentValueFromTextField(adjacentTextField)
                        adjacentTextField.text = String(adjacentValue + 1)
                    }
                    newValueString = String(00)
                } else if currentField.tag == 6 {
                    if let adjacentTextField = self.view.viewWithTag(5) as? UITextField {
                        adjacentValue = returnCurrentValueFromTextField(adjacentTextField)
                        adjacentTextField.text = String(adjacentValue + 1)
                    }
                    newValueString = String(00)
                }
            } else if currentValue >= 0 && currentValue <= 59 {
                    newValueString = String(currentValue + inc)
            }
            currentField.text = newValueString
        }
    }
    
    func returnCurrentValueFromTextField(textField: UITextField) -> Int {
        var currentValue: Int!
        if let text = textField.text {
            currentValue = Int(text)
            if currentValue == nil {
                currentValue = 0
            }
            return currentValue
        }
        return 0
    }
    
    func addKeyboardToolbar() {
        let keyboardToolbar = UIToolbar()
        keyboardToolbar.sizeToFit()
        
        let flexBarButton = UIBarButtonItem(barButtonSystemItem: .FlexibleSpace, target: nil, action: nil)
        
        let startBarButton = UIBarButtonItem(title: "Start", style: .Plain, target: self, action: #selector(PVClipperViewController.playFromStartTime))
        startBarButton.tag = 10
        
        let endBarButton = UIBarButtonItem(title: "  End  ", style: .Plain, target: self, action: #selector(PVClipperViewController.playFromEndTime))
        endBarButton.tag = 11
        
        let prevBarButton = UIBarButtonItem(title: " <––  ", style: .Plain, target: self, action: #selector(PVClipperViewController.navToTextField(_:)))
        prevBarButton.tag = 12
        
        let nextBarButton = UIBarButtonItem(title: "  ––>  ", style: .Plain, target: self, action: #selector(PVClipperViewController.navToTextField(_:)))
        nextBarButton.tag = 13
        
        let minusOneBarButton = UIBarButtonItem(title: "  –1  ", style: .Plain, target: self, action: #selector(PVClipperViewController.incrementTextField(_:)))
        minusOneBarButton.tag = 14
        
        let plusOneBarButton = UIBarButtonItem(title: "  +1  ", style: .Plain, target: self, action: #selector(PVClipperViewController.incrementTextField(_:)))
        plusOneBarButton.tag = 15
        
        keyboardToolbar.items = [startBarButton, endBarButton, flexBarButton, prevBarButton, nextBarButton, minusOneBarButton, plusOneBarButton]
        
        startHourTextField.inputAccessoryView = keyboardToolbar
        startMinuteTextField.inputAccessoryView = keyboardToolbar
        startSecTextField.inputAccessoryView = keyboardToolbar
        endHourTextField.inputAccessoryView = keyboardToolbar
        endMinuteTextField.inputAccessoryView = keyboardToolbar
        endSecTextField.inputAccessoryView = keyboardToolbar
    }
    
    func playFromStartTime() {
        let playFromStartTime = Double(getStartTimeFromTextFields())
        PVMediaPlayer.sharedInstance.goToTime(playFromStartTime)
    }
    
    func playFromEndTime() {
        
        // TODO: BUG: When pressing the "End" key twice quickly in the Make Clip view, I run into the error "An instance of AVPlayer cannot remove a time observer that was added by a different instance of AVPlayer..."
        // I implemented a work around for this issue by not allowing the app to set a new boundaryObserver until the previous one has been removed (currently the end time observer is removed every 3 seconds). This is not optimal...
        if self.boundaryObserver != nil {
            return
        }
        
        let playFromEndDouble = Double(getEndTimeFromTextFields())
        if playFromEndDouble == 0 {
            return
        }
        
        let playFromEndCMTime = CMTimeMakeWithSeconds(playFromEndDouble, 1)
        let playFromEndValue = NSValue(CMTime: playFromEndCMTime)
        
        self.boundaryObserver = avPlayer.addBoundaryTimeObserverForTimes([playFromEndValue], queue: nil, usingBlock: {
            PVMediaPlayer.sharedInstance.playOrPause()
            if let observer = self.boundaryObserver{
                self.avPlayer.removeTimeObserver(observer)
                self.boundaryObserver = nil
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
            
            startHourTextField.resignFirstResponder()
            startMinuteTextField.resignFirstResponder()
            startSecTextField.resignFirstResponder()
            endHourTextField.resignFirstResponder()
            endMinuteTextField.resignFirstResponder()
            endSecTextField.resignFirstResponder()
            
            destinationVC.episodeID = episode.objectID
            destinationVC.startTime = startTime
            destinationVC.endTime = endTime
        }
    }
}
