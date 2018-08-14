import Foundation

public class SECompiler {
    
    static let swiftc = "/opt/apple/swift-latest/usr/bin/swiftc"
	static let swift = "/opt/apple/swift-latest/usr/bin/swift"
    
    // Location of the main.swift file
    static let seMain = "/etc/swiftengine/magic/main.swift"
    
    // Path to the SECore library
    static var pathToSECoreObjectsList: String {
        return "\(SEGlobals.SECORE_LOCATION)/SEObjects.list"
    }
    
    /*
     Ex. DOCUMENT_ROOT: /usr/me/
        Request comes in for /usr/me/dir1/dir2/test.swift
     
        relativePath: dir1/dir2/
        executable: test
    */
    static var relativePath: String!
    static var executableName: String!
    static let binaryCompilationLocation = "/var/swiftengine/.cache"
    
    static var fullExecutablePath: String {
        return "\(SECompiler.binaryCompilationLocation)\(SECompiler.relativePath!)/\(SECompiler.executableName!)"
    }
    
    static var requireList: Set<String> = []
    
    // This method is the *only* way to access SECompiler
    public class func excuteRequest(path: String) {
        // Set executable name
        SECompiler.setPathComponents(forPath: path)
        // Execute request
        SECompiler._excuteRequest(path: path)
    }

    class func dump(_ str: String, _ doExit: Bool = false){
        print(str)
        if(doExit){
            exit(0)
        }
    }
    
    // Solely for test purposes; remove before deployment
    private class func printEnvVars(_ envVars: [String:String]) {
        let keys = envVars.keys.sorted()
        var startedHttp = false
        var finishedHttp = false
        var startedServer = false
        dump("\nEnv Vars:")
        for key in keys {
            if !startedHttp && key.starts(with: "HTTP") {
                startedHttp = true
                dump("")
            }
            if startedHttp && !finishedHttp && !key.starts(with: "HTTP") {
                finishedHttp = true
                dump("")
            }
            else if finishedHttp && !startedServer && key.starts(with: "SERVER") {
                startedServer = true
                dump("")
            }
            dump("\(key)=\(envVars[key]!)")
        }
        dump("", true)
    }
    
	
    private class func compileFile(fileUri : String) {
        
        //dump("Binary Location: \(binaryCompilationLocation)\nRelative Path: \(relativePath!)\nExecutable: \(executableName!)\nFull exe path: \(fullExecutablePath)", true)
        
        //SECompiler.printEnvVars(ProcessInfo.processInfo.environment)
        
        var args = [
			SECompiler.swiftc, 
                "-v", 
                "-g",
            //"-Xcc", "-num-threads", "-Xcc", "25",
			"-o", SECompiler.fullExecutablePath, // Compile binary to this location
            "-I", "\(SEGlobals.SECORE_LOCATION)", // Add path to SECore for search path
			//"-Xcc", "-v",
            SECompiler.seMain, // This should always be the first source file so it is treated as the primary file
        ]


        #if os(OSX)
            args.append("-sdk")
            args.append("/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX10.13.sdk")
        #endif

        do {
            let contents = try SECompiler.getFileContents(path: fileUri)
            SECompiler.requireList.insert(fileUri)
            SECompiler.generateRequireList(path: fileUri, content: contents)
            args.append(contentsOf: SECompiler.requireList)
            
            // Write out .sources file
            SECompiler.createSourcesFile(requiresList: SECompiler.requireList)
        }
        catch {
            let errorStr = "<h3>error: invalid file path \(fileUri)</h3>"
            SEResponse.outputHTML(status: 500, title: "File Not Found", style: nil, body: errorStr, compilationError: true)
        }
        
        // Add SECore objects
        // var seCoreObjects = SECompiler.getSECoreObjectsList()
        // seCoreObjects = seCoreObjects.map{"\(SEGlobals.SECORE_LOCATION)/\($0)"}
        // args.append(contentsOf: seCoreObjects)

        // add the libFile
        //args.append("\(SEGlobals.SECORE_LOCATION)/libSwiftEngine.a")
        args.append("\(SEGlobals.SECORE_LOCATION)/libSwiftEngine.dylib")
        // let cmd = args.joined(separator: " ")
        // print("cmd: \(cmd)")

		// Run the executable
        let newArgs = args //["/usr/bin/env"]
        let (_, stdErr, status) = SEShell.run(newArgs)
        if (status != 0) {
            let output = SECompiler.getErrors(stdErr)
            SEResponse.outputHTML(status: 500, title: nil, style: SECompiler.lineNumberStyle, body: output, compilationError: true)
        }

	}
    
    
    
    // Get's the necessary SECore objects from the specified path
    private class func getSECoreObjectsList() -> [String] {
        if let contents = try? SECompiler.getFileContents(path: SECompiler.pathToSECoreObjectsList) {
            var ret = [String]()
            var files = contents.components(separatedBy: .newlines)
            files = files.filter(){ $0 != ""}
            ret.append(contentsOf: files)
            return ret
        }
        return [String]()
    }
    
    

    // DFS-search starting with the entry point file to generate the list of required files
    private class func generateRequireList(path: String, content: String) {
        // Get lines of the file
        let lines = content.components(separatedBy: .newlines)
        for (lineNum, line) in lines.enumerated() {
            // Starts with the require key
            if line.starts(with: SEGlobals.REQUIRE_KEY) {
                
                // Split components to get the require file name
                let lineComponents = line.components(separatedBy: SEGlobals.REQUIRE_KEY)
                for file in lineComponents {
                    // File isn't empty and it's not in the require list
                    if (!file.isEmpty) && (!SECompiler.requireList.contains(file)) {
                        
                        // If the require starts with '/' then path is DOCUMENT_ROOT; else, it's down the full path
                        var requirePath = "\(SEGlobals.DOCUMENT_ROOT)"
                        if !file.starts(with: "/") {
                            requirePath += "\(SECompiler.relativePath!)"
                        }
                        requirePath += "\(file)"
                        
                        // Add require to the list
                        SECompiler.requireList.insert(requirePath)
                        
                        do {
                            // Recurse
                            let fileContents = try SECompiler.getFileContents(path: requirePath)
                            SECompiler.generateRequireList(path: path, content: fileContents)
                        }
                        catch {
                            let errorStr = "\n\(path):\(lineNum+1):\(1): error: could not find file \(file)\n\(line)\n^\n"
                            let output = SECompiler.getErrors(errorStr)
                            SEResponse.outputHTML(status: 404, title: "File Not Found", style: SECompiler.lineNumberStyle, body: output, compilationError: true)
                        }
                    }
                }
            }
        }
    }
    
    
    
    // Write out the .sources file to the compileBinaryLocation
    private class func createSourcesFile(requiresList: Set<String>) {
        
        // Get path that is not part of the document root and make dirs for that
        let cacheDir = "\(SECompiler.binaryCompilationLocation)\(SECompiler.relativePath!)"
        SEShell.bash("mkdir -p \(cacheDir)")
        
        let fout = "\(SECompiler.executableName!).sources"
        let fileUrl = URL(fileURLWithPath: "\(cacheDir)\(fout)")
        let textToWriteOut = requiresList.joined(separator: "\n")
        
        do {
            try textToWriteOut.write(to: fileUrl, atomically: false, encoding: .utf8)
        }
        catch {
            SEShell.stdErr.write(error.localizedDescription)
            exit(-1)
        }
    }
    
    
    
    // Checks to see if any of the source files are newer than executable
    private class func isBinaryCurrent() -> Bool {
        
        let fileManager = FileManager.default
        let sourcesFile = "\(SECompiler.fullExecutablePath).sources"
        
        // Ensure binary exits
        guard fileManager.fileExists(atPath: SECompiler.fullExecutablePath) else {
            return false
        }
        
        // Ensure .sources file exists
        guard fileManager.fileExists(atPath: sourcesFile) else {
            return false
        }
        
        do {
            // Read sources from sourcesFile
            let sources = try String(contentsOfFile: sourcesFile, encoding: .utf8).components(separatedBy: "\n")
            
            // Get date of .sources file
            let sourcesFileAttrs = try fileManager.attributesOfItem(atPath: SECompiler.fullExecutablePath)
            if let sourcesFileCreationDate = sourcesFileAttrs[.modificationDate] as? Date {
                
                // Iterated through required files, check to see if that file's creation date is older
                for file in sources {
                    let absolutePath = file
                    let fileAttrs = try fileManager.attributesOfItem(atPath: absolutePath)
                    
                    if let fileCreationDate = fileAttrs[.modificationDate] as? Date {
                        // File is newer than .sources file
                        if sourcesFileCreationDate < fileCreationDate {
                            return false
                        }
                    }
                }
            }
        }
        catch {
            SEShell.stdErr.write(error.localizedDescription)
            exit(-1)
        }
        
        // All required files are newer than .sources file
        return true
    }
	
    
    
	private class func generateObjectFile(sourceUrl: String, isMain: Bool = false) {
		
	}
	
    
    
	private class func listOfObjectFiles(baseDir: String) throws -> [String] {
		let text = try SECompiler.getFileContents(path: baseDir + "/objectslist.txt")
		// split each line into array item, filter out any empty lines, and append absolute URLs
		let list = text.components(separatedBy: "\n").filter{$0 != ""}.map{baseDir + "/" + $0}
		return list
	}
	
    
    
	private class func listOfModulemapFiles(baseDir:String) throws -> [String] {
		let text = try SECompiler.getFileContents(path: baseDir + "/modulemaplist.txt")
		// split each line into array item, filter out any empty lines, and append absolute URLs
		let list = text.components(separatedBy: "\n").filter{$0 != ""}.map{baseDir + "/" + $0}
		return list
	}
	
    
    
	private class func getFileContents(path: String) throws -> String {
		let text = try String(contentsOfFile: path as String, encoding: .utf8)
		return text
	}
	
    
    
	private class func debugOut(_ resp : Any) {
		print("Content-type: text/html")
		print("")
		print("<pre>")
		print("\(resp)")
		print("</pre>")
	}
    
    
    
    private class func getErrors(_ error: String) -> String {
        let arrError = SECompiler.matchError(error)
        return SECompiler.decoreError(sError: error, errors: arrError)
    }

}


/*   Private helper functions for starting the request/compilation process  */
extension SECompiler {
    
    private class func _excuteRequest(path: String) {

        //SECompiler.compileFile(fileUri: path)
        
        // Check if binary if current; if not, compile file
        if !SECompiler.isBinaryCurrent() {
            SECompiler.compileFile(fileUri: path)
        }

        
        // Execute the binary
        #if false
            let (stdOut, stdErr, status) = SEShell.run([fullExecutablePath])
            if (status != 0) {
                print(stdErr)
                // let output = SECompiler.getErrors(stdErr)
                // SEResponse.outputHTML(status: 500, title: nil, style: SECompiler.lineNumberStyle, body: output, compilationError: true)
            }
            print(status)
            print(stdErr)
            print(stdOut)
        #else
            SEShell.runBinary(fullExecutablePath)

        #endif
        exit(0)
    }
    
    
    private class func setPathComponents(forPath path: String) {
        // Get executable name and relative path
        if let filename = path.components(separatedBy: "/").last, let execName = filename.components(separatedBy: ".").first {
            SECompiler.executableName = execName
            SECompiler.relativePath = String(path.dropFirst(SEGlobals.DOCUMENT_ROOT.count).dropLast("/\(filename)".count))
            return
        }
        
        // Could not get path componenets, can't proceed
        exit(-1)
    }
    
}


/*  Private helper methods for displaying errors and outputting code   */
extension SECompiler {
    
    private class func matchError(_ error: String) -> [NSTextCheckingResult] {
        let errorPattern =     "\n(?<filePath>[^:\n]+)" +            // get the filename
            ":" +
            // get the line number
            "(?<lineNumber>[^:\n]+)" +      // match everything except a colon and new line
            ":" +                           // match the colon
            // get char position
            "(?<charPosition>[^:\n]+)" +
            ":" +
            // get the type of annotation (error|warning|etc)
            "(?<type>[^:\n]+)" +
            ":" +
            // get the description of error
            "(?<desc>[^\n]+)" +
            "(?=\n)" +                          // detect end of line (but don't consume it)
            // iterate through the compile details
            "(?<compiler>" +
            "(?:" +         // dont capture this block as we're capturing this in the parent
            "\n" +
            "(?!(/))" + // do a negative lookahead to make sure that the next line doesn't start with a forward slash ("/"), as this would most likely indicate that this is the file column of another error line
            "[^\n]+" +  // look for anything that doesn't start with the filename
            "(?=\n)" +
            ")*" +
        ")"
        //let nsString = NSString(string: error)
        // arrError = matches(for: errorPattern, in: error).map { nsString.substring(with: $0.range)}
        // return arrError
        return matches(for: errorPattern, in: error)
    }
    
    private class func matches(for regex: String, in text: String) -> [NSTextCheckingResult] {
        do {
            let regex = try NSRegularExpression(pattern: regex)
            let nsString = NSString(string: text)
            return regex.matches(in: text, range: NSRange(location: 0, length: nsString.length))
            // return results.map { nsString.substring(with: $0.range)}
        }
        catch {
            return []
        }
    }
    
    private class func decoreError(sError: String, errors: [NSTextCheckingResult]) -> String {
        let numErrors = errors.count
    
        var output = "<h3>\(numErrors) issue\(numErrors > 1 ? "s" : "") found on this page</h3>"
        
        for i in 0..<numErrors {
            let error = errors[i]
            output += "<br><br><hr size=1>"
            output += "<h4>Issue #\(i + 1) : <font color=#dd0000>\(SECompiler.getTagValue(sError, textCheckingResult: error, key: 4)): \(SECompiler.getTagValue(sError, textCheckingResult: error, key: 5))</font> </h4>"
            output += "In file <b><font color=#dd0000>\(SECompiler.getTagValue(sError, textCheckingResult: error, key: 1))</font></b> on line \(SECompiler.getTagValue(sError, textCheckingResult: error, key: 2))<br>"
            output += "<div style=\"margin:5px 0px 15px 0px; font-weight: bold;\">"
            output += SECompiler.getCodeSnippetFromFile(fileName: SECompiler.getTagValue(sError, textCheckingResult: error, key: 1), lineNo: Int(SECompiler.getTagValue(sError, textCheckingResult: error, key: 2))!)
            output += "Compiler diagnostics: "
            output += "<span style=\"color:#dd0000;\">\(SECompiler.getTagValue(sError, textCheckingResult: error, key: 5)) </span>"
            output += "</div>"
            output += "<pre style=\"font-size:.7em\" class=\"language-swift\" ><code>"
            output += "\(SECompiler.getTagValue(sError, textCheckingResult: error, key: 6))"
            output += "</code></pre>"
        }
        return output
    }
    
    private class func getTagValue(_ sError: String, textCheckingResult: NSTextCheckingResult, key: Int) -> String {
        let range = textCheckingResult.range(at: key)
        let stringRange = Range(range, in: sError)!
        return String(sError[stringRange])
    }
    
    private class func getCodeSnippetFromFile(fileName: String, lineNo: Int, span: Int = 5) -> String {
        do {
            let data = try String(contentsOfFile: fileName, encoding: .utf8)
            let lines = data.components(separatedBy: .newlines)
            let startLine = (lineNo - span) < 1 ? 1 : (lineNo - span)
            let endLine = (startLine + span*2) > lines.count ? lines.count : (startLine + span*2)
            
            var output = "<pre " +
                "style=\"font-size:.7em\" " +
                "class=\"language-swift line-numbers\" " +
                "data-start=\"\(startLine)\" " +
                "data-line=\"\(lineNo + 1)\" " +
                "data-line-offset=\"\(startLine > 0 ? startLine : 1)\" " +
            "><code>"
            for i in startLine...endLine {
                if lines[i-1] != "" {
                    output += "</br>"
                }
                if i == lineNo {
                    output += "<font color=red><b>\(lines[i-1])</b></font>"
                } else {
                    output += ("\(lines[i-1])" + "")
                }
            }
            output += "</code></pre>"
            return output
        }
        catch {
            
        }
        return ""
    }
    
    private class var lineNumberStyle: String {
        return "pre.line-numbers {" +
            "position: relative;" +
            "padding-left: 3.8em;" +
            "counter-reset: linenumber;" +
            "}" +
            "pre.line-numbers > code {" +
            "position: relative;" +
            "}" +
            ".line-numbers .line-numbers-rows {" +
            "position: absolute;" +
            "pointer-events: none;" +
            "top: 0;" +
            "font-size: 100%;" +
            "left: -3.8em;" +
            "width: 3em; " + /* works for line-numbers below 1000 lines */
            "letter-spacing: -1px;" +
            "border-right: 1px solid #999;" +
            "-webkit-user-select: none;" +
            "-moz-user-select: none;" +
            "-ms-user-select: none;" +
            "user-select: none;" +
            "}" +
            ".line-numbers-rows > span {" +
            "pointer-events: none;" +
            "display: block;" +
            "counter-increment: linenumber;" +
            "}" +
            ".line-numbers-rows > span:before {" +
            "content: counter(linenumber);" +
            "color: #999;" +
            "display: block;" +
            "padding-right: 0.8em;" +
            "text-align: right;" +
            "}" +
            ".line-highlight  {" +
            "background: hsla(11, 96%, 50%,.28);" +
            "background: linear-gradient(to right, hsla(11, 96%, 50%,.21) 70%, hsla(11, 96%, 50%,0));" +
        "}"
    }
    
}


