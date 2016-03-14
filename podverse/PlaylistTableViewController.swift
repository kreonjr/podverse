//
//  PlaylistViewController.swift
//  podverse
//
//  Created by Mitchell Downey on 2/2/16.
//  Copyright © 2016 Mitchell Downey. All rights reserved.
//

import UIKit

class PlaylistViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    
    var playlist:Playlist!
    
    let pvMediaPlayer = PVMediaPlayer.sharedInstance

    func loadData() {
        tableView.reloadData()
    }
    
    func segueToNowPlaying(sender: UIBarButtonItem) {
        performSegueWithIdentifier("PlaylistItem to Now Playing", sender: nil)
    }
    
    func removePlayerNavButton(notification: NSNotification) {
        dispatch_async(dispatch_get_main_queue()) {
            self.loadData()
            self.pvMediaPlayer.removePlayerNavButton(self)
        }
    }
    
    func showPlaylistShare(sender: UIBarButtonItem) {
        let alert = UIAlertController(title: "Playlist saved at URL:", message: playlist.url, preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: "OK", style: .Cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Copy", style: .Default, handler: { (action) -> Void in
            UIPasteboard.generalPasteboard().string = self.playlist.url ?? ""
        }))
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .Plain, target: nil, action: nil)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        loadData()
        
        // Set navigation bar styles
        navigationItem.title = "Playlist"
        
        if pvMediaPlayer.nowPlayingEpisode != nil || pvMediaPlayer.nowPlayingClip != nil {
            let shareBarButton = UIBarButtonItem(title: "Share", style: .Plain, target: self, action: "showPlaylistShare:")
            let playerBarButton = UIBarButtonItem(title: "Player", style: .Plain, target: self, action: "segueToNowPlaying:")
            navigationItem.rightBarButtonItems = [playerBarButton, shareBarButton]
        } else {
            let shareBarButton = UIBarButtonItem(title: "Share", style: .Plain, target: self, action: "showPlaylistShare:")
            navigationItem.rightBarButtonItem = shareBarButton
        }
        
        PVMediaPlayer.sharedInstance.addPlayerNavButton(self)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "removePlayerNavButton:", name: Constants.kPlayerHasNoItem, object: nil)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: Constants.kPlayerHasNoItem, object: nil)
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
        return playlist.title
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return playlist.playlistItems.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) as! PlaylistTableViewCell
        
        let playlistItem = playlist.playlistItems[indexPath.row]
        
        // If episode property exists, handle as a clip
        if playlistItem["episode"] != nil {
            
            if let clipTitle = playlistItem["title"] as? String {
                cell.itemTitle?.text = clipTitle
            }
            
            if let podcast = playlistItem["podcast"] as? Dictionary<String,AnyObject> {
                if let podcastTitle = podcast["title"] as? String {
                        cell.podcastTitle?.text = podcastTitle
                }
                cell.pvImage?.image = UIImage(named: "Blank52")

                if let imageURLString = podcast["imageURL"] as? String {
                    if let imageURL = NSURL(string: imageURLString) {
                        if let imageData = NSData(contentsOfURL: imageURL) {
                            if let image = UIImage(data: imageData) {
                                cell.pvImage?.image = image
                            }
                        }
                    }
                }
            }
        
            if let episode = playlistItem["episode"] as? Dictionary<String,AnyObject> {
                if let pubDate = episode["pubDate"] as? String {
                    cell.itemPubDate?.text = pubDate
                }
            }
        
        
            if let duration = playlistItem["duration"] as? NSNumber {
                cell.duration?.text = PVUtility.convertNSNumberToHHMMSSString(duration)
            }
        
            // TODO: add status property (whether or not a playlistItem has been listened to before,  ) to playlistItems
            let status = "played/unplayed"
            cell.status?.text = status
        
        }
        // Else if episode property does not exist, handle as an episode
        else {
            
            if let podcast = playlistItem["podcast"] as? Dictionary<String,AnyObject> {
                if let title = podcast["title"] as? String {
                    cell.podcastTitle?.text = title
                }
            }
            
            if let title = playlistItem["title"] as? String {
                cell.itemTitle?.text = title
            }
            
            if let duration = playlistItem["duration"] as? String {
                cell.duration?.text = duration
            }
            
            if let pubDate = playlistItem["pubDate"] as? String {
                cell.itemPubDate?.text = pubDate
            }
            
            if let imageURLString = playlistItem["imageURL"] as? String {
                if let imageURL = NSURL(string: imageURLString) {
                    if let imageData = NSData(contentsOfURL: imageURL) {
                        if let image = UIImage(data: imageData) {
                            cell.pvImage?.image = image
                        }
                    }
                }
            }
            
            let status = "played/unplayed"
            cell.status?.text = status
        }
        
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
         let selectedItem = playlist.playlistItems[indexPath.row]
         pvMediaPlayer.loadPlaylistItemAndPlay(selectedItem)
            
         self.performSegueWithIdentifier("PlaylistItem to Now Playing", sender: nil)
        
//        if let episode = selectedItem as? Episode {
//            pvMediaPlayer.loadEpisodeDownloadedMediaFileOrStreamAndPlay(episode)
//        } else if let clip = selectedItem as? Clip {
//            pvMediaPlayer.loadClipDownloadedMediaFileOrStreamAndPlay(clip)
//        }
        
//        // If not the last item in the array, then perform selected episode actions
//        if indexPath.row < episodesArray.count {
//            
//            let selectedEpisode = episodesArray[indexPath.row]
//            
//            let episodeActions = UIAlertController(title: "Episode Options", message: "", preferredStyle: UIAlertControllerStyle.ActionSheet)
//            
//            if selectedEpisode.fileName != nil {
//                episodeActions.addAction(UIAlertAction(title: "Play Episode", style: .Default, handler: { action in
//                    self.pvMediaPlayer.loadEpisodeDownloadedMediaFileOrStreamAndPlay(selectedEpisode)
//                    self.performSegueWithIdentifier("Episodes to Now Playing", sender: nil)
//                }))
//            } else {
//                if selectedEpisode.taskIdentifier != nil {
//                    episodeActions.addAction(UIAlertAction(title: "Downloading Episode", style: .Default, handler: nil))
//                } else {
//                    episodeActions.addAction(UIAlertAction(title: "Download Episode", style: .Default, handler: { action in
//                        PVDownloader.sharedInstance.startDownloadingEpisode(selectedEpisode)
//                        let cell = tableView.cellForRowAtIndexPath(indexPath) as! EpisodesTableCell
//                        cell.downloadPlayButton.setTitle("DLing", forState: .Normal)
//                    }))
//                }
//            }
//            
//            let totalClips = String(selectedEpisode.clips.count)
//            episodeActions.addAction(UIAlertAction(title: "Show Clips (\(totalClips))", style: .Default, handler: { action in
//                self.performSegueWithIdentifier("Show Clips", sender: self)
//            }))
//            
//            episodeActions.addAction(UIAlertAction (title: "Episode Info", style: .Default, handler: nil))
//            
//            episodeActions.addAction(UIAlertAction (title: "Stream Episode", style: .Default, handler: { action in
//                self.pvMediaPlayer.loadEpisodeDownloadedMediaFileOrStreamAndPlay(selectedEpisode)
//                self.performSegueWithIdentifier("Episodes to Now Playing", sender: nil)
//            }))
//            
//            episodeActions.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
//            
//            self.presentViewController(episodeActions, animated: true, completion: nil)
//        }
//            // Else Show All Episodes or Show Downloaded Episodes
//        else {
//            toggleShowAllEpisodes()
//        }
    }
    
    // Override to support conditional editing of the table view.
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return NO if you do not want the specified item to be editable.
        return true
    }
    
    // Override to support editing the table view.
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
//            let podcastToRemove = podcastArray[indexPath.row]
//            
//            // Remove Player button if the now playing episode was one of the podcast's episodes
//            let allPodcastEpisodes = podcastToRemove.episodes.allObjects as! [Episode]
//            if let nowPlayingEpisode = PVMediaPlayer.sharedInstance.nowPlayingEpisode {
//                if allPodcastEpisodes.contains(nowPlayingEpisode) {
//                    self.navigationItem.rightBarButtonItem = nil
//                }
//            }
//            
//            PVDeleter.sharedInstance.deletePodcast(podcastToRemove)
//            podcastArray.removeAtIndex(indexPath.row)
//            
//            self.tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        }
    }
    
    // MARK: - Navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "PlaylistItem to Now Playing" {
            let mediaPlayerViewController = segue.destinationViewController as! MediaPlayerViewController
            mediaPlayerViewController.hidesBottomBarWhenPushed = true
        }
    }
}
