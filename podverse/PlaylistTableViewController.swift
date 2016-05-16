//
//  PlaylistViewController.swift
//  podverse
//
//  Created by Mitchell Downey on 2/2/16.
//  Copyright © 2016 Mitchell Downey. All rights reserved.
//

import UIKit
import CoreData

class PlaylistViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    
    private var playlist:Playlist!
    var playlistObjectId:NSManagedObjectID!
    private var moc = CoreDataHelper.sharedInstance.managedObjectContext
    
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
        
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        loadData()
        
        // Set navigation bar styles
        navigationItem.title = "Playlist"
        
        if pvMediaPlayer.nowPlayingEpisode != nil || pvMediaPlayer.nowPlayingClip != nil {
            let shareBarButton = UIBarButtonItem(title: "Share", style: .Plain, target: self, action: #selector(PlaylistViewController.showPlaylistShare(_:)))
            let playerBarButton = UIBarButtonItem(title: "Player", style: .Plain, target: self, action: #selector(PlaylistViewController.segueToNowPlaying))
            navigationItem.rightBarButtonItems = [playerBarButton, shareBarButton]
        } else {
            let shareBarButton = UIBarButtonItem(title: "Share", style: .Plain, target: self, action: #selector(PlaylistViewController.showPlaylistShare(_:)))
            navigationItem.rightBarButtonItem = shareBarButton
        }
        
        self.addPlayerNavButton()
    }
    
    func loadData() {
        tableView.reloadData()
    }
    
    func removePlayerNavButtonAndReload() {
        self.removePlayerNavButton()
        self.loadData()
    }
    
    func showPlaylistShare(sender: UIBarButtonItem) {
        let playlistPageUrl = playlist.url!.stringByReplacingOccurrencesOfString("/pl/", withString: "/playlist/", options: NSStringCompareOptions.LiteralSearch, range: nil)
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
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) as! PlaylistTableViewCell
        
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
            
            if let imageData = episode.podcast.imageData, image = UIImage(data: imageData) {
                cell.pvImage?.image = image
            }
            else if let itunesImageData = episode.podcast.itunesImage, itunesImage = UIImage(data: itunesImageData) {
                cell.pvImage?.image = itunesImage
            }
            else {
                cell.pvImage?.image = UIImage(named: "Blank52")
            }
            
            let status = "played/unplayed"
            cell.status?.text = status
            
        }
        else if let clip = playlistItems[indexPath.row] as? Clip {
            
            if let clipTitle = clip.title {
                cell.itemTitle?.text = clipTitle
            }
            
            cell.podcastTitle?.text = clip.episode.podcast.title
            
            if let imageData = clip.episode.podcast.imageData, image = UIImage(data: imageData) {
                cell.pvImage?.image = image
            }
            else if let itunesImageData = clip.episode.podcast.itunesImage, itunesImage = UIImage(data: itunesImageData) {
                cell.pvImage?.image = itunesImage
            }
            else {
                cell.pvImage?.image = UIImage(named: "Blank52")
            }
            
            if let pubDate = clip.episode.pubDate {
                cell.itemPubDate?.text = PVUtility.formatDateToString(pubDate)
            }
        
            if let duration = clip.episode.duration {
                cell.duration?.text = PVUtility.convertNSNumberToHHMMSSString(duration)
            }
        
            // TODO: add status property (whether or not a playlistItem has been listened to before,  ) to playlistItems
            let status = "played/unplayed"
            cell.status?.text = status
        
        }
        
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let playlistItemActions = UIAlertController(title: "Item Options", message: "", preferredStyle: UIAlertControllerStyle.ActionSheet)
        
        if let episode = playlistItems[indexPath.row] as? Episode {

            if episode.fileName != nil {
                playlistItemActions.addAction(UIAlertAction(title: "Play", style: .Default, handler: { action in
                self.pvMediaPlayer.loadEpisodeDownloadedMediaFileOrStreamAndPlay(episode.objectID)
                    self.segueToNowPlaying()
                }))
            } else {
                playlistItemActions.addAction(UIAlertAction(title: "Stream", style: .Default, handler: { action in
                self.pvMediaPlayer.loadEpisodeDownloadedMediaFileOrStreamAndPlay(episode.objectID)
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
