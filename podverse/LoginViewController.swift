//
//  LoginViewController.swift
//  podverse
//
//  Created by Mitchell Downey on 5/22/16.
//  Copyright © 2016 Mitchell Downey. All rights reserved.
//

import UIKit

class LoginViewController: UIViewController {

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
        if emailInput.text != "" {
            NSUserDefaults.standardUserDefaults().setObject(emailInput.text, forKey: Constants.kUserEmailEntered)
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            self.view.window?.rootViewController = storyboard.instantiateInitialViewController()
        } else {
            let loginAlert = UIAlertController(title: "Enter Email", message: "Please enter a valid email to login to your account", preferredStyle: UIAlertControllerStyle.Alert)
            loginAlert.addAction(UIAlertAction(title: "Ok", style: .Default, handler: nil))
            presentViewController(loginAlert, animated: true, completion: nil)
        }
    }
    
    @IBAction func dismissView(sender: AnyObject) {
        NSUserDefaults.standardUserDefaults().setObject(true, forKey: Constants.kNoThanksLogin)
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        self.view.window?.rootViewController = storyboard.instantiateInitialViewController()
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
