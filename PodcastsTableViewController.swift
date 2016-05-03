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
    
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    
    @IBAction func indexChanged(sender: UISegmentedControl) {
        switch segmentedControl.selectedSegmentIndex
        {
        case 0:
            addPlaylistByURL.hidden = true
            reloadTable()
        case 1:
            addPlaylistByURL.hidden = false
            reloadTable()
        default:
            break;
        }
    }
    
    @IBOutlet weak var addPlaylistByURL: UIButton!
    
    var appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    
    var playlistManager = PlaylistManager.sharedInstance
    
    var podcastsArray = [Podcast]() {
        didSet {
            print("Changed")
        }
    }
    
    let coreDataHelper = CoreDataHelper.sharedInstance
    
    var refreshControl: UIRefreshControl!
    
    private let REFRESH_PODCAST_TIME:Double = 3600
    
    var playlists:[Playlist] {
        get {
            let unsortedPlaylists = PlaylistManager.sharedInstance.playlists
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
        self.navigationItem.title = "Podverse"
        
        addPlaylistByURL.hidden = true

        playlistManager.delegate = self
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .Plain, target: nil, action: nil)
        
        refreshControl = UIRefreshControl()
        refreshControl.attributedTitle = NSAttributedString(string: "Pull to refresh all podcasts")
        refreshControl.addTarget(self, action: "refreshPodcastFeeds", forControlEvents: UIControlEvents.ValueChanged)
        tableView.addSubview(refreshControl)
                
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "removePlayerNavButton:", name: Constants.kPlayerHasNoItem, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "loadData", name: Constants.kDownloadHasFinished, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "loadData", name: Constants.kRefreshAddToPlaylistTableDataNotification, object: nil)
        
        //TODO: Investigate why this is needed
//        let moc = CoreDataHelper().managedObjectContext
//        let episodeArray = CoreDataHelper.fetchEntities("Episode", predicate: nil, moc:moc) as! [Episode]
//        for episode in episodeArray {
//            episode.taskIdentifier = nil
//        }
        
        refreshPodcastFeeds()
        startCheckSubscriptionsForNewEpisodesTimer()
        
        PlaylistManager.sharedInstance.refreshPlaylists { () -> Void in
            self.reloadTable()
        }
    }
    
    func refreshAllData() {
        refreshPodcastFeeds()
        PlaylistManager.sharedInstance.refreshPlaylists { () -> Void in
            self.tableView.reloadSections(NSIndexSet(index: 1), withRowAnimation: .None)
        }
    }
    
    func refreshPodcastFeeds() {
        let moc = self.coreDataHelper.managedObjectContext
        let podcastsPredicate = NSPredicate(format: "isSubscribed == %@", NSNumber(bool: true))
        let podcastArray = CoreDataHelper.fetchEntities("Podcast", predicate: podcastsPredicate, moc:moc) as! [Podcast]

        for podcast in podcastArray {
            let feedURL = NSURL(string:podcast.feedURL)
            
            dispatch_async(Constants.feedParsingQueue) {
                let feedParser = PVFeedParser(onlyGetMostRecentEpisode: true, shouldSubscribe:false)
                feedParser.delegate = self
                if let feedURLString = feedURL?.absoluteString {
                    feedParser.parsePodcastFeed(feedURLString)
                }
            }
        }
    }
    
    func removePlayerNavButton(notification: NSNotification) {
        self.loadData()
        PVMediaPlayer.sharedInstance.removePlayerNavButton(self)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
                
        PVMediaPlayer.sharedInstance.addPlayerNavButton(self)        
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
        } else {
            return playlists.count
        }
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

    func showAddPlaylistByURLAlert() {
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
                
                PVSubscriber.unsubscribeFromPodcast(podcastToRemove, moc:podcastToRemove.managedObjectContext)
                podcastsArray.removeAtIndex(indexPath.row)
                
                self.tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
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
    
    func reloadTable() {
        tableView.reloadData()
        refreshControl?.endRefreshing()
    }

    @IBAction func addPlaylistByURL(sender: AnyObject) {
        showAddPlaylistByURLAlert()
    }
    
    // This function runs once on app load, then runs in the background every 30 minutes.
    // Check if a new episode is available for a subscribed podcast; if true, download that episode.
    // TODO: shouldn't we check via push notifications? Rather than a timer that continuously runs in the background?
    func startCheckSubscriptionsForNewEpisodesTimer() {
        NSTimer.scheduledTimerWithTimeInterval(REFRESH_PODCAST_TIME, target: self, selector: "refreshAllData", userInfo: nil, repeats: true)
    }
    
    func loadData() {
        let podcastsPredicate = NSPredicate(format: "isSubscribed == %@", NSNumber(bool: true))
        self.podcastsArray = CoreDataHelper.fetchEntities("Podcast", predicate: podcastsPredicate, moc:coreDataHelper.managedObjectContext) as! [Podcast]
        self.podcastsArray.sortInPlace{ $0.title.removeArticles() < $1.title.removeArticles() }

        //TODO (Somewhere else, not in the view controller) Set pubdate in cell equal to most recent episode's pubdate
//            for podcast in self.podcastsArray {
//                let podcastPredicate = NSPredicate(format: "podcast == %@", podcast)
//                let mostRecentEpisodeArray = CoreDataHelper.fetchOnlyEntityWithMostRecentPubDate("Episode", predicate: podcastPredicate, moc:moc) as! [Episode]
//                if mostRecentEpisodeArray.count > 0 {
//                    if let mostRecentEpisodePubDate = mostRecentEpisodeArray[0].pubDate {
//                        podcast.lastPubDate = mostRecentEpisodePubDate
//                    }
//                }
//            }

        self.reloadTable()
    }
    
    func segueToNowPlaying(sender: UIBarButtonItem) {
        self.performSegueWithIdentifier("Podcasts to Now Playing", sender: nil)
    }
}

extension PodcastsTableViewController: PVFeedParserDelegate {
    func feedParsingComplete(feedURL:String?) {
        if let url = feedURL, let index = podcastsArray.indexOf({ url == $0.feedURL }) {
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.tableView.reloadRowsAtIndexPaths([NSIndexPath(forRow: index, inSection: 0)], withRowAnimation: .None)
            })
        }
        else {
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.loadData()
            })
        }
    }
    
    func feedItemParsed() {
        //loadData()
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
