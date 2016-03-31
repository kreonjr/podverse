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

    var playlistManager = PlaylistManager.sharedInstance
    
    var podcastsArray = [Podcast]()
    
    var refreshControl: UIRefreshControl!
    
    var playlists:[Playlist] {
        get {
            let unsortedPlaylists = PlaylistManager.sharedInstance.playlists
            var sortedPlaylists = unsortedPlaylists.sort({ $0.title.lowercaseString < $1.title.lowercaseString })
            
            for (index , playlist) in sortedPlaylists.enumerate() {
                // TODO: there's got to be a better way to do this. The goal is to make My Episodes and My Clips always be the first 2 playlists in the table.
                if playlist.title == Constants.kMyClipsPlaylist {
                    sortedPlaylists.removeAtIndex(index)
                    sortedPlaylists.insert(playlist, atIndex: 0)
                } else if playlist.title == Constants.kMyEpisodesPlaylist {
                    sortedPlaylists.removeAtIndex(index)
                    sortedPlaylists.insert(playlist, atIndex: 0)
                }
            }
            return sortedPlaylists
        }
    }
    
    func loadData() {
        let podcastsPredicate = NSPredicate(format: "isSubscribed == %@", NSNumber(bool: true))
        podcastsArray = CoreDataHelper.sharedInstance.fetchEntities("Podcast", predicate: podcastsPredicate) as! [Podcast]
        podcastsArray.sortInPlace{ $0.title.removeArticles() < $1.title.removeArticles() }

        // TODO: The answer in the SO link below claims that using a string in a predicate can cause performance issues. Well below we are passing a podcast object as the NSPredicate. If strings can cause performance issues, wouldn't this cause egregiously horrible performance issues? I know this "fetchOnlyEntityWithMostRecentPubDate" has had mutating array crashes in the past (although I haven't seen it happen since mid-February). Could it be that we are using a bad predicate? If yes, how can we make this more performant?
        // http://stackoverflow.com/questions/30368945/saving-coredata-on-background-thread-causes-fetching-into-a-deadlock-and-crash

        // Set pubdate in cell equal to most recent episode's pubdate
        for podcast in podcastsArray {
            let podcastPredicate = NSPredicate(format: "podcast == %@", podcast)
            let mostRecentEpisodeArray = CoreDataHelper.sharedInstance.fetchOnlyEntityWithMostRecentPubDate("Episode", predicate: podcastPredicate) as! [Episode]
            if mostRecentEpisodeArray.count > 0 {
                if let mostRecentEpisodePubDate = mostRecentEpisodeArray[0].pubDate {
                    podcast.lastPubDate = mostRecentEpisodePubDate
                }
            }
        }
        
        self.tableView.reloadData()
    }
    
    func segueToNowPlaying(sender: UIBarButtonItem) {
        self.performSegueWithIdentifier("Podcasts to Now Playing", sender: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        playlistManager.delegate = self
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .Plain, target: nil, action: nil)
        
        refreshControl = UIRefreshControl()
        refreshControl.attributedTitle = NSAttributedString(string: "Pull to refresh all podcasts")
        refreshControl.addTarget(self, action: "refreshPodcastFeeds", forControlEvents: UIControlEvents.ValueChanged)
        tableView.addSubview(refreshControl)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector:"loadData" , name: Constants.refreshPodcastTableDataNotification, object: nil)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "removePlayerNavButton:", name: Constants.kPlayerHasNoItem, object: nil)

        let episodeArray = CoreDataHelper.sharedInstance.fetchEntities("Episode", predicate: nil) as! [Episode]
        for episode in episodeArray {
            episode.taskIdentifier = nil
        }
        
        for episode:Episode in DLEpisodesList.shared.downloadingEpisodes {
            PVDownloader.sharedInstance.startDownloadingEpisode(episode)
        }
        
        self.refreshPodcastFeeds()
        
        PlaylistManager.sharedInstance.refreshPlaylists()
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
        
        PVMediaPlayer.sharedInstance.addPlayerNavButton(self)
        
        loadData()
    }

    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
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
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if indexPath.section == 1 && indexPath.row >= playlists.count {
            return 60
        } else {
            return 100
        }
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return podcastsArray.count
        } else {
            return playlists.count
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
            
            //TODO: Calculate all clips in podcast
            cell.totalClips?.text = "\(0) clips"
            
            cell.lastPublishedDate?.text = ""
            if let lastPubDate = podcast.lastPubDate {
                cell.lastPublishedDate?.text = PVUtility.formatDateToString(lastPubDate)
            }
            
            if let imageData = podcast.imageData, image = UIImage(data: imageData) {
                cell.pvImage?.image = image
            }
            else if let itunesImageData = podcast.itunesImage, itunesImage = UIImage(data: itunesImageData) {
                cell.pvImage?.image = itunesImage
            }
            else {
                cell.pvImage?.image = UIImage(named: "Blank52")
            }
        } else {
            let playlist = playlists[indexPath.row]
            cell.title?.text = playlist.title
            cell.episodesDownloadedOrStarted?.text = "playlist creator's name here"
            
            cell.lastPublishedDate?.text = "playlist last updated date"
            //                cell.lastPublishedDate?.text = PVUtility.formatDateToString(lastBuildDate)
            
            cell.totalClips?.text = "\(playlist.totalItems) items"
            
            cell.pvImage?.image = UIImage(named: "Blank52")

            for item in playlist.allItems {
                if let episode = item as? Episode {
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
                }
                else if let clip = item as? Clip {
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

    func showAddPlaylistByURLAlert() {
        let addPlaylistByURLAlert = UIAlertController(title: "Add Playlist By URL", message: nil, preferredStyle: UIAlertControllerStyle.Alert)
        
        addPlaylistByURLAlert.addTextFieldWithConfigurationHandler({(textField: UITextField!) in
            textField.placeholder = "http://podverse.tv/pl/..."
        })
        
        addPlaylistByURLAlert.addAction(UIAlertAction(title: "Cancel", style: .Default, handler: nil))
        
        addPlaylistByURLAlert.addAction(UIAlertAction(title: "Add", style: .Default, handler: { (action: UIAlertAction!) in
            let textField = addPlaylistByURLAlert.textFields![0] as UITextField
            if let urlString = textField.text {
                self.playlistManager.addPlaylistByUrlString(urlString)
            }
            self.loadData()
        }))
        
        presentViewController(addPlaylistByURLAlert, animated: true, completion: nil)
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
            
            PVDeleter.deletePodcast(podcastToRemove)
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

    @IBAction func addPlaylistByURL(sender: AnyObject) {
        showAddPlaylistByURLAlert()
    }
}

extension PodcastsTableViewController:PlaylistManagerDelegate {
    func playlistAddedByUrl() {
        self.reloadTable()
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
