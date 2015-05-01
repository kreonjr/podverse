//
//  PodcastsTableViewController.swift
//  Podverse
//
//  Created by Mitchell Downey on 4/27/15.
//  Copyright (c) 2015 Mitchell Downey. All rights reserved.
//

import UIKit

class PodcastsTableViewController: UITableViewController, NSXMLParserDelegate, MWFeedParserDelegate {
    
    var parser: NSXMLParser = NSXMLParser()
    
    var feedURLs: [NSURL] = []
    
    var podcast: PodcastModel = PodcastModel()
    var episode: EpisodeModel = EpisodeModel()
    
    var podcasts: [PodcastModel] = []
    var episodes: [EpisodeModel] = []
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
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
         
            var feedParser: MWFeedParser = MWFeedParser(feedURL: feedURLs[i] as NSURL)
            feedParser.delegate = self
            feedParser.feedParseType = ParseTypeFull
            feedParser.connectionType = ConnectionTypeAsynchronously
            feedParser.parse()
            
        }
        
    }

    override func didReceiveMemoryWarning() {
        
        super.didReceiveMemoryWarning()
        
    }
    
    func feedParserDidStart(parser: MWFeedParser!) {
        
        episodes = []
        
    }
    
    func feedParser(parser: MWFeedParser!, didParseFeedInfo info: MWFeedInfo!) {
        
        podcast = PodcastModel()
        
        if info.title != nil {
            podcast.title = info.title
        }
        if info.summary != nil {
            podcast.summary = info.summary
        }
        if info.url != nil {
            podcast.feedURL = info.url
        }

    }
    
    func feedParser(parser: MWFeedParser!, didParseFeedItem item: MWFeedItem!) {
        
        episode = EpisodeModel()
        
        if item.title != nil {
            episode.title = item.title
        }
        if item.summary != nil {
            episode.summary = item.summary
        }
        if item.date != nil {
            episode.pubDate = item.date
        }
        
        episodes.append(episode)
        
    }
    
    func feedParserDidFinish(parser: MWFeedParser!) {
        
        podcast.episodes.extend(episodes)
        
        podcasts.append(podcast)
        
        // dispatch_async is necessary to reload the tableView with new data
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            self.tableView.reloadData()
        })
        
    }
    
    func feedParser(parser: MWFeedParser!, didFailWithError error: NSError!) {
        
    }
    
    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        
        return 1

    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return podcasts.count
        
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCellWithIdentifier("podcastCell", forIndexPath: indexPath) as! UITableViewCell
        let podcast: PodcastModel = podcasts[indexPath.row]
        var currentPodcast = podcasts[indexPath.row]
        cell.textLabel!.text = currentPodcast.title
        
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
            viewController.episodes = podcast.episodes
        }
    }

}
