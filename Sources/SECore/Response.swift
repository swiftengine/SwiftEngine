

public class Response {
    
    public init() { }
    
//    let stdin    = FileHandle.standardInput
//    let stdout   = FileHandle.standardOutput
//    let stderror = FileHandle.standardError
    
    var httpBodyResponseStarted = false
    var responseRestrictedByRequestHandlers = false
    var responseBuffer = ""
    
    public func write(_ str: String) {
        print(str)
    }
}



