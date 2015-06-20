//
//  PVDownloader.swift
//  
//
//  Created by Mitchell Downey on 6/20/15.
//
//

import UIKit

class PVDownloader: NSObject {
   
    var moc: NSManagedObjectContext!
    
    func downloadEpisode(episode: Episode, completion: ((AnyObject) -> Void)!) {
        moc = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext
        
        let episodeMediaURLString = episode.mediaURL
        
        println(episodeMediaURLString)
        
        let session = NSURLSession.sharedSession()
        let episodeURL = NSURL(string: episodeMediaURLString)

        let task = session.dataTaskWithURL(episodeURL!, completionHandler: {(data, response, error) -> Void in
            if error != nil {
                println(error.localizedDescription)
            } else {
                if data != nil {
                    // Get the place to store the downloaded file in app's local memory
                    let dirPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as! String
                    
                    // Name the file with 
                    
                    
                    
//                    episode.downloadedMediaFileURL = data
                    self.moc.save(nil)
                }
                println("episode has been downloaded")
            }
        })
            
//        moc.save(nil)
        
        task.resume()
        
    }
    
}
