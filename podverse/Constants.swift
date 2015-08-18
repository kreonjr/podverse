//
//  Constants.swift
//  podverse
//
//  Created by Mitchell Downey on 7/6/15.
//  Copyright (c) 2015 Mitchell Downey. All rights reserved.
//

import ReachabilitySwift

let kDownloadHasFinished  = "downloadHasFinished"

let kDownloadHasProgressed = "downloadHasProgressed"

let kReachableWithWIFI = "ReachableWithWIFI"
let kNotReachable = "NotReachable"
let kReachableWithWWAN = "ReachableWithWWAN"

// Reachability ensures that certain functions only happen when WiFi is connected, when WWAN is available, or when no internet access is connected
var reachability: Reachability?
var reachabilityStatus = kReachableWithWIFI