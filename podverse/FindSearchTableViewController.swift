//
//  FindSearchTableViewController.swift
//  
//
//  Created by Mitchell Downey on 7/10/15.
//
//

import UIKit
import CoreData

class FindSearchTableViewController: UITableViewController, UISearchBarDelegate {
    
    @IBOutlet weak var searchBar: UISearchBar!
    
    var appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    
    var moc: NSManagedObjectContext! {
        get {
            return appDelegate.managedObjectContext
        }
    }
    
    var jsonTableData = []
    
    var iTunesSearchPodcastArray = [SearchResultPodcast]()
    var iTunesSearchPodcastFeedURLArray: [NSURL] = []
    
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
                    let jsonResult = try NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.MutableContainers) as! NSDictionary
                    if let results: NSArray = jsonResult["results"] as? NSArray {
                        
                        // If no results, then show the "No results found" message. Else show the results.
                        if results.count < 1 {
                            let addByRSSAlert = UIAlertController(title: "No results found", message: "Please try a different search.", preferredStyle: UIAlertControllerStyle.Alert)
                            
                            addByRSSAlert.addAction(UIAlertAction(title: "Ok", style: .Default, handler: nil))
                            dispatch_async(dispatch_get_main_queue()) {
                                self.presentViewController(addByRSSAlert, animated: true, completion: nil)
                            }
                        } else {
                            for (var i = 0; i < results.count; i++) {
                                
                                let podcastJSON: AnyObject = results[i]
                                
                                let searchResultPodcast = SearchResultPodcast()
                                
                                searchResultPodcast.artistName = podcastJSON["artistName"] as? String
                                
                                if let feedURLString = podcastJSON["feedUrl"] as? String {
                                    searchResultPodcast.feedURL = NSURL(string: feedURLString)
                                    
                                    let predicate = NSPredicate(format: "feedURL == %@", searchResultPodcast.feedURL!)
                                    let podcastAlreadySubscribedTo = CoreDataHelper.fetchEntities("Podcast", managedObjectContext:Constants.moc, predicate: predicate)
                                    
                                    if podcastAlreadySubscribedTo.count != 0 {
                                        searchResultPodcast.isSubscribed = true
                                    } else {
                                        searchResultPodcast.isSubscribed = false
                                    }
                                }
                                
                                if let imageURLString = podcastJSON["artworkUrl100"] as? String {
                                    let imgURL = NSURL(string: imageURLString)
                                    let request = NSURLRequest(URL: imgURL!)
                                    NSURLConnection.sendAsynchronousRequest(
                                        request, queue: NSOperationQueue.mainQueue(),
                                        completionHandler: { response, data, error in
                                            if error == nil {
                                                searchResultPodcast.image = data
                                                self.tableView.reloadData()
                                            } else {
                                                print(error)
                                            }
                                        }
                                    )
                                }
                                
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
    
    override func viewDidAppear(animated: Bool) {        
        // If there is a now playing episode, add Now Playing button to navigation bar
        if ((PVMediaPlayer.sharedInstance.nowPlayingEpisode) != nil) {
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Player", style: .Plain, target: self, action: "segueToNowPlaying:")
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .Plain, target: nil, action: nil)
    }
    
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        searchItunesFor(searchBar.text!)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return iTunesSearchPodcastArray.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) as! FindSearchTableViewCell
        
        let podcast = iTunesSearchPodcastArray[indexPath.row]
        
        cell.title?.text = podcast.title
        cell.summary?.text = podcast.artistName
        cell.pvImage?.image = UIImage(named: "Blank52")

        if let imageData = podcast.image {
            let image = UIImage(data: imageData)
            cell.pvImage?.image = image
        } else if let itunesImageData = podcast.itunesImage {
            let itunesImage = UIImage(data: itunesImageData)
            cell.pvImage?.image = itunesImage
        }

        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let searchResultPodcastActions = UIAlertController(title: "Options", message: "", preferredStyle: UIAlertControllerStyle.ActionSheet)
        
        let iTunesSearchPodcast = iTunesSearchPodcastArray[indexPath.row]
        
        if iTunesSearchPodcast.isSubscribed == false {
            searchResultPodcastActions.addAction(UIAlertAction(title: "Subscribe", style: .Default, handler: { action in
                if let feedURL = iTunesSearchPodcast.feedURL {
                    PVSubscriber.sharedInstance.subscribeToPodcast(feedURL.absoluteString)
                    iTunesSearchPodcast.isSubscribed = true
                }
            }))
        }
        else {
            searchResultPodcastActions.addAction(UIAlertAction(title: "Unsubscribe", style: .Default, handler: { action in
                print("unsubscribe to podcast")
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
        
        self.presentViewController(searchResultPodcastActions, animated: true, completion: nil)
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
            mediaPlayerViewController.returnToNowPlaying = true
            mediaPlayerViewController.hidesBottomBarWhenPushed = true
        }
    }
}