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
    
    var pvMediaPlayer = PVMediaPlayer.sharedInstance
    
    func loadData() {
        if let clipsArray = selectedEpisode.clips.allObjects as? [Clip] {
            self.clipsArray = clipsArray.sort {
                $0.startTime.compare($1.startTime) == NSComparisonResult.OrderedAscending
            }
        
            self.tableView.reloadData()
        }
    }
    
    func removePlayerButtonAndReload() {
        self.removePlayerNavButton()
        self.loadData()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        self.addPlayerNavButton()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = self.selectedEpisode.title
        
        self.automaticallyAdjustsScrollViewInsets = false
        
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .Plain, target: nil, action: nil)
        
        if let imageData = selectedPodcast.imageThumbData, image = UIImage(data: imageData) {
            headerImageView.image = image
        }
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(removePlayerButtonAndReload), name: Constants.kPlayerHasNoItem, object: nil)

        headerSummaryLabel.text = PVUtility.removeHTMLFromString(selectedEpisode.summary)
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
        
        cell.duration?.text = PVUtility.convertNSNumberToHHMMSSString(clip.duration)

        
        var startTime: String
        var endTime: String?
        startTime = PVUtility.convertNSNumberToHHMMSSString(clip.startTime)
        endTime = " - " + PVUtility.convertNSNumberToHHMMSSString(clip.endTime)

        cell.startTimeEndTime.text = startTime + endTime!
        
        cell.sharesTotal.text = "Shares: 123"
        
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let selectedClip = clipsArray[indexPath.row]
        self.pvMediaPlayer.loadClipDownloadedMediaFileOrStreamAndPlay(selectedClip.objectID)
        self.segueToNowPlaying()
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
        if segue.identifier == Constants.TO_PLAYER_SEGUE_ID {
            let mediaPlayerViewController = segue.destinationViewController as! MediaPlayerViewController
            mediaPlayerViewController.hidesBottomBarWhenPushed = true
        }
    }
}
