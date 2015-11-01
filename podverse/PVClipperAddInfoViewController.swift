//
//  PVClipperAddInfoViewController.swift
//  podverse
//
//  Created by Kreon on 10/31/15.
//  Copyright © 2015 Mitchell Downey. All rights reserved.
//

import UIKit

class PVClipperAddInfoViewController: UIViewController {

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
}
