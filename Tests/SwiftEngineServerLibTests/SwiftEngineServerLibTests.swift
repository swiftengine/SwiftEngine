
/*
 For testing SELogger, subclass FileManager, override the methods used in SELogger like write
 so it doesn't actually write out to a file
 */

//import Foundation
import XCTest
import NIO
//import NIOHTTP1
//import NIOFoundationCompat
import SwiftEngineServerLib

open class SEFileManagerTestHarness: SEFileManagerProtocol {
    public init() {}
    public func fileExists(atPath path: String) -> Bool {
        return true
    }
    public func contentsOfDirectory(atPath path: String) -> [String] {
        return [String]()
    }
    public func moveItem(atPath: String, toPath: String) {
        
    }
}

class SELoggerTest: XCTestCase {
    
    override func setUp() {
        SELogger.fileManager = SEFileManagerTestHarness()
    }
    
    override func tearDown() {
        
    }
    
    func test200Access() {
        
        //SELogger.log(request: <#T##HTTPRequestHead#>, ip: <#T##String#>, stdOut: <#T##String#>)
        XCTAssert(true)
    }
    
}
