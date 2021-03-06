//
//  PlaylistItemsViewController.swift
//  podverse
//
//  Created by Mitchell Downey on 2/2/16.
//  Copyright © 2016 Mitchell Downey. All rights reserved.
//

import UIKit
import CoreData

class PlaylistItemsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    
    private var playlist:Playlist!
    var playlistObjectId:NSManagedObjectID!
    private var moc = CoreDataHelper.sharedInstance.managedObjectContext
    let reachability = PVReachability.manager
    
    var playlistItems = [AnyObject]()
    
    let pvMediaPlayer = PVMediaPlayer.sharedInstance
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .Plain, target: nil, action: nil)
        
        playlist = CoreDataHelper.fetchEntityWithID(playlistObjectId, moc: self.moc) as! Playlist
        
        if let clips = playlist.clips {
            for clip in clips {
                playlistItems.append(clip)
            }
        }
        
        if let episodes = playlist.episodes {
            for episode in episodes {
                playlistItems.append(episode)
            }
        }
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(removePlayerNavButtonAndReload), name: Constants.kPlayerHasNoItem, object: nil)
        
        tableView.reloadData()
        
        // Set navigation bar styles
        navigationItem.title = "Playlist"
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        let shareBarButton = UIBarButtonItem(title: "Share", style: .Plain, target: self, action: #selector(PlaylistItemsViewController.showPlaylistShare(_:)))
        let playerNavButton = self.playerNavButton()
        if let playerNav = playerNavButton {
            navigationItem.rightBarButtonItems = [playerNav, shareBarButton]
        } else {
            navigationItem.rightBarButtonItems = [shareBarButton]
        }
    }
    
    func removePlayerNavButtonAndReload() {
        self.removePlayerNavButton()
        self.tableView.reloadData()
    }
    
    func showPlaylistShare(sender: UIBarButtonItem) {
        let playlistPageUrl = playlist.podverseURL!.stringByReplacingOccurrencesOfString("/pl/", withString: "/playlist/", options: NSStringCompareOptions.LiteralSearch, range: nil)
        let alert = UIAlertController(title: "Link to Playlist Page", message: playlistPageUrl, preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: "OK", style: .Cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Copy", style: .Default, handler: { (action) -> Void in
            UIPasteboard.generalPasteboard().string = playlistPageUrl ?? ""
        }))
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    // MARK: - Table view data source
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return playlist.title
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return playlistItems.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) as! PlaylistItemsTableViewCell
        
        if let episode = playlistItems[indexPath.row] as? Episode {
            
            cell.podcastTitle?.text = episode.podcast.title
            
            if let episodeTitle = episode.title {
                cell.itemTitle?.text = episodeTitle
            }
            
            if let episodeDuration = episode.duration {
                cell.duration?.text = PVUtility.convertNSNumberToHHMMSSString(episodeDuration)
            }
            
            if let pubDate = episode.pubDate {
                cell.itemPubDate?.text = PVUtility.formatDateToString(pubDate)
            }
            
            if let imageData = episode.podcast.imageThumbData, image = UIImage(data: imageData) {
                cell.pvImage?.image = image
            }
            else {
                cell.pvImage?.image = UIImage(named: "PodverseIcon")
            }
            
            cell.startEndTime?.text = "Full Episode"
        }
        else if let clip = playlistItems[indexPath.row] as? Clip {
            
            if let clipTitle = clip.title {
                cell.itemTitle?.text = clipTitle
            } else if let episodeTitle = clip.episode.title {
                cell.itemTitle?.text = episodeTitle
            } else {
                cell.itemTitle?.text = "untitled clip"
            }
            
            cell.podcastTitle?.text = clip.episode.podcast.title
            
            if let imageData = clip.episode.podcast.imageThumbData, image = UIImage(data: imageData) {
                cell.pvImage?.image = image
            }
            else {
                cell.pvImage?.image = UIImage(named: "PodverseIcon")
            }
            
            if let pubDate = clip.episode.pubDate {
                cell.itemPubDate?.text = PVUtility.formatDateToString(pubDate)
            }
        
            cell.duration?.text = " "
            
            var startEndString = ""
            if clip.endTime == nil {
                startEndString += "Start: " + PVUtility.convertNSNumberToHHMMSSString(clip.startTime)
            } else if let endTime = clip.endTime {
                startEndString += PVUtility.convertNSNumberToHHMMSSString(clip.startTime) + " – " + PVUtility.convertNSNumberToHHMMSSString(endTime)
            }
            cell.startEndTime?.text = startEndString
            
        }
        
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let playlistItemActions = UIAlertController(title: "Item Options", message: "", preferredStyle: UIAlertControllerStyle.ActionSheet)
        
        if let episode = playlistItems[indexPath.row] as? Episode {

            if episode.fileName != nil {
                playlistItemActions.addAction(UIAlertAction(title: "Play", style: .Default, handler: { action in
                    self.pvMediaPlayer.loadEpisodeDownloadedMediaFileOrStream(episode.objectID, paused: false)
                    self.segueToNowPlaying()
                }))
            } else {
                playlistItemActions.addAction(UIAlertAction(title: "Stream", style: .Default, handler: { action in
                if !self.reachability.hasInternetConnection() {
                    self.showInternetNeededAlert("Connect to WiFi or cellular data to stream an episode.")
                    return
                }
                    self.pvMediaPlayer.loadEpisodeDownloadedMediaFileOrStream(episode.objectID, paused: false)
                    self.segueToNowPlaying()
                }))
            }
            
            playlistItemActions.addAction(UIAlertAction (title: "Episode", style: .Default, handler: { action in
                // TODO: add episode page
            }))
            
            playlistItemActions.addAction(UIAlertAction (title: "Podcast", style: .Default, handler: { action in
                // TODO: add podcast page
            }))

        } else if let clip = playlistItems[indexPath.row] as? Clip {
            
            if clip.episode.fileName != nil {
                playlistItemActions.addAction(UIAlertAction(title: "Play", style: .Default, handler: { action in
                    self.pvMediaPlayer.loadClipDownloadedMediaFileOrStreamAndPlay(clip.objectID)
                    self.segueToNowPlaying()
                }))
            } else {
                if !self.reachability.hasInternetConnection() {
                    self.showInternetNeededAlert("Connect to WiFi or cellular data to stream a clip.")
                    return
                }
                playlistItemActions.addAction(UIAlertAction(title: "Stream", style: .Default, handler: { action in
                    
                    self.pvMediaPlayer.loadClipDownloadedMediaFileOrStreamAndPlay(clip.objectID)
                    self.segueToNowPlaying()
                }))
            }
            
            playlistItemActions.addAction(UIAlertAction (title: "Episode", style: .Default, handler: { action in
                // TODO: add episode page
            }))
            
            playlistItemActions.addAction(UIAlertAction (title: "Podcast", style: .Default, handler: { action in
                // TODO: add podcast page
            }))
        }
        
        playlistItemActions.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
        
        self.presentViewController(playlistItemActions, animated: true, completion: nil)
    }
    
    // Override to support conditional editing of the table view.
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return NO if you do not want the specified item to be editable.
        return true
    }
    
    // Override to support editing the table view.
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            let playlistItemToRemove = playlistItems[indexPath.row]
            
            // Remove Player button if the now playing item matches the playlistItem
            if let nowPlayingEpisode = PVMediaPlayer.sharedInstance.nowPlayingEpisode {
                if let episode = playlistItems[indexPath.row] as? Episode {
                    if episode.mediaURL == nowPlayingEpisode.mediaURL  {
                        self.navigationItem.rightBarButtonItem = nil
                    }
                }
            } else if let nowPlayingClip = PVMediaPlayer.sharedInstance.nowPlayingClip {
                if let clip = playlistItems[indexPath.row] as? Clip {
                    if clip.episode.mediaURL == nowPlayingClip.episode.mediaURL  {
                        self.navigationItem.rightBarButtonItem = nil
                    }
                }
            }
            
            PVDeleter.deletePlaylistItem(playlist, item: playlistItemToRemove)
            self.playlistItems.removeAtIndex(indexPath.row)
            
            self.tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        }
    }
    
    // MARK: - Navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == Constants.TO_PLAYER_SEGUE_ID {
            let mediaPlayerViewController = segue.destinationViewController as! MediaPlayerViewController
            mediaPlayerViewController.hidesBottomBarWhenPushed = true
        }
    }
}
