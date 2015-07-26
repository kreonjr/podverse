//
//  DownloadsTableViewController.swift
//  podverse
//
//  Created by Mitchell Downey on 6/23/15.
//  Copyright (c) 2015 Mitchell Downey. All rights reserved.
//

import UIKit

class DownloadsTableViewController: UITableViewController {
    
    var utility = PVUtility()
    
    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    
    var episodeDownloadArray = [Episode]()
    
    var downloader = PVDownloader()
    
    var reloadDataTimer: NSTimer!
    
    func segueToNowPlaying(sender: UIBarButtonItem) {
        self.performSegueWithIdentifier("Downloads to Now Playing", sender: nil)
    }
    
    func reloadDownloadTableData() {
        dispatch_async(dispatch_get_main_queue()) {
            self.tableView.reloadData()
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        
        // Add the Player button if an episode is loaded in the media player
        if ((appDelegate.nowPlayingEpisode) != nil) {
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Player", style: .Plain, target: self, action: "segueToNowPlaying:")
        }
        
        self.episodeDownloadArray = self.appDelegate.episodeDownloadArray
        
        dispatch_async(dispatch_get_main_queue()) {
            self.tableView.reloadData()
        }
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Style the navigation bar
        self.navigationController?.navigationBar.barStyle = UIBarStyle.Black
        self.navigationController?.navigationBar.tintColor = UIColor.whiteColor()
        self.navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName: UIColor.whiteColor(), NSFontAttributeName: UIFont.boldSystemFontOfSize(16.0)]
        
        // Create timer to reload the download table data every second
        self.reloadDataTimer = NSTimer(timeInterval: 1.0, target: self, selector: Selector("reloadDownloadTableData"), userInfo: nil, repeats: true)
        NSRunLoop.currentRunLoop().addTimer(reloadDataTimer, forMode: NSRunLoopCommonModes)
        
    }
    
    override func viewDidDisappear(animated: Bool) {
        
        //  TOASK: What if I had two different observers in one view controller?
        //  Would we pass in something other than self?
        NSNotificationCenter.defaultCenter().removeObserver(self)
        
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
        // #warning Incomplete method implementation.
        // Return the number of rows in the section.
        
        self.episodeDownloadArray = self.appDelegate.episodeDownloadArray
        
        return self.episodeDownloadArray.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell: DownloadsTableViewCell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) as! DownloadsTableViewCell
        let episode = episodeDownloadArray[indexPath.row]
        
        cell.title!.text = episode.title
        
        var imageData = episode.podcast.image
        
        if imageData != nil {
            var image = UIImage(data: imageData!)
            // TODO: below is probably definitely not the proper way to check for a nil value for an image, but I was stuck on it for a long time and moved on
            if image!.size.height != 0.0 {
                cell.pvImage?.image = image
            } else {
                var itunesImageData = episode.podcast.itunesImage
                var itunesImage = UIImage(data: itunesImageData!)
                
                if itunesImage!.size.height != 0.0 {
                    cell.pvImage?.image = itunesImage
                }
            }
        }

        cell.progress.progress = Float(episode.downloadProgress!)
        
        // Format the total bytes into a human readable KB or MB number
        let dataFormatter = NSByteCountFormatter()
        let currentBytesDownloaded = Int64(Float(episode.downloadProgress!) * Float(episode.mediaBytes!))
        let formattedCurrentBytesDownloaded = dataFormatter.stringFromByteCount(currentBytesDownloaded)
        let formattedTotalFileBytes = dataFormatter.stringFromByteCount(Int64(Float(episode.mediaBytes!)))
        
        cell.progressBytes.text = "\(formattedCurrentBytesDownloaded) / \(formattedTotalFileBytes)"
        
        if episode.downloadComplete == true {
            cell.downloadStatus.text = "Finished"
        }
        else if episode.isDownloading == true {
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
            
            mediaPlayerViewController.selectedEpisode = appDelegate.nowPlayingEpisode
            
            mediaPlayerViewController.hidesBottomBarWhenPushed = true
        }    }


}
