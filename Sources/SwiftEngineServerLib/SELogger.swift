//
//  SELogger.swift
//  SwiftEngineServer
//
//  Created by Brandon Holden on 8/10/18.
//

import Foundation
import NIOHTTP1


public class SELogger {
    
    public enum LogLevel: Int {
        case debug = 1,
        info,
        notice,
        warm,
        error,
        crit,
        alert,
        emerg
    }
    
    // FileHandle for dependency injection
    public static var fileHandle: SEFileHandleProtocol = SEFileHandle()
    
    // FileManager for dependency injection
    public static var fileManager: SEFileManagerProtocol = SEFileManager()
    
    public static let defaultLogLevel: LogLevel = LogLevel.error
    public static var maxLogSize = 10_000_000
    

    private static let cal = Calendar(identifier: .gregorian)
    
    // This shouldn't be a property of the class but doing it for now
    private static let basePath = "/var/log/swiftengine"
    
    
    private static let accessLogName = "access.log"
    private static let errorLogName = "error.log"
    
    
    // This is for our own debugging purposes
    private static let internalErrorLogName = "unexpected_error.log"
    
    
    public class func log() {
        
    }
    
    
    // Log internally
    internal class func log(request: HTTPRequestHead, ip: String, stdOut: String) {
        let components = stdOut.components(separatedBy: "\n\n")
        let headers = components[0]
        let responseLine = headers.components(separatedBy: .newlines)[0]
        
        guard responseLine.count > 1 else {
            SELogger.logUnexpectedCrash("Could not get response code. StdOut: \(stdOut)")
            return
        }
        let responseCode = responseLine.components(separatedBy: " ")[1]
        
        guard components.count > 1 else {
            SELogger.logUnexpectedCrash("Could not get body. StdOut: \(stdOut)")
            return
        }
        let body = components[1]

        // Log the request
        let requestStr = "\(request.method) \(request.version) \(request.uri)"
        SELogger.log(ip: ip, requestStr: requestStr, responseCode: responseCode, bodyLength: body.count)
        
        // If response code isn't 200, error
        if responseCode != "200" {
            let errorMsg = stdOut.replacingOccurrences(of: "\n", with: " ")
            SELogger.logError(ip: ip, errorMessage: errorMsg)
        }
    }
    
    // Logs an unexpected crash
    internal class func logUnexpectedCrash(_ str: String) {
        SELogger.writeOut("\(str)\n", toFile: SELogger.internalErrorLogName)
    }
    
    
    // Log a server request
    private class func log(ip: String, requestStr: String, responseCode code: String, bodyLength length: Int) {
        let str = "\(ip) - - [\(SELogger.getLogTime())] \"\(requestStr)\" \(code) \(length)\n"
        let file = SELogger.accessLogName
        SELogger.writeOut(str, toFile: file)
    }
    
    // Log a server error
    private class func logError(ip: String, errorMessage: String, logLevel: LogLevel = SELogger.defaultLogLevel) {
        let str = "[\(SELogger.getErrorTime())] [\(logLevel)] [client \(ip)] \(errorMessage)\n"
        let file = "\(logLevel).log"
        SELogger.writeOut(str, toFile: file)
    }
    
    
    // Generic writing to file
    private class func writeOut(_ str: String, toFile file: String) {
        let path = "\(SELogger.basePath)/\(file)"
        if let data = str.data(using: .utf8) {
            // File already exists
            if SELogger.fileManager.fileExists(atPath: path) {
                do {
                    try SELogger.fileHandle.open(atPath: path)
                    let size = try SELogger.fileHandle.seekToEndOfFile()
                    
                    // Rotate logs if larger than max alloted size
                    if size >= SELogger.maxLogSize {
                        // Close this file handle as it will change, rotate, then call this function again
                        try SELogger.fileHandle.closeFile()
                        SELogger.rotateLogs()
                        SELogger.writeOut(str, toFile: file)
                        return
                    }
                    try SELogger.fileHandle.write(data)
                    try SELogger.fileHandle.closeFile()
                }
                catch {
                    SELogger.logUnexpectedCrash("Error returned from SELogger: \(error.localizedDescription)")
                }
                
            }
            // File does not exist
            else {
                let fileUrl = URL(fileURLWithPath: "\(path)")
                do {
                    try str.write(to: fileUrl, atomically: false, encoding: .utf8)
                }
                catch {
                    print("Could not write out to \(path)")
                    exit(-1)
                }
            }
        }
    }
    
    // Rotates logs with the specified name
    private class func rotateLogs() {
        do {
            let allLogs = try SELogger.fileManager.contentsOfDirectory(atPath: SELogger.basePath)
            let logTypes = [SELogger.accessLogName, SELogger.errorLogName]
            for name in logTypes {
                // Have the relevant logs in reverse sorted order (i.e: ..., access.log.1, access.log.0, access.log) so increment number by 1
                let logs = allLogs.filter({$0.starts(with: name)}).sorted().reversed()
                for file in logs {
                    // Get log number of the file
                    if let fileNumStr = file.chopPrefix("\(name)."), let fileNum = Int(fileNumStr) {
                        try SELogger.fileManager.moveItem(atPath: "\(SELogger.basePath)/\(file)", toPath: "\(SELogger.basePath)/\(name).\(fileNum+1)")
                    }
                    // Means we hit the currently active log; append 0
                    else {
                        try SELogger.fileManager.moveItem(atPath: "\(SELogger.basePath)/\(file)", toPath: "\(SELogger.basePath)/\(name).0")
                    }
                }
            }
        }
        catch {
            print("Error rotating logs")
            exit(-1)
        }

    }
    
    // Construct string with time information for access.log entries
    public class func getLogTime() -> String {
        let now = Date()
        
        let day = SELogger.getDateComponentWithLengthTwo(.day, ofDate: now)
        let month = SELogger.getMonth(SELogger.cal.component(.month, from: now))
        let year = SELogger.cal.component(.year, from: now)
        
        let hour = SELogger.getDateComponentWithLengthTwo(.hour, ofDate: now)
        let minute = SELogger.getDateComponentWithLengthTwo(.minute, ofDate: now)
        let second = SELogger.getDateComponentWithLengthTwo(.second, ofDate: now)
        
        let timezone = SELogger.getTimezoneString()
        
        let dateStr = "\(day)/\(month)/\(year):\(hour):\(minute):\(second) \(timezone)"
        return dateStr
    }
    
    // Construct string with time information for error.log entries
    public static func getErrorTime() -> String {
        let now = Date()
        
        let dayOfWeek = SELogger.getDay(SELogger.cal.component(.weekday, from: now))
        let day = SELogger.getDateComponentWithLengthTwo(.day, ofDate: now)
        let month = SELogger.getMonth(SELogger.cal.component(.month, from: now))
        
        let hour = SELogger.getDateComponentWithLengthTwo(.hour, ofDate: now)
        let minute = SELogger.getDateComponentWithLengthTwo(.minute, ofDate: now)
        let second = SELogger.getDateComponentWithLengthTwo(.second, ofDate: now)
        
        let timezone = SELogger.getTimezoneString()
        
        let dateStr = "\(dayOfWeek) \(month) \(day) \(hour):\(minute):\(second) \(timezone)"
        return dateStr
    }
    
    // Get the timezone string
    private static func getTimezoneString() -> String {
        let timezone = TimeZone.current.secondsFromGMT() / 60 / 60
        if timezone < 10 && timezone >= 0 {
            return "0\(timezone)00"
        }
        else if timezone >= 10 {
            return "\(timezone)00"
        }
        else if timezone < 0 && timezone > -10 {
            return "-0\(abs(timezone))00"
        }
        else {
            return "-\(abs(timezone))00"
        }
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

