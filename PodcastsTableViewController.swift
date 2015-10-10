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
    
    var moc: NSManagedObjectContext! {
        get {
            return appDelegate.managedObjectContext
        }
    }

    var podcastArray = [Podcast]()
    
    @IBAction func addPodcast(sender: AnyObject) {
        print("does nothing for now :)")
    }
    
    func loadData() {
        podcastArray = CoreDataHelper.fetchEntities("Podcast", managedObjectContext: moc, predicate: nil) as! [Podcast]
        self.tableView.reloadData()
    }
    
    func segueToNowPlaying(sender: UIBarButtonItem) {
        self.performSegueWithIdentifier("Podcasts to Now Playing", sender: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
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
        if ((appDelegate.nowPlayingEpisode) != nil) {
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
        
        let imageData = podcast.image
        let itunesImageData = podcast.itunesImage
        
        let totalEpisodesDownloadedPredicate = NSPredicate(format: "podcast == %@ && downloadComplete == true", podcast)
        let totalEpisodesDownloaded = CoreDataHelper.fetchEntities("Episode", managedObjectContext: moc, predicate: totalEpisodesDownloadedPredicate)
        cell.episodesDownloadedOrStarted?.text = "\(totalEpisodesDownloaded.count) downloaded, 12 in progress"
        
        if let lastPubDate = podcast.lastPubDate {
            cell.lastPublishedDate?.text = PVUtility.formatDateToString(lastPubDate)
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
            
            let podcast = podcastArray[indexPath.row]
            
            // Get all episodes with this podcast as a parent, then delete those episodes from CoreData and the episodeDownloadArray
            let episodeToRemovePredicate = NSPredicate(format: "podcast == %@", podcast)
            let episodeToRemoveArray = CoreDataHelper.fetchEntities("Episode", managedObjectContext: moc, predicate: episodeToRemovePredicate)
            
            // Get the downloadSession and the downloadTasks, and make downloadTasks available to parent
            let downloadSession = PVDownloader.sharedInstance.downloadSession
            var downloadTasksArray = [NSURLSessionDownloadTask]()
            downloadSession.getTasksWithCompletionHandler { dataTasks, uploadTasks, downloadTasks in
                downloadTasksArray = downloadTasks
            }
            
            // Delete each episode from the moc, cancel current downloadTask, and remove episode from the episodeDownloadArray
            for var i = 0; i < episodeToRemoveArray.count; i++ {
                let episodeToRemove = episodeToRemoveArray[i] as! Episode
                moc.deleteObject(episodeToRemove)
                
                // If the episodeToRemove is currently downloading, then retrieve and cancel the download
                if episodeToRemove.taskIdentifier != nil {
                    for episodeDownloadTask in downloadTasksArray {
                        if episodeDownloadTask.taskIdentifier == episodeToRemove.taskIdentifier {
                            episodeDownloadTask.cancel()
                        }
                    }
                }
                
                // If the episodeToRemove is in the episodeDownloadArray, then remove the episodeToRemove from the episodeDownloadArray
                if appDelegate.episodeDownloadArray.contains(episodeToRemove) {
                    let episodeDownloadArrayIndex = appDelegate.episodeDownloadArray.indexOf(episodeToRemove)
                    appDelegate.episodeDownloadArray.removeAtIndex(episodeDownloadArrayIndex!)
                }
                
                // If the episodeToRemove is currently now playing, then remove the now playing episode, and remove the Player button from the navbar
                // TODO: this is needed below
                if episodeToRemove == appDelegate.nowPlayingEpisode {
                    
                }
                
                
            }
            
            // Delete podcast from CoreData, then update UI
            moc.deleteObject(podcast)
            podcastArray.removeAtIndex(indexPath.row)
            self.tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
            
            // Save
            do {
                try moc.save()
                print("podcast and it's episodes deleted")
            } catch let error as NSError {
                print(error)
            }
        }
    }

    // MARK: - Navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showEpisodes" {
            let episodesTableViewController = segue.destinationViewController as! EpisodesTableViewController
            if let index = self.tableView.indexPathForSelectedRow {
                episodesTableViewController.selectedPodcast = podcastArray[index.row]
            }
            navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .Plain, target: nil, action: nil)
        } else if segue.identifier == "Podcasts to Now Playing" {
            let mediaPlayerViewController = segue.destinationViewController as! MediaPlayerViewController
            mediaPlayerViewController.selectedEpisode = appDelegate.nowPlayingEpisode
            mediaPlayerViewController.hidesBottomBarWhenPushed = true
        }
    }

}
