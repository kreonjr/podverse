//
//  PVClipper.swift
//  podverse
//
//  Created by Mitchell Downey on 10/10/15.
//  Copyright © 2015 Mitchell Downey. All rights reserved.
//

import UIKit

class PVClipperViewController: UIViewController, UITextFieldDelegate {

    var startTime = 0
    var endTime = 0
    var totalDuration = 0
    var clipDuration = 0
    
    @IBOutlet weak var startHourTextField: UITextField!
    @IBOutlet weak var startMinuteTextField: UITextField!
    @IBOutlet weak var startSecTextField: UITextField!
    @IBOutlet weak var endHourTextField: UITextField!
    @IBOutlet weak var endMinuteTextField: UITextField!
    @IBOutlet weak var endSecTextField: UITextField!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
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

            var hours = 0
            var minutes = 0
            var secs = 0
            endTime = totalDuration
            
            //Start Time
            if let hourText = startHourTextField.text where hourText.characters.count != 0 {
                hours = Int(hourText)!
            }
            if let minText = startMinuteTextField.text where minText.characters.count != 0 {
                minutes = Int(minText)!
            }
            if let secText = startSecTextField.text where secText.characters.count != 0 {
                secs = Int(secText)!
            }
            
            (segue.destinationViewController as! PVClipperAddInfoViewController).clipTime = totalDuration - PVUtility.hoursMinutesSecondsToSeconds(hours, minutes: minutes, seconds: secs)
        }
    }

}
