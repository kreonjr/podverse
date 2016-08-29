//
//  PVAuth.swift
//  podverse
//

import Lock

protocol PVAuthDelegate {
    func authFinished()
}

class PVAuth: NSObject {
    
    var delegate:PVAuthDelegate?
    static let sharedInstance = PVAuth()
    let coreDataHelper = CoreDataHelper.sharedInstance

    func loginAsAnon () {
        
        // user must be signed out to login as anon
        if let _ = NSUserDefaults.standardUserDefaults().stringForKey("idToken"), let _ = NSUserDefaults.standardUserDefaults().stringForKey("userId") {
            return
        }
        
        GetAnonIdTokenAndUserIdFromServer(completionBlock: { (response) -> Void in
            if let idToken = response["idToken"] as? String {
                NSUserDefaults.standardUserDefaults().setObject(idToken, forKey: "idToken")
            }
            
            if let userId = response["userId"] as? String {
                NSUserDefaults.standardUserDefaults().setObject(userId, forKey: "userId")
            }
            
            PlaylistManager.sharedInstance.getMyPlaylistsFromServer({
                PlaylistManager.sharedInstance.createDefaultPlaylists()
            })
            
            self.delegate?.authFinished()
        }) { (error) -> Void in
            print(error)
        }.call()
    }
    
    func showAuth0LockLoginVC (vc: UIViewController) {
        let lock = A0Lock.sharedLock()
        let controller = lock.newLockViewController()
        controller.closable = true
        
        controller.onAuthenticationBlock = {(profile, token) in
            guard let idToken = token?.idToken else {
                return
            }
            
            guard let userId = profile?.userId else {
                return
            }
            
            self.updateOwnedItemsThenSwitchToNewUser(idToken, userId: userId, completionBlock: { () in
                    controller.dismissViewControllerAnimated(true, completion: nil)
                })
            
        }
        
        controller.onUserDismissBlock = {() in
            self.loginAsAnon()
            self.delegate?.authFinished()
        }
        
        lock.presentLockController(controller, fromController: vc, presentationStyle: .Custom)
    }
    
    func showAuth0LockSignUpVC (vc: UIViewController) {
        let lock = A0Lock.sharedLock()
        let controller = lock.newSignUpViewController()
        
        controller.onAuthenticationBlock = {(profile, token) in
            guard let idToken = token?.idToken else {
                return
            }
            
            guard let userId = profile?.userId else {
                return
            }
            
            self.updateOwnedItemsThenSwitchToNewUser(idToken, userId: userId, completionBlock: { () in
                vc.navigationController?.popToRootViewControllerAnimated(true)
            })
        }
        
        vc.navigationController?.pushViewController(controller, animated: true)
    }
    
    func updateOwnedItemsThenSwitchToNewUser (idToken: String, userId: String, completionBlock: (() -> ())?) {
        // If logging in on first app launch, then a prevUserId will not be defined. In that case there also shouldn't be any clips or playlists created locally yet.
        var ownedItemsPred = NSPredicate(format: "ownerId == %@", "")
        if let prevUserId = NSUserDefaults.standardUserDefaults().stringForKey("userId") {
            ownedItemsPred = NSPredicate(format: "ownerId == %@", prevUserId)
        }
        
        let moc = self.coreDataHelper.managedObjectContext
        
        let ownedPlaylistsArray = CoreDataHelper.fetchEntities("Playlist", predicate: ownedItemsPred, moc:moc) as! [Playlist]
        let ownedClipsArray = CoreDataHelper.fetchEntities("Clip", predicate: ownedItemsPred, moc:moc) as! [Clip]
        
        let dispatchGroup = dispatch_group_create()
        
        // TODO: We should create a batch update endpoint in the web app so we don't have to send a request for each individual playlist and clip
        for var playlist in ownedPlaylistsArray {
            dispatch_group_enter(dispatchGroup)
            
            playlist.ownerId = userId
            
            SavePlaylistToServer(playlist: playlist, newPlaylist:(playlist.id == nil), addMediaRefId: nil, completionBlock: { (response) -> Void in
                
                guard let dictResponse = response as? Dictionary<String,AnyObject> else {
                    return
                }
                
                playlist = PlaylistManager.sharedInstance.syncLocalPlaylistFieldsWithResponse(playlist, dictResponse: dictResponse)
                
                CoreDataHelper.saveCoreData(moc, completionBlock: { (saved) in
                    dispatch_group_leave(dispatchGroup)
                })
            }) { (error) -> Void in
                print("Not saved to server. Error: ", error?.localizedDescription)
                CoreDataHelper.saveCoreData(moc, completionBlock: nil)
            }.call()
        }
        
        for clip in ownedClipsArray {
            dispatch_group_enter(dispatchGroup)
            
            clip.ownerId = userId
            
            SaveClipToServer(clip: clip, completionBlock: { (response) -> Void in
                
                guard let dictResponse = response as? Dictionary<String,AnyObject> else {
                    return
                }
                
                // TODO: this has a lot repeated code shared in PVClipperAddInfoController.swift
                // Should be cleaned up!
                if let mediaRefId = dictResponse["id"] as? String {
                    clip.mediaRefId = mediaRefId
                }
                
                if let podverseURL = dictResponse["podverseURL"] as? String {
                    clip.podverseURL = podverseURL
                }
                
                if let ownerId = dictResponse["ownerId"] as? String {
                    clip.ownerId = ownerId
                }
                
                if let ownerName = dictResponse["ownerName"] as? String {
                    clip.ownerName = ownerName
                }
                
                if let title = dictResponse["title"] as? String {
                    clip.title = title
                }
                
                if let startTime = dictResponse["startTime"] as? NSNumber {
                    clip.startTime = startTime
                }
                
                if let endTime = dictResponse["endTime"] as? NSNumber {
                    clip.endTime = endTime
                }
                
                if let dateCreated = dictResponse["dateCreated"] as? String {
                    clip.dateCreated = PVUtility.formatStringToDate(dateCreated)
                }
                
                if let lastUpdated = dictResponse["lastUpdated"] as? String {
                    clip.lastUpdated = PVUtility.formatStringToDate(lastUpdated)
                }
                
                if let serverEpisodeId = dictResponse["episodeId"] as? NSNumber {
                    clip.serverEpisodeId = serverEpisodeId
                }
                
                CoreDataHelper.saveCoreData(moc, completionBlock: { (saved) in
                    dispatch_group_leave(dispatchGroup)
                })
            }) { (error) -> Void in
                print("Not saved to server. Error: ", error?.localizedDescription)
                CoreDataHelper.saveCoreData(moc, completionBlock: nil)
            }.call()
            
        }
        
        if ownedPlaylistsArray.count < 1 && ownedClipsArray.count < 1 {
            dispatch_group_enter(dispatchGroup)
            dispatch_group_leave(dispatchGroup)
        }
        
        dispatch_group_notify(dispatchGroup, dispatch_get_main_queue()) { () -> Void in
            NSUserDefaults.standardUserDefaults().setObject(idToken, forKey: "idToken")
            NSUserDefaults.standardUserDefaults().setObject(userId, forKey: "userId")
            
            PlaylistManager.sharedInstance.getMyPlaylistsFromServer({
                PlaylistManager.sharedInstance.createDefaultPlaylists()
            })
            
            self.delegate?.authFinished()
            if let cBlock = completionBlock {
                cBlock()
            }
        }
    }
    
    func setUserNameAndUpdateOwnedItems(userName: String?) {
        guard let idToken = NSUserDefaults.standardUserDefaults().stringForKey("idToken") else {
            return
        }
        
        guard let userId = NSUserDefaults.standardUserDefaults().stringForKey("userId") else {
            return
        }
        
        NSUserDefaults.standardUserDefaults().setObject(userName, forKey: "userName")
        
        self.updateOwnedItemsThenSwitchToNewUser(idToken, userId: userId, completionBlock: nil)
    }
    
}
