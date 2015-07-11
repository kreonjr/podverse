//
//  PVItunesAPI.swift
//  podverse
//
//  Created by Mitchell Downey on 7/11/15.
//  Copyright (c) 2015 Mitchell Downey. All rights reserved.
//

import UIKit

class PVItunesAPI: NSObject, NSURLSessionDelegate {

    var session: NSURLSession?
    var dataTask: NSURLSessionDataTask?
    
    func initializeItunesAPISession() {
        var sessionConfiguration = NSURLSessionConfiguration.defaultSessionConfiguration()
        self.session = NSURLSession(configuration: sessionConfiguration, delegate: self, delegateQueue: nil)
    }

}