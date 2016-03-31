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
    
    var appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    
    var jsonTableData = []
    
    var iTunesSearchPodcastArray = [SearchResultPodcast]()
    var iTunesSearchPodcastFeedURLArray: [NSURL] = []
    
    func removePlayerNavButton(notification: NSNotification) {
        dispatch_async(dispatch_get_main_queue()) {
            PVMediaPlayer.sharedInstance.removePlayerNavButton(self)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .Plain, target: nil, action: nil)
        searchBar.delegate = self
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        PVMediaPlayer.sharedInstance.addPlayerNavButton(self)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "removePlayerNavButton:", name: Constants.kPlayerHasNoItem, object: nil)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: Constants.kPlayerHasNoItem, object: nil)
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
                                // Get all podcasts in Core Data to use to determine if you're already subscribed to a search result podcast
                                let allSubscribedPodcasts = CoreDataHelper.sharedInstance.fetchEntities("Podcast", predicate: nil) as! [Podcast]
                                
                                for (var i = 0; i < results.count; i++) {
                                    
                                    let podcastJSON: AnyObject = results[i]
                                    
                                    let searchResultPodcast = SearchResultPodcast()
                                    
                                    searchResultPodcast.artistName = podcastJSON["artistName"] as? String
                                    
                                    if let feedURLString = podcastJSON["feedUrl"] as? String {
                                        searchResultPodcast.feedURL = NSURL(string: feedURLString)
                                        
                                        let podcastAlreadySubscribedTo = allSubscribedPodcasts.filter{ $0.feedURL == feedURLString }
                                        
                                        if podcastAlreadySubscribedTo.count != 0 {
                                            searchResultPodcast.isSubscribed = true
                                        } else {
                                            searchResultPodcast.isSubscribed = false
                                        }
                                    }
                                    
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
                                    
                                    searchResultPodcast.primaryGenreName = podcastJSON["primaryGenreName"] as? String
                                    
                                    searchResultPodcast.title = podcastJSON["collectionName"] as? String
                                    
                                    self.iTunesSearchPodcastArray.append(searchResultPodcast)
                                    dispatch_async(dispatch_get_main_queue()) {
                                        self.tableView.reloadData()
                                    }
                                    
                                }
                            }
                        }
                    } else {
                        dispatch_async(dispatch_get_main_queue()) {
                            let addByRSSAlert = UIAlertController(title: "No internet connection", message: "Please connect to the internet to search.", preferredStyle: UIAlertControllerStyle.Alert)
                            
                            addByRSSAlert.addAction(UIAlertAction(title: "Ok", style: .Default, handler: nil))
                            self.presentViewController(addByRSSAlert, animated: true, completion: nil)
                        }
                    }
                } catch let error as NSError {
                    print(error)
                }
            }
            
            task.resume()
        }
    }
    
    func segueToNowPlaying(sender: UIBarButtonItem) {
        self.performSegueWithIdentifier("Find Search to Now Playing", sender: nil)
    }
    
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        searchItunesFor(searchBar.text!)
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
        
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) as! FindSearchTableViewCell
        
        let podcast = iTunesSearchPodcastArray[indexPath.row]
        
        cell.title?.text = podcast.title
        cell.artist?.text = podcast.artistName
        cell.pvImage?.image = UIImage(named: "Blank52")

        if let imageUrl = NSURL(string:podcast.imageURL!) {
            UIImage.downloadImageWithURL(imageUrl, completion: { (completed, image) -> () in
                cell.pvImage?.image = image
            })
        }

        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let searchResultPodcastActions = UIAlertController(title: "Options", message: "", preferredStyle: UIAlertControllerStyle.ActionSheet)
        
        let iTunesSearchPodcast = iTunesSearchPodcastArray[indexPath.row]
        
        if iTunesSearchPodcast.isSubscribed == false {
            searchResultPodcastActions.addAction(UIAlertAction(title: "Subscribe", style: .Default, handler: { action in
                if let feedURL = iTunesSearchPodcast.feedURL {
                    PVSubscriber.subscribeToPodcast(feedURL.absoluteString)
                    iTunesSearchPodcast.isSubscribed = true
                }
            }))
        }
        else {
            searchResultPodcastActions.addAction(UIAlertAction(title: "Unsubscribe", style: .Default, handler: { action in
                if let podcasts = CoreDataHelper.sharedInstance.fetchEntities("Podcast", predicate: nil) as? [Podcast] {
                    if let index = podcasts.indexOf({ $0.feedURL == iTunesSearchPodcast.feedURL?.absoluteString }) {
                        PVSubscriber.unsubscribeFromPodcast(podcasts[index])
                    }
                }
            }))
        }
        
        searchResultPodcastActions.addAction(UIAlertAction(title: "Show Episodes", style: .Default, handler: { action in
            print("Show Episodes")
        }))
        
        searchResultPodcastActions.addAction(UIAlertAction (title: "Show Clips", style: .Default, handler: { action in
            print("Show Clips")
        }))
        
        searchResultPodcastActions.addAction(UIAlertAction (title: "Show Profile", style: .Default, handler: { action in
            self.performSegueWithIdentifier("Show Podcast Profile", sender: self)
        }))
        
        searchResultPodcastActions.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
        
        self.presentViewController(searchResultPodcastActions, animated: false, completion: nil)
    }

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "Show Podcast Profile" {
            let podcastProfileViewController = segue.destinationViewController as! PodcastProfileViewController
            if let index = self.tableView.indexPathForSelectedRow {
                podcastProfileViewController.searchResultPodcast = iTunesSearchPodcastArray[index.row]
            }
        }
        else if segue.identifier == "Find Search to Now Playing" {
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