//
//  PodcastsTableViewController.swift
//  Podverse
//
//  Created by Mitchell Downey on 4/27/15.
//  Copyright (c) 2015 Mitchell Downey. All rights reserved.
//

import UIKit

class PodcastsTableViewController: UITableViewController, NSXMLParserDelegate, MWFeedParserDelegate {
    
    var parser: NSXMLParser = NSXMLParser()
    
    var podcastUrls: NSArray = ["http://joeroganexp.joerogan.libsynpro.com/rss", "http://lavenderhour.libsyn.com/rss", "http://feeds.feedburner.com/dancarlin/history", "http://yourmomshousepodcast.libsyn.com/rss", "http://theartofcharmpodcast.theartofcharm.libsynpro.com/rss", "http://feeds.feedburner.com/PointlessWithKevenPereira", "http://feeds.feedburner.com/TheDrunkenTaoistPodcast"]
    
    var podcastUrl: String = String()
    var podcastTitle: String = String()
    var podcastSummary: String = String()
    
    var podcastImage: String = String()
    var parsingImage: Bool = false
    
    var episodeTitle: String = String()
    var episodeSummary: String = String()
    var episodePubDate: String = String()
    
    var parsingChannel: Bool = false
    var parsingImg: Bool = false
    var eName: String = String()
    
    var podcasts: [PodcastModel] = []
    var episodes: [EpisodeModel] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        var feedURL = NSURL(string: "http://joeroganexp.joerogan.libsynpro.com/rss")
        
        let feedParser: MWFeedParser = MWFeedParser(feedURL: feedURL)
        println(feedParser)
        feedParser.delegate = self
        
        feedParser.feedParseType = ParseTypeFull
        
        feedParser.connectionType = ConnectionTypeAsynchronously
        
        feedParser.parse()
        
        println(feedParser)
        
        for var i = 0; i < podcastUrls.count; i++ {
            podcastUrl = podcastUrls[i] as! String
            let url: NSURL = NSURL(string: podcastUrl)!
            
            parser = NSXMLParser(contentsOfURL: url)!
            println(parser)
            parser.delegate = self
            parser.parse()
        }
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func feedParserDidStart(parser: MWFeedParser!) {
        println("feedParserDidStart")
    }
    
    func feedParserDidFinish(parser: MWFeedParser!) {
        println("feedParserDidFinish")
    }
    
    func feedParser(parser: MWFeedParser!, didParseFeedInfo info: MWFeedInfo!) {
        println("didParseFeedInfo")
        println(info.image)
        
    }
    
    func feedParser(parser: MWFeedParser!, didParseFeedItem item: MWFeedItem!) {
        println("didParseFeedItem")
        println(item.title)
        // println(item.image)
    }
    
    func feedParser(parser: MWFeedParser!, didFailWithError error: NSError!) {
        println("didFailWithError")
        println(NSError)
        println(error)
    }
    
    func parser(parser: NSXMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [NSObject : AnyObject]) {
        
        eName = elementName
        if elementName == "channel" {
            podcastTitle = String()
            podcastSummary = String()
            parsingChannel = true
            parsingImage = false
            episodes = []
        } else if elementName == "item" {
            episodeTitle = String()
            episodeSummary = String()
            episodePubDate = String()
            parsingChannel = false
        }
        
    }
    
    func parser(parser: NSXMLParser, foundCharacters string: String?) {
        let data = string?.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
        if (!data!.isEmpty) {
            if parsingChannel {
                if eName == "title" && parsingImage == false {
                    podcastTitle += data!
                    parsingImage = true
                } else if eName == "description" {
                    podcastSummary += data!
                } else if eName == "image" {
                }
            } else {
                if eName == "title" {
                    episodeTitle += data!
                } else if eName == "description" {
                    episodeSummary += data!
                } else if eName == "pubDate" {
                    episodePubDate += data!
                }
            }
        }
    }
    
    func parser(parser: NSXMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == "channel" {
            let podcast: PodcastModel = PodcastModel()
            podcast.title = podcastTitle
            podcast.summary = podcastSummary
            podcast.episodes = episodes
            podcasts.append(podcast)
        } else if elementName == "item" {
            let episode: EpisodeModel = EpisodeModel()
            episode.title = episodeTitle
            episode.summary = episodeSummary
            episode.pubDate = episodePubDate
            episodes.append(episode)
        }
    }

    
    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Potentially incomplete method implementation.
        // Return the number of sections.
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete method implementation.
        // Return the number of rows in the section.
        return podcasts.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("podcastCell", forIndexPath: indexPath) as! UITableViewCell
        
        let podcast: PodcastModel = podcasts[indexPath.row]

        var currentPodcast = podcasts[indexPath.row]
        cell.textLabel!.text = currentPodcast.title

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
        if segue.identifier == "ShowEpisodes" {
            let viewController: EpisodesTableViewController = segue.destinationViewController as! EpisodesTableViewController
            let indexPath = self.tableView.indexPathForSelectedRow()!
            let podcast = podcasts[indexPath.row]
            
            viewController.episodes = podcast.episodes
        }
    }

}
