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
    var subscriber = PVSubscriber()
    
    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    
    var downloader = PVDownloader()
    
    var parser = PVFeedParser()
    
    var selectedPodcast: Podcast!
    
    var moc: NSManagedObjectContext!
    var episodesArray = [Episode]()
    
    var showAllAvailableEpisodes: Bool = false
    
    func loadData() {
        
        // Clear the episodes array, then retrieve and sort the full episode or downloaded episode array
        self.episodesArray = [Episode]()
        var unsortedEpisodes = NSMutableArray()
        
        if self.showAllAvailableEpisodes == true {
            for singleEpisode in selectedPodcast.episodes {
                let loopEpisode = singleEpisode as! Episode
                unsortedEpisodes.addObject(loopEpisode)
            }
        }
        else {
            let downloadedEpisodesArrayPredicate = NSPredicate(format: "fileName != nil || isDownloading == true", [])

            let downloadedEpisodesArray = selectedPodcast.episodes.filteredSetUsingPredicate(downloadedEpisodesArrayPredicate)
            
            for singleEpisode in downloadedEpisodesArray {
                let loopEpisode = singleEpisode as! Episode
                unsortedEpisodes.addObject(loopEpisode)
            }
        }
        
        let sortDescriptor = NSSortDescriptor(key: "pubDate", ascending: false)
        
        self.episodesArray = unsortedEpisodes.sortedArrayUsingDescriptors([sortDescriptor]) as! [Episode]
        
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
            var selectedEpisode = episodesArray[indexPath.row]
            if selectedEpisode.fileName != nil {
                self.performSegueWithIdentifier("Quick Play Downloaded Episode", sender: selectedEpisode)
            } else {
                self.downloader.startPauseOrResumeDownloadingEpisode(selectedEpisode, completion: nil)
                if (selectedEpisode.isDownloading == true) {
                    cell.downloadPlayButton.setTitle("\u{f110}", forState: .Normal)
                    
                }
            }
        }
        
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
//        if let context = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext {
//            moc = context
//        }

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
        
        headerCell.pvImage?.image = UIImage(named: "Blank52")
        
        var imageData = selectedPodcast.image
        var itunesImageData = selectedPodcast.itunesImage
        
        if imageData != nil {
            var image = UIImage(data: imageData!)
            // TODO: below is probably definitely not the proper way to check for a nil value for an image, but I was stuck on it for a long time and moved on
            if image!.size.height != 0.0 {
                headerCell.pvImage?.image = image
            }
        }
        else {
            if itunesImageData != nil {
                var itunesImage = UIImage(data: itunesImageData!)
                
                if itunesImage!.size.height != 0.0 {
                    headerCell.pvImage?.image = itunesImage
                }
            }
        }
        
        headerCell.summary!.text = selectedPodcast.summary
        return headerCell
    }
    
    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 100
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return episodesArray.count + 1
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        // If not the last cell, then insert episode information into cell
        if indexPath.row < episodesArray.count {
            let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) as! EpisodesTableCell
            
            let episode = episodesArray[indexPath.row]
            
            cell.title?.text = episode.title
            
            if let summary = episode.summary {
                cell.summary?.text = utility.removeHTMLFromString(summary)
            }
            
            cell.totalClips?.text = String("123 clips")
            
            if let duration = episode.duration {
                cell.totalTimeLeft?.text = utility.convertNSNumberToHHMMSSString(episode.duration!)
            }

            if let pubDate = episode.pubDate {
                cell.pubDate?.text = utility.formatDateToString(pubDate)
            }
            
            // Set icon conditionally if is downloaded, is downloading, or has not downloaded
            // If filename exists, then episode is downloaded and display play button
            if episode.fileName != nil {
                cell.downloadPlayButton.setTitle("\u{f04b}", forState: .Normal)
            }
            // Else if episode is downloading, then display downloading icon
            else if (episode.isDownloading == true) {
                cell.downloadPlayButton.setTitle("\u{f110}", forState: .Normal)
            }
            // Else display the start download icon
            else {
                cell.downloadPlayButton.setTitle("\u{f019}", forState: .Normal)
            }
            
            cell.downloadPlayButton.addTarget(self, action: "downloadPlay:", forControlEvents: .TouchUpInside)
            
            return cell
        }
        // Return the Show All Available Episodes / Show Downloaded Episodes button
        else {
            let cell = tableView.dequeueReusableCellWithIdentifier("showAllEpisodesCell", forIndexPath: indexPath) as! UITableViewCell
            
            if showAllAvailableEpisodes == true {
                cell.textLabel!.text = "Show Downloaded Episodes"
            }
            else {
                cell.textLabel!.text = "Show All Available Episodes"
            }
            
            return cell
        }
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if indexPath.row < episodesArray.count {
            return 120
        }
        else {
            return 60
        }

    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        // If not the last item in the array, then perform selected episode actions
        if indexPath.row < episodesArray.count {
            
            var episodeActions = UIAlertController(title: "Episode Options", message: "", preferredStyle: UIAlertControllerStyle.ActionSheet)
            
            let selectedEpisode = episodesArray[indexPath.row]
            
            if selectedEpisode.fileName != nil {
                
                episodeActions.addAction(UIAlertAction(title: "Play Episode", style: .Default, handler: { action in
                    self.performSegueWithIdentifier("playDownloadedEpisode", sender: nil)
                }))
                
            } else {
                
                episodeActions.addAction(UIAlertAction(title: "Download Episode", style: .Default, handler: { action in
                    
                    self.downloader.startPauseOrResumeDownloadingEpisode(selectedEpisode, completion: nil)
                    
                    let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) as! EpisodesTableCell
                    
                    if (selectedEpisode.isDownloading == true) {
                        cell.downloadPlayButton.setTitle("\u{f110}", forState: .Normal)
                    } else {
                        cell.downloadPlayButton.setTitle("\u{f019}", forState: .Normal)
                    }
                    
                    dispatch_async(dispatch_get_main_queue()) {
                        self.tableView.reloadData()
                    }
                    
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
        // Else perform the Show All Episodes / Show Downloaded Episodes toggle
        else {
            showAllAvailableEpisodes = !showAllAvailableEpisodes
            self.loadData()
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
        if segue.identifier == "playDownloadedEpisode" {
            
            let mediaPlayerViewController = segue.destinationViewController as! MediaPlayerViewController
            if let index = self.tableView.indexPathForSelectedRow() {
                mediaPlayerViewController.selectedEpisode = episodesArray[index.row]
            }
            mediaPlayerViewController.startDownloadedEpisode = true
            mediaPlayerViewController.hidesBottomBarWhenPushed = true
            
        }
        else if segue.identifier == "Quick Play Downloaded Episode" {
            
            let mediaPlayerViewController = segue.destinationViewController as! MediaPlayerViewController
            mediaPlayerViewController.selectedEpisode = sender as! Episode
            mediaPlayerViewController.startDownloadedEpisode = true
            mediaPlayerViewController.hidesBottomBarWhenPushed = true
            
        }
        else if segue.identifier == "showClips" {
            
            let clipsTableViewController = segue.destinationViewController as! ClipsTableViewController
            if let index = self.tableView.indexPathForSelectedRow() {
                clipsTableViewController.selectedEpisode = episodesArray[index.row]
            }
            navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .Plain, target: nil, action: nil)
            
        }
        else if segue.identifier == "streamEpisode" {
            
            let mediaPlayerViewController = segue.destinationViewController as! MediaPlayerViewController
            if let index = self.tableView.indexPathForSelectedRow() {
                mediaPlayerViewController.selectedEpisode = episodesArray[index.row]
            }
            mediaPlayerViewController.startStreamingEpisode = true
            mediaPlayerViewController.hidesBottomBarWhenPushed = true
            
        }
        else if segue.identifier == "Episodes to Now Playing" {
            
            let mediaPlayerViewController = segue.destinationViewController as! MediaPlayerViewController
            mediaPlayerViewController.selectedEpisode = appDelegate.nowPlayingEpisode
            mediaPlayerViewController.hidesBottomBarWhenPushed = true
            
        }
    }
    
}