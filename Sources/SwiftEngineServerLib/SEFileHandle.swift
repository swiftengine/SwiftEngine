//
//  SEFileHandle.swift
//  SwiftEngineServerLib
//
//  Created by Brandon Holden on 8/28/18.
//

import Foundation


public protocol SEFileHandleProtocol  {
    func open(atPath path: String) throws
    func seekToEndOfFile() throws -> UInt64
    func write(_ data: Data) throws
    func closeFile() throws
}


class SEFileHandle: SEFileHandleProtocol {
    var fileHandle: FileHandle!
    
    func open(atPath path: String) throws {
        // Ensure no other file is open
        guard self.fileHandle == nil else {
            throw SECommon.RuntimeError("This instance already has a file handle open. Can't open new file at path: \(path)")
        }
        
        // Open the file and set instance var
        self.fileHandle = FileHandle(forUpdatingAtPath: path)
        
        // Throw error if we could not open the file
        guard self.fileHandle != nil else {
            throw SECommon.RuntimeError("Could not open file at path: \(path)")
        }
    }
    
    func write(_ data: Data) throws {
        // Ensure file is open
        guard self.fileHandle != nil else {
            throw SECommon.RuntimeError("Could not write. No file is open")
        }
        
        self.fileHandle.write(data)
    }
    
    func closeFile() throws {
        guard self.fileHandle != nil else {
            throw SECommon.RuntimeError("Could not close file. No file is open")
        }
        
        self.fileHandle.closeFile()
        self.fileHandle = nil
    }
    
    func seekToEndOfFile() throws -> UInt64 {
        // Ensure file is open
        guard self.fileHandle != nil else {
            throw SECommon.RuntimeError("Could not write. No file is open")
        }
        
        return self.fileHandle.seekToEndOfFile()
    }
    
}
