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
    
    static func convertNSNumberToHHMMSSString (durationNSNumber : NSNumber?) -> String {
        guard let durationNumber = durationNSNumber else {
            return ""
        }
        
        let duration: Int = durationNumber.integerValue
        var hours = String(duration / 3600) + ":"
        if hours == "0:" {
            hours = ""
        }
        var minutes = String((duration / 60) % 60) + ":"
        if minutes.characters.count < 3 && hours != "" {
            minutes = "0" + minutes
        }
        var seconds = String(duration % 60)
        if seconds.characters.count < 2 && (hours != "" || minutes != "") {
            seconds = "0" + seconds
        }
        
        return "\(hours)\(minutes)\(seconds)"
    }
    
    static func removeHTMLFromString (string: String?) -> (String?) {
        if let str = string {
            let s = str.stringByReplacingOccurrencesOfString("<[^>]+>", withString: "", options: .RegularExpressionSearch, range: nil)
            return s
            
        } else {
            return nil
        }
    }
    
    static func encodePipeInString (string: String) -> (String) {
        let s = string.stringByReplacingOccurrencesOfString("|", withString: "%7C", options: .LiteralSearch, range: nil)
        return s
    }
    
    static func formatDateToString (date: NSDate) -> String {
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateStyle = NSDateFormatterStyle.ShortStyle
        let dateString = dateFormatter.stringFromDate(date)
        
        return dateString
    }
    
    static func formatStringToDate (string: String) -> NSDate? {
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd hh:mm:ss.SSSSxxx"
        let date = dateFormatter.dateFromString(string)
        return date
    }
    
    static func validateEmail(enteredEmail:String) -> Bool {
        let emailFormat = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailFormat)
        return emailPredicate.evaluateWithObject(enteredEmail)
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
    
    static func isAnonymousUser () -> Bool {
        if let userId = NSUserDefaults.standardUserDefaults().stringForKey("userId") where userId.rangeOfString("auth0|") == nil {
            return true
        } else {
            return false
        }
    }
}
