//
//  SettingsViewController.swift
//  podverse
//
//  Created by Mitchell Downey on 5/30/16.
//  Copyright © 2016 Mitchell Downey. All rights reserved.
//

import UIKit

class SettingsViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = "Podverse"
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .Plain, target: nil, action: nil)
        
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        navigationItem.rightBarButtonItem = self.playerNavButton()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func showChangeUserIdAlert() {
        let createChangeUserIdAlert = UIAlertController(title: "Change your User ID", message: nil, preferredStyle: UIAlertControllerStyle.Alert)
        
        let currentUserId = NSUserDefaults.standardUserDefaults().stringForKey("userEmail")
        
        createChangeUserIdAlert.addTextFieldWithConfigurationHandler({(textField: UITextField!) in
            textField?.text = currentUserId
        })
        
        createChangeUserIdAlert.addAction(UIAlertAction(title: "Cancel", style: .Default, handler: nil))
        
        createChangeUserIdAlert.addAction(UIAlertAction(title: "Save", style: .Default, handler: { (action: UIAlertAction!) in
            let textField = createChangeUserIdAlert.textFields![0] as UITextField
            if let newUserId = textField.text {
                NSUserDefaults.standardUserDefaults().setValue(newUserId, forKeyPath: Constants.kUserEmail)
            }
        }))
        
        presentViewController(createChangeUserIdAlert, animated: true, completion: nil)
    }
    
}

extension SettingsViewController: UITableViewDelegate, UITableViewDataSource {
    // MARK: - Table view data source
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "My Account"
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 60
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("settingsCell", forIndexPath: indexPath)
        
        cell.textLabel?.text = "User ID / Email"
        
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.row == 0 {
            tableView.deselectRowAtIndexPath(indexPath, animated: false)
            showChangeUserIdAlert()
        }
    }
}
