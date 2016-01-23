//
//  PVClipperAddInfoViewController.swift
//  podverse
//
//  Created by Kreon on 10/31/15.
//  Copyright © 2015 Mitchell Downey. All rights reserved.
//

import UIKit

class PVClipperAddInfoViewController: UIViewController {

    var clipTime:Int = 0
    var startTime:Int?
    var endTime:Int?
    var clip:Clip?
    var episode:Episode!
    var isEditingClip:Bool = false
    
    @IBOutlet weak var clipTitleTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        let saveButton = UIBarButtonItem(title: "Save", style: .Plain, target: self, action: "saveAndGoToReview")
        self.navigationItem.rightBarButtonItem = saveButton
        
        let backButton = UIBarButtonItem(title: "Back", style: .Plain, target: self, action: "popViewController")
        self.navigationItem.leftBarButtonItem = backButton
        
        clipTitleTextField.text = clip?.title
    }
    
    func popViewController() {
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    func saveAndGoToReview () {
        if let clipTitle = clipTitleTextField.text where clipTitle.characters.count > 0 {
            saveClipWithTitle(clipTitle)
        }
        else {
            // If no clip title provided, then create and save a default clip title
            let episodeTitle: String!
            let startTimeString: String!
            let endTimeString: String!
            let defaultTitle: String!
            
            if let episodeT = episode.title {
                episodeTitle = episodeT
            } else {
                episodeTitle = episode.podcast.title
            }
            
            if let startT = startTime {
                startTimeString = " - " + PVUtility.convertNSNumberToHHMMSSString(startT) + " start time"
            } else {
                startTimeString = ""
            }
            
            if endTime != 0 && endTime != nil {
                endTimeString = " to " + PVUtility.convertNSNumberToHHMMSSString(endTime!)
            } else {
                endTimeString = ""
            }
            
            defaultTitle = episodeTitle + startTimeString + endTimeString
            saveClipWithTitle(defaultTitle)
        }
        self.performSegueWithIdentifier("show_confirm_clip", sender: self)
    }
    
    func saveClipWithTitle(clipTitle:String) {
        if clip == nil {
            clip = (CoreDataHelper.insertManagedObject("Clip", managedObjectContext: Constants.moc) as! Clip)
            clip?.episode = episode
        }
        
        clip?.title = clipTitle
        
        if let clipStart = startTime {
            clip?.startTime = NSNumber(integer: clipStart)
        } else {
            clip?.startTime = NSNumber(integer: 0)
        }
        
        if let clipEnd = endTime {
            clip?.endTime = NSNumber(integer: clipEnd)
        } else {
            clip?.endTime = 0
        }
        
        if let clipEnd = clip?.endTime, clipStart = clip?.startTime, episodeDuration = episode.duration {
            if clipEnd != 0 {
                let clipDuration = NSNumber(integer: Int(clipEnd) - clipStart.integerValue)
                clip?.duration = clipDuration
            } else {
                let clipDuration = NSNumber(integer: Int(episodeDuration) - clipStart.integerValue)
                clip?.duration = clipDuration
            }
        }
        
        CoreDataHelper.saveCoreData(nil)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "show_confirm_clip" {
            (segue.destinationViewController as! PVClipperConfirmationViewController).clip = clip
        }
    }
}
