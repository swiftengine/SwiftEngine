//
//  SEFileManager.swift
//  SwiftEngineServerLib
//
//  Created by Brandon Holden on 8/28/18.
//

import Foundation


public protocol SEFileManagerProtocol {
    func fileExists(atPath path: String) -> Bool
    func contentsOfDirectory(atPath path: String) throws -> [String]
    func moveItem(atPath: String, toPath: String) throws
}

class SEFileManager: SEFileManagerProtocol {
    public init() {}
    public func fileExists(atPath path: String) -> Bool {
        return FileManager.default.fileExists(atPath: path)
    }
    public func contentsOfDirectory(atPath path: String) throws -> [String] {
        return try FileManager.default.contentsOfDirectory(atPath: path)
    }
    public func moveItem(atPath: String, toPath: String) throws {
        try FileManager.default.moveItem(atPath: atPath, toPath: toPath)
    }
}
