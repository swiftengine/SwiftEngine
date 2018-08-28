// File.swift
import Foundation


public class UploadedFile{
    public var name : String?
    public var tmpPath  : String?
    public var type : String?
    public var error : Int = 0
    public var size : Int = -1
    public var isPublic : Bool = false {
        willSet {
            if(newValue){
                shell("chmod","a+r", self.tmpPath!)
            }else{
                shell("chmod","a-r", self.tmpPath!)
            }
            
        }
    }


    public func moveTo(path: String) throws {

        let fileManager = FileManager.default

        if let tmpPath = self.tmpPath{

            if (fileManager.fileExists(atPath:path)){
                try fileManager.removeItem(atPath:path)
            }

            try fileManager.moveItem(atPath: tmpPath, toPath: path)
            
            self.tmpPath = path // set the new temp path so future refrence is from here

        }
    }

    

}


@discardableResult
public func shell(_ args: String...) -> Int32 {

    //let fm = FileManager.default
    //let pwd = fm.currentDirectoryPath

    #if swift(>=3.1)
    let task = Process()
    #else
    let task = Task()
    #endif
    task.launchPath = "/usr/bin/env"
    task.arguments = args
    task.launch()
    task.waitUntilExit()
    return task.terminationStatus
}
