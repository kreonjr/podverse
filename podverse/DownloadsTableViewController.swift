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
    
    var episodes:[DownloadingEpisode] {
        get {
            return DLEpisodesList.shared.downloadingEpisodes
        }
    }
    
    func segueToNowPlaying(sender: UIBarButtonItem) {
        self.performSegueWithIdentifier("Downloads to Now Playing", sender: nil)
    }
    
    func reloadDownloadTable() {
        dispatch_async(dispatch_get_main_queue()) {
            self.tableView.reloadData()
        }
    }
    
    func removePlayerNavButton(notification: NSNotification) {
        dispatch_async(dispatch_get_main_queue()) {
            self.reloadDownloadTable()
            PVMediaPlayer.sharedInstance.removePlayerNavButton(self)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .Plain, target: nil, action: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(DownloadsTableViewController.reloadDownloadData(_:)), name: Constants.kDownloadHasProgressed, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(DownloadsTableViewController.reloadDownloadData(_:)), name: Constants.kDownloadHasFinished, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(DownloadsTableViewController.pauseOrResumeDownloadData(_:)), name: Constants.kDownloadHasPausedOrResumed, object: nil)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(DownloadsTableViewController.removePlayerNavButton(_:)), name: Constants.kPlayerHasNoItem, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(DownloadsTableViewController.reloadDownloadTable), name: Constants.kUpdateDownloadsTable, object: nil)
    }
    
    func reloadDownloadData(notification:NSNotification) {
        if let downloadDataInfo = notification.userInfo {
            for(index, episode) in self.episodes.enumerate() {
                let indexPath = NSIndexPath(forRow: index, inSection: 0)
                if episode.mediaURL == downloadDataInfo["mediaUrl"] as? String, let totalBytes = downloadDataInfo["totalBytes"] as? Float, let currentBytes = downloadDataInfo["currentBytes"]as? Float, let cell = self.tableView.cellForRowAtIndexPath(indexPath) as? DownloadsTableViewCell  {
                    
                        // Format the total bytes into a human readable KB or MB number
                        let dataFormatter = NSByteCountFormatter()
                        
                        cell.progress.progress = Float(currentBytes / totalBytes)
                        let formattedCurrentBytesDownloaded = dataFormatter.stringFromByteCount(Int64(currentBytes))
                        let formattedTotalFileBytes = dataFormatter.stringFromByteCount(Int64(totalBytes))
                        cell.progressBytes.text = "\(formattedCurrentBytesDownloaded) / \(formattedTotalFileBytes)"
                    
                        if cell.progress.progress == 1.0 {
                            cell.downloadStatus.text = "Finished"
                            cell.progressBytes.text = "\(formattedTotalFileBytes)"
                        }
                                        
                        return
                }
            }
        }
    }
    
    func pauseOrResumeDownloadData(notification:NSNotification) {
        if let downloadDataInfo = notification.userInfo {
            for(index, episode) in self.episodes.enumerate() {
                let indexPath = NSIndexPath(forRow: index, inSection: 0)
                if episode.mediaURL == downloadDataInfo["mediaUrl"] as? String, let pauseOrResume = downloadDataInfo["pauseOrResume"] as? String, let cell = self.tableView.cellForRowAtIndexPath(indexPath) as? DownloadsTableViewCell  {
                    cell.downloadStatus.text = pauseOrResume
                    return
                }
            }
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        PVMediaPlayer.sharedInstance.addPlayerNavButton(self)
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
        let downloadingEpisode = DLEpisodesList.shared.downloadingEpisodes[indexPath.row]
        
        cell.title?.text = downloadingEpisode.title
        
        if let imageData = downloadingEpisode.imageData {
            if let image = UIImage(data: imageData) {
                cell.pvImage?.image = image
            }
        }
        
        if downloadingEpisode.downloadComplete == true {
            cell.downloadStatus.text = "Finished"
            cell.progress.progress = Float(1)
        }
        else if downloadingEpisode.taskIdentifier != nil {
            cell.downloadStatus.text = "Downloading"
            cell.progress.progress = downloadingEpisode.progress
        }
        else {
            cell.downloadStatus.text = "Paused"
            cell.progress.progress = downloadingEpisode.progress
        }
        
        cell.progressBytes.text = downloadingEpisode.formattedTotalBytesDownloaded

        return cell
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 100
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let downloadingEpisode = DLEpisodesList.shared.downloadingEpisodes[indexPath.row]
        
        guard downloadingEpisode.mediaURL != nil else {
            return
        }
        
        let downloader = PVDownloader()
        downloader.pauseOrResumeDownloadingEpisode(downloadingEpisode)
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
