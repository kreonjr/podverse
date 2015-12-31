//
//  PVUtility.swift
//  podverse
//
//  Created by Mitchell Downey on 6/4/15.
//  Copyright (c) 2015 Mitchell Downey. All rights reserved.
//

import UIKit

class PVUtility: NSObject {
   
    static func secondsToHoursMinutesSeconds (seconds : Int) -> (Int, Int, Int) {
        return (seconds / 3600, (seconds % 3600) / 60, (seconds % 3600) % 60)
    }
    
    static func hoursMinutesSecondsToSeconds (hours : Int = 0, minutes : Int = 0, seconds : Int = 0) -> (Int) {
        let hoursInSeconds = hours * 3600
        let minutesInSeconds = minutes * 60
        let totalSeconds = hoursInSeconds + minutesInSeconds + seconds
        
        return totalSeconds
    }
    
    static func convertHHMMSSStringToNSNumber (durationString : String) -> (NSNumber) {
        var durationStringArray = durationString.componentsSeparatedByString(":").reverse().map() { String($0) }
        var seconds = 0
        var minutes = 0
        var hours = 0
        if durationStringArray.first != nil {
            if let s = Int(durationStringArray.first!) {
                seconds = s
            }
            durationStringArray.removeAtIndex(0)
        }
        if durationStringArray.first != nil {
            if let m = Int(durationStringArray.first!) {
                minutes = m
            }
            durationStringArray.removeAtIndex(0)
        }
        if durationStringArray.first != nil {
            if let h = Int(durationStringArray.first!) {
                hours = h
            }
            durationStringArray.removeAtIndex(0)
        }
        
        return NSNumber(integer: hoursMinutesSecondsToSeconds(hours, minutes: minutes, seconds: seconds))
    }
    
    static func convertNSNumberToHHMMSSString (durationNSNumber : NSNumber) -> (String) {
        let duration: Int = durationNSNumber.integerValue
        var hours = String(duration / 3600) + ":"
        if hours == "0:" {
            hours = ""
        }
        var minutes = String((duration / 60) % 60) + ":"
        if minutes.characters.count < 3 {
            minutes = "0" + minutes
        }
        var seconds = String(duration % 60)
        if seconds.characters.count < 2 {
            seconds = "0" + seconds
        }
        
        return "\(hours)\(minutes)\(seconds)"
    }
    
    static func removeHTMLFromString (string: String) -> (String) {
        let str = string.stringByReplacingOccurrencesOfString("<[^>]+>", withString: "", options: .RegularExpressionSearch, range: nil)
        return str
    }
    
    static func formatDateToString (date: NSDate) -> String {
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateStyle = NSDateFormatterStyle.ShortStyle
        let dateString = dateFormatter.stringFromDate(date)
        
        return dateString
    }
    
    static func deleteEpisodeFromDiskWithName(fileName:String) {
        let URLs = NSFileManager().URLsForDirectory(NSSearchPathDirectory.DocumentDirectory, inDomains: NSSearchPathDomainMask.UserDomainMask)
        let destinationURL = URLs.first?.URLByAppendingPathComponent(fileName)
        
        do {
            try NSFileManager().removeItemAtURL(destinationURL!)
        } catch {
            print("Item does not exist on disk")
        }
    }
    
}
