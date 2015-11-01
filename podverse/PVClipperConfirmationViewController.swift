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
    
    var clipTime:Int = 0
    
    var moc = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        let doneButton = UIBarButtonItem(title: "Save", style: .Plain, target: self, action: "saveClip")
        self.navigationItem.rightBarButtonItem = doneButton
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        self.clipDuration.text = PVUtility.convertNSNumberToHHMMSSString(NSNumber(integer: clipTime))
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func saveClip () {
        let clip = CoreDataHelper.insertManagedObject("Clip", managedObjectContext: moc) as! Clip
        clip.episode = PVMediaPlayer.sharedInstance.nowPlayingEpisode
        
        // Save
        do {
            try moc.save()
        } catch let error as NSError {
            print(error)
        }
    }
}
