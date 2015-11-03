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
     var clip:Clip?
    
    @IBOutlet weak var clipTitleTextField: UITextField!
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        let saveButton = UIBarButtonItem(title: "Save", style: .Plain, target: self, action: "saveAndGoToReview")
        self.navigationItem.rightBarButtonItem = saveButton
        
        let backButton = UIBarButtonItem(title: "Back", style: .Plain, target: self, action: "popViewController")
        self.navigationItem.leftBarButtonItem = backButton
    }
    
    func popViewController() {
        self.navigationController?.popViewControllerAnimated(true)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func saveAndGoToReview () {
        saveClip()
        self.performSegueWithIdentifier("show_confirm_clip", sender: self)
    }
    
    func saveClip () {
        clip?.title = clipTitleTextField.text
        
        // Save
        do {
            try Constants.moc.save()
        } catch let error as NSError {
            print(error)
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "show_confirm_clip" {
            (segue.destinationViewController as! PVClipperConfirmationViewController).clip = clip
        }
    }
}
