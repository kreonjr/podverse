//
//  LoginViewController.swift
//  podverse
//
//  Created by Mitchell Downey on 5/22/16.
//  Copyright © 2016 Mitchell Downey. All rights reserved.
//

import UIKit
import Lock

protocol LoginModalDelegate {
    func loginTapped()
}

class LoginViewController: UIViewController {
    
    let reachability = PVReachability()
    let playlistManager = PlaylistManager.sharedInstance
    var delegate:LoginModalDelegate?
    
    @IBAction func login(sender: AnyObject) {
        self.dismissViewControllerAnimated(false, completion: {
            self.delegate?.loginTapped()
        })
    }
    
    @IBAction func dismissView(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
        PVAuth.loginAsAnon()
    }

}
