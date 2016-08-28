//
//  PodcastProfileViewController.swift
//  podverse
//
//  Created by Mitchell Downey on 7/12/15.
//  Copyright (c) 2015 Mitchell Downey. All rights reserved.
//

import UIKit

class PodcastProfileViewController: UIViewController {
    
    
    
    var searchResultPodcast: SearchResultPodcast?
    var podcast: Podcast?
    
    @IBOutlet weak var searchResultImage: UIImageView!
    @IBOutlet weak var searchResultTitle: UILabel!
    @IBOutlet weak var searchResultTotalClips: UILabel!
    @IBOutlet weak var searchResultLastPublishedDate: UILabel!
    
    @IBOutlet weak var searchResultPrimaryGenreName: UILabel!
    @IBOutlet weak var searchResultEpisodesTotal: UILabel!
    @IBOutlet weak var searchResultFeedURL: UILabel!
    
    @IBOutlet weak var searchResultSummary: UITextView!
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        navigationItem.rightBarButtonItem = self.playerNavButton()
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let searchPodcast = searchResultPodcast {
            searchResultTitle.text = searchPodcast.title
            
            searchResultTotalClips.text = "123 clips"
            
            if let lastPubDate = searchPodcast.lastPubDate {
                searchResultLastPublishedDate.text = PVUtility.formatDateToString(lastPubDate)
            }
            
            if let genre = searchPodcast.primaryGenreName {
                searchResultPrimaryGenreName.text = "Genre: " + genre
            }

            //
            ////        searchResultEpisodesTotal.text = "Episodes Available: " + String(searchResultPodcast.episodesTotal!)
            
            //        searchResultFeedURL.text = "RSS Feed: " + searchResultPodcast.feedURL
            
            if let artistName = searchPodcast.artistName {
                searchResultSummary.text = artistName
            }
            
            if let imageUrlString = searchPodcast.imageURL, let imageUrl = NSURL(string: imageUrlString) {
                UIImage.downloadImageWithURL(imageUrl, completion: { [weak self] (completed, image) -> () in
                    if completed {
                        self?.searchResultImage?.image = image
                    }
                    else {
                        if let itunesUrlString = searchPodcast.itunesImageURL, let itunesUrl = NSURL(string: itunesUrlString) {
                            UIImage.downloadImageWithURL(itunesUrl, completion: { [weak self] (completed, iTunesImage) -> () in
                                if completed {
                                    self?.searchResultImage?.image = iTunesImage
                                }
                            })
                        }
                    }
                })
            }
        } else if let coredataPodcast = podcast {
            searchResultTitle.text = coredataPodcast.title
            
            searchResultTotalClips.text = "123 clips"
            
            if let lastPubDate = coredataPodcast.lastPubDate {
                searchResultLastPublishedDate.text = PVUtility.formatDateToString(lastPubDate)
            }
            
//            if let genre = coredataPodcast.primaryGenreName {
//                searchResultPrimaryGenreName.text = "Genre: " + genre
//            }
            
            //
            ////        searchResultEpisodesTotal.text = "Episodes Available: " + String(searchResultPodcast.episodesTotal!)
            
            //        searchResultFeedURL.text = "RSS Feed: " + searchResultPodcast.feedURL
            
            if let author = coredataPodcast.author {
                searchResultSummary.text = author
            }
            
            if let imageUrlString = coredataPodcast.imageURL, let imageUrl = NSURL(string: imageUrlString) {
                UIImage.downloadImageWithURL(imageUrl, completion: { [weak self] (completed, image) -> () in
                    if completed {
                        self?.searchResultImage?.image = image
                    }
                    else {
                        if let itunesUrlString = coredataPodcast.itunesImageURL, let itunesUrl = NSURL(string: itunesUrlString) {
                            UIImage.downloadImageWithURL(itunesUrl, completion: { [weak self] (completed, iTunesImage) -> () in
                                if completed {
                                    self?.searchResultImage?.image = iTunesImage
                                }
                            })
                        }
                    }
                })
            }

        }
        
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

}
