//
//  SELogger.swift
//  SEProcessorLib
//
//  Created by Brandon Holden on 8/10/18.
//

import Foundation

class SELogger {
    
    private static let cal = Calendar(identifier: .gregorian)
    
    
    public class func log(ip: String, requestStr: String, responseCode code: Int, bodyLength length: Int) {
        let str = "\(ip) - - [\(SELogger.getLogTime())] \"\(requestStr)\" \(code) \(length)"
    }
    
    public class func logError(ip: String, requestStr: String, errorMessage: String) {
        let str = "[\(SELogger.getErrorTime())] [error] [client \(ip)] \(errorMessage)"
    }
    
    
    // Construct string with time information for access.log entries
    private class func getLogTime() -> String {
        let now = Date()
        
        let day = SELogger.getDateComponentWithLengthTwo(.day, ofDate: now)
        let month = SELogger.getMonth(SELogger.cal.component(.month, from: now))
        let year = SELogger.cal.component(.year, from: now)
        
        let hour = SELogger.getDateComponentWithLengthTwo(.hour, ofDate: now)
        let minute = SELogger.getDateComponentWithLengthTwo(.minute, ofDate: now)
        let second = SELogger.getDateComponentWithLengthTwo(.second, ofDate: now)
        
        let timezone = TimeZone.current.secondsFromGMT() / 60 / 60
        let timezoneStr: String
        if timezone < 10 && timezone >= 0 {
            timezoneStr = "0\(timezone)00"
        }
        else if timezone >= 10 {
            timezoneStr = "\(timezone)00"
        }
        else if timezone < 0 && timezone > -10 {
            timezoneStr = "-0\(abs(timezone))00"
        }
        else {
            timezoneStr = "-\(abs(timezone))00"
        }
        
        let dateStr = "\(day)/\(month)/\(year):\(hour):\(minute):\(second) \(timezoneStr)"
        return dateStr
    }
    
    private static func getErrorTime() -> String {
        let now = Date()
        
        let dayOfWeek = SELogger.getDay(SELogger.cal.component(.weekday, from: now))
        let day = SELogger.getDateComponentWithLengthTwo(.day, ofDate: now)
        let month = SELogger.getMonth(SELogger.cal.component(.month, from: now))
        
        let hour = SELogger.getDateComponentWithLengthTwo(.hour, ofDate: now)
        let minute = SELogger.getDateComponentWithLengthTwo(.minute, ofDate: now)
        let second = SELogger.getDateComponentWithLengthTwo(.second, ofDate: now)
        
        let timezone = TimeZone.current.secondsFromGMT() / 60 / 60
        let timezoneStr: String
        if timezone < 10 && timezone >= 0 {
            timezoneStr = "0\(timezone)00"
        }
        else if timezone >= 10 {
            timezoneStr = "\(timezone)00"
        }
        else if timezone < 0 && timezone > -10 {
            timezoneStr = "-0\(abs(timezone))00"
        }
        else {
            timezoneStr = "-\(abs(timezone))00"
        }
        
        let dateStr = "\(dayOfWeek) \(month) \(day) \(hour):\(minute):\(second) \(timezoneStr)"
        return dateStr
    }
    
    
    // Helper functions for getting pieces of date strings
    private static func getDateComponentWithLengthTwo(_ dc: Calendar.Component, ofDate date: Date) -> String {
        let component = SELogger.cal.component(dc, from: date)
        if component < 10 {
            return "0\(component)"
        }
        return "\(component)"
    }
    
    private static func getDay(_ dayInt: Int) -> String {
        switch dayInt {
        case 1: return "Sun"
        case 2: return "Mon"
        case 3: return "Tues"
        case 4: return "Wed"
        case 5: return "Thur"
        case 6: return "Fri"
        case 7: return "Sat"
        default: return "Unknown"
        }
    }
    
    private static func getMonth(_ monthInt: Int) -> String {
        switch monthInt {
        case 1: return "Jan"
        case 2: return "Feb"
        case 3: return "Mar"
        case 4: return "Apr"
        case 5: return "May"
        case 6: return "Jun"
        case 7: return "Jul"
        case 8: return "Aug"
        case 9: return "Sep"
        case 10: return "Oct"
        case 11: return "Nov"
        case 12: return "Dec"
        default: return "Unknown"
        }
    }
    
}

