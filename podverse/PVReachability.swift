//
//  PVReachability.swift
//  podverse
//
//  Created by Kreon on 6/4/16.
//  Copyright © 2016 Mitchell Downey. All rights reserved.
//

import Foundation
import Reachability

class PVReachability {
    static let manager = PVReachability()
    var reachability:Reachability!
    
    init (){
        do {
            reachability = try Reachability.reachabilityForInternetConnection()
        }
        catch {
            fatalError("Reachability was not initialized. \nError: \(error)")
        }
        
        reachability.whenReachable = { reachability in
            if NSUserDefaults.standardUserDefaults().boolForKey("DefaultPlaylistsCreated") == false {
                PlaylistManager.sharedInstance.createDefaultPlaylists()
                 NSUserDefaults.standardUserDefaults().setBool(true, forKey: "DefaultPlaylistsCreated")
            }
        }
        
        do {
            try reachability.startNotifier()
        } catch {
            print("Unable to start notifier")
        }
    }
    
    func hasInternetConnection() -> Bool {
        return reachability.isReachable() ?? false
    }
}