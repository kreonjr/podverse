//
//  GetPlaylistByUserIdFromServer.swift
//  podverse
//
//  Created by Mitchell Downey on 6/5/16.
//  Copyright © 2016 Mitchell Downey. All rights reserved.
//

import Foundation

final class GetPlaylistsByUserIdFromServer:WebService {
    internal init(userId:String,completionBlock: (response: Dictionary<String, AnyObject>) -> Void, errorBlock: (error: NSError?) -> Void) {
        super.init(name:"pl/?"+userId,completionBlock: completionBlock, errorBlock: errorBlock)
        self.setHttpMethod(.METHOD_GET)
    }
}