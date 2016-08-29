//
//  PodcastProfileViewController.swift
//  podverse
//
//  Created by Mitchell Downey on 7/12/15.
//  Copyright (c) 2015 Mitchell Downey. All rights reserved.
//

import UIKit
import TTTAttributedLabel

class PodcastProfileViewController: UIViewController, TTTAttributedLabelDelegate {
    
    var podcast: Podcast?
    
    @IBOutlet weak var podcastImage: UIImageView!
    @IBOutlet weak var podcastTitle: UILabel!
    @IBOutlet weak var totalClips: UILabel!
    @IBOutlet weak var lastPublishedDate: UILabel!
    
    @IBOutlet weak var homePage: TTTAttributedLabel!
    @IBOutlet weak var author: UILabel!
    @IBOutlet weak var categories: UILabel!
    @IBOutlet weak var summary: UITextView!
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        navigationItem.rightBarButtonItem = self.playerNavButton()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let coredataPodcast = podcast {
            podcastTitle.text = coredataPodcast.title
            
            totalClips.text = "123 clips"
            
            if let lastBuildDate = coredataPodcast.lastBuildDate {
                lastPublishedDate.text = PVUtility.formatDateToString(lastBuildDate)
            }
            
            if let podcastAuthor = coredataPodcast.author {
                author.text = podcastAuthor
            }
            
            if let podcastCategories = coredataPodcast.categories {
                categories.text = podcastCategories
            }
            
            if let link = coredataPodcast.link {
                let range = NSRangeFromString(link)
                homePage.enabledTextCheckingTypes = NSTextCheckingType.Link.rawValue
                homePage.addLinkToURL(NSURL(string: link), withRange: range)
                homePage.delegate = self
                homePage.text = link
            }
            
            if let podcastSummary = coredataPodcast.summary, let cleanedSummary = PVUtility.removeHTMLFromString(podcastSummary) {
                summary.text = cleanedSummary
            }
            
            if let imageData = coredataPodcast.imageThumbData, image = UIImage(data: imageData) {
                podcastImage.image = image
            }
            else {
                podcastImage.image = UIImage(named: "PodverseIcon")
            }

        }
        
    }
    
    var viewDidLayoutSubviewsAtLeastOnce = false
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if !viewDidLayoutSubviewsAtLeastOnce {
            summary?.setContentOffset(CGPointZero, animated: false)
        }
        
        viewDidLayoutSubviewsAtLeastOnce = true
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == Constants.TO_PLAYER_SEGUE_ID {
            let mediaPlayerViewController = segue.destinationViewController as! MediaPlayerViewController
            mediaPlayerViewController.hidesBottomBarWhenPushed = true
        }
    }
    
    func attributedLabel(label: TTTAttributedLabel!, didSelectLinkWithURL url: NSURL!) {
        UIApplication.sharedApplication().openURL(url)
    }

}
