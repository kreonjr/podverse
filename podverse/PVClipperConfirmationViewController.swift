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
    
    @IBOutlet weak var shareButton: UIButton!
    
    var clip:Clip?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        let doneButton = UIBarButtonItem(title: "Save", style: .Plain, target: self, action: "saveClip")
        self.navigationItem.rightBarButtonItem = doneButton
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        if let duration = clip?.duration {
            clipDuration.text = PVUtility.convertNSNumberToHHMMSSString(duration)
        }
        
        clipTitleLabel.text = clip?.title
    }
    
    func saveClip () {
        // Save
        do {
            try Constants.moc.save()
        } catch let error as NSError {
            print(error)
        }
    }
    
    @IBAction func shareClip(sender: AnyObject) {
        let textToShare = "Share clips somewhere"
        let objectsToShare = [textToShare]
        let activityVC = UIActivityViewController(activityItems: objectsToShare, applicationActivities: nil)

        self.presentViewController(activityVC, animated: true, completion: nil)
    }
    
}
