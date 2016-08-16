//
//  GetPlaylistsByUserIdFromServer.swift
//  podverse
//
//  Created by Mitchell Downey on 6/5/16.
//  Copyright © 2016 Mitchell Downey. All rights reserved.
//

import Foundation

class GetPlaylistsByUserIdFromServer:WebService {
    internal init(userId:String,completionBlock: (response: AnyObject) -> Void, errorBlock: (error: NSError?) -> Void) {
        let uId = PVUtility.encodePipeInString(userId)
        
        super.init(name:"playlists?ownerId="+uId,completionBlock: completionBlock, errorBlock: errorBlock)
        self.setHttpMethod(.METHOD_GET)
    }
}