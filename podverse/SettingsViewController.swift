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

        navigationItem.title = "Settings"
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .Plain, target: nil, action: nil)
        
        PVAuth.sharedInstance.delegate = self
        
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
        
        // TODO: remove this alert below, then uncomment and update the alert below it when we can update userIds on the clips and playlists stored on the server
        let featureNotAvailableAlert = UIAlertController(title: "Feature Not Available", message: nil, preferredStyle: UIAlertControllerStyle.Alert)
        
        featureNotAvailableAlert.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
        
        presentViewController(featureNotAvailableAlert, animated: true, completion: nil)
        
//        let createChangeUserIdAlert = UIAlertController(title: "", message: "Please enter a valid email address", preferredStyle: UIAlertControllerStyle.Alert)
//        
//        if let currentUserId = NSUserDefaults.standardUserDefaults().stringForKey("userId") {
//            
//            createChangeUserIdAlert.title = PVUtility.validateEmail(currentUserId) ? "Change Your Username" : "Create a Username"
//            
//            createChangeUserIdAlert.addTextFieldWithConfigurationHandler({(textField: UITextField!) in
//                if PVUtility.validateEmail(currentUserId) {
//                    textField?.text = currentUserId
//                }
//            })
//            
//            createChangeUserIdAlert.addAction(UIAlertAction(title: "Cancel", style: .Default, handler: nil))
//            
//            createChangeUserIdAlert.addAction(UIAlertAction(title: "Save", style: .Default, handler: { (action: UIAlertAction!) in
//                let textField = createChangeUserIdAlert.textFields![0] as UITextField
//                
//                if let newUserId = textField.text where PVUtility.validateEmail(newUserId) {
//                    let moc = CoreDataHelper.sharedInstance.backgroundContext
//                    
//                    let userCreatedPredicate = NSPredicate(format: "userId == %@", currentUserId, true)
//                    let userClipsArray = CoreDataHelper.fetchEntities("Clip", predicate: userCreatedPredicate, moc:moc) as! [Clip]
//                    for clip in userClipsArray {
//                        // TODO: update the userId for the corresponding clips saved on server when userId is changed
//                        clip.userId = newUserId
//                    }
//                    let userPlaylistsArray = CoreDataHelper.fetchEntities("Playlist", predicate: userCreatedPredicate, moc:moc) as! [Playlist]
//                    for playlist in userPlaylistsArray {
//                        // TODO: update the userId for the corresponding playlists saved on server when userId is changed
//                        playlist.userId = newUserId
//                    }
//                    CoreDataHelper.saveCoreData(moc, completionBlock: nil)
//                    
//                    NSUserDefaults.standardUserDefaults().setValue(newUserId, forKeyPath: Constants.kUserId)
//                    
//                    self.tableView.reloadData()
//                }
//            }))
//            
//        }
//        presentViewController(createChangeUserIdAlert, animated: true, completion: nil)
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
        return 2
    }
    
    // TODO: probably this can be done in a cleaner way than how I'm doing it with prototype cells...
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("settingsCell", forIndexPath: indexPath)
        if indexPath.row == 0 {
            if PVUtility.isAnonymousUser() {
                cell.textLabel?.text = "Log in"
            } else {
                cell.textLabel?.text = "Edit Username"
            }
        } else if indexPath.row == 1 {
            if PVUtility.isAnonymousUser() {
                cell.textLabel?.text = "Sign up"
            } else {
                cell.textLabel?.text = "Log out"
            }
            
        }
        
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.row == 0 {
            
            if PVUtility.isAnonymousUser() {
                PVAuth.sharedInstance.showAuth0LockLoginVC(self)
            } else {
                let setUserNameAlert = UIAlertController(title: "Edit Username", message: "Your username is visible on the clips and playlists you create.", preferredStyle: UIAlertControllerStyle.Alert)
                
                setUserNameAlert.addTextFieldWithConfigurationHandler({(textField: UITextField!) in
                    if let userName = NSUserDefaults.standardUserDefaults().stringForKey("userName") {
                        textField.text = userName
                    }

                })
                
                setUserNameAlert.addAction(UIAlertAction(title: "Cancel", style: .Default, handler: nil))
                
                setUserNameAlert.addAction(UIAlertAction(title: "Save", style: .Default, handler: { (action: UIAlertAction!) in
                    if let textField = setUserNameAlert.textFields?[0], username = textField.text {
                        PVAuth.sharedInstance.setUserNameAndUpdateOwnedItems(username)
                    }
                }))
                
                presentViewController(setUserNameAlert, animated: true, completion: nil)
            }
            
        } else if indexPath.row == 1 {
            if PVUtility.isAnonymousUser() {
                PVAuth.sharedInstance.showAuth0LockSignUpVC(self)
            } else {
                let logOutAlert = UIAlertController(title: "Log Out", message: "Podverse is intended for one user per mobile device at a time. To log out please delete the app, then reinstall if you want to sign in as a new user.", preferredStyle: UIAlertControllerStyle.Alert)
                logOutAlert.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
                presentViewController(logOutAlert, animated: true, completion: nil)
            }
        }
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == Constants.TO_PLAYER_SEGUE_ID {
            let mediaPlayerViewController = segue.destinationViewController as! MediaPlayerViewController
            mediaPlayerViewController.hidesBottomBarWhenPushed = true
        }
    }
}

extension SettingsViewController:PVAuthDelegate {
    func authFinished() {
        self.tableView.reloadData()
    }
}
