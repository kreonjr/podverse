//
//  LoginViewController.swift
//  podverse
//
//  Created by Mitchell Downey on 5/22/16.
//  Copyright © 2016 Mitchell Downey. All rights reserved.
//

import UIKit

class LoginViewController: UIViewController {
    
    let reachability = PVReachability()
    let playlistManager = PlaylistManager.sharedInstance
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBOutlet weak var emailInput: UITextField!
    
    @IBAction func login(sender: AnyObject) {
        if let text = emailInput.text where PVUtility.validateEmail(text) {
            NSUserDefaults.standardUserDefaults().setValue(emailInput.text, forKeyPath: Constants.kUserId)
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            self.view.window?.rootViewController = storyboard.instantiateInitialViewController()
            if reachability.hasInternetConnection() {
                playlistManager.getMyPlaylistsFromServer({
                    self.playlistManager.createDefaultPlaylists()
                })
            }
        } else {
            let loginAlert = UIAlertController(title: "Enter Email", message: "Please enter a valid email to login to your account", preferredStyle: UIAlertControllerStyle.Alert)
            loginAlert.addAction(UIAlertAction(title: "Ok", style: .Default, handler: nil))
            presentViewController(loginAlert, animated: true, completion: nil)
        }
    }
    
    @IBAction func dismissView(sender: AnyObject) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        self.view.window?.rootViewController = storyboard.instantiateInitialViewController()
        if reachability.hasInternetConnection() {
            playlistManager.createDefaultPlaylists()
        }
    }

}
