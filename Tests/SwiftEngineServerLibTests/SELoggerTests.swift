//
//  SEHTTPHandlerTests.swift
//  SwiftEngineServerLibTests
//
//  Created by Brandon Holden on 8/24/18.
//

import XCTest
import NIOHTTP1
@testable import SwiftEngineServerLib


private final class SEFileManagerTestUtil: SEFileManagerProtocol {
    public func fileExists(atPath path: String) -> Bool {
        return true
    }
    public func contentsOfDirectory(atPath path: String) -> [String] {
        return [String]()
    }
    public func moveItem(atPath: String, toPath: String) {
        
    }
}

private final class SEFileHandleTestUtil: SEFileHandleProtocol {

    var writeData: Data?
    var filePath: String?
    
    func open(atPath path: String) throws {
        // Ensure no other file is open
        guard self.filePath == nil else {
            throw SECommon.RuntimeError("This instance already has a file handle open. Can't open new file at path: \(path)")
        }
        
        // Set instance var
        self.filePath = path
        
        // Throw error if we could not open the file
        guard self.filePath != nil else {
            throw SECommon.RuntimeError("Could not open file at path: \(path)")
        }
    }

    func seekToEndOfFile() throws -> UInt64 {
        guard self.filePath != nil else {
            throw SECommon.RuntimeError("There is no file path set")
        }
        return 4221994
    }
    func write(_ data: Data) throws {
        guard self.filePath != nil else {
            throw SECommon.RuntimeError("There is no file path set")
        }
        self.writeData = data
    }
    func closeFile() throws {
        guard self.filePath != nil else {
            throw SECommon.RuntimeError("There is no file path set")
        }
        self.filePath = nil
    }
}

class SELoggerTest: XCTestCase {
    
    
    override func setUp() {
        SELogger.fileManager = SEFileManagerTestUtil()
    }
    
    override func tearDown() {
        
    }
    
    func testGoodAccess() {
        let fh = SEFileHandleTestUtil()
        SELogger.fileHandle = fh
        
        let ip = "127.0.0.1"
        let status = "200"
        let uri = "/hello"
        let body = "Body of message"
        let request = HTTPRequestHead(version: HTTPVersion(major: 1, minor: 1), method: .GET, uri: uri)
        let stdOut = "HTTP/\(request.version.major).\(request.version.minor) \(status) OK\n\n\(body)"
        
        SELogger.log(request: request, ip: ip, stdOut: stdOut)
        
        if let data = fh.writeData, let response = String(data: data, encoding: .utf8) {
            let str = "\(ip) - - [\(SELogger.getLogTime())] \"\(request.method) HTTP/\(request.version.major).\(request.version.minor) \(uri)\" \(status) \(body.count)\n"
            XCTAssertEqual(response, str)
        }
        else {
            XCTFail()
        }
    }
    
    
    func testBadAccess() {
        let fh = SEFileHandleTestUtil()
        SELogger.fileHandle = fh
        
        let ip = "127.0.0.1"
        let status = "404"
        let uri = "/badAccess"
        let body = "Could not find file"
        let request = HTTPRequestHead(version: HTTPVersion(major: 1, minor: 1), method: .GET, uri: uri)
        let stdOut = "HTTP/\(request.version.major).\(request.version.minor) \(status) FileNotFound\n\n\(body)"
        
        SELogger.log(request: request, ip: ip, stdOut: stdOut)

        if let data = fh.writeData, let response = String(data: data, encoding: .utf8) {
            let str = "[\(SELogger.getErrorTime())] [\(SELogger.defaultLogLevel)] [client \(ip)] HTTP/\(request.version.major).\(request.version.minor) \(status) FileNotFound  \(body)\n"
            XCTAssertEqual(response, str)
        }
        else {
            XCTFail()
        }
    }
    
    
    func testGoodAccessPost() {
        let fh = SEFileHandleTestUtil()
        SELogger.fileHandle = fh
        
        let ip = "127.0.0.1"
        let status = "200"
        let uri = "/hello"
        let body = "Body of message"
        let request = HTTPRequestHead(version: HTTPVersion(major: 1, minor: 1), method: .POST, uri: uri)
        let stdOut = "HTTP/\(request.version.major).\(request.version.minor) \(status) OK\n\n\(body)"
        
        SELogger.log(request: request, ip: ip, stdOut: stdOut)
        
        if let data = fh.writeData, let response = String(data: data, encoding: .utf8) {
            let str = "\(ip) - - [\(SELogger.getLogTime())] \"\(request.method) HTTP/\(request.version.major).\(request.version.minor) \(uri)\" \(status) \(body.count)\n"
            XCTAssertEqual(response, str)
        }
        else {
            XCTFail()
        }
    }
    
    
    func testImproperFormat() {
        let fh = SEFileHandleTestUtil()
        SELogger.fileHandle = fh
        
        let ip = "127.0.0.1"
        let status = "200"
        let uri = "/"
        let body = "Body of message"
        let request = HTTPRequestHead(version: HTTPVersion(major: 1, minor: 1), method: .GET, uri: uri)
        let stdOut = "HTTP/\(request.version.major).\(request.version.minor) \(status) OK\n\(body)"
        
        SELogger.log(request: request, ip: ip, stdOut: stdOut)
        
        if let data = fh.writeData, let response = String(data: data, encoding: .utf8) {
            let str = "Could not get body. StdOut: \(stdOut)\n"
            XCTAssertEqual(response, str)
        }
        else {
            XCTFail()
        }
    }
    
    
    func testGoodAccessLongQuery() {
        let fh = SEFileHandleTestUtil()
        SELogger.fileHandle = fh
        
        let ip = "127.0.0.1"
        let status = "200"
        let uri = "/people/users?fname=brandon&lname=holden"
        let body = "Body of message"
        let request = HTTPRequestHead(version: HTTPVersion(major: 1, minor: 1), method: .GET, uri: uri)
        let stdOut = "HTTP/\(request.version.major).\(request.version.minor) \(status) OK\n\n\(body)"
        
        SELogger.log(request: request, ip: ip, stdOut: stdOut)
        
        if let data = fh.writeData, let response = String(data: data, encoding: .utf8) {
            let str = "\(ip) - - [\(SELogger.getLogTime())] \"\(request.method) HTTP/\(request.version.major).\(request.version.minor) \(uri)\" \(status) \(body.count)\n"
            XCTAssertEqual(response, str)
        }
        else {
            XCTFail()
        }
    }
}
