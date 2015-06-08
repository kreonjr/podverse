//
//  MediaPlayerViewController.swift
//  podverse
//
//  Created by Mitchell Downey on 6/2/15.
//  Copyright (c) 2015 Mitchell Downey. All rights reserved.
//

import UIKit

class MediaPlayerViewController: UIViewController {
    
    var utility = PVUtility()
    
    var moc: NSManagedObjectContext!
    
    var selectedEpisode: Episode!
    var selectedClip: Clip!
    
    var newClip: Clip!
    
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
        newClip = CoreDataHelper.insertManagedObject(NSStringFromClass(Clip), managedObjectContext: self.moc) as! Clip
        
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
        newClip.startTime = utility.convertStringToNSNumber(makeClipViewTimeStart.text)
        newClip.endTime = utility.convertStringToNSNumber(makeClipViewTimeEnd.text)
        newClip.title = makeClipViewTitleField.text
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
        
        makeClipViewTime.hidden = true
        makeClipViewTitle.hidden = true
        makeClipViewShare.hidden = true
        
        if let context = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext {
            moc = context
        }
        
        var newClip = CoreDataHelper.insertManagedObject(NSStringFromClass(Clip), managedObjectContext: self.moc) as! Clip
        
        createMakeClipButton()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
