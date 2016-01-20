//
//  EpisodesTableViewController.swift
//  podverse
//
//  Created by Mitchell Downey on 6/2/15.
//  Copyright (c) 2015 Mitchell Downey. All rights reserved.
//

import UIKit
import CoreData

class EpisodesTableViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, PVFeedParserDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var headerImageView: UIImageView!
    @IBOutlet weak var headerSummaryLabel: UILabel!
    @IBOutlet weak var headerShadowView: UIView!
    
    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    
    var selectedPodcast: Podcast!
    
    var episodesArray = [Episode]()
    
    var refreshControl: UIRefreshControl!
    
    var showAllEpisodes: Bool!
    
    var pvMediaPlayer = PVMediaPlayer.sharedInstance
    
    func loadData() {
        
        // Clear the episodes array, then retrieve and sort the full episode or downloaded episode array
        self.episodesArray = [Episode]()
        let unsortedEpisodes = NSMutableArray()
        
        var episodesArray: NSSet!
        
        // If showAllEpisodes is false, then only retrieve the downloaded episodes
        if showAllEpisodes == false {
            let downloadedEpisodesArrayPredicate = NSPredicate(format: "fileName != nil || taskIdentifier != nil", argumentArray: nil)
            episodesArray = selectedPodcast.episodes.filteredSetUsingPredicate(downloadedEpisodesArrayPredicate)
        } else {
            episodesArray = selectedPodcast.episodes
        }
        
        for singleEpisode in episodesArray {
            unsortedEpisodes.addObject(singleEpisode)
        }
        
        let sortDescriptor = NSSortDescriptor(key: "pubDate", ascending: false)
        
        self.episodesArray = unsortedEpisodes.sortedArrayUsingDescriptors([sortDescriptor]) as! [Episode]
        
        self.tableView.reloadData()
    }
    
    func segueToNowPlaying(sender: UIBarButtonItem) {
        self.performSegueWithIdentifier("Episodes to Now Playing", sender: nil)
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
                if pvMediaPlayer.avPlayer.rate == 1 {
                    pvMediaPlayer.saveCurrentTimeAsPlaybackPosition()
                }
                pvMediaPlayer.loadEpisodeMediaFileOrStreamAndPlay(selectedEpisode)
                self.performSegueWithIdentifier("Show Media Player", sender: nil)
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
        if ((pvMediaPlayer.nowPlayingEpisode) != nil) {
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Player", style: .Plain, target: self, action: "segueToNowPlaying:")
        }
        loadData()
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
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if showAllEpisodes == false {
            return "Downloaded"
        } else {
            return "All Available Episodes"
        }
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return episodesArray.count + 1
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        
        // If not the last cell, then insert episode information into cell
        if indexPath.row < episodesArray.count {
            let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) as! EpisodesTableCell
            
            let episode = episodesArray[indexPath.row]
            
            cell.title?.text = episode.title
            
            if let summary = episode.summary {
                cell.summary?.text = PVUtility.removeHTMLFromString(summary)
            }
            
            let totalClips = String(episode.clips.count)
            cell.totalClips?.text = String(totalClips + " clips")
            
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
            // Return the Show All Available Episodes button
        else {
            let cell = tableView.dequeueReusableCellWithIdentifier("showAllEpisodesCell", forIndexPath: indexPath)

            if showAllEpisodes == false {
                cell.textLabel!.text = "Show All Episodes"

            } else {
                cell.textLabel!.text = "Show Downloaded Episodes"
            }
            
            return cell
        }
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
        
        // If not the last item in the array, then perform selected episode actions
        if indexPath.row < episodesArray.count {
            
            let selectedEpisode = episodesArray[indexPath.row]
            
            let episodeActions = UIAlertController(title: "Episode Options", message: "", preferredStyle: UIAlertControllerStyle.ActionSheet)
            
            if selectedEpisode.fileName != nil {
                episodeActions.addAction(UIAlertAction(title: "Play Episode", style: .Default, handler: { action in
                    pvMediaPlayer.loadEpisodeMediaFileOrStreamAndPlay(selectedEpisode)
                    self.performSegueWithIdentifier("Show Media Player", sender: nil)
                }))
            } else {
                if selectedEpisode.taskIdentifier != nil {
                    episodeActions.addAction(UIAlertAction(title: "Downloading Episode", style: .Default, handler: nil))
                } else {
                    episodeActions.addAction(UIAlertAction(title: "Download Episode", style: .Default, handler: { action in
                        PVDownloader.sharedInstance.startDownloadingEpisode(selectedEpisode)
                        let cell = tableView.cellForRowAtIndexPath(indexPath) as! EpisodesTableCell
                        cell.downloadPlayButton.setTitle("DLing", forState: .Normal)
                    }))
                }
            }
            
            let totalClips = String(selectedEpisode.clips.count)
            episodeActions.addAction(UIAlertAction(title: "Show Clips (\(totalClips))", style: .Default, handler: { action in
                self.performSegueWithIdentifier("Show Clips", sender: self)
            }))
            
            episodeActions.addAction(UIAlertAction (title: "Episode Info", style: .Default, handler: nil))
            
            episodeActions.addAction(UIAlertAction (title: "Stream Episode", style: .Default, handler: { action in
                pvMediaPlayer.loadEpisodeMediaFileOrStreamAndPlay(selectedEpisode)
                self.performSegueWithIdentifier("Show Media Player", sender: nil)
            }))
            
            episodeActions.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
            
            self.presentViewController(episodeActions, animated: true, completion: nil)
        }
            // Else Show All Episodes or Show Downloaded Episodes
        else {
            toggleShowAllEpisodes()
        }
    }
    
    func toggleShowAllEpisodes() {
        let vc = self.storyboard?.instantiateViewControllerWithIdentifier("episodesTableViewController") as! EpisodesTableViewController
        vc.selectedPodcast = selectedPodcast
        vc.showAllEpisodes = !showAllEpisodes
        if showAllEpisodes == false {
            self.navigationController?.pushViewController(vc, animated: true)
        } else {
            navigationController?.popViewControllerAnimated(true)
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
            PVDeleter.sharedInstance.deleteEpisode(episodesArray[indexPath.row])
            episodesArray.removeAtIndex(indexPath.row)
            self.tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        }
    }
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "Show Media Player" {
            let mediaPlayerViewController = segue.destinationViewController as! MediaPlayerViewController
            mediaPlayerViewController.hidesBottomBarWhenPushed = true
        } else if segue.identifier == "Show Clips" {
            let clipsTableViewController = segue.destinationViewController as! ClipsTableViewController
            let index = self.tableView.indexPathForSelectedRow!
            clipsTableViewController.selectedPodcast = selectedPodcast
            clipsTableViewController.selectedEpisode = episodesArray[index.row]
        } else if segue.identifier == "Episodes to Now Playing" {
            let mediaPlayerViewController = segue.destinationViewController as! MediaPlayerViewController
            mediaPlayerViewController.hidesBottomBarWhenPushed = true
        }
    }
    
    func feedParsingComplete() {
        self.refreshControl.endRefreshing()
        tableView.reloadData()
    }
}