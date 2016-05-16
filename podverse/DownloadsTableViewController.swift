//
//  DownloadsTableViewController.swift
//  podverse
//
//  Created by Mitchell Downey on 6/23/15.
//  Copyright (c) 2015 Mitchell Downey. All rights reserved.
//

import UIKit
import CoreData

class DownloadsTableViewController: UITableViewController {

    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    
    var episodes:[DownloadingEpisode] {
        get {
            return DLEpisodesList.shared.downloadingEpisodes
        }
    }
    
    func reloadDownloadTable() {
        self.tableView.reloadData()
    }
    
    func removePlayerButtonAndReload() {
        self.reloadDownloadTable()
        self.removePlayerNavButton()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .Plain, target: nil, action: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(reloadDownloadData(_:)), name: Constants.kDownloadHasProgressed, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(reloadDownloadData(_:)), name: Constants.kDownloadHasFinished, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(pauseOrResumeDownloadData(_:)), name: Constants.kDownloadHasPausedOrResumed, object: nil)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(removePlayerButtonAndReload), name: Constants.kPlayerHasNoItem, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(reloadDownloadTable), name: Constants.kUpdateDownloadsTable, object: nil)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.addPlayerNavButton()
    }
    
    func reloadDownloadData(notification:NSNotification) {
        if let downloadDataInfo = notification.userInfo {
            for(index, episode) in self.episodes.enumerate() {
                let indexPath = NSIndexPath(forRow: index, inSection: 0)
                if episode.mediaURL == downloadDataInfo["mediaUrl"] as? String, let totalBytes = downloadDataInfo["totalBytes"] as? Float, let currentBytes = downloadDataInfo["currentBytes"]as? Float, let cell = self.tableView.cellForRowAtIndexPath(indexPath) as? DownloadsTableViewCell  {
                    
                        // Format the total bytes into a human readable KB or MB number
                        let dataFormatter = NSByteCountFormatter()
                        
                        cell.progress.progress = Float(currentBytes / totalBytes)
                        let formattedCurrentBytesDownloaded = dataFormatter.stringFromByteCount(Int64(currentBytes))
                        let formattedTotalFileBytes = dataFormatter.stringFromByteCount(Int64(totalBytes))
                        cell.progressBytes.text = "\(formattedCurrentBytesDownloaded) / \(formattedTotalFileBytes)"
                    
                        if cell.progress.progress == 1.0 {
                            cell.downloadStatus.text = "Finished"
                            cell.progressBytes.text = "\(formattedTotalFileBytes)"
                        }
                                        
                        return
                }
            }
        }
    }
    
    func pauseOrResumeDownloadData(notification:NSNotification) {
        if let downloadDataInfo = notification.userInfo {
            for(index, episode) in self.episodes.enumerate() {
                let indexPath = NSIndexPath(forRow: index, inSection: 0)
                if episode.mediaURL == downloadDataInfo["mediaUrl"] as? String, let pauseOrResume = downloadDataInfo["pauseOrResume"] as? String, let cell = self.tableView.cellForRowAtIndexPath(indexPath) as? DownloadsTableViewCell  {
                    cell.downloadStatus.text = pauseOrResume
                    return
                }
            }
        }
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return DLEpisodesList.shared.downloadingEpisodes.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell: DownloadsTableViewCell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) as! DownloadsTableViewCell
        let downloadingEpisode = DLEpisodesList.shared.downloadingEpisodes[indexPath.row]
        
        cell.title?.text = downloadingEpisode.title
        
        if let imageData = downloadingEpisode.imageData {
            if let image = UIImage(data: imageData) {
                cell.pvImage?.image = image
            }
        }
        
        if downloadingEpisode.downloadComplete == true {
            cell.downloadStatus.text = "Finished"
            cell.progress.progress = Float(1)
        }
        else if downloadingEpisode.taskIdentifier != nil {
            cell.downloadStatus.text = "Downloading"
            cell.progress.progress = downloadingEpisode.progress
        }
        else {
            cell.downloadStatus.text = "Paused"
            cell.progress.progress = downloadingEpisode.progress
        }
        
        cell.progressBytes.text = downloadingEpisode.formattedTotalBytesDownloaded

        return cell
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 100
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let downloadingEpisode = DLEpisodesList.shared.downloadingEpisodes[indexPath.row]
        
        guard downloadingEpisode.mediaURL != nil else {
            return
        }
        
        PVDownloader.sharedInstance.pauseOrResumeDownloadingEpisode(downloadingEpisode)
    }

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "To Now Playing" {
            let mediaPlayerViewController = segue.destinationViewController as! MediaPlayerViewController
            mediaPlayerViewController.hidesBottomBarWhenPushed = true
        }
    }

}
