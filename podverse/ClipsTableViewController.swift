//
//  ClipsTableViewController.swift
//  podverse
//
//  Created by Mitchell Downey on 6/2/15.
//  Copyright (c) 2015 Mitchell Downey. All rights reserved.
//

import UIKit

class ClipsTableViewController: UITableViewController {
    
    var utility = PVUtility()
    
    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    
    var selectedEpisode: Episode!
    
    var moc: NSManagedObjectContext!
    var clipArray = [Clip]()
    
    func loadData() {
        clipArray = [Clip]()
        clipArray = CoreDataHelper.fetchEntities(NSStringFromClass(Clip), managedObjectContext: moc, predicate: nil) as! [Clip]
        
        var unsortedClips = NSMutableArray()

        for singleClip in selectedEpisode.clips {
            let loopClip = singleClip as! Clip
            unsortedClips.addObject(loopClip)
        }
        
        let sortDescriptor = NSSortDescriptor(key: "startTime", ascending: false)
        
//        var fullEpisodeClip = CoreDataHelper.insertManagedObject(NSStringFromClass(Clip), managedObjectContext: self.moc) as! Clip
//        
//        fullEpisodeClip.title = "Play Full Episode"
//        fullEpisodeClip.startTime = "0:00"
//        fullEpisodeClip.endTime = "12:34:56"
        
        clipArray = unsortedClips.sortedArrayUsingDescriptors([sortDescriptor]) as! [Clip]
        
        self.tableView.reloadData()
    }
    
    func segueToNowPlaying(sender: UIBarButtonItem) {
        self.performSegueWithIdentifier("Clips to Now Playing", sender: nil)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        if let context = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext {
            moc = context
        }
        
        loadData()
        
        self.title = selectedEpisode.title
        
        if ((appDelegate.nowPlayingEpisode) != nil) {
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Player", style: .Plain, target: self, action: "segueToNowPlaying:")
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    // MARK: - Table view data source

    override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerCell = tableView.dequeueReusableCellWithIdentifier("HeaderCell") as! ClipsTableHeaderCell
        
        var imageData = selectedEpisode.podcast.image
        var image = UIImage(data: imageData)
        
        headerCell.pvImage!.image = image
        headerCell.summary!.text = utility.removeHTMLFromString(selectedEpisode.summary)
        
        return headerCell
    }
    
    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 100
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return clipArray.count + 1
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) as! ClipsTableCell
        
        if indexPath.row == 0 {
            cell.title?.text = "PLAY FULL EPISODE"
            cell.startTimeEndTime?.text = "2:34:56"
            cell.totalTime?.text = ""
            cell.score?.text = "1234"
        } else {
            cell.title?.text = clipArray[indexPath.row].title
            cell.startTimeEndTime?.text = "1:12:34 - 1:23:45"
            cell.totalTime?.text = "10m 11s"
            cell.score?.text = "1234"
        }
        
        return cell
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 100
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
        if segue.identifier == "Play" {
            let mediaPlayerViewController = segue.destinationViewController as! MediaPlayerViewController
            
            if let index = self.tableView.indexPathForSelectedRow() {
                if index.row == 0 {
                    mediaPlayerViewController.selectedEpisode = selectedEpisode
                } else {
                    mediaPlayerViewController.selectedClip = clipArray[index.row]
                }
            }
            
            navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .Plain, target: nil, action: nil)
            
            mediaPlayerViewController.hidesBottomBarWhenPushed = true
        } else if segue.identifier == "Clips to Now Playing" {
            let mediaPlayerViewController = segue.destinationViewController as! MediaPlayerViewController
            
            mediaPlayerViewController.selectedEpisode = appDelegate.nowPlayingEpisode
            
            mediaPlayerViewController.hidesBottomBarWhenPushed = true
        }
    }
}
