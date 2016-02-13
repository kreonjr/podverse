//
//  PodcastsTableViewController.swift
//  
//
//  Created by Mitchell Downey on 6/2/15.
//
//

import UIKit
import CoreData

class PodcastsTableViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var tableView: UITableView!
    var appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate

    var podcastsArray = [Podcast]()
    
    var refreshControl: UIRefreshControl!
    
    func loadData() {
        podcastsArray = CoreDataHelper.sharedInstance.fetchEntities("Podcast", managedObjectContext: Constants.moc, predicate: nil) as! [Podcast]
        podcastsArray.sortInPlace{ $0.title.removeArticles() < $1.title.removeArticles() }
        
        self.tableView.reloadData()
    }
    
    func segueToNowPlaying(sender: UIBarButtonItem) {
        self.performSegueWithIdentifier("Podcasts to Now Playing", sender: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .Plain, target: nil, action: nil)
        
        refreshControl = UIRefreshControl()
        refreshControl.attributedTitle = NSAttributedString(string: "Pull to refresh all podcasts")
        refreshControl.addTarget(self, action: "refreshPodcastFeeds", forControlEvents: UIControlEvents.ValueChanged)
        tableView.addSubview(refreshControl)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector:"reloadTable" , name: Constants.refreshPodcastTableDataNotification, object: nil)
    }
    
    func refreshPodcastFeeds() {
        appDelegate.refreshPodcastFeeds()
    }
    
    func removePlayerNavButton(notification: NSNotification) {
        dispatch_async(dispatch_get_main_queue()) {
            self.loadData()
            PVMediaPlayer.sharedInstance.removePlayerNavButton(self)
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        // Set navigation bar styles
        self.navigationItem.title = "Podverse"
        self.navigationController?.navigationBar.barStyle = UIBarStyle.Black
        self.navigationController?.navigationBar.tintColor = UIColor.whiteColor()
        self.navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName: UIColor.whiteColor(), NSFontAttributeName: UIFont.boldSystemFontOfSize(16.0)]
        
        PVMediaPlayer.sharedInstance.addPlayerNavButton(self)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "removePlayerNavButton:", name: Constants.kPlayerHasNoItem, object: nil)
        
        loadData()
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
        return 2
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return "My Subscribed Podcasts"
        } else {
            return "My Playlists"
        }
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return podcastsArray.count
        } else {
            let allPlaylists = PVPlaylister.sharedInstance.retrieveAllPlaylists()
            return allPlaylists.count
        }
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) as! PodcastsTableCell
        
        if indexPath.section == 0 {
            let podcast = podcastsArray[indexPath.row]
            cell.title?.text = podcast.title
            
            let episodes = podcast.episodes.allObjects as! [Episode]
            let episodesDownloaded = episodes.filter{ $0.fileName != nil }
            cell.episodesDownloadedOrStarted?.text = "\(episodesDownloaded.count) downloaded"
            
            cell.totalClips?.text = String(podcast.clips.count) + " clips"
            
            // Set pubdate in cell equal to most recent episode's pubdate
            let podcastPredicate = NSPredicate(format: "podcast == %@", podcast)
            let mostRecentEpisodeArray = CoreDataHelper.sharedInstance.fetchOnlyEntityWithMostRecentPubDate("Episode", managedObjectContext: Constants.moc, predicate: podcastPredicate) as! [Episode]
            cell.lastPublishedDate?.text = ""
            if mostRecentEpisodeArray.count > 0 {
                if let mostRecentEpisodePubDate = mostRecentEpisodeArray[0].pubDate {
                    cell.lastPublishedDate?.text = PVUtility.formatDateToString(mostRecentEpisodePubDate)
                }
            }
            
            cell.pvImage?.image = UIImage(named: "Blank52")
            if let imageData = podcast.imageData {
                if let image = UIImage(data: imageData) {
                    cell.pvImage?.image = image
                }
            }
            else if let itunesImageData = podcast.itunesImage {
                if let itunesImage = UIImage(data: itunesImageData) {
                    cell.pvImage?.image = itunesImage
                }
            }

        } else {
            let playlists = PVPlaylister.sharedInstance.retrieveAllPlaylists()
            if playlists.count > 0 {
                let playlist = playlists[indexPath.row]
                cell.title?.text = playlist.title
                
                cell.episodesDownloadedOrStarted?.text = "something here"
                
                cell.lastPublishedDate?.text = "last updated date"
                //                cell.lastPublishedDate?.text = PVUtility.formatDateToString(lastBuildDate)
                
                let totalItems = PVPlaylister.sharedInstance.countPlaylistItems(playlist)
                
                cell.totalClips?.text = String(totalItems) + " items"
                
                cell.pvImage?.image = UIImage(named: "Blank52")
                // TODO: Retrieve the image of the podcast/episode/clip that was most recently added to the playlist
                //                if let imageData = podcast.imageData {
                //                    if let image = UIImage(data: imageData) {
                //                        cell.pvImage?.image = image
                //                    }
                //                }
                //                else if let itunesImageData = podcast.itunesImage {
                //                    if let itunesImage = UIImage(data: itunesImageData) {
                //                        cell.pvImage?.image = itunesImage
                //                    }
                //                }
            }
        }
        
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.section == 0 {
            self.performSegueWithIdentifier("Show Episodes", sender: nil)
        } else {
            self.performSegueWithIdentifier("Show Playlist", sender: nil)
        }
    }

    // Override to support conditional editing of the table view.
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return NO if you do not want the specified item to be editable.
        return true
    }
    
    // Override to support editing the table view.
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            let podcastToRemove = podcastsArray[indexPath.row]

            // Remove Player button if the now playing episode was one of the podcast's episodes
            let allPodcastEpisodes = podcastToRemove.episodes.allObjects as! [Episode]
            if let nowPlayingEpisode = PVMediaPlayer.sharedInstance.nowPlayingEpisode {
                if allPodcastEpisodes.contains(nowPlayingEpisode) {
                    self.navigationItem.rightBarButtonItem = nil
                }
            }
            
            PVDeleter.sharedInstance.deletePodcast(podcastToRemove)
            podcastsArray.removeAtIndex(indexPath.row)
            
            self.tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        }
    }

    // MARK: - Navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "Show Episodes" {
            let episodesTableViewController = segue.destinationViewController as! EpisodesTableViewController
            if let index = tableView.indexPathForSelectedRow {
                episodesTableViewController.selectedPodcast = podcastsArray[index.row]
            }
            episodesTableViewController.showAllEpisodes = false
        } else if segue.identifier == "Show Playlist" {
            let playlistViewController = segue.destinationViewController as! PlaylistViewController
            if let index = tableView.indexPathForSelectedRow {
                let playlists = PVPlaylister.sharedInstance.retrieveAllPlaylists()
                playlistViewController.playlist = playlists[index.row]
            }
        } else if segue.identifier == "Podcasts to Now Playing" {
            let mediaPlayerViewController = segue.destinationViewController as! MediaPlayerViewController
            mediaPlayerViewController.hidesBottomBarWhenPushed = true
        }
    }
    
    func reloadTable() {
        tableView.reloadData()
        refreshControl?.endRefreshing()
    }

}

extension String {
    func removeArticles() -> String {
        var words = self.componentsSeparatedByString(" ")
        
        //Only one word so count it as sortable
        if(words.count <= 1) {
            return self
        }
        
        if( words[0].lowercaseString == "a" || words[0].lowercaseString == "the" || words[0].lowercaseString == "an" ) {
            words.removeFirst()
            return words.joinWithSeparator(" ")
        }
        
        return self
    }
}
