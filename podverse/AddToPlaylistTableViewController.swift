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
    
    let pvPlaylister = PVPlaylister.sharedInstance
    let pvMediaPlayer = PVMediaPlayer.sharedInstance
    
    var episode:Episode?
    var clip:Clip?
    
    var playlists:[Playlist] = []

    func loadData() {
        playlists = pvPlaylister.retrieveAllPlaylists()
        if playlists.count > 0 {
            if clip != nil {
                playlists = playlists.filter() { $0.title != "My Saved Episodes" }
            } else if episode != nil {
                playlists = playlists.filter() { $0.title != "My Saved Clips" }
            }
        }
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
                self.pvPlaylister.createPlaylist(playlistTitle)
            }
            self.loadData()
        }))
    
        presentViewController(createPlaylistAlert, animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if pvMediaPlayer.nowPlayingClip != nil {
            clip = pvMediaPlayer.nowPlayingClip
        } else if pvMediaPlayer.nowPlayingEpisode != nil {
            episode = pvMediaPlayer.nowPlayingEpisode
        }
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        // Set navigation bar styles
        navigationItem.title = "Add to Playlist"
        navigationController?.navigationBar.barStyle = UIBarStyle.Black
        navigationController?.navigationBar.tintColor = UIColor.whiteColor()
        navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName: UIColor.whiteColor(), NSFontAttributeName: UIFont.boldSystemFontOfSize(16.0)]
        
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .Plain, target: nil, action: nil)
        
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
        cell.totalItems?.text = String(pvPlaylister.countPlaylistItems(playlist)) + " items"
        
        return cell
    }

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        let playlist = playlists[indexPath.row]

        if let c = clip {
            pvPlaylister.addClipToPlaylist(playlist, clip: c)
        } else if let e = episode {
            pvPlaylister.addEpisodeToPlaylist(playlist, episode: e)
        }
        
        SavePlaylistToServer(playlist: playlist, completionBlock: {[unowned self] (response) -> Void in
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
