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
    
    var findSearchArray = ["Search for Podcasts", "Add Podcast by RSS"]
    
    var findBrowseArray = ["All", "ABC", "DEF", "GHI"]
    
    func segueToNowPlaying(sender: UIBarButtonItem) {
        self.performSegueWithIdentifier("Find to Now Playing", sender: nil)
    }
    
    override func viewDidAppear(animated: Bool) {
        // If there is a now playing episode, add Now Playing button to navigation bar
        if ((PVMediaPlayer.sharedInstance.nowPlayingEpisode) != nil) {
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Player", style: .Plain, target: self, action: "segueToNowPlaying:")
        }
        
        // Set navigation bar styles
        self.navigationItem.title = "Find"
        self.navigationController?.navigationBar.barStyle = UIBarStyle.Black
        self.navigationController?.navigationBar.tintColor = UIColor.whiteColor()
        self.navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName: UIColor.whiteColor(), NSFontAttributeName: UIFont.boldSystemFontOfSize(16.0)]
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        
        if (section == 0) {
            return ""
        }
        else {
            return "Browse"
        }
        
    }
    
    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 40
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (section == 0) {
            return findSearchArray.count
        }
        else {
            return findBrowseArray.count
        }
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath)

        if indexPath.section == 0 {
            let title = findSearchArray[indexPath.row]
            cell.textLabel!.text = title
        }
        else {
            let title = findBrowseArray[indexPath.row]
            cell.textLabel!.text = title
        }

        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.section == 0 {
            if indexPath.row == 0 {
                self.performSegueWithIdentifier("Search for Podcasts", sender: tableView)
            }
            else {
                tableView.deselectRowAtIndexPath(indexPath, animated: false)
                var addByRSSAlert = UIAlertController(title: "Add Podcast by RSS Feed", message: "Type the RSS feed URL below.", preferredStyle: UIAlertControllerStyle.Alert)
                
                addByRSSAlert.addTextFieldWithConfigurationHandler({(textField: UITextField!) in
                    textField.placeholder = "https://rssfeed.example.com/"
                })
                
                addByRSSAlert.addAction(UIAlertAction(title: "Cancel", style: .Default, handler: nil))
                
                addByRSSAlert.addAction(UIAlertAction(title: "Add", style: .Default, handler: { (action: UIAlertAction!) in
                    let textField = addByRSSAlert.textFields![0] as UITextField
                    PVSubscriber.sharedInstance.subscribeToPodcast(textField.text!)
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
        if segue.identifier == "Search For Podcasts" {
            navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .Plain, target: nil, action: nil)
        }
        else if segue.identifier == "Find to Now Playing" {
            let mediaPlayerViewController = segue.destinationViewController as! MediaPlayerViewController
            mediaPlayerViewController.returnToNowPlaying = true
            mediaPlayerViewController.hidesBottomBarWhenPushed = true
            navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .Plain, target: nil, action: nil)
        }
    }

}
