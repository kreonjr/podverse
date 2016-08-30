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
    var subscribedPodcastsArray = [Podcast]()
    var followedPodcastsArray = [Podcast]()
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
        
        tabBarController?.tabBar.translucent = false

        bottomButton.hidden = true
        showFindAPodcastIfNoneAreFollowed()
        
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
        showFindAPodcastIfNoneAreFollowed()
        self.tableView.reloadData()
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
            for(index, podcast) in self.subscribedPodcastsArray.enumerate() {
                if podcast.feedURL == unsubscribedPodcastInfo["feedURL"] as? String {
                    //ATTENTION NOTE: Any additional view controllers pushed on this nav stack need to be checked and popped
                    if let topVC = self.navigationController?.topViewController as? EpisodesTableViewController where topVC.selectedPodcast.feedURL == podcast.feedURL {
                        self.navigationController?.popToRootViewControllerAnimated(false)
                    }
                    else if let topVC = self.navigationController?.topViewController as? ClipsTableViewController where topVC.selectedPodcast.feedURL == podcast.feedURL {
                        self.navigationController?.popToRootViewControllerAnimated(false)
                    }
                    
                    subscribedPodcastsArray.removeAtIndex(index)
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
                let feedParser = PVFeedParser(onlyGetMostRecentEpisode: true, shouldSubscribe:false, shouldFollow: false, shouldParseChannelOnly: false)
                feedParser.delegate = self
                if let feedURLString = feedURL?.absoluteString {
                    feedParser.parsePodcastFeed(feedURLString)
                    dispatch_async(dispatch_get_main_queue(), { 
                        self.updateParsingActivity()
                    })
                }
            }
        }
        
        showFindAPodcastIfNoneAreFollowed()
        
        refreshControl.endRefreshing()
    }
    
    private func showFindAPodcastIfNoneAreFollowed() {
        if subscribedPodcastsArray.count == 0 && followedPodcastsArray.count == 0 {
            bottomButton.setTitle("Find a podcast", forState: .Normal)
            bottomButton.hidden = false
        } else {
            bottomButton.hidden = true
        }
    }
    
    // MARK: - Navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "Show Episodes" {
            let episodesTableViewController = segue.destinationViewController as! EpisodesTableViewController
            if let index = tableView.indexPathForSelectedRow {
                
                // if there are no downloaded episodes, then showAllEpisodes
                let downloadedEpisodesArrayPredicate = NSPredicate(format: "fileName != nil || taskIdentifier != nil", argumentArray: nil)
                var downloadedEpisodesArray: NSSet!
                
                if index.section == 0 {
                    episodesTableViewController.selectedPodcastId = subscribedPodcastsArray[index.row].objectID
                    downloadedEpisodesArray = subscribedPodcastsArray[index.row].episodes.filteredSetUsingPredicate(downloadedEpisodesArrayPredicate)
                } else {
                    episodesTableViewController.selectedPodcastId = followedPodcastsArray[index.row].objectID
                        downloadedEpisodesArray = followedPodcastsArray[index.row].episodes.filteredSetUsingPredicate(downloadedEpisodesArrayPredicate)
                }
                
                
                if downloadedEpisodesArray.count > 0 {
                    episodesTableViewController.showAllEpisodes = false
                } else {
                    episodesTableViewController.showAllEpisodes = true
                }
                
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
        tabBarController?.selectedIndex = 2
    }
    
    // This function runs once on app load, then runs in the background every 30 minutes.
    // Check if a new episode is available for a subscribed podcast; if true, download that episode.
    // TODO: shouldn't we check via push notifications? Rather than a timer that continuously runs in the background?
    func startCheckSubscriptionsForNewEpisodesTimer() {
        NSTimer.scheduledTimerWithTimeInterval(REFRESH_PODCAST_TIME, target: self, selector: #selector(refreshData), userInfo: nil, repeats: true)
    }
    
    func reloadPodcastData() {
        let subscribedPredicate = NSPredicate(format: "isSubscribed == %@", true)
        self.managedObjectContext = coreDataHelper.managedObjectContext
        self.subscribedPodcastsArray = CoreDataHelper.fetchEntities("Podcast", predicate: subscribedPredicate, moc:managedObjectContext) as! [Podcast]

        self.subscribedPodcastsArray.sortInPlace{ $0.title.removeArticles() < $1.title.removeArticles() }

        for podcast in self.subscribedPodcastsArray {
            let podcastPredicate = NSPredicate(format: "podcast == %@", podcast)
            let mostRecentEpisodeArray = CoreDataHelper.fetchOnlyEntityWithMostRecentPubDate("Episode", predicate: podcastPredicate, moc:managedObjectContext) as! [Episode]
            if let mostRecentEpisodePubDate = mostRecentEpisodeArray.first?.pubDate {
                podcast.lastPubDate = mostRecentEpisodePubDate
            }
        }
        
        let notSubscribedPredicate = NSPredicate(format: "isSubscribed == %@", false)
        let followedPredicate = NSPredicate(format: "isFollowed == %@", true)
        let compoundPredicate = NSCompoundPredicate.init(andPredicateWithSubpredicates: [notSubscribedPredicate, followedPredicate])
        self.followedPodcastsArray = CoreDataHelper.fetchEntities("Podcast", predicate: compoundPredicate, moc:managedObjectContext) as! [Podcast]
        
        self.followedPodcastsArray.sortInPlace{ $0.title.removeArticles() < $1.title.removeArticles() }
        
        for podcast in self.followedPodcastsArray {
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
        return 2
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return "Subscribed"
        } else {
            return "Following"
        }
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 100
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return subscribedPodcastsArray.count
        } else {
            return followedPodcastsArray.count
        }
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) as! PodcastsTableCell
        
        let podcast: Podcast!
        
        if indexPath.section == 0 {
            podcast = subscribedPodcastsArray[indexPath.row]
        } else {
            podcast = followedPodcastsArray[indexPath.row]
        }
        
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
    
    func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]? {
        
        let podcastToEdit: Podcast!
        
        if indexPath.section == 0 {
            podcastToEdit = subscribedPodcastsArray[indexPath.row]
        } else {
            podcastToEdit = followedPodcastsArray[indexPath.row]
        }
        
        var subscribeOrFollow = "Subscribe"
        if podcastToEdit.isSubscribed == true {
            subscribeOrFollow = "Follow"
        }
        
        let subscribeOrFollowAction = UITableViewRowAction(style: .Default, title: subscribeOrFollow, handler: {action, indexpath in
            if subscribeOrFollow == "Subscribe" {
                PVSubscriber.subscribeToPodcast(podcastToEdit.feedURL, podcastTableDelegate: self)
            } else {
                PVFollower.followPodcast(podcastToEdit.feedURL, podcastTableDelegate: self)
            }
        })
        
        subscribeOrFollowAction.backgroundColor = UIColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1.0);
        
        let deleteAction = UITableViewRowAction(style: .Default, title: "Delete", handler: {action, indexpath in
            
            // Remove Player button if the now playing episode was one of the podcast's episodes
            let allPodcastEpisodes = podcastToEdit.episodes.allObjects as! [Episode]
            if let nowPlayingEpisode = PVMediaPlayer.sharedInstance.nowPlayingEpisode {
                if allPodcastEpisodes.contains(nowPlayingEpisode) {
                    self.navigationItem.rightBarButtonItem = nil
                }
            }
            
            if indexPath.section == 0 {
                self.subscribedPodcastsArray.removeAtIndex(indexPath.row)
            } else {
                self.followedPodcastsArray.removeAtIndex(indexPath.row)
            }
            
            self.tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
            
            PVFollower.unfollowPodcast(podcastToEdit.objectID, completionBlock: nil)
            
            self.showFindAPodcastIfNoneAreFollowed()
        })
        
        return [deleteAction, subscribeOrFollowAction]
    }
    
}

extension PodcastsTableViewController: PVFeedParserDelegate {
    func feedParsingComplete(feedURL:String?) {
        if let url = feedURL, let index = self.subscribedPodcastsArray.indexOf({ url == $0.feedURL }) {
            let podcast = CoreDataHelper.fetchEntityWithID(self.subscribedPodcastsArray[index].objectID, moc: self.managedObjectContext) as! Podcast
            self.subscribedPodcastsArray[index] = podcast
            self.tableView.reloadRowsAtIndexPaths([NSIndexPath(forRow: index, inSection: 0)], withRowAnimation: .None)
        } else if let url = feedURL, let index = self.followedPodcastsArray.indexOf({ url == $0.feedURL }) {
            let podcast = CoreDataHelper.fetchEntityWithID(self.followedPodcastsArray[index].objectID, moc: self.managedObjectContext) as! Podcast
            self.followedPodcastsArray[index] = podcast
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
