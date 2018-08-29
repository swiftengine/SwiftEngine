//
//  SECompilerTests.swift
//  SEProcessorTests
//
//  Created by Brandon Holden on 8/29/18.
//

import Foundation
import XCTest
@testable import SEProcessorLib



class SECompilerTest: XCTestCase {
    
    override func setUp() {
        
    }
    
    override func tearDown() {
        
    }
    
    // Proper require syntax
    func testStandardRequire() {
        let line = "//se: require hello.swift"
        if let reqFile = SECompiler.getRequiredFile(line) {
            XCTAssertEqual("hello.swift", reqFile)
        }
        else {
            XCTFail()
        }
    }
    
    // Proper require syntax with full path specified
    func testStandardRequireFullPath() {
        let line = "//se: require /users/greetings/hello.swift"
        if let reqFile = SECompiler.getRequiredFile(line) {
            XCTAssertEqual("/users/greetings/hello.swift", reqFile)
        }
        else {
            XCTFail()
        }
    }
    
    // No space between 'se:' and 'require'
    func testRequireNoSpaceInRequire() {
        let line = "//se:require hello.swift"
        if let reqFile = SECompiler.getRequiredFile(line) {
            XCTAssertEqual("hello.swift", reqFile)
        }
        else {
            XCTFail()
        }
    }
    
    // Capitalized directive
    func testRequireCapitalized() {
        let line = "//SE: REQUIRE hello.swift"
        if let reqFile = SECompiler.getRequiredFile(line) {
            XCTAssertEqual("hello.swift", reqFile)
        }
        else {
            XCTFail()
        }
    }
    
    // Three forward slashes rather than two
    func testRequireInvalidCommentFormat() {
        let line = "///se: require hello.swift"
        XCTAssertNil(SECompiler.getRequiredFile(line))
    }
    
    // No spaces at all
    func testRequireNoSpaces() {
        let line = "//se:requirehello.swift"
        if let reqFile = SECompiler.getRequiredFile(line) {
            XCTAssertEqual("hello.swift", reqFile)
        }
        else {
            XCTFail()
        }
    }
    
    // If there is extra characters in the comment
    func testRequireExtraneousCharacters() {
        let line = "//se: require hello.swift how are you?"
        if let reqFile = SECompiler.getRequiredFile(line) {
            XCTAssertEqual("hello.swift", reqFile)
        }
        else {
            XCTFail()
        }
    }
    
    // Require syntax but no file specified
    func testRequireNoFile() {
        let line = "//se: require"
        XCTAssertNil(SECompiler.getRequiredFile(line))
    }
    
    
}
