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
    var playlistItems = [AnyObject]()
    
    func loadData() {
        if let podcasts = playlist.podcasts {
            if podcasts.count > 0 {
                for podcast in podcasts {
                    playlistItems.append(podcast as! Podcast)
                }
            }
        }
        if let episodes = playlist.episodes {
            if episodes.count > 0 {
                for episode in episodes {
                    playlistItems.append(episode as! Episode)
                }
            }
        }
        if let clips = playlist.clips {
            if clips.count > 0 {
                for clip in clips {
                    playlistItems.append(clip as! Clip)
                }
            }
        }
        tableView.reloadData()
    }
    
    func segueToNowPlaying(sender: UIBarButtonItem) {
        performSegueWithIdentifier("Playlist to Now Playing", sender: nil)
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
        navigationController?.navigationBar.barStyle = UIBarStyle.Black
        navigationController?.navigationBar.tintColor = UIColor.whiteColor()
        navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName: UIColor.whiteColor(), NSFontAttributeName: UIFont.boldSystemFontOfSize(16.0)]
        
        PVMediaPlayer.sharedInstance.addPlayerNavButton(self)
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
        return "Playlist Title"
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return playlistItems.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) as! PlaylistTableViewCell
        
        let playlistItem = playlistItems[indexPath.row]
        
        let playlistItemMirror = Mirror(reflecting: playlistItem)
        print(playlistItemMirror.subjectType)
                
        if let episode = playlistItem as? Episode {
            
            if let itemTitle = episode.title {
                cell.itemTitle?.text = itemTitle
            }
            
            let podcastTitle = episode.podcast.title
            cell.podcastTitle?.text = podcastTitle
            
            if let duration = episode.duration {
                cell.duration?.text = PVUtility.convertNSNumberToHHMMSSString(duration)
            }
            
            let status = "played/unplayed"
            cell.status?.text = status
            
            let pubDate = episode.pubDate
            cell.itemPubDate?.text = PVUtility.formatDateToString(pubDate!)
            
            cell.pvImage?.image = UIImage(named: "Blank52")
            if let imageData = episode.podcast.imageData {
                if let image = UIImage(data: imageData) {
                    cell.pvImage?.image = image
                }
            }
            else if let itunesImageData = episode.podcast.itunesImage {
                if let itunesImage = UIImage(data: itunesImageData) {
                    cell.pvImage?.image = itunesImage
                }
            }
        
        } else if let clip = playlistItem as? Clip {
            
            if let itemTitle = clip.title {
                cell.itemTitle?.text = itemTitle
            }
            
            let podcastTitle = clip.episode.podcast.title
            cell.podcastTitle?.text = podcastTitle
            
            let duration = clip.duration
            cell.duration?.text = PVUtility.convertNSNumberToHHMMSSString(duration)
            
            let status = "played/unplayed"
            cell.status?.text = status
            
            let pubDate = clip.episode.pubDate
            cell.itemPubDate?.text = PVUtility.formatDateToString(pubDate!)
            
            cell.pvImage?.image = UIImage(named: "Blank52")
            if let imageData = clip.episode.podcast.imageData {
                if let image = UIImage(data: imageData) {
                    cell.pvImage?.image = image
                }
            }
            else if let itunesImageData = clip.episode.podcast.itunesImage {
                if let itunesImage = UIImage(data: itunesImageData) {
                    cell.pvImage?.image = itunesImage
                }
            }
            
        }
        
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
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
        if segue.identifier == "Playlist to Now Playing" {
            let mediaPlayerViewController = segue.destinationViewController as! MediaPlayerViewController
            mediaPlayerViewController.hidesBottomBarWhenPushed = true
        }
    }
}
