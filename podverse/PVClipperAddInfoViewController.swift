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
            self.performSegueWithIdentifier("show_confirm_clip", sender: self)
        }
        else {
            let timingAlert = UIAlertController(title: "Error", message: "A clip title is necessary to save the clip.", preferredStyle:.Alert)
            
            timingAlert.addAction(UIAlertAction(title: "OK", style: .Cancel, handler: nil))
            
            self.presentViewController(timingAlert, animated: true, completion: nil)
        }
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
            clip?.endTime = episode.duration
        }
        
        if let clipEnd = clip?.endTime, clipStart = clip?.startTime {
            let clipDuration = NSNumber(integer: clipEnd.integerValue - clipStart.integerValue)
            clip?.duration = clipDuration
        }
        
        CoreDataHelper.saveCoreData(nil)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "show_confirm_clip" {
            (segue.destinationViewController as! PVClipperConfirmationViewController).clip = clip
        }
    }
}
