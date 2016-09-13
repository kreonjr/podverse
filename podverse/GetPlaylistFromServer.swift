//
//  GetPlaylistFromServer.swift
//  podverse
//
//  Created by Kreon on 2/28/16.
//  Copyright © 2016 Mitchell Downey. All rights reserved.
//

import Foundation

final class GetPlaylistFromServer:WebService {
    internal init(playlistId:String,completionBlock: (response: AnyObject) -> Void, errorBlock: (error: NSError?) -> Void) {
        super.init(name:"playlists/"+playlistId, completionBlock: completionBlock, errorBlock: errorBlock)
    
        self.setHttpMethod(.METHOD_GET)
    }
}