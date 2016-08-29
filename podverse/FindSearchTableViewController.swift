//
//  FindSearchTableViewController.swift
//  
//
//  Created by Mitchell Downey on 7/10/15.
//
//

import UIKit
import CoreData

class FindSearchTableViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate {
    
    @IBOutlet weak var searchBar: UISearchBar!
    
    @IBOutlet weak var tableView: UITableView!
    
    var iTunesSearchPodcastArray = [SearchResultPodcast]()
    var iTunesSearchPodcastFeedURLArray: [NSURL] = []
    
    var podcast: Podcast?
    
    let moc = CoreDataHelper.sharedInstance.managedObjectContext
    
    var podcastVC:PodcastsTableViewController? {
        get {
            if let navController = self.tabBarController?.viewControllers?.first as? UINavigationController, podcastTable = navController.topViewController as? PodcastsTableViewController {
                return podcastTable
            }
            
            return nil
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .Plain, target: nil, action: nil)
        searchBar.delegate = self
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(removePlayerNavButton), name: Constants.kPlayerHasNoItem, object: nil)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        navigationItem.rightBarButtonItem = self.playerNavButton()
    }
    
    func searchItunesFor(searchText: String) {
        iTunesSearchPodcastFeedURLArray.removeAll(keepCapacity: false)
        iTunesSearchPodcastArray.removeAll(keepCapacity: false)
        self.tableView.reloadData()
        
        let itunesSearchTerm = searchText.stringByReplacingOccurrencesOfString(" ", withString: "+", options: NSStringCompareOptions.CaseInsensitiveSearch, range: nil)
        
        if let escapedSearchTerm = itunesSearchTerm.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet()) {
            
            let urlPath = "https://itunes.apple.com/search?media=podcast&entity=podcast&term=\(escapedSearchTerm)"
            let url = NSURL(string: urlPath)
            let session = NSURLSession.sharedSession()
            let task = session.dataTaskWithURL(url!) {(data, response, error) in
                
                if (error != nil) {
                    print(error!.localizedDescription)
                }
                
                do {
                    if let d = data {
                        let jsonResult = try NSJSONSerialization.JSONObjectWithData(d, options: NSJSONReadingOptions.MutableContainers) as! NSDictionary
                        if let results: NSArray = jsonResult["results"] as? NSArray {
                            
                            // If no results, then show the "No results found" message. Else show the results.
                            if results.count < 1 {
                                let addByRSSAlert = UIAlertController(title: "No results found", message: "Please try a different search.", preferredStyle: UIAlertControllerStyle.Alert)
                                
                                addByRSSAlert.addAction(UIAlertAction(title: "Ok", style: .Default, handler: nil))
                                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                                	self.presentViewController(addByRSSAlert, animated: true, completion: nil)
                            	})
                            } else {
                                for podcastJSON in results {
                                    let searchResultPodcast = SearchResultPodcast()
                                    
                                    searchResultPodcast.feedURL = podcastJSON["feedUrl"] as? String
                                    
                                    searchResultPodcast.artistName = podcastJSON["artistName"] as? String
                                    
                                    searchResultPodcast.itunesImageURL = podcastJSON["artworkUrl100"] as? String
                                    
                                    searchResultPodcast.imageURL = podcastJSON["artworkUrl100"] as? String
                                    
                                    // Grab the releaseDate, then convert into NSDate
                                    if let lastPubDateString = podcastJSON["releaseDate"] as? String {
                                        var modifiedPubDateString = lastPubDateString.stringByReplacingOccurrencesOfString("T", withString: " ", options: NSStringCompareOptions.LiteralSearch, range: nil)
                                        modifiedPubDateString = modifiedPubDateString.stringByReplacingOccurrencesOfString("Z", withString: "", options: NSStringCompareOptions.LiteralSearch, range: nil)
                                        let dateFormatter = NSDateFormatter()
                                        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                                        searchResultPodcast.lastPubDate = dateFormatter.dateFromString(modifiedPubDateString)
                                    }
                                    
                                    searchResultPodcast.categories = podcastJSON["primaryGenreName"] as? String
                                    
                                    searchResultPodcast.title = podcastJSON["collectionName"] as? String
                                    
                                    self.iTunesSearchPodcastArray.append(searchResultPodcast)
                                    dispatch_async(dispatch_get_main_queue()) {
                                        self.tableView.reloadData()
                                    }
                                    
                                }
                            }
                        }
                    } else {
                        self.showInternetNeededAlert("Connect to WiFi or cellular data to search for podcasts.")
                    }
                } catch let error as NSError {
                    print(error)
                }
            }
            
            task.resume()
        }
    }
    
    func searchBarShouldBeginEditing(searchBar: UISearchBar) -> Bool {
        if PVReachability.manager.hasInternetConnection() == false {
            searchBar.resignFirstResponder()
            showInternetNeededAlert("Connect to WiFi or cellular data to search for podcasts.")
            return false
        }
        return true
    }
    
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        searchItunesFor(searchBar.text!)
        searchBar.resignFirstResponder()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return iTunesSearchPodcastArray.count
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("FindTableViewCell", forIndexPath: indexPath) as! FindSearchTableViewCell
        
        let podcast = iTunesSearchPodcastArray[indexPath.row]
        
        cell.title?.text = podcast.title
        cell.artist?.text = podcast.artistName
        cell.pvImage?.image = UIImage(named: "PodverseIcon")

        if let imageUrlString = podcast.imageURL, imageUrl = NSURL(string:imageUrlString) {
            UIImage.downloadImageWithURL(imageUrl, completion: { (completed, image) -> () in
                cell.pvImage?.image = image
            })
        }

        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let searchResultPodcastActions = UIAlertController(title: "Options", message: "", preferredStyle: UIAlertControllerStyle.ActionSheet)
        
        let iTunesSearchPodcast = iTunesSearchPodcastArray[indexPath.row]
        var isSubscribed = false
        
        
        if let savedPodcasts = CoreDataHelper.fetchEntities("Podcast", predicate: nil, moc:moc) as? [Podcast] {
            for savedPodcast in savedPodcasts {
                if iTunesSearchPodcast.feedURL == savedPodcast.feedURL {
                    if savedPodcast.isSubscribed == true {
                        isSubscribed = true
                    }
                }
            }
        }
        
        if isSubscribed == false {
            searchResultPodcastActions.addAction(UIAlertAction(title: "Subscribe", style: .Default, handler: { action in
                if let feedURL = iTunesSearchPodcast.feedURL {
                    PVSubscriber.subscribeToPodcast(feedURL, podcastTableDelegate: self.podcastVC)
                }
            }))
        }
        else {
            searchResultPodcastActions.addAction(UIAlertAction(title: "Unsubscribe", style: .Default, handler: { action in
                if let podcasts = CoreDataHelper.fetchEntities("Podcast", predicate: nil, moc:self.moc) as? [Podcast] {
                    if let index = podcasts.indexOf({ $0.feedURL == iTunesSearchPodcast.feedURL }) {
                        
                        let unsubscribedPodcastUserInfo:[NSObject:AnyObject] = ["feedURL":iTunesSearchPodcast.feedURL ?? ""]

                        PVSubscriber.unsubscribeFromPodcast(podcasts[index].objectID, completionBlock: {
                            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                                NSNotificationCenter.defaultCenter().postNotificationName(Constants.kUnsubscribeFromPodcast, object: self, userInfo: unsubscribedPodcastUserInfo)
                            })
                        })
                    }
                }
            }))
        }

        // TODO: add follow feature
        searchResultPodcastActions.addAction(UIAlertAction(title: "Follow", style: .Default, handler: { action in
            print("Follow")
        }))
        
        searchResultPodcastActions.addAction(UIAlertAction (title: "Show Profile", style: .Default, handler: { action in
            let feedParser = PVFeedParser(onlyGetMostRecentEpisode: false, shouldSubscribe:false, shouldParseChannelOnly: true)
            feedParser.delegate = self
            if let feedURLString = iTunesSearchPodcast.feedURL {
                feedParser.parsePodcastFeed(feedURLString)
            }
        }))
        
        searchResultPodcastActions.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
        
        dispatch_async(dispatch_get_main_queue(), {})
        
        self.presentViewController(searchResultPodcastActions, animated: false, completion: nil)
    }

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "Show Podcast Profile" {
            let podcastProfileViewController = segue.destinationViewController as! PodcastProfileViewController
            podcastProfileViewController.podcast = podcast
        }
        else if segue.identifier == Constants.TO_PLAYER_SEGUE_ID {
            let mediaPlayerViewController = segue.destinationViewController as! MediaPlayerViewController
            mediaPlayerViewController.hidesBottomBarWhenPushed = true
        }
    }
}

extension UIImage {
    static func downloadImageWithURL(url:NSURL, completion:(completed:Bool, image:UIImage?) -> ()) {
        let session = NSURLSession.sharedSession()
        
        let task = session.dataTaskWithURL(url) { (imageData, response, error) -> Void in
            if error == nil {
                if let data = imageData {
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        completion(completed: true, image: UIImage(data: data))
                    })
                }
                else {
                    completion(completed: false, image: nil)
                }
            }
        }
        
        task.resume()
    }
}

extension FindSearchTableViewController: PVFeedParserDelegate {
    func feedParsingComplete(feedURL:String?) {
        if let rssFeedURL = feedURL {
            podcast = CoreDataHelper.retrieveExistingOrCreateNewPodcast(rssFeedURL, moc: moc)
            self.performSegueWithIdentifier("Show Podcast Profile", sender: self)
        }
    }
}