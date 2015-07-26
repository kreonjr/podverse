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

    var parser = PVFeedParser()
    
    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    
    let downloader = PVDownloader()
    
    var moc: NSManagedObjectContext!
    var podcastArray = [Podcast]()
    
    var counter = 0
    
    @IBAction func addPodcast(sender: AnyObject) {
        let addPodcastAlert = UIAlertController(title: "New Podcast", message: "Enter podcast feed URL", preferredStyle: UIAlertControllerStyle.Alert)
        addPodcastAlert.addTextFieldWithConfigurationHandler(nil)
        addPodcastAlert.addAction(UIAlertAction(title: "Save", style: UIAlertActionStyle.Default, handler: { (alertAction: UIAlertAction!) -> Void in
            let textField = addPodcastAlert.textFields?.last as! UITextField
            if textField.text != "" {
                var feedURLString = textField.text
                var feedURL = NSURL(string: feedURLString)
                
                // Uses Callback/Promise to make sure table data is refreshed
                // after parsePodcastFeed() finishes
                self.parser.parsePodcastFeed(feedURL!, returnPodcast: true, returnOnlyLatestEpisode: false,
                    resolve: {
                        self.loadData()
                    },
                    reject: {
                        // do nothing
                    }
                )
                
            }
        }))
        
        addPodcastAlert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil))
        
        self.presentViewController(addPodcastAlert, animated: true, completion: nil)
    }
    
    func loadData() {
        podcastArray = CoreDataHelper.fetchEntities("Podcast", managedObjectContext: moc, predicate: nil) as! [Podcast]
        println(podcastArray.count)
        self.tableView.reloadData()
    }
    
    func segueToNowPlaying(sender: UIBarButtonItem) {
        self.performSegueWithIdentifier("Podcasts to Now Playing", sender: nil)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        // Alert the user to enable background notifications
        let registerUserNotificationSettings = UIApplication.instancesRespondToSelector("registerUserNotificationSettings:")
        if registerUserNotificationSettings {
            var types: UIUserNotificationType = UIUserNotificationType.Alert | UIUserNotificationType.Sound
            UIApplication.sharedApplication().registerUserNotificationSettings(UIUserNotificationSettings(forTypes: types, categories: nil))
        }
        
        if let context = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext {
            moc = context
        }
        
        loadData()
        
        self.navigationItem.title = "Podverse"
        self.navigationController?.navigationBar.barStyle = UIBarStyle.Black
        self.navigationController?.navigationBar.tintColor = UIColor.whiteColor()
        self.navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName: UIColor.whiteColor(), NSFontAttributeName: UIFont.boldSystemFontOfSize(16.0)]
        
        if ((appDelegate.nowPlayingEpisode) != nil) {
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Player", style: .Plain, target: self, action: "segueToNowPlaying:")
        }
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        for var i = 0; i < self.appDelegate.episodeDownloadArray.count; i++ {
            self.downloader.startPauseOrResumeDownloadingEpisode(self.appDelegate.episodeDownloadArray[i], completion: nil)
        }

        println("episode download array total below")
        println(self.appDelegate.episodeDownloadArray.count)

        
    }
    
    override func viewWillDisappear(animated: Bool) {
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
        
        var imageData = podcast.image
        var itunesImageData = podcast.itunesImage

        if imageData != nil {
            
            var image = UIImage(data: imageData!)
            
            // TODO: below is probably definitely not the proper way to check for a nil value for an image, but I was stuck on it for a long time and moved on
            if image!.size.height != 0.0 {
                cell.pvImage?.image = image
            }

        }
        else if itunesImageData != nil {
            
            var itunesImage = UIImage(data: itunesImageData!)
            
            // TODO: below is probably definitely not the proper way to check for a nil value for an image, but I was stuck on it for a long time and moved on
            if itunesImage!.size.height != 0.0 {
                cell.pvImage?.image = itunesImage
            }
        }

        return cell
    }

    /*
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return NO if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Delete the row from the data source
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return NO if you do not want the item to be re-orderable.
        return true
    }
    */

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showEpisodes" {
            let episodesTableViewController = segue.destinationViewController as! EpisodesTableViewController
            if let index = self.tableView.indexPathForSelectedRow() {
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
