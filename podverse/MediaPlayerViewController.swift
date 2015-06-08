//
//  MediaPlayerViewController.swift
//  podverse
//
//  Created by Mitchell Downey on 6/2/15.
//  Copyright (c) 2015 Mitchell Downey. All rights reserved.
//

import UIKit

class MediaPlayerViewController: UIViewController {

    var selectedEpisode: Episode!
    var selectedClip: Clip!
    
    var moc: NSManagedObjectContext!
    
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

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        createMakeClipButton()
        
        // Do any additional setup after loading the view.
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
