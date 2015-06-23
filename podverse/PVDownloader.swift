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
        
        let session = NSURLSession.sharedSession()
        let episodeURL = NSURL(string: episodeMediaURLString)
        
        

        let task = session.dataTaskWithURL(episodeURL!, completionHandler: {(data, response, error) -> Void in
            println("download began")
            if error != nil {
                println(error.localizedDescription)
            } else {
                if data != nil {
                    // Get the place to store the downloaded file in app's local memory
                    let dirPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as! String
                    
                    // Name the file with date/time to be unique
                    var currentDateTime = NSDate()
                    var formatter = NSDateFormatter()
                    formatter.dateFormat = "ddMMyyyy-HHmmss"
                    // TODO: hardcoding .mp3 here would cause a problem for .ogg or other file formats
                    var fileName = formatter.stringFromDate(currentDateTime) + ".mp3"
                    var filePath = dirPath.stringByAppendingPathComponent(fileName)
                    
                    // Save the file locally with the unique file name as the URL path
                    let fileManager = NSFileManager.defaultManager()
                    fileManager.createFileAtPath(filePath, contents: data, attributes: nil)
                    
                    episode.downloadedMediaFileURL = fileName
                    self.moc.save(nil)
                }
                println("episode has been downloaded")
            }
        })
        
        task.resume()
        
    }
    
}
