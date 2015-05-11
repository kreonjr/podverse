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
    
    var episode: EpisodeModel = EpisodeModel()
    
    var playerPosition = CMTimeMake(5, 1)
    
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
        println(episode.title)
        
        let url = episode.mediaURL
        avPlayer = AVPlayer(URL: url)
        
//        let mediaURL = episode.mediaURL
//        avPlayer = AVPlayer(contentsOfURL: mediaURL, error: nil)

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
