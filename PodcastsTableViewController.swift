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
    
    @IBOutlet weak var bottomButton: UIButton!
    
    var managedObjectContext:NSManagedObjectContext!
    var podcastsArray = [Podcast]()
    let coreDataHelper = CoreDataHelper.sharedInstance
    var playlistManager = PlaylistManager.sharedInstance
    let parsingPodcasts = ParsingPodcastsList.shared
    let reachability = PVReachability.manager
    var refreshControl: UIRefreshControl!
    @IBOutlet weak var parsingActivity: UIActivityIndicatorView!
    @IBOutlet weak var parsingActivityLabel: UILabel!
    @IBOutlet weak var parsingActivityBar: UIProgressView!
    @IBOutlet weak var parsingActivityContainer: UIView!
    
    private let REFRESH_PODCAST_TIME:Double = 3600
    
    override func viewDidLoad() {
        super.viewDidLoad()
        var isFirstTimeAppOpened: Bool = false
        
        if NSUserDefaults.standardUserDefaults().objectForKey("ONE_TIME_LOGIN") == nil {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
                if let loginVC = storyboard.instantiateViewControllerWithIdentifier("LoginVC") as? LoginViewController {
                loginVC.delegate = self
                self.presentViewController(loginVC, animated: false, completion: nil)
            }
            NSUserDefaults.standardUserDefaults().setObject(NSUUID().UUIDString, forKey: "ONE_TIME_LOGIN")
            isFirstTimeAppOpened = true
        }
        
        navigationItem.title = "Podcasts"
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .Plain, target: nil, action: nil)

        bottomButton.hidden = true
        showSubscribeToPodcastsIfNoneAreSubscribed()
        
        refreshControl = UIRefreshControl()
        refreshControl.attributedTitle = NSAttributedString(string: "Pull to refresh all podcasts")
        refreshControl.addTarget(self, action: #selector(refreshData), forControlEvents: UIControlEvents.ValueChanged)
        tableView.addSubview(refreshControl)
                
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(removePlayerNavButtonAndReload), name: Constants.kPlayerHasNoItem, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(reloadPodcastData), name: Constants.kDownloadHasFinished, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(unsubscribeFromPodcast(_:)), name: Constants.kUnsubscribeFromPodcast, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(clearParsingActivity), name: Constants.kInternetIsUnreachable, object: nil)
        updateParsingActivity()
        
        if isFirstTimeAppOpened != true {
            reloadPodcastData()
            refreshPodcastFeeds()
        }

        startCheckSubscriptionsForNewEpisodesTimer()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        navigationItem.rightBarButtonItem = self.playerNavButton()
        showSubscribeToPodcastsIfNoneAreSubscribed()
    }
    
    func refreshData() {
        if reachability.hasInternetConnection() == false && refreshControl.refreshing == true {
            showInternetNeededAlert("Connect to WiFi or cellular data to parse podcast feeds.")
            refreshControl.endRefreshing()
            return
        }
        refreshPodcastFeeds()
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
        if podcastsArray.count == 0 {
            bottomButton.setTitle("Subscribe to a podcast", forState: .Normal)
            bottomButton.hidden = false
        } else if podcastsArray.count > 0 {
            bottomButton.hidden = true
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
        tabBarController?.selectedIndex = 2
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
        return "My Subscribed Podcasts"
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 100
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return podcastsArray.count
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) as! PodcastsTableCell

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
        
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        self.performSegueWithIdentifier("Show Episodes", sender: nil)
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
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
            podcastsArray.removeAtIndex(indexPath.row)
            self.tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
            
            PVSubscriber.unsubscribeFromPodcast(podcastToRemove.objectID, completionBlock: nil)
            
            showSubscribeToPodcastsIfNoneAreSubscribed()
        }
    }
}

extension PodcastsTableViewController: PVFeedParserDelegate {
    func feedParsingComplete(feedURL:String?) {
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
    
    func feedParsingStarted() {
        updateParsingActivity()
    }
    
    func feedParserChannelParsed() {
        self.reloadPodcastData()
    }
}

extension PodcastsTableViewController:LoginModalDelegate {
    // TODO: what happens if a user logs into a different account through the app?
    
    func loginTapped() {
        PVAuth.sharedInstance.showAuth0LockLoginVC(self)
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
