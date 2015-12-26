//
//  String+FeedElementIdentification.swift
//
//  Created by Nacho on 5/10/14.
//  Copyright (c) 2014 Ignacio Nieto Carvajal. All rights reserved.
//

import Foundation

enum DateFormat {
    case ISO8601, RFC822, IncompleteRFC822
    case Custom(String)
}

extension NSDate {
    // MARK: Date From String
    convenience init(fromString swiftString: String, format:DateFormat)
    {
        if swiftString.isEmpty {
            self.init()
            return
        }
        
        let string = swiftString as NSString
        
        switch format {
            case .ISO8601:
                
                var s = string
                if string.hasSuffix(" 00:00") {
                    s = s.substringToIndex(s.length-6) + "GMT"
                } else if string.hasSuffix("+00:00") {
                    s = s.substringToIndex(s.length-6) + "GMT"
                } else if string.hasSuffix("Z") {
                    s = s.substringToIndex(s.length-1) + "GMT"
                } else if string.hasSuffix("+0000") {
                    s = s.substringToIndex(s.length-5) + "GMT"
                }

                let formatter = NSDateFormatter()
                formatter.locale = NSLocale(localeIdentifier: "en_US_POSIX")
                formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZ"
                if let date = formatter.dateFromString(string as String) {
                    self.init(timeInterval:0, sinceDate:date)
                } else {
                    self.init()
                }
                
            case .RFC822:
                
// PODVERSE: the block of code was commented out below and replaced with the uncommented block below it.
//                var s  = string
//                if string.hasSuffix("Z") {
//                    s = s.substringToIndex(s.length-1) + "GMT"
//                } else if string.hasSuffix("+0000") {
//                    s = s.substringToIndex(s.length-5) + "GMT"
//                } else if string.hasSuffix("+00:00") {
//                    s = s.substringToIndex(s.length-6) + "GMT"
//                }
//                let formatter = NSDateFormatter()
//                formatter.locale = NSLocale(localeIdentifier: "en_US_POSIX")
//                formatter.dateFormat = "EEE, d MMM yyyy HH:mm:ss ZZZ"
//                if let date = formatter.dateFromString(string as String) {
//                    self.init(timeInterval:0, sinceDate:date)
//                } else {
//                    self.init()
//                }
                
                // PODVERSE: this block of code was implemented based on the Stack Overflow answer at http://stackoverflow.com/questions/1850824/parsing-a-rfc-822-date-with-nsdateformatter
                var date: NSDate!
                let RFC822String = string.uppercaseString
                let formatter = NSDateFormatter()
                formatter.locale = NSLocale(localeIdentifier: "en_US_POSIX")
                
                if string.rangeOfString(",").location != NSNotFound {
                    if (date == nil) { // Sun, 19 May 2002 15:21:36 GMT
                        formatter.dateFormat = "EEE, d MMM yyyy HH:mm:ss zzz"
                        date = formatter.dateFromString(RFC822String)
                    }
                    if (date == nil) { // Sun, 19 May 2002 15:21 GMT
                        formatter.dateFormat = "EEE, d MMM yyyy HH:mm zzz"
                        date = formatter.dateFromString(RFC822String)
                    }
                    if (date == nil) { // Sun, 19 May 2002 15:21:36
                        formatter.dateFormat = "EEE, d MMM yyyy HH:mm:ss"
                        date = formatter.dateFromString(RFC822String)
                    }
                    if (date == nil) { // Sun, 19 May 2002 15:21
                        formatter.dateFormat = "EEE, d MMM yyyy HH:mm"
                        date = formatter.dateFromString(RFC822String)
                    }
                } else {
                    if (date == nil) { // 19 May 2002 15:21:36 GMT
                        formatter.dateFormat = "d MMM yyyy HH:mm:ss zzz"
                        date = formatter.dateFromString(RFC822String)
                    }
                    if (date == nil) { // 19 May 2002 15:21 GMT
                        formatter.dateFormat = "d MMM yyyy HH:mm zzz"
                        date = formatter.dateFromString(RFC822String)
                    }
                    if (date == nil) { // 19 May 2002 15:21:36
                        formatter.dateFormat = "d MMM yyyy HH:mm:ss"
                        date = formatter.dateFromString(RFC822String)
                    }
                    if (date == nil) { // 19 May 2002 15:21
                        formatter.dateFormat = "d MMM yyyy HH:mm"
                        date = formatter.dateFromString(RFC822String)
                    }
                }

                if (date != nil) {
                    self.init(timeInterval:0, sinceDate:date)
                } else {
                    NSLog("Could not parse RFC822 date: \"%@\" Possibly invalid format.", string);
                    self.init()
                }

            case .IncompleteRFC822:
                
                var s  = string
                if string.hasSuffix("Z") {
                    s = s.substringToIndex(s.length-1) + "GMT"
                } else if string.hasSuffix("+0000") {
                    s = s.substringToIndex(s.length-5) + "GMT"
                } else if string.hasSuffix("+00:00") {
                    s = s.substringToIndex(s.length-6) + "GMT"
                }
                let formatter = NSDateFormatter()
                formatter.locale = NSLocale(localeIdentifier: "en_US_POSIX")
                formatter.dateFormat = "d MMM yyyy HH:mm:ss ZZZ"
                if let date = formatter.dateFromString(string as String) {
                    self.init(timeInterval:0, sinceDate:date)
                } else {
                    self.init()
                }
            
            case .Custom(let dateFormat):
                
                let formatter = NSDateFormatter()
                formatter.locale = NSLocale(localeIdentifier: "en_US_POSIX")
                formatter.dateFormat = dateFormat
                if let date = formatter.dateFromString(string as String) {
                    self.init(timeInterval:0, sinceDate:date)
                } else {
                    self.init()
                }
        }
    }
     

    

    // MARK: To String
    
    func toString() -> String {
        return self.toString(dateStyle: .ShortStyle, timeStyle: .ShortStyle, doesRelativeDateFormatting: false)
    }
    
    func toString(format format: DateFormat) -> String
    {
        var dateFormat: String
        switch format {
            case .ISO8601:
                dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
            case .RFC822:
                dateFormat = "EEE, d MMM yyyy HH:mm:ss ZZZ"
            case .IncompleteRFC822:
                dateFormat = "d MMM yyyy HH:mm:ss ZZZ"
            case .Custom(let string):
                dateFormat = string
        }
        let formatter = NSDateFormatter()
        formatter.dateFormat = dateFormat
        return formatter.stringFromDate(self)
    }

    func toString(dateStyle dateStyle: NSDateFormatterStyle, timeStyle: NSDateFormatterStyle, doesRelativeDateFormatting: Bool = false) -> String
    {
        let formatter = NSDateFormatter()
        formatter.dateStyle = dateStyle
        formatter.timeStyle = timeStyle
        formatter.doesRelativeDateFormatting = doesRelativeDateFormatting
        return formatter.stringFromDate(self)
    }
   
}