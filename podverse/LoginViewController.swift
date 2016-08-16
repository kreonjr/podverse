//
//  LoginViewController.swift
//  podverse
//
//  Created by Mitchell Downey on 5/22/16.
//  Copyright © 2016 Mitchell Downey. All rights reserved.
//

import UIKit
import Lock

protocol LoginModalDelegate {
    func loginTapped()
}

class LoginViewController: UIViewController {
    
    let reachability = PVReachability()
    let playlistManager = PlaylistManager.sharedInstance
    var delegate:LoginModalDelegate?
    
    @IBAction func login(sender: AnyObject) {
        self.dismissViewControllerAnimated(false, completion: {
            self.delegate?.loginTapped()
        })
    }
    
    @IBAction func dismissView(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
        
        // TODO: If connected to the internet, get anonymous access_token and userId from the web server, then create default playlists.
//        self.playlistManager.getMyPlaylistsFromServer({
//            self.playlistManager.createDefaultPlaylists()
//        })
        
    }

}
