//
//  PodcastProfileViewController.swift
//  podverse
//
//  Created by Mitchell Downey on 7/12/15.
//  Copyright (c) 2015 Mitchell Downey. All rights reserved.
//

import UIKit

class PodcastProfileViewController: UIViewController {
        
    var searchResultPodcast: SearchResultPodcast!
    
    @IBOutlet weak var searchResultImage: UIImageView!
    @IBOutlet weak var searchResultTitle: UILabel!
    @IBOutlet weak var searchResultTotalClips: UILabel!
    @IBOutlet weak var searchResultLastPublishedDate: UILabel!
    
    @IBOutlet weak var searchResultHeaderView: UIView!
    
    @IBOutlet weak var searchResultPrimaryGenreName: UILabel!
    @IBOutlet weak var searchResultEpisodesTotal: UILabel!
    @IBOutlet weak var searchResultFeedURL: UILabel!
    
    @IBOutlet weak var searchResultSummary: UITextView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        searchResultHeaderView.layer.borderColor = UIColor.lightGrayColor().CGColor
        searchResultHeaderView.layer.borderWidth = 0.5
        
        searchResultTitle.text = searchResultPodcast.title
        
        if let imageUrlString = searchResultPodcast.imageURL, let imageUrl = NSURL(string: imageUrlString) {
            UIImage.downloadImageWithURL(imageUrl, completion: { (completed, image) -> () in
                if completed {
                   self.searchResultImage?.image = image
                }
                else {
                    if let itunesUrlString = self.searchResultPodcast.itunesImageURL, let itunesUrl = NSURL(string: itunesUrlString) {
                        UIImage.downloadImageWithURL(itunesUrl, completion: { (completed, iTunesImage) -> () in
                            if completed {
                                self.searchResultImage?.image = iTunesImage
                            }
                        })
                    }
                }
            })
        }
        
        searchResultTotalClips.text = "123 clips"
        
        searchResultLastPublishedDate.text = PVUtility.formatDateToString(searchResultPodcast.lastPubDate!)

        searchResultPrimaryGenreName.text = "Genre: " + searchResultPodcast.primaryGenreName!
//
////        searchResultEpisodesTotal.text = "Episodes Available: " + String(searchResultPodcast.episodesTotal!)
        
//        searchResultFeedURL.text = "RSS Feed: " + searchResultPodcast.feedURL

        searchResultSummary.text = searchResultPodcast.artistName!
        
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
