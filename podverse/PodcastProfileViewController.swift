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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        println(searchResultPodcast)
        
        
        searchResultTitle.text = searchResultPodcast.title
        
        searchResultTotalClips.text = "123 clips"
        
        searchResultLastPublishedDate.text = "01/01/1999"
        
        var imageData = searchResultPodcast.image
        if imageData != nil {
            var image = UIImage(data: imageData!)
            // TODO: below is probably definitely not the proper way to check for a nil value for an image, but I was stuck on it for a long time and moved on
            if image!.size.height != 0.0 {
                searchResultImage?.image = image
            } else {
                var itunesImageData = searchResultPodcast.itunesImage
                var itunesImage = UIImage(data: itunesImageData!)
                
                if itunesImage!.size.height != 0.0 {
                    searchResultImage?.image = itunesImage
                }
            }
        }
        
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
