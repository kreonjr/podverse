//
//  DownloadsTableViewController.swift
//  podverse
//
//  Created by Mitchell Downey on 6/23/15.
//  Copyright (c) 2015 Mitchell Downey. All rights reserved.
//

import UIKit
import CoreData

class DownloadsTableViewController: UITableViewController {

    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    
    var reloadDataTimer: NSTimer!
    
    func segueToNowPlaying(sender: UIBarButtonItem) {
        self.performSegueWithIdentifier("Downloads to Now Playing", sender: nil)
    }
    
    func reloadDownloadTableData() {
        self.tableView.reloadData()
    }
    
    func removePlayerNavButton(notification: NSNotification) {
        dispatch_async(dispatch_get_main_queue()) {
            self.reloadDownloadTableData()
            PVMediaPlayer.sharedInstance.removePlayerNavButton(self)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Style the navigation bar
        self.navigationController?.navigationBar.barStyle = UIBarStyle.Black
        self.navigationController?.navigationBar.tintColor = UIColor.whiteColor()
        self.navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName: UIColor.whiteColor(), NSFontAttributeName: UIFont.boldSystemFontOfSize(16.0)]
        
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .Plain, target: nil, action: nil)
        
    }
    
    override func viewWillAppear(animated: Bool) {
        
        PVMediaPlayer.sharedInstance.addPlayerNavButton(self)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "removePlayerNavButton:", name: Constants.kPlayerHasNoItem, object: nil)
        
        reloadDownloadTableData()
        
        // Create reloadDataTimer when this view appears to reload table data every second
        self.reloadDataTimer = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: Selector("reloadDownloadTableData"), userInfo: nil, repeats: true)
    }
    
    override func viewDidDisappear(animated: Bool) {
        // Remove reloadDataTimer when leaving this view
        if self.reloadDataTimer != nil {
            self.reloadDataTimer.invalidate()
            self.reloadDataTimer = nil
        }
        
        NSNotificationCenter.defaultCenter().removeObserver(self, name: Constants.kPlayerHasNoItem, object: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
        
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Potentially incomplete method implementation.
        // Return the number of sections.
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return DLEpisodesList.shared.downloadingEpisodes.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell: DownloadsTableViewCell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) as! DownloadsTableViewCell
        let episode = DLEpisodesList.shared.downloadingEpisodes[indexPath.row]
        
        cell.title!.text = episode.title
        
        if let imageData = episode.podcast.imageData {
            if let image = UIImage(data: imageData) {
                cell.pvImage?.image = image
            }
        }

        if cell.pvImage?.image == nil {
            if let itunesImageData = episode.podcast.itunesImage {
                if let itunesImage = UIImage(data: itunesImageData) {
                    cell.pvImage?.image = itunesImage
                }
            }
        }
        
        if let downloadProgress = episode.downloadProgress, let totalMediaBytes = episode.mediaBytes {
            // Format the total bytes into a human readable KB or MB number
            let dataFormatter = NSByteCountFormatter()
            
            cell.progress.progress = Float(downloadProgress)
            let currentBytesDownloaded = Int64(Float(downloadProgress) * Float(totalMediaBytes))
            let formattedCurrentBytesDownloaded = dataFormatter.stringFromByteCount(currentBytesDownloaded)
            let formattedTotalFileBytes = dataFormatter.stringFromByteCount(Int64(Float(totalMediaBytes)))
            cell.progressBytes.text = "\(formattedCurrentBytesDownloaded) / \(formattedTotalFileBytes)"
        }
        
        if episode.downloadComplete == true {
            cell.downloadStatus.text = "Finished"
        }
        else if episode.taskIdentifier != nil {
            cell.downloadStatus.text = "Downloading"
        }
        else {
            cell.downloadStatus.text = "Paused"
        }

        return cell
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 100
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let episode = DLEpisodesList.shared.downloadingEpisodes[indexPath.row]
        PVDownloader.sharedInstance.pauseOrResumeDownloadingEpisode(episode)
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
        if segue.identifier == "Downloads to Now Playing" {
            let mediaPlayerViewController = segue.destinationViewController as! MediaPlayerViewController
            mediaPlayerViewController.hidesBottomBarWhenPushed = true
        }
    }

}
