//
//  ClipsTableViewController.swift
//  podverse
//
//  Created by Mitchell Downey on 6/2/15.
//  Copyright (c) 2015 Mitchell Downey. All rights reserved.
//

import UIKit
import CoreData

class ClipsTableViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    
    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    
    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var headerImageView: UIImageView!
    
    @IBOutlet weak var headerSummaryLabel: UILabel!
    @IBOutlet weak var headerShadowView: UITableView!
    
    var selectedPodcast: Podcast!
    var selectedEpisode: Episode!
    
    var clipsArray = [Clip]()
    
    func loadData() {
        if let clipsArray = selectedEpisode.clips.allObjects as? [Clip] {
            self.clipsArray = clipsArray.sort {
                $0.startTime.compare($1.startTime) == NSComparisonResult.OrderedAscending
            }
        
            self.tableView.reloadData()
        }
    }
    
    func segueToNowPlaying(sender: UIBarButtonItem) {
        self.performSegueWithIdentifier("Clips to Now Playing", sender: nil)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        // If there is a now playing episode, add Now Playing button to navigation bar
        if ((PVMediaPlayer.sharedInstance.nowPlayingEpisode) != nil) {
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Player", style: .Plain, target: self, action: "segueToNowPlaying:")
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = self.selectedEpisode.title
        
        self.automaticallyAdjustsScrollViewInsets = false
        
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .Plain, target: nil, action: nil)
        
        if let imageData = selectedPodcast.imageData, image = UIImage(data: imageData) {
            headerImageView.image = image
        }
        else if let itunesImageData = selectedPodcast.itunesImage, itunesImage = UIImage(data: itunesImageData) {
            headerImageView.image = itunesImage
        }
        
        headerSummaryLabel.text = selectedEpisode.summary
        loadData()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    // MARK: - Table view data source
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return clipsArray.count
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 100
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) as! ClipsTableCell
        
        let clip = clipsArray[indexPath.row]
        
        if let title = clip.title {
            cell.title?.text = title
        }
        
        if let duration = clip.duration {
            cell.duration?.text = PVUtility.convertNSNumberToHHMMSSString(duration)
        }
        
        var startTime: String
        var endTime: String?
        startTime = PVUtility.convertNSNumberToHHMMSSString(clip.startTime)
        if let endT = clip.endTime {
            endTime = " - " + PVUtility.convertNSNumberToHHMMSSString(endT)
        }
        cell.startTimeEndTime.text = startTime + endTime!
        
        cell.sharesTotal.text = "Shares: 123"
        
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
        if segue.identifier == "Play" {
            let mediaPlayerViewController = segue.destinationViewController as! MediaPlayerViewController
            
            let index = self.tableView.indexPathForSelectedRow!
            if index.row == 0 {
                PVMediaPlayer.sharedInstance.nowPlayingEpisode = selectedEpisode
            } else {
                PVMediaPlayer.sharedInstance.nowPlayingClip = clipsArray[index.row]
            }
            
            mediaPlayerViewController.hidesBottomBarWhenPushed = true
        } else if segue.identifier == "Clips to Now Playing" {
            let mediaPlayerViewController = segue.destinationViewController as! MediaPlayerViewController
            mediaPlayerViewController.returnToNowPlaying = true
            mediaPlayerViewController.hidesBottomBarWhenPushed = true
        }
    }
}
