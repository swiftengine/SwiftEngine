//
//  SELogger.swift
//  SEProcessorLib
//
//  Created by Brandon Holden on 8/10/18.
//

import Foundation

class SELogger {
    
    private static let cal = Calendar(identifier: .gregorian)
    
    
    public class func log(ip: String, requestStr: String, responseCode: Int, bodyLength: Int) {
        
    }
    
    public class func logError(ip: String, requestStr: String, errorMessage: String) {
        
    }
    
    
    private class func getTime() -> String {
        let now = Date()
        let dayInt = SELogger.cal.component(.day, from: now)
        var day: String = "\(dayInt)"
        if dayInt < 10 {
            day = "0\(dayInt)"
        }
        let month = SELogger.cal.component(.month, from: now).getMonth()
        let year = SELogger.cal.component(.year, from: now)
        let hourInt = SELogger.cal.component(.hour, from: now)
        var hour: String = "\(hourInt)"
        if hourInt < 10 {
            hour = "0\(hourInt)"
        }
        let minuteInt = SELogger.cal.component(.minute, from: now)
        var minute: String = "\(minuteInt)"
        if minuteInt < 10 {
            minute = "0\(minuteInt)"
        }
        let secondInt = SELogger.cal.component(.second, from: now)
        var second: String = "\(secondInt)"
        if secondInt < 10 {
            second = "0\(secondInt)"
        }
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
        
        let dateStr = "[\(day)/\(month)/\(year):\(hour):\(minute):\(second) \(timezoneStr)]"
        return dateStr
    }

    
    
    
}


extension Int {
    
    func getMonth() -> String {
        switch self {
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
