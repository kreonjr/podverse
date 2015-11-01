//
//  PVClipper.swift
//  podverse
//
//  Created by Mitchell Downey on 10/10/15.
//  Copyright © 2015 Mitchell Downey. All rights reserved.
//

import UIKit

protocol ClipperDelegate {
    func displayTimePicker()
}

class PVClipperViewController: UIViewController {
    
    @IBOutlet weak var startTimeLabel: UILabel!
    
    @IBOutlet weak var endTimeLabel: UILabel!
    
    var delegate: ClipperDelegate?
    
    var startTime = 0.0
    var endTime = 0.0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let startTapGesture = UITapGestureRecognizer(target: self, action: "showTimePicker")
        let endTapGesture = UITapGestureRecognizer(target: self, action: "showTimePicker")
        self.startTimeLabel.addGestureRecognizer(startTapGesture)
        self.endTimeLabel.addGestureRecognizer(endTapGesture)
        self.startTimeLabel.userInteractionEnabled = true
        self.endTimeLabel.userInteractionEnabled = true
    }
    
    @IBAction func showAddClipDetails(sender: AnyObject) {
        self.performSegueWithIdentifier("show_add_clipTitle", sender: self)
    }

    func updateUI() {
        self.startTimeLabel.text = PVUtility.convertNSNumberToHHMMSSString(NSNumber(double: startTime))
    }
    
    func showTimePicker() {
        if let delegate = self.delegate {
            delegate.displayTimePicker()
        }
    }
    
}
