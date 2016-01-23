//
//  PVClipperConfirmationViewController.swift
//  podverse
//
//  Created by Kreon on 10/31/15.
//  Copyright © 2015 Mitchell Downey. All rights reserved.
//

import UIKit

class PVClipperConfirmationViewController: UIViewController {

    @IBOutlet weak var clipTitleLabel: UILabel!
    @IBOutlet weak var clipDuration: UILabel!

    var clip:Clip?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        let shareButton = UIBarButtonItem(title: "Share", style: .Plain, target: self, action: "shareClip")
        self.navigationItem.rightBarButtonItem = shareButton
        
        let editButton = UIBarButtonItem(title: "Edit", style: .Plain, target: self, action: "popToRoot")
        self.navigationItem.leftBarButtonItem = editButton

    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        if let duration = clip?.duration {
            if clip?.endTime != 0 {
                clipDuration.text = PVUtility.convertNSNumberToHHMMSSString(duration)
            } else {
                clipDuration.text = PVUtility.convertNSNumberToHHMMSSString(duration) + " (no end time provided)"
            }

        }
        
        clipTitleLabel.text = clip?.title
    }
    
    func popToRoot() {
        if let rootVC = navigationController?.viewControllers.first as? PVClipperViewController {
            rootVC.clip = clip
        }
        
        self.navigationController?.popToRootViewControllerAnimated(true)
    }
    
    func shareClip() {
        let textToShare = "Share clips somewhere"
        let objectsToShare = [textToShare]
        let activityVC = UIActivityViewController(activityItems: objectsToShare, applicationActivities: nil)

        self.presentViewController(activityVC, animated: true, completion: nil)
    }
    
}
