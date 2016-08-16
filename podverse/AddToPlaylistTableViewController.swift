//
//  AddToPlaylistTableViewController.swift
//  podverse
//
//  Created by Mitchell Downey on 2/5/16.
//  Copyright © 2016 Mitchell Downey. All rights reserved.
//

import UIKit
import CoreData

class AddToPlaylistTableViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    let pvMediaPlayer = PVMediaPlayer.sharedInstance
    let playlistManager = PlaylistManager.sharedInstance
    var managedObjectContext = CoreDataHelper.sharedInstance.managedObjectContext
    let reachability = PVReachability.manager
    var episode:Episode?
    var clip:Clip?
    
    var validPlaylists:[Playlist]!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(navBackToMediaPlayer), name: Constants.kPlayerHasNoItem, object: nil)
        
        self.navigationController?.navigationBar.barTintColor = UIColor(red: 41.0/255.0, green: 104.0/255.0, blue: 177.0/255.0, alpha: 1.0)
        
        if pvMediaPlayer.nowPlayingClip != nil {
            clip = pvMediaPlayer.nowPlayingClip
        } else if pvMediaPlayer.nowPlayingEpisode != nil {
            episode = pvMediaPlayer.nowPlayingEpisode
        }
        
        navigationItem.title = "Add to Playlist"
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "New", style: .Plain, target: self, action: #selector(showCreatePlaylistAlert))
        
        loadData()
        playlistManager.delegate = self
    }
    
    func showCreatePlaylistAlert() {
        if !reachability.hasInternetConnection() {
            showInternetNeededAlert("Connect to WiFi or cellular data to create a playlist.")
            return
        }
        
        let createPlaylistAlert = UIAlertController(title: "Add New Playlist", message: nil, preferredStyle: UIAlertControllerStyle.Alert)
        
        createPlaylistAlert.addTextFieldWithConfigurationHandler({(textField: UITextField!) in
            textField.placeholder = "title of playlist"
        })
        
        createPlaylistAlert.addAction(UIAlertAction(title: "Cancel", style: .Default, handler: nil))
        
        createPlaylistAlert.addAction(UIAlertAction(title: "Save", style: .Default, handler: { (action: UIAlertAction!) in
            let textField = createPlaylistAlert.textFields![0] as UITextField
            if let playlistTitle = textField.text {
                let moc = CoreDataHelper.sharedInstance.managedObjectContext
                
                let playlist = CoreDataHelper.insertManagedObject("Playlist", moc:moc) as! Playlist
                playlist.title = playlistTitle
                CoreDataHelper.saveCoreData(moc, completionBlock:nil)
                self.playlistManager.savePlaylist(playlist, moc:moc)
            }
        }))
    
        presentViewController(createPlaylistAlert, animated: true, completion: nil)
    }
    
    func navBackToMediaPlayer() {
        if let mediaPlayerVC = self.navigationController?.viewControllers[(self.navigationController?.viewControllers.count)! - 2] as? MediaPlayerViewController {
            self.navigationController?.popToViewController(mediaPlayerVC, animated: true)
        }
    }
    
    private func loadData() {
        validPlaylists = CoreDataHelper.fetchEntities("Playlist", predicate: nil, moc: managedObjectContext) as! [Playlist]
        // TODO: there has to be a better way to do this...
        for (index , playlist) in validPlaylists.enumerate() {
            if clip == nil {
                if playlist.title == Constants.kMyClipsPlaylist {
                    validPlaylists.removeAtIndex(index)
                    break
                }
            } else if episode == nil {
                if playlist.title == Constants.kMyEpisodesPlaylist {
                    validPlaylists.removeAtIndex(index)
                    break
                }
            }
        }
        
        validPlaylists.sortInPlace({ $0.title?.lowercaseString < $1.title?.lowercaseString })
        for (index , playlist) in validPlaylists.enumerate() {
            if clip == nil {
                if playlist.title == Constants.kMyEpisodesPlaylist {
                    validPlaylists.removeAtIndex(index)
                    validPlaylists.insert(playlist, atIndex: 0)
                    break
                }
            } else if episode == nil {
                if playlist.title == Constants.kMyClipsPlaylist {
                    validPlaylists.removeAtIndex(index)
                    validPlaylists.insert(playlist, atIndex: 0)
                    break
                }
            }
        }
        
        tableView.reloadData()
    }
    
    // MARK: - Table view data source
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return validPlaylists.count
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) as! AddToPlaylistTableViewCell
        let playlist = validPlaylists[indexPath.row]
        cell.title?.text = playlist.title
        cell.totalItems?.text = "\(playlist.allItems.count) items"
        
        return cell
    }

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if !reachability.hasInternetConnection() {
            showInternetNeededAlert("Connect to WiFi or cellular data to add to a playlist.")
            return
        }
        
        let playlist = CoreDataHelper.fetchEntityWithID(validPlaylists[indexPath.row].objectID, moc: self.managedObjectContext) as! Playlist
        
        if let c = clip {
            playlistManager.addItemToPlaylist(playlist, clip: c, episode: nil, moc: self.managedObjectContext)
        } else if let e = episode {
            playlistManager.addItemToPlaylist(playlist, clip: nil, episode: e, moc: self.managedObjectContext)
        }
    }
}


extension AddToPlaylistTableViewController: PlaylistManagerDelegate {
    func itemAddedToPlaylist() {
        self.navBackToMediaPlayer()
        self.loadData()
    }
    
    func playlistAddedByUrl() {
        self.loadData()
    }
    
    func didSavePlaylist() {
        self.loadData()
    }
}
