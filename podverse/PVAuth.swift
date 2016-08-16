//
//  PVAuth.swift
//  podverse
//

import Foundation

class PVAuth: NSObject {

    static func loginAsAnon () {
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
        }) { (error) -> Void in
            print(error)
        }.call()
    }

}
