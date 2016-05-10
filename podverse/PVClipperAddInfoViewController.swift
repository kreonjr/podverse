//
//  PVClipperAddInfoViewController.swift
//  podverse
//
//  Created by Kreon on 10/31/15.
//  Copyright © 2015 Mitchell Downey. All rights reserved.
//

import UIKit
import CoreData

class PVClipperAddInfoViewController: UIViewController {

    var clipTime:Int = 0
    var startTime:Int?
    var endTime:Int?
    var clip:Clip?
    var episodeID:NSManagedObjectID!
    var isEditingClip:Bool = false
    var moc = CoreDataHelper.sharedInstance.managedObjectContext
    var episode:Episode!
    
    @IBOutlet weak var clipTitleTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        let saveButton = UIBarButtonItem(title: "Save", style: .Plain, target: self, action: #selector(PVClipperAddInfoViewController.saveAndGoToReview))
        self.navigationItem.rightBarButtonItem = saveButton
        
        let backButton = UIBarButtonItem(title: "Back", style: .Plain, target: self, action: #selector(PVClipperAddInfoViewController.popViewController))
        self.navigationItem.leftBarButtonItem = backButton
        
        clipTitleTextField.text = clip?.title
        episode = CoreDataHelper.fetchEntityWithID(episodeID, moc: moc) as! Episode
    }
    
    func popViewController() {
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    func saveAndGoToReview () {
        if let clipTitle = clipTitleTextField.text where clipTitle.characters.count > 0 {
            saveClipWithTitle(clipTitle)
        }
        else {
            // If no clip title provided, then create and save a default clip title
            var episodeTitle = episode.podcast.title
            var startTimeString = ""
            var endTimeString = ""
            let defaultTitle: String!
            
            if let episodeT = episode.title {
                episodeTitle = episodeT
            }
            
            if let startT = startTime {
                startTimeString = " - " + PVUtility.convertNSNumberToHHMMSSString(startT)
            }
            
            if endTime != 0 && endTime != nil {
                endTimeString = " to " + PVUtility.convertNSNumberToHHMMSSString(endTime!)
            }
            
            defaultTitle = episodeTitle + startTimeString + endTimeString
            saveClipWithTitle(defaultTitle)
        }
        self.performSegueWithIdentifier("show_confirm_clip", sender: self)
    }
    
    func saveClipWithTitle(clipTitle:String) {
        if clip == nil {
            clip = (CoreDataHelper.insertManagedObject("Clip", moc:moc) as! Clip)
            episode.addClipObject(clip!)
        }
        
        clip?.title = clipTitle
        
        if let clipStart = startTime {
            clip?.startTime = NSNumber(integer: clipStart)
        } else {
            clip?.startTime = NSNumber(integer: 0)
        }
        
        if let clipEnd = endTime {
            clip?.endTime = NSNumber(integer: clipEnd)
        } else {
            clip?.endTime = 0
        }
        
        if let clipEnd = clip?.endTime, clipStart = clip?.startTime, episodeDuration = episode.duration {
            if clipEnd != 0 {
                let clipDuration = NSNumber(integer: Int(clipEnd) - clipStart.integerValue)
                clip?.duration = clipDuration
            } else {
                let clipDuration = NSNumber(integer: Int(episodeDuration) - clipStart.integerValue)
                clip?.duration = clipDuration
            }
        }
        
        clip?.dateCreated = NSDate()
        
        if let unwrappedClip = clip {
            saveClip(unwrappedClip)
        }
        
        CoreDataHelper.saveCoreData(moc, completionBlock:nil)
    }
    
    final private func saveClip(clip:Clip) {
        let saveClipWS = SaveClipToServer(clip: clip, completionBlock: {[weak self] (response) -> Void in
            guard let strongSelf = self else {
                return
            }
            
            strongSelf.clip?.clipUrl = response["clipUri"] as? String
            
            CoreDataHelper.saveCoreData(strongSelf.moc, completionBlock:nil)
            
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                let alert = UIAlertController(title: "Clip saved with URL:", message: strongSelf.clip?.clipUrl, preferredStyle: .Alert)
                alert.addAction(UIAlertAction(title: "OK", style: .Cancel, handler: nil))
                alert.addAction(UIAlertAction(title: "Copy", style: .Default, handler: { (action) -> Void in
                    UIPasteboard.generalPasteboard().string = strongSelf.clip?.clipUrl ?? ""
                }))
                strongSelf.presentViewController(alert, animated: true, completion: nil)
                
                let playlists = CoreDataHelper.fetchEntities("Playlist", predicate: nil, moc: strongSelf.moc) as! [Playlist]
                for playlist in playlists {
                    if playlist.title == Constants.kMyClipsPlaylist {
                        PlaylistManager.sharedInstance.addItemToPlaylist(playlist, clip: strongSelf.clip, episode: nil, moc:strongSelf.moc)
                    }
                }
            })
        }) { (error) -> Void in
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                let alert = UIAlertController(title: "Error", message: error?.localizedDescription, preferredStyle: .Alert)
                alert.addAction(UIAlertAction(title: "OK", style: .Cancel, handler: nil))
                self.presentViewController(alert, animated: true, completion: nil)
            })
        }
        
        saveClipWS.call()
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "show_confirm_clip" {
            (segue.destinationViewController as! PVClipperConfirmationViewController).clip = clip
        }
    }
}
