//
//  PodcastsTableViewController.swift
//  
//
//  Created by Mitchell Downey on 6/2/15.
//
//

import UIKit
import CoreData

class PodcastsTableViewController: UITableViewController {

    @IBOutlet var myPodcastsTableView: UITableView!
    
    var appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate

    var podcastArray = [Podcast]()
    
    func loadData() {
        podcastArray = CoreDataHelper.sharedInstance.fetchEntities("Podcast", managedObjectContext: Constants.moc, predicate: nil) as! [Podcast]
        podcastArray.sortInPlace{ $0.title.removeArticles() < $1.title.removeArticles() }
        
        self.tableView.reloadData()
    }
    
    func segueToNowPlaying(sender: UIBarButtonItem) {
        self.performSegueWithIdentifier("Podcasts to Now Playing", sender: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .Plain, target: nil, action: nil)
        
        self.refreshControl?.addTarget(self, action: "refreshPodcastFeeds", forControlEvents: UIControlEvents.ValueChanged)
        NSNotificationCenter.defaultCenter().addObserver(self, selector:"reloadTable" , name: Constants.refreshPodcastTableDataNotification, object: nil)
    }
    
    func refreshPodcastFeeds() {
        appDelegate.refreshPodcastFeeds()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        loadData()
        
        // Set navigation bar styles
        self.navigationItem.title = "Podverse"
        self.navigationController?.navigationBar.barStyle = UIBarStyle.Black
        self.navigationController?.navigationBar.tintColor = UIColor.whiteColor()
        self.navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName: UIColor.whiteColor(), NSFontAttributeName: UIFont.boldSystemFontOfSize(16.0)]
        
        PVMediaPlayer.sharedInstance.addPlayerNavButton(self)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return "My Subscribed Podcasts"
        } else {
            return "My Playlists"
        }
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return podcastArray.count
        } else {
            if let playlistArray = PVPlaylister.sharedInstance.allPlaylists {
                return playlistArray.count
            } else {
                return 0
            }
        }
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) as! PodcastsTableCell
        
        if indexPath.section == 0 {
            let podcast = podcastArray[indexPath.row]
            cell.title?.text = podcast.title
            cell.pvImage?.image = UIImage(named: "Blank52")
            
            let episodes = podcast.episodes.allObjects as! [Episode]
            let episodesDownloaded = episodes.filter{ $0.downloadComplete == true }
            cell.episodesDownloadedOrStarted?.text = "\(episodesDownloaded.count) downloaded"
            
            if let lastPubDate = podcast.lastPubDate {
                cell.lastPublishedDate?.text = PVUtility.formatDateToString(lastPubDate)
            } else if let lastBuildDate = podcast.lastBuildDate {
                cell.lastPublishedDate?.text = PVUtility.formatDateToString(lastBuildDate)
            }
            
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
            if let playlists = PVPlaylister.sharedInstance.allPlaylists {
                let playlist = playlists[indexPath.row]
                cell.title?.text = playlist.title
                
                var totalItems = 0
                
                if let podcastCount = playlist.podcasts?.allObjects.count {
                    totalItems += podcastCount
                }
                
                if let episodeCount = playlist.episodes?.allObjects.count {
                    totalItems += episodeCount
                }
                
                if let clipCount = playlist.clips?.allObjects.count {
                    totalItems += clipCount
                }
                
                cell.episodesDownloadedOrStarted?.text = String(totalItems)
            }
        }
        
        return cell
    }

    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return NO if you do not want the specified item to be editable.
        return true
    }
    
    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            let podcastToRemove = podcastArray[indexPath.row]

            // Remove Player button if the now playing episode was one of the podcast's episodes
            let allPodcastEpisodes = podcastToRemove.episodes.allObjects as! [Episode]
            if let nowPlayingEpisode = PVMediaPlayer.sharedInstance.nowPlayingEpisode {
                if allPodcastEpisodes.contains(nowPlayingEpisode) {
                    self.navigationItem.rightBarButtonItem = nil
                }
            }
            
            PVDeleter.sharedInstance.deletePodcast(podcastToRemove)
            podcastArray.removeAtIndex(indexPath.row)
            
            self.tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        }
    }

    // MARK: - Navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showEpisodes" {
            let episodesTableViewController = segue.destinationViewController as! EpisodesTableViewController
            if let index = self.tableView.indexPathForSelectedRow {
                episodesTableViewController.selectedPodcast = podcastArray[index.row]
            }
            episodesTableViewController.showAllEpisodes = false
        } else if segue.identifier == "Podcasts to Now Playing" {
            let mediaPlayerViewController = segue.destinationViewController as! MediaPlayerViewController
            mediaPlayerViewController.hidesBottomBarWhenPushed = true
        }
    }
    
    func reloadTable() {
        tableView.reloadData()
        self.refreshControl?.endRefreshing()
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
