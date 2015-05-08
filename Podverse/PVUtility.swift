//
//  PVUtility.swift
//  Podverse
//
//  Created by Mitchell Downey on 5/7/15.
//  Copyright (c) 2015 Mitchell Downey. All rights reserved.
//

import Foundation

class PVUtility : NSObject {

    func secondsToHoursMinutesSeconds (seconds : Int) -> (Int, Int, Int) {
        return (seconds / 3600, (seconds % 3600) / 60, (seconds % 3600) % 60)
    }
    
    func hoursMinutesSecondsToSeconds (hours : Int = 0, minutes : Int = 0, seconds : Int = 0) -> (Int) {
        let hoursInSeconds = hours * 3600
        let minutesInSeconds = minutes * 60
        let totalSeconds = hoursInSeconds + minutesInSeconds + seconds
        
        return totalSeconds
    }
    
    // TODO: why do I need to use two ! ! for durationStringArray.last!.toInt()!?
    func convertStringToNSTimeInterval (durationString : String) -> (NSTimeInterval) {
        var durationStringArray = reverse(durationString.componentsSeparatedByString(":"))
        var seconds: Int = Int()
        var minutes: Int = Int()
        var hours: Int = Int()
        if durationStringArray.first != nil {
            seconds = durationStringArray.first!.toInt()!
            durationStringArray.removeAtIndex(0)
        }
        if durationStringArray.first != nil {
            minutes = durationStringArray.first!.toInt()!
            durationStringArray.removeAtIndex(0)
        }
        if durationStringArray.first != nil {
            hours = durationStringArray.first!.toInt()!
            durationStringArray.removeAtIndex(0)
        }
        
        return NSTimeInterval(hoursMinutesSecondsToSeconds(hours: hours, minutes: minutes, seconds: seconds))
    }
    func convertNSTimeIntervalToHHMMSSString (durationNSTimeInterval : NSTimeInterval) -> (NSString) {
        var duration: Int = Int(durationNSTimeInterval)
        var hours = String(duration / 3600) + ":"
        if hours == "0:" {
            hours = ""
        }
        var minutes = String((duration / 60) % 60) + ":"
        if count(minutes) < 3 {
            minutes = "0" + minutes
        }
        var seconds = String(duration % 60)
        if count(seconds) < 2 {
            seconds = "0" + seconds
        }
        
        return "\(hours)\(minutes)\(seconds)"
    }
    
    func removeHTMLFromString (string: String) -> (String) {
        let str = string.stringByReplacingOccurrencesOfString("<[^>]+>", withString: "", options: .RegularExpressionSearch, range: nil)
        return str
    }
    
}