//
//  PodcastsTableViewController.swift
//  Podverse
//
//  Created by Mitchell Downey on 4/27/15.
//  Copyright (c) 2015 Mitchell Downey. All rights reserved.
//

import UIKit

class PodcastsTableViewController: UITableViewController, PVFeedParserProtocol {
    
    @IBOutlet var myPodcastsTableView: UITableView!
    
    var parser: PVFeedParser = PVFeedParser()
    
    var feedURLs: [NSURL] = []
    
    var podcast: PodcastModel = PodcastModel()
    var episode: EpisodeModel = EpisodeModel()
    
    var podcasts: [PodcastModel] = []
    
    func didReceiveFeedResults(results: PodcastModel) {
        dispatch_async(dispatch_get_main_queue(), {
            self.podcasts.append(results)
            self.myPodcastsTableView!.reloadData()
        })
    }
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        parser.delegate = self
        
        self.title = "My Podcasts"
        
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .Plain, target: nil, action: nil)
        
        // Convert an array full of Strings into NSURLs. I'm not sure why or if using NSURL would be
        // preferable than using Strings for the RSS URLs...
        var feedURLsStringsArray = ["http://joeroganexp.joerogan.libsynpro.com/rss", "http://lavenderhour.libsyn.com/rss", "http://feeds.feedburner.com/dancarlin/history", "http://yourmomshousepodcast.libsyn.com/rss", "http://theartofcharmpodcast.theartofcharm.libsynpro.com/rss", "http://feeds.feedburner.com/PointlessWithKevenPereira", "http://feeds.feedburner.com/TheDrunkenTaoistPodcast"] as [String]?
        
        if let array = feedURLsStringsArray {
            for string in array {
                var feedURL = NSURL(string: string)
                feedURLs.append(feedURL!)
            }
        }
        
        for var i = 0; i < feedURLs.count; i++ {
            parser.parsePodcastFeed(feedURLs[i])
        }
        
    }

    override func didReceiveMemoryWarning() {
        
        super.didReceiveMemoryWarning()
        
    }
    
    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return podcasts.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCellWithIdentifier("podcastCell", forIndexPath: indexPath) as! myPodcastTableCell
        let podcast: PodcastModel = podcasts[indexPath.row]
        var currentPodcast = podcasts[indexPath.row]
        cell.layoutMargins = UIEdgeInsetsZero
        cell.preservesSuperviewLayoutMargins = false
        cell.PVtitle?.text = currentPodcast.title
        
        var dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "M/d/yy"
        let dateString = dateFormatter.stringFromDate(currentPodcast.lastPubDate)
        cell.PVlastPubDate?.text = dateString
        
        cell.PVimage?.image = UIImage(named: "Blank52")
        
        var image: UIImage? = podcast.image
        
        // TODO: this definitely is not the proper way to check for a null value for an image,
        // but I've spent about 10 hours trying to figure out how to check if UIImage is nil or not, and no success.
        // There is something about Swift classes and optionals that I must not be understanding.
        // The Problem: When the info.image not nil conditional runs in PVFeedParser, info.image is ALWAYS not nil,
        // even when there is no imageURL for that image. Also, the if let imgData NSData condition is always passing,
        // even when there is no imageURL for that image. Images without a URL are still producing a UIImage,
        // except their UIImage's have a height/width of 0,0. I know there must be a more proper way to check for nil,
        // but until one of us figures it out, I'll check if the UIImage has no height, and if it has no height,
        // then we know there isn't an image for that podcast.
        
        if image!.size.height != 0.0 {

            cell.PVimage?.image = image
        } else {
            var itunesImage: UIImage? = podcast.itunesImage
            if itunesImage!.size.height != 0.0 {
                cell.PVimage?.image = itunesImage
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
        if segue.identifier == "ShowEpisodes" {
            let viewController: EpisodesTableViewController = segue.destinationViewController as! EpisodesTableViewController
            let indexPath = self.tableView.indexPathForSelectedRow()!
            let podcast = podcasts[indexPath.row]
            viewController.podcast = podcast
            viewController.episodes = podcast.episodes
        }
    }

}
