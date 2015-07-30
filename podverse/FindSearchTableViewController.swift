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
    
    var jsonTableData = []
    
    var subscriber = PVSubscriber()
    
    var downloader = PVDownloader()
    
    var timer: NSTimer? = nil
    
    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    
    var moc: NSManagedObjectContext!
    
    func searchItunesFor(searchText: String) {
        appDelegate.iTunesSearchPodcastFeedURLArray.removeAll(keepCapacity: false)
        appDelegate.iTunesSearchPodcastArray.removeAll(keepCapacity: false)
        self.tableView.reloadData()
        
        let itunesSearchTerm = searchText.stringByReplacingOccurrencesOfString(" ", withString: "+", options: NSStringCompareOptions.CaseInsensitiveSearch, range: nil)
        
        if let escapedSearchTerm = itunesSearchTerm.stringByAddingPercentEscapesUsingEncoding(NSUTF8StringEncoding) {
            
            let urlPath = "http://itunes.apple.com/search?media=podcast&entity=podcast&term=\(escapedSearchTerm)"
            let url = NSURL(string: urlPath)
            let session = NSURLSession.sharedSession()
            let task = session.dataTaskWithURL(url!, completionHandler: {data, response, error -> Void in
                
                if (error != nil) {
                    println(error.localizedDescription)
                }
                
                var err: NSError?
                
                if let jsonResult = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.MutableContainers, error: &err) as? NSDictionary {
                    
                    if (err != nil) {
                        println("JSON Error \(err!.localizedDescription)")
                    }
                    
                    if let results: NSArray = jsonResult["results"] as? NSArray {
                        for (var i = 0; i < results.count; i++) {
                            
                            let podcastJSON: AnyObject = results[i]
                            
                            let searchResultPodcast = SearchResultPodcast()

                            searchResultPodcast.artistName = podcastJSON["artistName"] as? String
                            
                            let feedURLString = podcastJSON["feedUrl"] as? String
                            searchResultPodcast.feedURL = NSURL(string: feedURLString!)
                            
                            if searchResultPodcast.feedURL != nil {
                                let predicate = NSPredicate(format: "feedURL == %@", searchResultPodcast.feedURL!)
                                let podcastAlreadySubscribedTo = CoreDataHelper.fetchEntities("Podcast", managedObjectContext: self.moc, predicate: predicate)
                                
                                if podcastAlreadySubscribedTo.count != 0 {
                                    searchResultPodcast.isSubscribed = true
                                } else {
                                    searchResultPodcast.isSubscribed = false
                                }
                            }
                            
                            let imageURLString = podcastJSON["artworkUrl100"] as? String
                            var imgURL: NSURL = NSURL(string: imageURLString!)!
                            let request: NSURLRequest = NSURLRequest(URL: imgURL)
                            NSURLConnection.sendAsynchronousRequest(
                                request, queue: NSOperationQueue.mainQueue(),
                                completionHandler: {(response: NSURLResponse!,data: NSData!,error: NSError!) -> Void in
                                    if error == nil {
                                        searchResultPodcast.image = data
                                        self.tableView.reloadData()
                                    } else {
                                        println(error)
                                    }
                            })

                            // Grab the releaseDate, then convert into NSDate
                            var lastPubDateString = podcastJSON["releaseDate"] as? String
                            lastPubDateString = lastPubDateString?.stringByReplacingOccurrencesOfString("T", withString: " ", options: NSStringCompareOptions.LiteralSearch, range: nil)
                            lastPubDateString = lastPubDateString?.stringByReplacingOccurrencesOfString("Z", withString: "", options: NSStringCompareOptions.LiteralSearch, range: nil)
                            let dateFormatter = NSDateFormatter()
                            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                            if lastPubDateString != nil {
                                searchResultPodcast.lastPubDate = dateFormatter.dateFromString(lastPubDateString!)
                            }

                            searchResultPodcast.primaryGenreName = podcastJSON["primaryGenreName"] as? String
                            
                            searchResultPodcast.title = podcastJSON["collectionName"] as? String
                            
                            self.appDelegate.iTunesSearchPodcastArray.append(searchResultPodcast)
                            self.tableView.reloadData()
                            
                        }
                    }
                    
                }
            })
            
            task.resume()
            
        }
    }
    
    func segueToNowPlaying(sender: UIBarButtonItem) {
        self.performSegueWithIdentifier("Find Search to Now Playing", sender: nil)
    }
    
    override func viewDidAppear(animated: Bool) {
        moc = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext
        
        self.navigationController?.navigationBar.barStyle = UIBarStyle.Black
        self.navigationController?.navigationBar.tintColor = UIColor.whiteColor()
        self.navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName: UIColor.whiteColor(), NSFontAttributeName: UIFont.boldSystemFontOfSize(16.0)]
        
        if ((appDelegate.nowPlayingEpisode) != nil) {
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Player", style: .Plain, target: self, action: "segueToNowPlaying:")
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        searchItunesFor(searchBar.text)
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
        return self.appDelegate.iTunesSearchPodcastArray.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) as! FindSearchTableViewCell
        
        let podcast = self.appDelegate.iTunesSearchPodcastArray[indexPath.row]
        
        cell.title?.text = podcast.title
        cell.summary?.text = podcast.artistName
        cell.pvImage?.image = UIImage(named: "Blank52")

        var imageData = podcast.image
        
        if imageData != nil {
            var image = UIImage(data: imageData!)
            // TODO: below is probably definitely not the proper way to check for a nil value for an image, but I was stuck on it for a long time and moved on
            if image!.size.height != 0.0 {
                cell.pvImage?.image = image
            } else {
                var itunesImageData = podcast.itunesImage
                var itunesImage = UIImage(data: itunesImageData!)
                
                if itunesImage!.size.height != 0.0 {
                    cell.pvImage?.image = itunesImage
                }
            }
        }

        return cell
        
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        var searchResultPodcastActions = UIAlertController(title: "Options", message: "", preferredStyle: UIAlertControllerStyle.ActionSheet)
        
        let iTunesSearchPodcast = self.appDelegate.iTunesSearchPodcastArray[indexPath.row]
        
        if iTunesSearchPodcast.isSubscribed == false {
            searchResultPodcastActions.addAction(UIAlertAction(title: "Subscribe", style: .Default, handler: { action in
                self.subscriber.subscribeToPodcast(iTunesSearchPodcast.feedURL!.absoluteString!)
                iTunesSearchPodcast.isSubscribed = true
            }))
        }
        else {
            searchResultPodcastActions.addAction(UIAlertAction(title: "Unsubscribe", style: .Default, handler: { action in
                println("unsubscribe to podcast")
            }))
        }
        
        searchResultPodcastActions.addAction(UIAlertAction(title: "Show Episodes", style: .Default, handler: { action in
            println("Show Episodes")
        }))
        
        searchResultPodcastActions.addAction(UIAlertAction (title: "Show Clips", style: .Default, handler: { action in
            println("Show Clips")
        }))
        
        searchResultPodcastActions.addAction(UIAlertAction (title: "Show Profile", style: .Default, handler: { action in
            self.performSegueWithIdentifier("Show Podcast Profile", sender: self)
        }))
        
        searchResultPodcastActions.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
        
        self.presentViewController(searchResultPodcastActions, animated: true, completion: nil)
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
        if segue.identifier == "Show Podcast Profile" {
            
            let podcastProfileViewController = segue.destinationViewController as! PodcastProfileViewController
            
            if let index = self.tableView.indexPathForSelectedRow() {
                podcastProfileViewController.searchResultPodcast = self.appDelegate.iTunesSearchPodcastArray[index.row]
            }
            
        }
    }


}
