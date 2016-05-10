//
//  PodcastsTableViewController.swift
//  
//
//  Created by Mitchell Downey on 6/2/15.
//
//

import UIKit
import CoreData

class PodcastsTableViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    @IBAction func indexChanged(sender: UISegmentedControl) {
        switch segmentedControl.selectedSegmentIndex
        {
        case 0:
            addPlaylistByURL.hidden = true
            self.tableView.reloadData()
        case 1:
            addPlaylistByURL.hidden = false
            self.tableView.reloadData()
        default:
            break;
        }
    }
    
    @IBOutlet weak var addPlaylistByURL: UIButton!
        
    var playlistManager = PlaylistManager.sharedInstance
    var managedObjectContext:NSManagedObjectContext!
    var podcastsArray = [Podcast]()
    let coreDataHelper = CoreDataHelper.sharedInstance
    var refreshControl: UIRefreshControl!
    private var itemsParsing = 0
    private var totalItemsToParse = 0
    @IBOutlet weak var parsingActivity: UIActivityIndicatorView!
    @IBOutlet weak var parsingActivityLabel: UILabel!
    @IBOutlet weak var parsingActivityBar: UIProgressView!
    @IBOutlet weak var parsingActivityContainer: UIView!
    
    private let REFRESH_PODCAST_TIME:Double = 3600
    
    var playlists:[Playlist] {
        get {
            let moc = coreDataHelper.managedObjectContext
            let unsortedPlaylists = CoreDataHelper.fetchEntities("Playlist", predicate: nil, moc: moc) as! [Playlist]
            var sortedPlaylists = unsortedPlaylists.sort({ $0.title.lowercaseString < $1.title.lowercaseString })
            
            for (index , playlist) in sortedPlaylists.enumerate() {
                // TODO: This method is problematic. We need a way to distinguish the user's "My Clips" and "My Episodes" playlists WITHOUT depending on the title. 
                // Currently it depends on the title, and so if you share your "My Clips" or "My Episodes" playlist with me, then the UI will move your playlist to the beginning of the array as if it were my own.
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Podverse"
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .Plain, target: nil, action: nil)

        addPlaylistByURL.hidden = true
        playlistManager.delegate = self
        
        refreshControl = UIRefreshControl()
        refreshControl.attributedTitle = NSAttributedString(string: "Pull to refresh all podcasts")
        refreshControl.addTarget(self, action: #selector(refreshData), forControlEvents: UIControlEvents.ValueChanged)
        tableView.addSubview(refreshControl)
                
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(removePlayerNavButtonAndReload), name: Constants.kPlayerHasNoItem, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(reloadPodcastData), name: Constants.kDownloadHasFinished, object: nil)
        updateParsingActivity()
        
        refreshPodcastFeeds()
        refreshPlaylists()
        startCheckSubscriptionsForNewEpisodesTimer()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.addPlayerNavButton()
    }
    
    func refreshData() {
        if segmentedControl.selectedSegmentIndex == 0 {
            refreshPodcastFeeds()
        }
        else {
            refreshPlaylists()
        }
    }
    
    private func refreshPlaylists() {
        PlaylistManager.sharedInstance.refreshPlaylists { () -> Void in
            self.refreshControl.endRefreshing()
            self.tableView.reloadData()
        }
    }
    
    private func refreshPodcastFeeds() {
        let moc = self.coreDataHelper.managedObjectContext
        let podcastsPredicate = NSPredicate(format: "isSubscribed == %@", NSNumber(bool: true))
        let podcastArray = CoreDataHelper.fetchEntities("Podcast", predicate: podcastsPredicate, moc:moc) as! [Podcast]
        totalItemsToParse = podcastsArray.count
        
        for podcast in podcastArray {
            let feedURL = NSURL(string:podcast.feedURL)
            
            dispatch_async(Constants.feedParsingQueue) {
                let feedParser = PVFeedParser(onlyGetMostRecentEpisode: true, shouldSubscribe:false)
                feedParser.delegate = self
                if let feedURLString = feedURL?.absoluteString {
                    feedParser.parsePodcastFeed(feedURLString)
                    dispatch_async(dispatch_get_main_queue(), { 
                        self.updateParsingActivity()
                    })
                }
            }
        }
        
        refreshControl.endRefreshing()
    }
    
    private func showAddPlaylistByURLAlert() {
        let addPlaylistByURLAlert = UIAlertController(title: "Add Playlist By URL", message: nil, preferredStyle: UIAlertControllerStyle.Alert)
        
        addPlaylistByURLAlert.addTextFieldWithConfigurationHandler({(textField: UITextField!) in
            textField.placeholder = "http://podverse.tv/playlist/..."
        })
        
        addPlaylistByURLAlert.addAction(UIAlertAction(title: "Cancel", style: .Default, handler: nil))
        
        addPlaylistByURLAlert.addAction(UIAlertAction(title: "Add", style: .Default, handler: { (action: UIAlertAction!) in
            let textField = addPlaylistByURLAlert.textFields![0] as UITextField
            if let urlString = textField.text {
                self.playlistManager.addPlaylistByUrlString(urlString)
            }
            self.reloadPodcastData()
        }))
        
        presentViewController(addPlaylistByURLAlert, animated: true, completion: nil)
    }
    
    // MARK: - Navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "Show Episodes" {
            let episodesTableViewController = segue.destinationViewController as! EpisodesTableViewController
            if let index = tableView.indexPathForSelectedRow {
                episodesTableViewController.selectedPodcastId = podcastsArray[index.row].objectID
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

    func removePlayerNavButtonAndReload() {
        self.removePlayerNavButton()
        self.reloadPodcastData()
    }
    
    @IBAction func addPlaylistByURL(sender: AnyObject) {
        showAddPlaylistByURLAlert()
    }
    
    // This function runs once on app load, then runs in the background every 30 minutes.
    // Check if a new episode is available for a subscribed podcast; if true, download that episode.
    // TODO: shouldn't we check via push notifications? Rather than a timer that continuously runs in the background?
    func startCheckSubscriptionsForNewEpisodesTimer() {
        NSTimer.scheduledTimerWithTimeInterval(REFRESH_PODCAST_TIME, target: self, selector: #selector(refreshData), userInfo: nil, repeats: true)
    }
    
    func reloadPodcastData() {
        let podcastsPredicate = NSPredicate(format: "isSubscribed == %@", NSNumber(bool: true))
        self.managedObjectContext = coreDataHelper.managedObjectContext
        self.podcastsArray = CoreDataHelper.fetchEntities("Podcast", predicate: podcastsPredicate, moc:managedObjectContext) as! [Podcast]

        
        self.podcastsArray.sortInPlace{ $0.title.removeArticles() < $1.title.removeArticles() }

        //TODO (Somewhere else, not in the view controller) Set pubdate in cell equal to most recent episode's pubdate
            for podcast in self.podcastsArray {
                let podcastPredicate = NSPredicate(format: "podcast == %@", podcast)
                let mostRecentEpisodeArray = CoreDataHelper.fetchOnlyEntityWithMostRecentPubDate("Episode", predicate: podcastPredicate, moc:managedObjectContext) as! [Episode]
                if mostRecentEpisodeArray.count > 0 {
                    if let mostRecentEpisodePubDate = mostRecentEpisodeArray[0].pubDate {
                        podcast.lastPubDate = mostRecentEpisodePubDate
                    }
                }
            }
        
        
        self.tableView.reloadData()
    }
    
    override func segueToNowPlaying(sender: UIBarButtonItem) {
        self.performSegueWithIdentifier("Podcasts to Now Playing", sender: nil)
    }
    
    private func updateParsingActivity() {
        self.parsingActivityLabel.text = "\(self.itemsParsing) of \(self.podcastsArray.count) parsed"
        self.parsingActivityBar.progress = Float(self.itemsParsing)/Float(self.podcastsArray.count)
        
        if self.itemsParsing == self.podcastsArray.count || self.itemsParsing == 0 {
            self.itemsParsing = 0
            self.parsingActivityContainer.hidden = true
            self.parsingActivity.stopAnimating()
        }
        else {
            self.parsingActivityContainer.hidden = false
            self.parsingActivity.startAnimating()
        }
    }
}

extension PodcastsTableViewController: UITableViewDelegate, UITableViewDataSource {
    // MARK: - Table view data source

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if segmentedControl.selectedSegmentIndex == 0 {
            return "My Subscribed Podcasts"
        } else {
            return "My Playlists"
        }
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if segmentedControl.selectedSegmentIndex == 1 && indexPath.row >= playlists.count {
            return 60
        } else {
            return 100
        }
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if segmentedControl.selectedSegmentIndex == 0 {
            return podcastsArray.count
        }
        
        return playlists.count
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) as! PodcastsTableCell

        if segmentedControl.selectedSegmentIndex == 0 {
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
            
            cell.totalClips?.text = "\(playlist.allItems.count) items"
            
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
        if segmentedControl.selectedSegmentIndex == 0 {
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
        if segmentedControl.selectedSegmentIndex == 0 {
            if editingStyle == .Delete {
                let podcastToRemove = podcastsArray[indexPath.row]
                
                // Remove Player button if the now playing episode was one of the podcast's episodes
                let allPodcastEpisodes = podcastToRemove.episodes.allObjects as! [Episode]
                if let nowPlayingEpisode = PVMediaPlayer.sharedInstance.nowPlayingEpisode {
                    if allPodcastEpisodes.contains(nowPlayingEpisode) {
                        self.navigationItem.rightBarButtonItem = nil
                    }
                }
                podcastsArray.removeAtIndex(indexPath.row)
                self.tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
                
                PVSubscriber.unsubscribeFromPodcast(podcastToRemove.objectID)
            }
        } else {
            if indexPath.row > 1 {
                if editingStyle == .Delete {
                    let playlistToRemove = playlists[indexPath.row]
                    
                    //TODO: alert the user to ask if they want to delete the playlist locally only, locally and from the server, or cancel
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
        
    }
}

extension PodcastsTableViewController: PVFeedParserDelegate {
    func feedParsingComplete(feedURL:String?) {
        if let url = feedURL, let index = self.podcastsArray.indexOf({ url == $0.feedURL }) {
            self.tableView.reloadRowsAtIndexPaths([NSIndexPath(forRow: index, inSection: 0)], withRowAnimation: .None)
        }
        else {
            self.reloadPodcastData()
        }
        
        itemsParsing += 1
        updateParsingActivity()
    }
    
    func feedParsingStarted() {
        updateParsingActivity()
    }
}

extension PodcastsTableViewController:PlaylistManagerDelegate {
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
