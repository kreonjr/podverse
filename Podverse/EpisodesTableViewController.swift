//
//  EpisodesTableViewController.swift
//  Podverse
//
//  Created by Mitchell Downey on 4/27/15.
//  Copyright (c) 2015 Mitchell Downey. All rights reserved.
//

import UIKit

class EpisodesTableViewController: UITableViewController {
    
    var utility: PVUtility = PVUtility()
    
    var podcast: PodcastModel = PodcastModel()
    var episodes: [EpisodeModel] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = podcast.title
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
        return episodes.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> EpisodeTableCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("episodeTableCell", forIndexPath: indexPath) as! EpisodeTableCell

        let episode: EpisodeModel = episodes[indexPath.row]
//        cell.textLabel!.text = episode.title
//        cell.detailTextLabel?.text = episode.summary
        cell.title?.text = episode.title
        cell.summary?.text = utility.removeHTMLFromString(episode.summary!)
        cell.duration?.text = utility.convertNSTimeIntervalToHHMMSSString(episode.duration!) as String
        
        let pubDateFormatter = NSDateFormatter()
        pubDateFormatter.dateStyle = NSDateFormatterStyle.ShortStyle
        let pubDateString = pubDateFormatter.stringFromDate(episode.pubDate!)
        cell.pubDate?.text = pubDateString
        
        let clips: String = String("10 clips")
        cell.clips?.text = clips
        
        return cell
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 120
    }
    
    override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let podcastHeaderCell = tableView.dequeueReusableCellWithIdentifier("PodcastHeaderCell") as! PodcastHeaderCell
        podcastHeaderCell.PVimage!.image = podcast.image
        podcastHeaderCell.PVsummary!.text = podcast.summary
        return podcastHeaderCell
    }
    
    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 100
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
        if segue.identifier == "MediaPlayer" {
            let viewController: MediaPlayerViewController = segue.destinationViewController as! MediaPlayerViewController
            let indexPath = self.tableView.indexPathForSelectedRow()!
            let episode = episodes[indexPath.row]
            viewController.episode = episode
            viewController.podcast = podcast
        }
    }


}
