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
    @IBOutlet weak var clipStartEndTime: UILabel!
    
    var clip:Clip?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        let shareButton = UIBarButtonItem(title: "Share", style: .Plain, target: self, action: #selector(PVClipperConfirmationViewController.shareClip))
        self.navigationItem.rightBarButtonItem = shareButton
        
        let editButton = UIBarButtonItem(title: "Edit", style: .Plain, target: self, action: #selector(PVClipperConfirmationViewController.popToRoot))
        self.navigationItem.leftBarButtonItem = editButton

    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        if let clipTitle = clip?.title {
            clipTitleLabel.text = clipTitle
        } else {
            if let episodeTitle = clip?.episode.title {
                clipTitleLabel.text = episodeTitle
            }
        }
        
        if let duration = clip?.duration {
            clipDuration.text = PVUtility.convertNSNumberToHHMMSSString(duration)
        } else {
            clipDuration.text = ""
        }
        
        if let startTime = clip?.startTime {
            
            var startEndTimeString = PVUtility.convertNSNumberToHHMMSSString(startTime)
            if let endTime = clip?.endTime {
                if Int(endTime) > Int(startTime) {
                    startEndTimeString += " – " + PVUtility.convertNSNumberToHHMMSSString(endTime)
                }
            }
            clipStartEndTime.text = startEndTimeString
            
        }
        
    }
    
    func popToRoot() {
        if let rootVC = navigationController?.viewControllers.first as? PVClipperViewController {
            rootVC.clip = clip
        }
        
        self.navigationController?.popToRootViewControllerAnimated(true)
    }
    
    func shareClip() {
        var textToShare = ""
        if let podverseURL = clip?.podverseURL {
            textToShare = podverseURL
        }
        
        let objectsToShare = [textToShare]
        let activityVC = UIActivityViewController(activityItems: objectsToShare, applicationActivities: nil)

        self.presentViewController(activityVC, animated: true, completion: nil)
    }
    
}
