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
            
            self.handleOwnerIdSwitchThenSwitchToNewUser(idToken, userId: userId, vc: vc, completionBlock: { () in
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
            
            self.handleOwnerIdSwitchThenSwitchToNewUser(idToken, userId: userId, vc: vc, completionBlock: { () in
                vc.navigationController?.popToRootViewControllerAnimated(true)
            })
        }
        
        vc.navigationController?.pushViewController(controller, animated: true)
    }
    
    func handleOwnerIdSwitchThenSwitchToNewUser (idToken: String, userId: String, vc: UIViewController, completionBlock: () -> Void) {
        var ownedPlaylistsPred = NSPredicate()
        if let prevUserId = NSUserDefaults.standardUserDefaults().stringForKey("userId") {
            ownedPlaylistsPred = NSPredicate(format: "ownerId == %@", prevUserId)
        }
        
        let moc = self.coreDataHelper.managedObjectContext
        
        let ownedPlaylistsArray = CoreDataHelper.fetchEntities("Playlist", predicate: ownedPlaylistsPred, moc:moc) as! [Playlist]
        
        let dispatchGroup = dispatch_group_create()
        
        for playlist in ownedPlaylistsArray {
            dispatch_group_enter(dispatchGroup)
            
            playlist.ownerId = userId
            
            SavePlaylistToServer(playlist: playlist, newPlaylist:(playlist.id == nil), addMediaRefId: nil, completionBlock: { (response) -> Void in
                CoreDataHelper.saveCoreData(moc, completionBlock: { (finished) in
                    dispatch_group_leave(dispatchGroup)
                })
            }) { (error) -> Void in
                print("Not saved to server. Error: ", error?.localizedDescription)
                CoreDataHelper.saveCoreData(moc, completionBlock: nil)
                }.call()
        }
        
        dispatch_group_notify(dispatchGroup, dispatch_get_main_queue()) { () -> Void in
            NSUserDefaults.standardUserDefaults().setObject(idToken, forKey: "idToken")
            NSUserDefaults.standardUserDefaults().setObject(userId, forKey: "userId")
            
            PlaylistManager.sharedInstance.getMyPlaylistsFromServer({
                PlaylistManager.sharedInstance.createDefaultPlaylists()
            })
            
            self.delegate?.authFinished()
            completionBlock()
        }
    }
    
}
