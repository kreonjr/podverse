//
//  FindTableViewController.swift
//  
//
//  Created by Mitchell Downey on 7/10/15.
//
//

import UIKit

class FindTableViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
    var appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    
    let reachability = PVReachability.manager
    
    var findSearchArray = ["Search", "Add Podcast by RSS"]
    
    var podcastVC:PodcastsTableViewController? {
        get {
            if let navController = self.tabBarController?.viewControllers?.first as? UINavigationController, podcastTable = navController.topViewController as? PodcastsTableViewController {
                return podcastTable
            }
            
            return nil
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        navigationItem.rightBarButtonItem = self.playerNavButton()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .Plain, target: nil, action: nil)
        
        // Set navigation bar styles
        self.navigationItem.title = "Find"
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(removePlayerNavButton), name: Constants.kPlayerHasNoItem, object: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

extension FindTableViewController:UITableViewDelegate, UITableViewDataSource {
    
    // MARK: - Table view data source
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Podcasts"
        
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return findSearchArray.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath)
        
        let title = findSearchArray[indexPath.row]
        cell.textLabel!.text = title
        
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.section == 0 {
            if indexPath.row == 0 {
                self.performSegueWithIdentifier("Search for Podcasts", sender: tableView)
            }
            else {
                if reachability.hasInternetConnection() == false {
                    showInternetNeededAlert("Connect to WiFi or cellular data to add podcast by RSS URL.")
                    return
                }
                let addByRSSAlert = UIAlertController(title: "Add Podcast by RSS Feed", message: "Type the RSS feed URL below.", preferredStyle: UIAlertControllerStyle.Alert)
                
                addByRSSAlert.addTextFieldWithConfigurationHandler({(textField: UITextField!) in
                    textField.placeholder = "https://rssfeed.example.com/"
                })
                
                addByRSSAlert.addAction(UIAlertAction(title: "Cancel", style: .Default, handler: nil))
                
                addByRSSAlert.addAction(UIAlertAction(title: "Add", style: .Default, handler: { (action: UIAlertAction!) in
                    if let textField = addByRSSAlert.textFields?[0], text = textField.text {
                        PVSubscriber.subscribeToPodcast(text, podcastTableDelegate: self.podcastVC)
                    }
                }))
                
                presentViewController(addByRSSAlert, animated: true, completion: nil)
            }
        }
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == Constants.TO_PLAYER_SEGUE_ID {
            let mediaPlayerViewController = segue.destinationViewController as! MediaPlayerViewController
            mediaPlayerViewController.hidesBottomBarWhenPushed = true
        }
    }
    
}
