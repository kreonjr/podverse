//
//  PodcastsTableViewController.swift
//  
//
//  Created by Mitchell Downey on 6/2/15.
//
//

import UIKit
import CoreData
import Lock

class PodcastsTableViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    @IBAction func indexChanged(sender: UISegmentedControl) {
        switch segmentedControl.selectedSegmentIndex
        {
        case 0:
            showSubscribeToPodcastsIfNoneAreSubscribed()
            self.tableView.reloadData()
        case 1:
            bottomButton.setTitle("Add Playlist by URL", forState: .Normal)
            bottomButton.hidden = false
            self.tableView.reloadData()
        default:
            break;
        }
    }
    
    @IBOutlet weak var bottomButton: UIButton!
        
    var playlistManager = PlaylistManager.sharedInstance
    var managedObjectContext:NSManagedObjectContext!
    var podcastsArray = [Podcast]()
    let coreDataHelper = CoreDataHelper.sharedInstance
    let parsingPodcasts = ParsingPodcastsList.shared
    let reachability = PVReachability.manager
    var refreshControl: UIRefreshControl!
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

        if NSUserDefaults.standardUserDefaults().objectForKey("ONE_TIME_LOGIN") == nil {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
                if let loginVC = storyboard.instantiateViewControllerWithIdentifier("LoginVC") as? LoginViewController {
                loginVC.delegate = self
                self.presentViewController(loginVC, animated: false, completion: nil)
            }
            NSUserDefaults.standardUserDefaults().setObject(NSUUID().UUIDString, forKey: "ONE_TIME_LOGIN")
        }
        
        navigationItem.title = "Podverse"
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .Plain, target: nil, action: nil)

        bottomButton.hidden = true
        playlistManager.delegate = self
        
        refreshControl = UIRefreshControl()
        refreshControl.attributedTitle = NSAttributedString(string: "Pull to refresh all podcasts")
        refreshControl.addTarget(self, action: #selector(refreshData), forControlEvents: UIControlEvents.ValueChanged)
        tableView.addSubview(refreshControl)
                
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(removePlayerNavButtonAndReload), name: Constants.kPlayerHasNoItem, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(reloadPodcastData), name: Constants.kDownloadHasFinished, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(unsubscribeFromPodcast(_:)), name: Constants.kUnsubscribeFromPodcast, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(clearParsingActivity), name: Constants.kInternetIsUnreachable, object: nil)
        updateParsingActivity()
        
        reloadPodcastData()
        refreshPodcastFeeds()
        refreshPlaylists()
        startCheckSubscriptionsForNewEpisodesTimer()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        navigationItem.rightBarButtonItem = self.playerNavButton()
        showSubscribeToPodcastsIfNoneAreSubscribed()
    }
    
    func refreshData() {
        if segmentedControl.selectedSegmentIndex == 0 {
            if reachability.hasInternetConnection() == false && refreshControl.refreshing == true {
                showInternetNeededAlert("Connect to WiFi or cellular data to parse podcast feeds.")
                refreshControl.endRefreshing()
                return
            }
            refreshPodcastFeeds()
        }
        else {
            if reachability.hasInternetConnection() == false && refreshControl.refreshing == true {
                showInternetNeededAlert("Connect to WiFi or cellular data to refresh playlists.")
                refreshControl.endRefreshing()
                return
            }
            refreshPlaylists()
        }
    }
    
    func unsubscribeFromPodcast(notification:NSNotification) {
        if let unsubscribedPodcastInfo = notification.userInfo {
            for(index, podcast) in self.podcastsArray.enumerate() {
                if podcast.feedURL == unsubscribedPodcastInfo["feedURL"] as? String {
                    //ATTENTION NOTE: Any additional view controllers pushed on this nav stack need to be checked and popped
                    if let topVC = self.navigationController?.topViewController as? EpisodesTableViewController where topVC.selectedPodcast.feedURL == podcast.feedURL {
                        self.navigationController?.popToRootViewControllerAnimated(false)
                    }
                    else if let topVC = self.navigationController?.topViewController as? ClipsTableViewController where topVC.selectedPodcast.feedURL == podcast.feedURL {
                        self.navigationController?.popToRootViewControllerAnimated(false)
                    }
                    
                    podcastsArray.removeAtIndex(index)
                    self.tableView.reloadData()
                }
            }
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
        
        for podcast in podcastArray {
            parsingPodcasts.urls.append(podcast.feedURL)
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
        
        showSubscribeToPodcastsIfNoneAreSubscribed()
        
        refreshControl.endRefreshing()
    }
    
    private func showSubscribeToPodcastsIfNoneAreSubscribed() {
        if podcastsArray.count == 0 && segmentedControl.selectedSegmentIndex == 0 {
            bottomButton.setTitle("Subscribe to a podcast", forState: .Normal)
            bottomButton.hidden = false
        } else if podcastsArray.count > 0 && segmentedControl.selectedSegmentIndex == 0 {
            bottomButton.hidden = true
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
                playlistViewController.playlistObjectId = playlists[index.row].objectID
            }
        } else if segue.identifier == Constants.TO_PLAYER_SEGUE_ID {
            let mediaPlayerViewController = segue.destinationViewController as! MediaPlayerViewController
            mediaPlayerViewController.hidesBottomBarWhenPushed = true
        }
    }

    func removePlayerNavButtonAndReload() {
        self.removePlayerNavButton()
        self.reloadPodcastData()
    }
    
    
    @IBAction func bottomButtonAction(sender: AnyObject) {
        if segmentedControl.selectedSegmentIndex == 0 {
            tabBarController?.selectedIndex = 1
        } else if segmentedControl.selectedSegmentIndex == 1 {
            showAddPlaylistByURLAlert()
        }
    }
    
    // This function runs once on app load, then runs in the background every 30 minutes.
    // Check if a new episode is available for a subscribed podcast; if true, download that episode.
    // TODO: shouldn't we check via push notifications? Rather than a timer that continuously runs in the background?
    func startCheckSubscriptionsForNewEpisodesTimer() {
        NSTimer.scheduledTimerWithTimeInterval(REFRESH_PODCAST_TIME, target: self, selector: #selector(refreshData), userInfo: nil, repeats: true)
    }
    
    func reloadPodcastData() {
        let podcastsPredicate = NSPredicate(format: "isSubscribed == %@", true)
        self.managedObjectContext = coreDataHelper.managedObjectContext
        self.podcastsArray = CoreDataHelper.fetchEntities("Podcast", predicate: podcastsPredicate, moc:managedObjectContext) as! [Podcast]

        
        self.podcastsArray.sortInPlace{ $0.title.removeArticles() < $1.title.removeArticles() }

        for podcast in self.podcastsArray {
            let podcastPredicate = NSPredicate(format: "podcast == %@", podcast)
            let mostRecentEpisodeArray = CoreDataHelper.fetchOnlyEntityWithMostRecentPubDate("Episode", predicate: podcastPredicate, moc:managedObjectContext) as! [Episode]
            if let mostRecentEpisodePubDate = mostRecentEpisodeArray.first?.pubDate {
                podcast.lastPubDate = mostRecentEpisodePubDate
            }
        }
        
        self.tableView.reloadData()
    }
    
    func clearParsingActivity() {
        parsingPodcasts.itemsParsing = 0
        self.parsingActivityContainer.hidden = true
    }
    
    func updateParsingActivity() {
        self.parsingActivityLabel.text = "\(parsingPodcasts.itemsParsing) of \(parsingPodcasts.urls.count) parsed"
        self.parsingActivityBar.progress = Float(parsingPodcasts.itemsParsing)/Float(parsingPodcasts.urls.count)
        
        if parsingPodcasts.itemsParsing >= parsingPodcasts.urls.count {
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
            
            cell.totalClips?.text = "\(podcast.totalClips) clips"
            
            cell.lastPublishedDate?.text = ""
            if let lastPubDate = podcast.lastPubDate {
                cell.lastPublishedDate?.text = PVUtility.formatDateToString(lastPubDate)
            }
            
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), { 
                var cellImage:UIImage?

                if let imageData = podcast.imageThumbData, image = UIImage(data: imageData) {
                    cellImage = image
                }
                else {
                    cellImage = UIImage(named: "PodverseIcon")
                }
                
                dispatch_async(dispatch_get_main_queue(), { 
                    if let visibleRows = self.tableView.indexPathsForVisibleRows where visibleRows.contains(indexPath) {
                        let existingCell = self.tableView.cellForRowAtIndexPath(indexPath) as! PodcastsTableCell
                        existingCell.pvImage.image = cellImage
                    }
                })
            })
        } else {
            let playlist = playlists[indexPath.row]
            cell.title?.text = playlist.title
            cell.episodesDownloadedOrStarted?.text = "playlist creator's name here"
            
            cell.lastPublishedDate?.text = "playlist last updated date"
            //                cell.lastPublishedDate?.text = PVUtility.formatDateToString(lastBuildDate)
            
            cell.totalClips?.text = "\(playlist.allItems.count) items"
            
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
            
        }

        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if segmentedControl.selectedSegmentIndex == 0 {
            self.performSegueWithIdentifier("Show Episodes", sender: nil)
        } else {
            self.performSegueWithIdentifier("Show Playlist", sender: nil)
        }
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
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
                
                PVSubscriber.unsubscribeFromPodcast(podcastToRemove.objectID, completionBlock: nil)
                
                showSubscribeToPodcastsIfNoneAreSubscribed()
            }
        } else {
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
        
    }
}

extension PodcastsTableViewController: PVFeedParserDelegate {
    func feedParsingComplete(feedURL:String?) {
        if segmentedControl.selectedSegmentIndex == 0 {
            if let url = feedURL, let index = self.podcastsArray.indexOf({ url == $0.feedURL }) {
                let podcast = CoreDataHelper.fetchEntityWithID(self.podcastsArray[index].objectID, moc: self.managedObjectContext) as! Podcast
                self.podcastsArray[index] = podcast
                self.tableView.reloadRowsAtIndexPaths([NSIndexPath(forRow: index, inSection: 0)], withRowAnimation: .None)
            }
            else {
                self.reloadPodcastData()
            }
            updateParsingActivity()
        }
    }
    
    func feedParsingStarted() {
        updateParsingActivity()
    }
    
    func feedParserChannelParsed() {
        self.reloadPodcastData()
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

extension PodcastsTableViewController:LoginModalDelegate {
    func loginTapped() {
        let lock = A0Lock.sharedLock()
        let controller = lock.newLockViewController()
        controller.closable = true
        
        controller.onAuthenticationBlock = {(profile, token) in
            NSUserDefaults.standardUserDefaults().setObject(token?.idToken, forKey: "idToken")
            NSUserDefaults.standardUserDefaults().setObject(profile?.userId, forKey: "userId")
            self.dismissViewControllerAnimated(true, completion: nil)
        }
        
        lock.presentLockController(controller, fromController: self, presentationStyle: .Custom)
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
