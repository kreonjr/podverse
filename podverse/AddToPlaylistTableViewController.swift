//
//  AddToPlaylistTableViewController.swift
//  podverse
//
//  Created by Mitchell Downey on 2/5/16.
//  Copyright © 2016 Mitchell Downey. All rights reserved.
//

import UIKit

class AddToPlaylistTableViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var tableView: UITableView!
        let pvMediaPlayer = PVMediaPlayer.sharedInstance
    let playlistManager = PlaylistManager.sharedInstance
    
    var episode:Episode?
    var clip:Clip?
    
    var playlists:[Playlist] = PlaylistManager.sharedInstance.playlists

    func loadData() {
        playlists = PlaylistManager.sharedInstance.playlists
        tableView.reloadData()
    }
    
    func showcreatePlaylistAlert() {
        let createPlaylistAlert = UIAlertController(title: "Add New Playlist", message: nil, preferredStyle: UIAlertControllerStyle.Alert)
        
        createPlaylistAlert.addTextFieldWithConfigurationHandler({(textField: UITextField!) in
            textField.placeholder = "title of playlist"
        })
        
        createPlaylistAlert.addAction(UIAlertAction(title: "Cancel", style: .Default, handler: nil))
        
        createPlaylistAlert.addAction(UIAlertAction(title: "Save", style: .Default, handler: { (action: UIAlertAction!) in
            let textField = createPlaylistAlert.textFields![0] as UITextField
            if let playlistTitle = textField.text {
                let playlist = Playlist(newTitle: playlistTitle)
                
                SavePlaylistToServer(playlist: playlist, newPlaylist:(playlist.playlistId == nil), completionBlock: {[unowned self] (response) -> Void in

                    playlist.playlistId = response["_id"] as? String
                    playlist.url = response["url"] as? String
                    
                    if let playlistId = playlist.playlistId {
                        PlaylistManager.saveIDToPlist(playlistId)
                        self.playlistManager.addPlaylist(playlist)
                    }
                    
                    NSNotificationCenter.defaultCenter().postNotificationName(Constants.kRefreshAddToPlaylistTableDataNotification, object: nil)

                    }) { (error) -> Void in
                        print("Not saved to server. Error: ", error?.localizedDescription)
                    }.call()
            }
        }))
    
        presentViewController(createPlaylistAlert, animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.navigationBar.barTintColor = UIColor(red: 41.0/255.0, green: 104.0/255.0, blue: 177.0/255.0, alpha: 1.0)
        
        if pvMediaPlayer.nowPlayingClip != nil {
            clip = pvMediaPlayer.nowPlayingClip
        } else if pvMediaPlayer.nowPlayingEpisode != nil {
            episode = pvMediaPlayer.nowPlayingEpisode
        }
        
        // Make sure the Play/Pause button displays properly after returning from background
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "loadData", name: Constants.kRefreshAddToPlaylistTableDataNotification, object: nil)
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        // Set navigation bar styles
        navigationItem.title = "Add to Playlist"
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "New", style: .Plain, target: self, action: "showcreatePlaylistAlert")
        
        loadData()
    }
    
    // MARK: - Table view data source
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return playlists.count
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) as! AddToPlaylistTableViewCell
        let playlist = playlists[indexPath.row]
        cell.title?.text = playlist.title
        cell.totalItems?.text = "123 items"
        // cell.totalItems?.text = String(pvPlaylister.countPlaylistItems(playlist)) + " items"
        
        return cell
    }

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        let playlist = playlists[indexPath.row]

        if let c = clip, let clipJSON = playlistManager.clipToPlaylistItemJSON(c) {
            playlist.playlistItems.append(clipJSON)
        }
        
        if let e = episode, let episodeJSON = playlistManager.episodeToPlaylistItemJSON(e)  {
                playlist.playlistItems.append(episodeJSON)
        }
        
        SavePlaylistToServer(playlist: playlist, newPlaylist:(playlist.playlistId == nil), completionBlock: {[unowned self] (response) -> Void in
                playlist.url = response["url"] as? String
            
                if let mediaPlayerVC = self.navigationController?.viewControllers[(self.navigationController?.viewControllers.count)! - 2] as? MediaPlayerViewController {
                    self.navigationController?.popToViewController(mediaPlayerVC, animated: true)
                }
            }) { (error) -> Void in
                print("Not saved to server. Error: ", error?.localizedDescription)
        }.call()
    }
    
//    // Override to support editing the table view.
//    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
//        if editingStyle == .Delete {
//            //            let podcastToRemove = podcastArray[indexPath.row]
//            //
//            //            // Remove Player button if the now playing episode was one of the podcast's episodes
//            //            let allPodcastEpisodes = podcastToRemove.episodes.allObjects as! [Episode]
//            //            if let nowPlayingEpisode = PVMediaPlayer.sharedInstance.nowPlayingEpisode {
//            //                if allPodcastEpisodes.contains(nowPlayingEpisode) {
//            //                    self.navigationItem.rightBarButtonItem = nil
//            //                }
//            //            }
//            //
//            //            PVDeleter.sharedInstance.deletePodcast(podcastToRemove)
//            //            podcastArray.removeAtIndex(indexPath.row)
//            //            
//            //            self.tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
//        }
//    }
//    
//    // MARK: - Navigation
//    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
//        if segue.identifier == "Playlist to Now Playing" {
//            let mediaPlayerViewController = segue.destinationViewController as! MediaPlayerViewController
//            mediaPlayerViewController.hidesBottomBarWhenPushed = true
//        }
//    }

}
