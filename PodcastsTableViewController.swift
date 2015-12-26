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
        podcastArray.sortInPlace({ $0.title < $1.title })
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
        
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        // Alert the user to enable background notifications
        // TODO: Shouldn't this be moved to somewhere like the AppDelegate?
        let registerUserNotificationSettings = UIApplication.instancesRespondToSelector("registerUserNotificationSettings:")
        if registerUserNotificationSettings {
            let types: UIUserNotificationType = [.Alert , .Sound]
            UIApplication.sharedApplication().registerUserNotificationSettings(UIUserNotificationSettings(forTypes: types, categories: nil))
        }
        
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
        
        let imageData = podcast.imageData
        let itunesImageData = podcast.itunesImage
        
        let totalEpisodesDownloadedPredicate = NSPredicate(format: "podcast == %@ && downloadComplete == true", podcast)
        let totalEpisodesDownloaded = CoreDataHelper.fetchEntities("Episode", managedObjectContext: Constants.moc, predicate: totalEpisodesDownloadedPredicate)
        cell.episodesDownloadedOrStarted?.text = "\(totalEpisodesDownloaded.count) downloaded, 12 in progress"
        
        if let lastPubDate = podcast.lastPubDate {
            cell.lastPublishedDate?.text = PVUtility.formatDateToString(lastPubDate)
        } else if let lastBuildDate = podcast.lastBuildDate {
            cell.lastPublishedDate?.text = PVUtility.formatDateToString(lastBuildDate)
        }

        if imageData != nil {
            let image = UIImage(data: imageData!)
            if image!.size.height != 0.0 {
                cell.pvImage?.image = image
            }
        }
        else if itunesImageData != nil {
            let itunesImage = UIImage(data: itunesImageData!)
            if itunesImage!.size.height != 0.0 {
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
        } else if segue.identifier == "Podcasts to Now Playing" {
            let mediaPlayerViewController = segue.destinationViewController as! MediaPlayerViewController
            mediaPlayerViewController.returnToNowPlaying = true
            mediaPlayerViewController.hidesBottomBarWhenPushed = true
        }
    }

}
