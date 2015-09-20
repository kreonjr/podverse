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
    
    // TODO: why do I need to use two ! ! for durationStringArray.last!.toInt()!?
    static func convertStringToNSNumber (durationString : String) -> (NSNumber) {
        var durationStringArray = durationString.componentsSeparatedByString(":").reverse().map() { String($0) }
        var seconds = Int()
        var minutes = Int()
        var hours = Int()
        if durationStringArray.first != nil {
            seconds = Int(durationStringArray.first!)!
            durationStringArray.removeAtIndex(0)
        }
        if durationStringArray.first != nil {
            minutes = Int(durationStringArray.first!)!
            durationStringArray.removeAtIndex(0)
        }
        if durationStringArray.first != nil {
            hours = Int(durationStringArray.first!)!
            durationStringArray.removeAtIndex(0)
        }
        
        return NSNumber(integer: hoursMinutesSecondsToSeconds(hours, minutes: minutes, seconds: seconds))
    }
    
    static func convertNSNumberToHHMMSSString (durationNSNumber : NSNumber) -> (String) {
        let duration: Int = Int(durationNSNumber)
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
    
}
