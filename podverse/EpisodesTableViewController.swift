//
//  EpisodesTableViewController.swift
//  podverse
//
//  Created by Mitchell Downey on 6/2/15.
//  Copyright (c) 2015 Mitchell Downey. All rights reserved.
//

import UIKit
import CoreData

class EpisodesTableViewController: UITableViewController {
    
    var utility = PVUtility()
    
    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    
    var downloader = PVDownloader()
    
    var selectedPodcast: Podcast!
    
    var moc: NSManagedObjectContext!
    var episodeArray = [Episode]()
    
    func loadData() {
        episodeArray = [Episode]()
        episodeArray = CoreDataHelper.fetchEntities("Episode", managedObjectContext: moc, predicate: nil) as! [Episode]
        
        var unsortedEpisodes = NSMutableArray()
        
        for singleEpisode in selectedPodcast.episodes {
            let loopEpisode = singleEpisode as! Episode
            unsortedEpisodes.addObject(loopEpisode)
        }
        
        let sortDescriptor = NSSortDescriptor(key: "pubDate", ascending: false)
        
        episodeArray = unsortedEpisodes.sortedArrayUsingDescriptors([sortDescriptor]) as! [Episode]
        
        self.tableView.reloadData()
    }
    
    func segueToNowPlaying(sender: UIBarButtonItem) {
        self.performSegueWithIdentifier("Episodes to Now Playing", sender: nil)
    }
    
    func updateDownloadFinishedButton(notification: NSNotification) {
        let userInfo : Dictionary<String,Episode> = notification.userInfo as! Dictionary<String,Episode>
        let episode = userInfo["episode"]
        
        //  TOASK: Could this be more efficient? Should we only reload the proper cell, and not all with reloadData?
        dispatch_async(dispatch_get_main_queue()) {
            self.tableView.reloadData()
        }

    }
    
    func downloadPlay(sender: UIButton) {
        let view = sender.superview!
        let cell = view.superview as! EpisodesTableCell
        let indexPath = self.tableView.indexPathForCell(cell)
        
        if let indexPath = self.tableView.indexPathForCell(cell) {
            var selectedEpisode = episodeArray[indexPath.row]
            if selectedEpisode.fileName != nil {
                self.performSegueWithIdentifier("Quick Play Downloaded Episode", sender: selectedEpisode)
            } else {
                self.downloader.startOrPauseDownloadingEpisode(selectedEpisode, tblViewController: self, completion: nil)
                if (selectedEpisode.isDownloading == true) {
                    cell.downloadPlayButton.setTitle("\u{f110}", forState: .Normal)
                }
            }
        }
        
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        if let context = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext {
            moc = context
        }

        loadData()
        
        self.title = selectedPodcast.title
        
        self.navigationController?.navigationBar.barStyle = UIBarStyle.Black
        
        self.navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName: UIColor.whiteColor(), NSFontAttributeName: UIFont.boldSystemFontOfSize(16.0)]
        
        if ((appDelegate.nowPlayingEpisode) != nil) {
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Player", style: .Plain, target: self, action: "segueToNowPlaying:")
        }
        
        dispatch_async(dispatch_get_main_queue()) {
            self.tableView.reloadData()
        }
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "updateDownloadFinishedButton:", name: kDownloadHasFinished, object: nil)

    }
    
    override func viewWillDisappear(animated: Bool) {

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerCell = tableView.dequeueReusableCellWithIdentifier("HeaderCell") as! EpisodesTableHeaderCell
        
        var imageData = selectedPodcast.image
        var image = UIImage(data: imageData!)
        
        headerCell.pvImage!.image = image
        headerCell.summary!.text = selectedPodcast.summary
        return headerCell
    }
    
    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 100
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Potentially incomplete method implementation.
        // Return the number of sections.
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete method implementation.
        // Return the number of rows in the section.
        return episodeArray.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) as! EpisodesTableCell
        
        let episode = episodeArray[indexPath.row]
        
        cell.title?.text = episode.title
        
        if episode.summary != nil {
            cell.summary?.text = utility.removeHTMLFromString(episode.summary!)
        }
        
        cell.totalClips?.text = String("123 clips")
        
        cell.totalTimeLeft?.text = utility.convertNSNumberToHHMMSSString(episode.duration!)
        
        cell.pubDate?.text = utility.formatDateToString(episode.pubDate!)
        
        if episode.fileName != nil {
            cell.downloadPlayButton.setTitle("\u{f04b}", forState: .Normal)
        }
        else {
            if (episode.isDownloading == true) {
                cell.downloadPlayButton.setTitle("\u{f110}", forState: .Normal)
            } else {
                cell.downloadPlayButton.setTitle("\u{f019}", forState: .Normal)
            }
        }
        
        cell.downloadPlayButton.addTarget(self, action: "downloadPlay:", forControlEvents: .TouchUpInside)
        
        return cell
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 120
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        var episodeActions = UIAlertController(title: "Episode Options", message: "", preferredStyle: UIAlertControllerStyle.ActionSheet)
        
        let selectedEpisode = episodeArray[indexPath.row]
        
        if selectedEpisode.fileName != nil {
            episodeActions.addAction(UIAlertAction(title: "Play Episode", style: .Default, handler: { action in
                self.performSegueWithIdentifier("playDownloadedEpisode", sender: nil)
            }))
        } else {
            episodeActions.addAction(UIAlertAction(title: "Download Episode", style: .Default, handler: { action in
                self.downloader.startOrPauseDownloadingEpisode(selectedEpisode, tblViewController: self, completion: nil)
            }))
        }
        
        let totalClips = "(123)"
        episodeActions.addAction(UIAlertAction(title: "Show Clips \(totalClips)", style: .Default, handler: { action in
            self.performSegueWithIdentifier("showClips", sender: self)
        }))
        
        episodeActions.addAction(UIAlertAction (title: "Episode Info", style: .Default, handler: nil))
        
        episodeActions.addAction(UIAlertAction (title: "Stream Episode", style: .Default, handler: { action in
            self.performSegueWithIdentifier("streamEpisode", sender: self)
        }))
        
        episodeActions.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
        
        self.presentViewController(episodeActions, animated: true, completion: nil)
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
        if segue.identifier == "playDownloadedEpisode" {
            
            let mediaPlayerViewController = segue.destinationViewController as! MediaPlayerViewController
            
            if let index = self.tableView.indexPathForSelectedRow() {
                mediaPlayerViewController.selectedEpisode = episodeArray[index.row]
            }
            
            mediaPlayerViewController.startDownloadedEpisode = true
            mediaPlayerViewController.hidesBottomBarWhenPushed = true
            
        } else if segue.identifier == "Quick Play Downloaded Episode" {
            
            let mediaPlayerViewController = segue.destinationViewController as! MediaPlayerViewController
            mediaPlayerViewController.selectedEpisode = sender as! Episode
            mediaPlayerViewController.startDownloadedEpisode = true
            mediaPlayerViewController.hidesBottomBarWhenPushed = true
            
        } else if segue.identifier == "showClips" {
            let clipsTableViewController = segue.destinationViewController as! ClipsTableViewController
            
            if let index = self.tableView.indexPathForSelectedRow() {
                clipsTableViewController.selectedEpisode = episodeArray[index.row]
            }
            
            navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .Plain, target: nil, action: nil)
        } else if segue.identifier == "streamEpisode" {
            let mediaPlayerViewController = segue.destinationViewController as! MediaPlayerViewController
            
            if let index = self.tableView.indexPathForSelectedRow() {
                mediaPlayerViewController.selectedEpisode = episodeArray[index.row]
            }
            
            mediaPlayerViewController.startStreamingEpisode = true
            
            mediaPlayerViewController.hidesBottomBarWhenPushed = true
            
        } else if segue.identifier == "Episodes to Now Playing" {
            let mediaPlayerViewController = segue.destinationViewController as! MediaPlayerViewController
            
            mediaPlayerViewController.selectedEpisode = appDelegate.nowPlayingEpisode
            
            mediaPlayerViewController.hidesBottomBarWhenPushed = true
        }
        // navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .Plain, target: nil, action: nil)
    }
    
}