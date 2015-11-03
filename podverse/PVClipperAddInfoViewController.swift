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
        let saveButton = UIBarButtonItem(title: "Review", style: .Plain, target: self, action: "goToConfirm")
        self.navigationItem.rightBarButtonItem = saveButton
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func goToConfirm () {
        self.performSegueWithIdentifier("show_confirm_clip", sender: self)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "show_confirm_clip" {
            clip?.title = clipTitleTextField.text
            (segue.destinationViewController as! PVClipperConfirmationViewController).clip = clip
        }
    }
}
