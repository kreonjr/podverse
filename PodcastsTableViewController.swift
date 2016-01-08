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
        podcastArray = CoreDataHelper.fetchEntities("Podcast", managedObjectContext: Constants.moc, predicate: nil) as! [Podcast]
        podcastArray.sortInPlace{ $0.title.removeArticles() < $1.title.removeArticles() }
        
        self.tableView.reloadData()
    }
    
    func segueToNowPlaying(sender: UIBarButtonItem) {
        self.performSegueWithIdentifier("Podcasts to Now Playing", sender: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .Plain, target: nil, action: nil)
        
        // If there are any unfinished downloads in the appDelegate.episodeDownloadArray, then resume those downloads
        for episode:Episode in appDelegate.episodeDownloadArray {
            PVDownloader.sharedInstance.startDownloadingEpisode(episode)
        }
        
        self.refreshControl!.addTarget(self, action: "refreshPodcastFeeds", forControlEvents: UIControlEvents.ValueChanged)
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
        
        // If there is a now playing episode, add Now Playing button to navigation bar
        if ((PVMediaPlayer.sharedInstance.nowPlayingEpisode) != nil) {
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Player", style: .Plain, target: self, action: "segueToNowPlaying:")
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Potentially incomplete method implementation.
        // Return the number of sections.
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete method implementation.
        // Return the number of rows in the section.
        return podcastArray.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) as! PodcastsTableCell
        let podcast = podcastArray[indexPath.row]
        cell.title?.text = podcast.title
        cell.pvImage?.image = UIImage(named: "Blank52")
        
        let totalEpisodesDownloadedPredicate = NSPredicate(format: "podcast == %@ && downloadComplete == true", podcast)
        let totalEpisodesDownloaded = CoreDataHelper.fetchEntities("Episode", managedObjectContext: Constants.moc, predicate: totalEpisodesDownloadedPredicate)
        cell.episodesDownloadedOrStarted?.text = "\(totalEpisodesDownloaded.count) downloaded"
        
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
            PVSubscriber.sharedInstance.unsubscribeFromPodcast(podcastToRemove)
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
            mediaPlayerViewController.returnToNowPlaying = true
            mediaPlayerViewController.hidesBottomBarWhenPushed = true
        }
    }
    
    func feedParsingComplete() {
        self.refreshControl!.endRefreshing()
        tableView.reloadData()
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
