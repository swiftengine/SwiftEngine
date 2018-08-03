

public class Response {

    
//    let stdin    = FileHandle.standardInput
//    let stdout   = FileHandle.standardOutput
//    let stderror = FileHandle.standardError
    
    var httpBodyResponseStarted = false
    var responseRestrictedByRequestHandlers = false
    var responseBuffer = ""

    unowned let ctx : RequestContext

    init(ctx: RequestContext){
        self.ctx = ctx
    }
    
    public func write(_ str: String) {

        //ctx.response.write("HTTP/1.1 200\n")
        print(str)
    }
}



