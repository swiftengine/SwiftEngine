//
//  SEClass.swift
//  HTTPTest
//
//  Created by Brandon Holden on 7/20/18.
//  Copyright © 2018 Brandon Holden. All rights reserved.
//

import Foundation

class SEShell{
    @discardableResult
    public class func run(_ args: String...) -> (stdOut : String, stdErr : String, status : Int32) {
        return run(args)
    }
    @discardableResult
    public class func run(_ args: [String], envVars: [String : String]? = nil ) -> (stdOut : String, stdErr : String, status : Int32) {
        //let fm = FileManager.default
        //let pwd = fm.currentDirectoryPath
        #if swift(>=3.1)
        let task = Process()
        #else
        let task = Task()
        #endif
        let pipeStdOut = Pipe()
        let pipeStdErr = Pipe()
        task.standardOutput = pipeStdOut
        task.standardError = pipeStdErr
        //var envShell = ProcessInfo.processInfo.environment
        task.arguments = args
        task.environment = envVars
        if #available(OSX 10.13, *) {
            task.executableURL = URL(fileURLWithPath: "/usr/bin/env")
            try! task.run()
        }
        else {
            task.launchPath = "/usr/bin/env"
            task.launch()
        }
        task.waitUntilExit()
        let dataStdOut = pipeStdOut.fileHandleForReading.readDataToEndOfFile()
        let stdOut = String(data: dataStdOut, encoding: String.Encoding.utf8) ?? "<NO OUTPUT FROM BASH>"
        //let stdOut = output.replacingOccurrences(of: "\n", with: "", options: .literal, range: nil)
        let dataStdErr = pipeStdErr.fileHandleForReading.readDataToEndOfFile()
        let stdErr = String(data: dataStdErr, encoding: String.Encoding.utf8) ?? "<NO OUTPUT FROM BASH>"
        let status = task.terminationStatus        
        return (stdOut, stdErr, status)
    }
    
    @discardableResult
    public class func bash(_ cmd: String) ->
        (stdOut : String, stdErr : String, status : Int32) {
            //let fm = FileManager.default
            //let pwd = fm.currentDirectoryPath
            #if swift(>=3.1)
            let task = Process()
            #else
            let task = Task()
            #endif
            // uncomment lines below to pass through the env
            //var envShell = ProcessInfo.processInfo.environment
            //task.environment = envShell
            // create a pipe for capturing the output from shell
            let pipeStdOut = Pipe()
            let pipeStdErr = Pipe()
            task.standardOutput = pipeStdOut
            task.standardError = pipeStdErr
            task.arguments = ["/bin/bash","-c", cmd]//args
            if #available(OSX 10.13, *) {
                task.executableURL = URL(fileURLWithPath: "/usr/bin/env")
                try! task.run()
            }
            else {
                task.launchPath = "/usr/bin/env"
                task.launch()
            }
            task.waitUntilExit()
            let dataStdOut = pipeStdOut.fileHandleForReading.readDataToEndOfFile()
            let stdOut = String(data: dataStdOut, encoding: String.Encoding.utf8) ?? "<NO OUTPUT FROM BASH>"
            //let stdOut = output.replacingOccurrences(of: "\n", with: "", options: .literal, range: nil)
            let dataStdErr = pipeStdErr.fileHandleForReading.readDataToEndOfFile()
            let stdErr = String(data: dataStdErr, encoding: String.Encoding.utf8) ?? "<NO OUTPUT FROM BASH>"
            let status = task.terminationStatus
            return (stdOut, stdErr, status)
            //return task.terminationStatus
    }
    public class func runBinary(_ fileUri : String){
        // first close all the current piple
        //        let stdin    = FileHandle.standardInput
        //        let stdout   = FileHandle.standardOutput
        //        let stderror = FileHandle.standardError
        //int fds[2];
        //let fds = [UnsafeMutablePointer<Int32>!](repeating: nil, count: 64)
        //        var fds: [Int32] = [-1, -1]
        //
        //        var pipe_in: [Int32] = [-1, -1]
        //        var pipe_out: [Int32] = [-1, -1]
        //        var pipe_err: [Int32] = [-1, -1]
        //
        //        pipe(&pipe_in)
        //        pipe(&pipe_out)
        //        pipe(&pipe_err)
        //close(pipe_in[1]);
        //close(pipe_out[0]);
        //close(pipe_err[0]);
        //        dup2(pipe_in[0], 0);
        //        dup2(pipe_out[1], 1);
        //        dup2(pipe_err[1], 2);
        //        close(pipe_in[0]);
        //        close(pipe_out[1]);
        //        close(pipe_err[1]);
        //pipe(&fds)
        //close(STDIN_FILENO)
        //dup2(fds[0], STDIN_FILENO)
        //close(fds[1]);
        //dup2(fds[0], STDIN_FILENO);
        //stdin.closeFile()
        //close(STDIN_FILENO)
        //stdout.closeFile()
        //stderror.closeFile()
        let args = [fileUri]
        // Array of UnsafeMutablePointer<Int8>
        let cargs = args.map { strdup($0) } + [nil]
        //exec(fileUri)
        execv(fileUri, cargs)
        //execvp(fileUri, cargs)
        //execl(fileUri, "main")
    }
    public class func runBinary(){
        let args = ["ls", "-l", "/Library"]
        // Array of UnsafeMutablePointer<Int8>
        let cargs = args.map { strdup($0) } + [nil]
        execv("/bin/ls", cargs)
    }
}
