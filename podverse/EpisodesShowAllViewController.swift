//
//  EpisodesShowAllViewController.swift
//  podverse
//
//  Created by Mitchell Downey on 12/21/15.
//  Copyright © 2015 Mitchell Downey. All rights reserved.
//

import UIKit
import CoreData

class EpisodesShowAllViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, PVFeedParserDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var headerImageView: UIImageView!
    @IBOutlet weak var headerSummaryLabel: UILabel!
    @IBOutlet weak var headerShadowView: UIView!
    
    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate

    var selectedPodcast: Podcast!
    
    var episodesArray = [Episode]()
    
    var refreshControl: UIRefreshControl!
    
    func loadData() {
        
        // Clear the episodes array, then retrieve and sort the full episode or downloaded episode array
        self.episodesArray = [Episode]()
        let unsortedEpisodes = NSMutableArray()
        
        // Retreive then Show all episodes in the RSS feed
        let allEpisodesArray = Array(selectedPodcast.episodes.allObjects)
        
        for singleEpisode in allEpisodesArray {
            let loopEpisode = singleEpisode as! Episode
            unsortedEpisodes.addObject(loopEpisode)
        }
        
        let sortDescriptor = NSSortDescriptor(key: "pubDate", ascending: false)
        
        self.episodesArray = unsortedEpisodes.sortedArrayUsingDescriptors([sortDescriptor]) as! [Episode]
        
        self.tableView.reloadData()
    }
    
    func segueToNowPlaying(sender: UIBarButtonItem) {
        self.performSegueWithIdentifier("Show All Episodes to Now Playing", sender: nil)
    }
    
    func updateDownloadFinishedButton(notification: NSNotification) {
        //        let userInfo : Dictionary<String,Episode> = notification.userInfo as! Dictionary<String,Episode>
        
        //  TOASK: Could this be more efficient? Should we only reload the proper cell, and not all with reloadData?
        dispatch_async(dispatch_get_main_queue()) {
            self.tableView.reloadData()
        }
        
    }
    
    func downloadPlay(sender: UIButton) {
        let view = sender.superview!
        let cell = view.superview as! EpisodesTableCell
        
        if let indexPath = self.tableView.indexPathForCell(cell) {
            let selectedEpisode = episodesArray[indexPath.row]
            if selectedEpisode.fileName != nil {
                if PVMediaPlayer.sharedInstance.avPlayer.rate == 1 {
                    PVMediaPlayer.sharedInstance.saveCurrentTimeAsPlaybackPosition()
                }
                self.performSegueWithIdentifier("Quick Play Downloaded Episode", sender: selectedEpisode)
            } else {
                PVDownloader.sharedInstance.startDownloadingEpisode(selectedEpisode)
                cell.downloadPlayButton.setTitle("DLing", forState: .Normal)
            }
        }
    }
    
    func refresh() {
        let feedParser = PVFeedParser(shouldGetMostRecent: false, shouldSubscribe: false)
        feedParser.delegate = self
        feedParser.parsePodcastFeed(selectedPodcast.feedURL)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        // If there is a now playing episode, add Now Playing button to navigation bar
        if ((PVMediaPlayer.sharedInstance.nowPlayingEpisode) != nil) {
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Player", style: .Plain, target: self, action: "segueToNowPlaying:")
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = selectedPodcast.title
        
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .Plain, target: nil, action: nil)
        
        self.automaticallyAdjustsScrollViewInsets = false
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "updateDownloadFinishedButton:", name: Constants.kDownloadHasFinished, object: nil)
        
        self.refreshControl = UIRefreshControl()
        self.refreshControl.attributedTitle = NSAttributedString(string: "Pull to refresh episodes")
        self.refreshControl.addTarget(self, action: "refresh", forControlEvents: UIControlEvents.ValueChanged)
        self.tableView.addSubview(refreshControl)
        
        if let imageData = selectedPodcast.imageData, image = UIImage(data: imageData)  {
            headerImageView.image = image
        }
        else if let itunesImageData = selectedPodcast.itunesImage, itunesImage = UIImage(data: itunesImageData) {
            headerImageView.image = itunesImage
        }
        
        headerSummaryLabel.text = selectedPodcast.summary
        
        loadData()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Table view data source
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return episodesArray.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {        
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) as! EpisodesTableCell
        
        let episode = episodesArray[indexPath.row]
        
        cell.title?.text = episode.title
        
        if let summary = episode.summary {
            cell.summary?.text = PVUtility.removeHTMLFromString(summary)
        }
        
        cell.totalClips?.text = String("123 clips")
        
        if let duration = episode.duration {
            cell.totalTimeLeft?.text = PVUtility.convertNSNumberToHHMMSSString(duration)
        }
        
        if let pubDate = episode.pubDate {
            cell.pubDate?.text = PVUtility.formatDateToString(pubDate)
        }
        
        // Set icon conditionally if is downloaded, is downloading, or has not downloaded
        // If filename exists, then episode is downloaded and display play button
        if episode.fileName != nil {
            cell.downloadPlayButton.setTitle("Play", forState: .Normal)
        }
            // Else if episode is downloading, then display downloading icon
            // TODO: why is the taskIdentifier sometimes getting turned into -1???
        else if (episode.taskIdentifier != nil) {
            cell.downloadPlayButton.setTitle("DLing", forState: .Normal)
        }
            // Else display the start download icon
        else {
            cell.downloadPlayButton.setTitle("DL", forState: .Normal)
        }
        
        cell.downloadPlayButton.addTarget(self, action: "downloadPlay:", forControlEvents: .TouchUpInside)
        
        return cell
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if indexPath.row < episodesArray.count {
            return 120
        }
        else {
            return 60
        }
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        if indexPath.row < episodesArray.count {
            let episodeActions = UIAlertController(title: "Episode Options", message: "", preferredStyle: UIAlertControllerStyle.ActionSheet)
            let selectedEpisode = episodesArray[indexPath.row]
            if selectedEpisode.fileName != nil {
                episodeActions.addAction(UIAlertAction(title: "Play Episode", style: .Default, handler: { action in
                    self.performSegueWithIdentifier("playDownloadedEpisode", sender: nil)
                }))
            } else {
                if selectedEpisode.fileName != nil {
                    episodeActions.addAction(UIAlertAction(title: "Play Episode", style: .Default, handler: { action in
                        self.performSegueWithIdentifier("playDownloadedEpisode", sender: nil)
                    }))
                } else if selectedEpisode.taskIdentifier != nil {
                    episodeActions.addAction(UIAlertAction(title: "Downloading Episode", style: .Default, handler: nil))
                } else {
                    episodeActions.addAction(UIAlertAction(title: "Download Episode", style: .Default, handler: { action in
                        PVDownloader.sharedInstance.startDownloadingEpisode(selectedEpisode)
                        let cell = tableView.cellForRowAtIndexPath(indexPath) as! EpisodesTableCell
                        cell.downloadPlayButton.setTitle("DLing", forState: .Normal)
                    }))
                }
            }
            
            let totalClips = "(123)"
            
            episodeActions.addAction(UIAlertAction(title: "Show Clips \(totalClips)", style: .Default, handler: { action in
                self.performSegueWithIdentifier("Show Clips", sender: self)
            }))
            
            episodeActions.addAction(UIAlertAction (title: "Episode Info", style: .Default, handler: nil))
            
            episodeActions.addAction(UIAlertAction (title: "Stream Episode", style: .Default, handler: { action in
                self.performSegueWithIdentifier("streamEpisode", sender: self)
            }))
            
            episodeActions.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
            
            self.presentViewController(episodeActions, animated: true, completion: nil)
        }
    }
    
    // Override to support conditional editing of the table view.
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return False if you do not want the specified item to be editable.
        if indexPath.row < episodesArray.count {
            let episode = episodesArray[indexPath.row]
            if episode.fileName != nil {
                return true
            }
            else {
                return false
            }
        }
        else {
            return false
        }
    }
    
    // Override to support editing the table view.
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            
            // Get the episode and store it in a variable
            let episodeToRemove = episodesArray[indexPath.row]
            
            // Get the downloadSession, and if there is a downloadSession with a matching taskIdentifier as episode's taskIdentifier, then cancel the downloadSession
            let downloadSession = PVDownloader.sharedInstance.downloadSession
            downloadSession.getTasksWithCompletionHandler { dataTasks, uploadTasks, downloadTasks in
                for episodeDownloadTask in downloadTasks {
                    if episodeDownloadTask.taskIdentifier == episodeToRemove.taskIdentifier {
                        episodeDownloadTask.cancel()
                    }
                }
            }
            
            // If the episode is currently in the episodeDownloadArray, then delete the episode from the episodeDownloadArray
            if appDelegate.episodeDownloadArray.contains(episodeToRemove) {
                let episodeDownloadArrayIndex = appDelegate.episodeDownloadArray.indexOf(episodeToRemove)
                appDelegate.episodeDownloadArray.removeAtIndex(episodeDownloadArrayIndex!)
            }
            
            // If the episodeToRemove is currently now playing, then remove the now playing episode, and remove the Player button from the navbar
            if let nowPlayingEpisode = PVMediaPlayer.sharedInstance.nowPlayingEpisode {
                if episodeToRemove == nowPlayingEpisode {
                    PVMediaPlayer.sharedInstance.avPlayer.pause()
                    PVMediaPlayer.sharedInstance.nowPlayingEpisode = nil
                    self.navigationItem.rightBarButtonItem = nil
                }
            }
            
            // Delete the episode from CoreData and the disk, and update the UI
            if let fileName = episodeToRemove.fileName {
                PVUtility.deleteEpisodeFromDiskWithName(fileName)
            }
            
            CoreDataHelper.deleteItemFromCoreData(episodeToRemove, completionBlock: { () -> Void in
                CoreDataHelper.saveCoreData(nil)
            })
            
            episodesArray.removeAtIndex(indexPath.row)
            self.tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)            
        }
    }
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "Show All Episodes" {
            //            let episodesShowAllViewController = segue.destinationViewController as! MediaPlayerViewController
            //            let index = self.tableView.indexPathForSelectedRow!
            //            PVMediaPlayer.sharedInstance.nowPlayingEpisode = episodesArray[index.row]
            //            mediaPlayerViewController.hidesBottomBarWhenPushed = true
        }
        else if segue.identifier == "playDownloadedEpisode" {
            let mediaPlayerViewController = segue.destinationViewController as! MediaPlayerViewController
            let index = self.tableView.indexPathForSelectedRow!
            PVMediaPlayer.sharedInstance.nowPlayingEpisode = episodesArray[index.row]
            mediaPlayerViewController.hidesBottomBarWhenPushed = true
        }
        else if segue.identifier == "Quick Play Downloaded Episode" {
            let mediaPlayerViewController = segue.destinationViewController as! MediaPlayerViewController
            PVMediaPlayer.sharedInstance.nowPlayingEpisode = sender as! Episode
            mediaPlayerViewController.hidesBottomBarWhenPushed = true
        }
        else if segue.identifier == "Show Clips" {
            let clipsTableViewController = segue.destinationViewController as! ClipsTableViewController
            let index = self.tableView.indexPathForSelectedRow!
            clipsTableViewController.selectedPodcast = selectedPodcast
            clipsTableViewController.selectedEpisode = episodesArray[index.row]
        }
        else if segue.identifier == "streamEpisode" {
            let mediaPlayerViewController = segue.destinationViewController as! MediaPlayerViewController
            let index = self.tableView.indexPathForSelectedRow!
            PVMediaPlayer.sharedInstance.nowPlayingEpisode = episodesArray[index.row]
            mediaPlayerViewController.hidesBottomBarWhenPushed = true
        }
        else if segue.identifier == "Show All Episodes to Now Playing" {
            let mediaPlayerViewController = segue.destinationViewController as! MediaPlayerViewController
            mediaPlayerViewController.returnToNowPlaying = true
            mediaPlayerViewController.hidesBottomBarWhenPushed = true
        }
    }
    
    func feedParsingComplete() {
        self.refreshControl.endRefreshing()
        tableView.reloadData()
    }
}