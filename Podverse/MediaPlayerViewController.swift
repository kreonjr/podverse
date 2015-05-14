//
//  MediaPlayer.swift
//  Podverse
//
//  Created by Mitchell Downey on 5/10/15.
//  Copyright (c) 2015 Mitchell Downey. All rights reserved.
//

import UIKit
import AVFoundation

class MediaPlayerViewController: UIViewController {
    
    var utility: PVUtility = PVUtility()
    
    var podcast: PodcastModel = PodcastModel()
    var episode: EpisodeModel = EpisodeModel()
    
    var playerPosition = CMTimeMake(5, 1)
    
    @IBOutlet weak var image: UIImageView!
    @IBOutlet weak var podcastTitle: UILabel!
    @IBOutlet weak var episodeTitle: UILabel!
    @IBOutlet weak var duration: UILabel!
    @IBOutlet weak var summary: UITextView!
    
    @IBOutlet weak var pausePlay: UIButton!
    
    var avPlayer = AVPlayer()
    
    @IBAction func stop(sender: AnyObject) {
        avPlayer.pause()
        avPlayer.seekToTime(CMTimeMake(0, 1))
        pausePlay.setTitle("Play", forState: UIControlState.Normal)
    }
    
    @IBAction func restart(sender: AnyObject) {
        avPlayer.seekToTime(CMTimeMake(0, 1))
        avPlayer.play()
        pausePlay.setTitle("Pause", forState: UIControlState.Normal)
    }
    
    @IBAction func pausePlay(sender: AnyObject) {
        if avPlayer.rate == 0 {
            avPlayer.play()
            pausePlay.setTitle("Pause", forState: UIControlState.Normal)
        } else {
            avPlayer.pause()
            pausePlay.setTitle("Play", forState: UIControlState.Normal)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let url = episode.mediaURL
        avPlayer = AVPlayer(URL: url)
        
        image?.image = podcast.image
        podcastTitle?.text = podcast.title
        episodeTitle?.text = episode.title
        duration?.text = utility.convertNSTimeIntervalToHHMMSSString(episode.duration!) as String
        summary?.text = utility.removeHTMLFromString(episode.summary!)
        
        
        //--- Add Custom Left Bar Button Item/s --//
        // thanks to Naveen Sharma
        // http://iostechsolutions.blogspot.com/2014/11/swift-add-custom-right-bar-button-item.html
        func addRightNavItemOnView() {
            let buttonMakeClip: UIButton = UIButton.buttonWithType(UIButtonType.Custom) as! UIButton
            buttonMakeClip.frame = CGRectMake(0, 0, 90, 90)
            buttonMakeClip.setTitle("Make Clip", forState: UIControlState.Normal)
            var rightBarButtonMakeClip: UIBarButtonItem = UIBarButtonItem(customView: buttonMakeClip)
            
            self.navigationItem.setRightBarButtonItems([rightBarButtonMakeClip], animated: true)
        }
        addRightNavItemOnView()
        
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
