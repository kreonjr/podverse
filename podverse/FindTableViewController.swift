//
//  FindTableViewController.swift
//  
//
//  Created by Mitchell Downey on 7/10/15.
//
//

import UIKit

class FindTableViewController: UITableViewController {
    
    var appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    
    var findSearchArray = ["Search", "Add Podcast by RSS"]
    
    var podcastVC:PodcastsTableViewController? {
        get {
            if let navController = self.tabBarController?.viewControllers?.first as? UINavigationController, podcastTable = navController.topViewController as? PodcastsTableViewController {
                return podcastTable
            }
            
            return nil
        }
    }
    
    func segueToNowPlaying(sender: UIBarButtonItem) {
        self.performSegueWithIdentifier("Find to Now Playing", sender: nil)
    }
    
    func removePlayerNavButton(notification: NSNotification) {
        dispatch_async(dispatch_get_main_queue()) {
            PVMediaPlayer.sharedInstance.removePlayerNavButton(self)
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        PVMediaPlayer.sharedInstance.addPlayerNavButton(self)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(FindTableViewController.removePlayerNavButton(_:)), name: Constants.kPlayerHasNoItem, object: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .Plain, target: nil, action: nil)
        
        // Set navigation bar styles
        self.navigationItem.title = "Find"
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: Constants.kPlayerHasNoItem, object: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Podcasts"

    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return findSearchArray.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath)

        let title = findSearchArray[indexPath.row]
        cell.textLabel!.text = title

        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.section == 0 {
            if indexPath.row == 0 {
                self.performSegueWithIdentifier("Search for Podcasts", sender: tableView)
            }
            else {
                tableView.deselectRowAtIndexPath(indexPath, animated: false)
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
        else {
            // perform segue based on dynamic itunes API data
        }
    }

    /*
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return NO if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Delete the row from the data source
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return NO if you do not want the item to be re-orderable.
        return true
    }
    */

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "Find to Now Playing" {
            let mediaPlayerViewController = segue.destinationViewController as! MediaPlayerViewController
            mediaPlayerViewController.hidesBottomBarWhenPushed = true
        }
    }

}
