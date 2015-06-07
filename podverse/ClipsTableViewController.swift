//
//  ClipsTableViewController.swift
//  podverse
//
//  Created by Mitchell Downey on 6/2/15.
//  Copyright (c) 2015 Mitchell Downey. All rights reserved.
//

import UIKit

class ClipsTableViewController: UITableViewController {

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
        
        clipArray = unsortedClips.sortedArrayUsingDescriptors([sortDescriptor]) as! [Clip]
        
        self.tableView.reloadData()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        if let context = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext {
            moc = context
        }
        
        loadData()
        
        self.title = selectedEpisode.title
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Potentially incomplete method implementation.
        // Return the number of sections.
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete method implementation.
        // Return the number of rows in the section.
        return clipArray.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) as! UITableViewCell
        cell.textLabel?.text = clipArray[indexPath.row].title
        return cell
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
        if segue.identifier == "playEpisode" {
            let mediaPlayerViewController = segue.destinationViewController as! MediaPlayerViewController
            
            mediaPlayerViewController.selectedEpisode? = selectedEpisode

            mediaPlayerViewController.selectedClip = nil
            
            navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .Plain, target: nil, action: nil)
        }
        if segue.identifier == "playClip" {
            let mediaPlayerViewController = segue.destinationViewController as! MediaPlayerViewController
            
            mediaPlayerViewController.selectedEpisode? = selectedEpisode
            
            if let index = self.tableView.indexPathForSelectedRow() {
                mediaPlayerViewController.selectedClip? = clipArray[index.row]
            }
            
            navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .Plain, target: nil, action: nil)
        }
    }
}
