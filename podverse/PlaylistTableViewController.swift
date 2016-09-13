//
//  PlaylistsTableViewController.swift
//

import UIKit
import CoreData
import Lock

class PlaylistsTableViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var bottomButton: UIButton!
        
    var playlistManager = PlaylistManager.sharedInstance
    var managedObjectContext:NSManagedObjectContext!
    let coreDataHelper = CoreDataHelper.sharedInstance
    let reachability = PVReachability.manager
    var refreshControl: UIRefreshControl!
    
    var playlists:[Playlist] {
        get {
            let moc = coreDataHelper.managedObjectContext
            let unsortedPlaylists = CoreDataHelper.fetchEntities("Playlist", predicate: nil, moc: moc) as! [Playlist]
            var sortedPlaylists = unsortedPlaylists.sort({ $0.title?.lowercaseString < $1.title?.lowercaseString })
            
            for (index, playlist) in sortedPlaylists.enumerate() {
                if playlist.isMyClips {
                    sortedPlaylists.removeAtIndex(index)
                    sortedPlaylists.insert(playlist, atIndex: 0)
                } else if playlist.isMyEpisodes {
                    sortedPlaylists.removeAtIndex(index)
                    sortedPlaylists.insert(playlist, atIndex: 0)
                }
            }
            return sortedPlaylists
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = "Playlists"
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .Plain, target: nil, action: nil)

        bottomButton.setTitle("Add Playlist by URL", forState: .Normal)
        bottomButton.hidden = false
        
        playlistManager.delegate = self
        
        refreshControl = UIRefreshControl()
        refreshControl.attributedTitle = NSAttributedString(string: "Pull to refresh all playlists")
        refreshControl.addTarget(self, action: #selector(refreshData), forControlEvents: UIControlEvents.ValueChanged)
        tableView.addSubview(refreshControl)
                
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(removePlayerNavButton), name: Constants.kPlayerHasNoItem, object: nil)
        
        refreshPlaylists()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        navigationItem.rightBarButtonItem = self.playerNavButton()
        self.tableView.reloadData()
    }
    
    func refreshData() {
        if reachability.hasInternetConnection() == false && refreshControl.refreshing == true {
            showInternetNeededAlert("Connect to WiFi or cellular data to refresh playlists.")
            refreshControl.endRefreshing()
            return
        }
        refreshPlaylists()
    }
    
    private func refreshPlaylists() {
        PlaylistManager.sharedInstance.refreshPlaylists { () -> Void in
            self.refreshControl.endRefreshing()
            self.tableView.reloadData()
        }
    }
    
    private func showAddPlaylistByURLAlert() {
        if reachability.hasInternetConnection() == false {
            showInternetNeededAlert("Connect to WiFi or cellular data to add a playlist by URL.")
            return
        }
        
        let addPlaylistByURLAlert = UIAlertController(title: "Add Playlist By URL", message: nil, preferredStyle: UIAlertControllerStyle.Alert)
        
        addPlaylistByURLAlert.addTextFieldWithConfigurationHandler({(textField: UITextField!) in
            textField.placeholder = "http://podverse.tv/playlist/..."
        })
        
        addPlaylistByURLAlert.addAction(UIAlertAction(title: "Cancel", style: .Default, handler: nil))
        
        addPlaylistByURLAlert.addAction(UIAlertAction(title: "Add", style: .Default, handler: { (action: UIAlertAction!) in
            let textField = addPlaylistByURLAlert.textFields![0] as UITextField
            if let urlString = textField.text {
                self.playlistManager.addPlaylistByUrlString(urlString, completion: nil)
            }
        }))
        
        presentViewController(addPlaylistByURLAlert, animated: true, completion: nil)
    }
    
    @IBAction func bottomButtonAction(sender: AnyObject) {
        showAddPlaylistByURLAlert()
    }
    
    // TODO: add timers to check for new playlist items that were added to a playlist you're subscribed to, then present a red # notification on the playlist tab
    
}

extension PlaylistsTableViewController: UITableViewDelegate, UITableViewDataSource {
    // MARK: - Table view data source

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "My Playlists"
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if indexPath.row >= playlists.count {
            return 60
        } else {
            return 100
        }
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return playlists.count
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) as! PlaylistsTableViewCell

            let playlist = playlists[indexPath.row]
            
            cell.title?.text = playlist.title
        
            if let ownerName = playlist.ownerName {
                cell.ownerName?.text = ownerName
            } else {
                cell.ownerName?.text = ""
            }
            
            if let lastUpdated = playlist.lastUpdated {
                cell.lastUpdatedDate?.text = PVUtility.formatDateToString(lastUpdated)
            } else {
                cell.lastUpdatedDate?.text = ""
            }
            
            cell.totalItems?.text = "\(playlist.allItems.count) items"
            
            cell.pvImage?.image = UIImage(named: "PodverseIcon")

            for item in playlist.allItems {
                if let episode = item as? Episode {
                    if let imageData = episode.podcast.imageThumbData {
                        if let image = UIImage(data: imageData) {
                            cell.pvImage?.image = image
                        }
                    }
                }
                else if let clip = item as? Clip {
                    if let imageData = clip.episode.podcast.imageThumbData {
                        if let image = UIImage(data: imageData) {
                            cell.pvImage?.image = image
                        }
                    }
                }
            }

        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        self.performSegueWithIdentifier("Show Playlist Items", sender: self)
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    
    // Override to support conditional editing of the table view.
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return NO if you do not want the specified item to be editable.
        return true
    }
    
    // Override to support editing the table view.
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        
        if indexPath.row > 1 {
            if editingStyle == .Delete {
                let playlistToRemove = playlists[indexPath.row]
                
                let deletePlaylistAlert = UIAlertController(title: "Delete Playlist", message: "Do you want to delete this playlist locally, or both locally and on podverse.fm?", preferredStyle: UIAlertControllerStyle.Alert)
                
                deletePlaylistAlert.addAction(UIAlertAction(title: "Locally", style: .Default, handler: { (action: UIAlertAction!) in
                    PVDeleter.deletePlaylist(playlistToRemove, deleteFromServer: false)
                    self.tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
                }))
                
                deletePlaylistAlert.addAction(UIAlertAction(title: "Locally and Online", style: .Default, handler: { (action: UIAlertAction!) in
                    PVDeleter.deletePlaylist(playlistToRemove, deleteFromServer: true)
                    self.tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
                }))
                
                deletePlaylistAlert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: { (action: UIAlertAction!) in
                    self.tableView.editing = false
                    
                }))
                
                presentViewController(deletePlaylistAlert, animated: true, completion: nil)
            }
        } else {
            let alert = UIAlertController(title: "Cannot Delete", message: "The \"My Episodes\" and \"My Clips\" playlists are required by default and cannot be deleted.", preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: { (action: UIAlertAction!) in
                self.tableView.editing = false
                
            }))
            
            self.presentViewController(alert, animated: true, completion: nil)
        }
    }
    
    // MARK: - Navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "Show Playlist Items" {
            let playlistItemsViewController = segue.destinationViewController as! PlaylistItemsViewController
            if let index = tableView.indexPathForSelectedRow {
                playlistItemsViewController.playlistObjectId = playlists[index.row].objectID
            }
        } else if segue.identifier == Constants.TO_PLAYER_SEGUE_ID {
            let mediaPlayerViewController = segue.destinationViewController as! MediaPlayerViewController
            mediaPlayerViewController.hidesBottomBarWhenPushed = true
        }
    }
}

extension PlaylistsTableViewController:PlaylistManagerDelegate {
    func playlistAddedByUrl() {
        refreshPlaylists()
    }
    
    func itemAddedToPlaylist() {
        refreshPlaylists()
    }
    
    func didSavePlaylist() {
        refreshPlaylists()
    }
}
