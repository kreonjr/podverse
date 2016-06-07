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
        
        let createChangeUserIdAlert = UIAlertController(title: "", message: "Please enter a valid email address", preferredStyle: UIAlertControllerStyle.Alert)
        
        if let currentUserId = NSUserDefaults.standardUserDefaults().stringForKey("userId") {
            
            createChangeUserIdAlert.title = PVUtility.validateEmail(currentUserId) ? "Change Your Username" : "Create a Username"
            
            createChangeUserIdAlert.addTextFieldWithConfigurationHandler({(textField: UITextField!) in
                if PVUtility.validateEmail(currentUserId) {
                    textField?.text = currentUserId
                }
            })
            
            createChangeUserIdAlert.addAction(UIAlertAction(title: "Cancel", style: .Default, handler: nil))
            
            createChangeUserIdAlert.addAction(UIAlertAction(title: "Save", style: .Default, handler: { (action: UIAlertAction!) in
                let textField = createChangeUserIdAlert.textFields![0] as UITextField
                
                if let newUserId = textField.text where PVUtility.validateEmail(newUserId) {
                    let moc = CoreDataHelper.sharedInstance.backgroundContext
                    
                    let userCreatedPredicate = NSPredicate(format: "userId == %@", currentUserId, true)
                    let userClipsArray = CoreDataHelper.fetchEntities("Clip", predicate: userCreatedPredicate, moc:moc) as! [Clip]
                    for clip in userClipsArray {
                        // TODO: update the userId for the corresponding clips saved on server when userId is changed
                        clip.userId = newUserId
                    }
                    let userPlaylistsArray = CoreDataHelper.fetchEntities("Playlist", predicate: userCreatedPredicate, moc:moc) as! [Playlist]
                    for playlist in userPlaylistsArray {
                        // TODO: update the userId for the corresponding playlists saved on server when userId is changed
                        playlist.userId = newUserId
                    }
                    CoreDataHelper.saveCoreData(moc, completionBlock: nil)
                    
                    NSUserDefaults.standardUserDefaults().setValue(newUserId, forKeyPath: Constants.kUserId)
                    
                    self.tableView.reloadData()
                }
            }))
            
        }
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
        return 44
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("settingsCell", forIndexPath: indexPath)
        
        if let userId = NSUserDefaults.standardUserDefaults().stringForKey("userId") where PVUtility.validateEmail(userId) {
            cell.textLabel?.text = "Change my username"
        } else {
            cell.textLabel?.text = "Create new username"
        }
        
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.row == 0 {
            showChangeUserIdAlert()
            tableView.deselectRowAtIndexPath(indexPath, animated: true)
        }
    }
}
