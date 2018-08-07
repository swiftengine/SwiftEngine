import Foundation



public class Response {

    let stdin = FileHandle.standardInput
    let stdout = FileHandle.standardOutput
    let stderror = FileHandle.standardError
    
    var httpBodyResponseStarted = false
    var responseRestrictedByRequestHandlers = false
    var responseBuffer: String?

    unowned let ctx : RequestContext
    
    init(ctx: RequestContext) {
        self.ctx = ctx
    }
    
    
    @discardableResult
    public func write(_ string: String) -> Response {
        
        // if this is just whitespace including the newlines then buffer it up
        // this helps avoid accidental errors in case the use has extra spaces from their html tags, especially as it pertains to writting headrs
        if string.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            self.responseBuffer = (self.responseBuffer ?? "") + string
            return self.ctx.response
        }
        
        if (responseRestrictedByRequestHandlers) {
            self.responseErr("Error: When using request handlers, response may only be initiated by the request handler function calls ", withExitCode: -200)
            return self.ctx.response
        }
        
        if (!httpBodyResponseStarted) {
            self.responseOut("\r\n")  // this is import; we follow the HTTP protocol standard here for separating header data from body
            httpBodyResponseStarted = true
        }
        
        
        // if we have something buffered up then now is the time to flush it
        if let responseBuffer = self.responseBuffer {
            self.responseOut(responseBuffer)
            self.responseBuffer = nil
        }
        
        //guard let data = string.data(using: .utf8) else { return }
        //stdout.write(data)
        
        self.responseOut(string)
        
        return self.ctx.response
    }
    
    
    @discardableResult
    public func header(_ value: String) -> Response {
        guard !httpBodyResponseStarted else {
            self.responseErr("Error: Cannot write header data '\(value)' after response output has begun", withExitCode: -200)
            return self.ctx.response
        }
        
        // make sure at least one of the parameters contains a value
        guard !(value.isEmpty) else{
            return self.ctx.response
        }
        
        self.responseOut("\(value)\r\n")
        return self.ctx.response
    }
    
    private func responseOut(_ str: String) {
        guard let data = str.data(using: .utf8) else { return }
        self.stdout.write(data)
    }
    
    private func responseErr(_ string: String, withExitCode exitCode: Int32? = nil){
        guard let data = string.data(using: .utf8) else { return }
        self.stderror.write(data)
        if let exitCode = exitCode {
            exit(exitCode)
        }
    }
    
    
    private func statusMessage(forCode code: Int) -> String {
        switch code {
        case 100: return "Continue"
        case 101: return "Switching Protocols"
        case 200: return "OK"
        case 201: return "Created"
        case 202: return "Accepted"
        case 203: return "Non-Authoritative Information"
        case 204: return "No Content"
        case 205: return "Reset Content"
        case 206: return "Partial Content"
        case 300: return "Multiple Choices"
        case 301: return "Moved Permanently"
        case 302: return "Moved Temporarily"
        case 303: return "See Other"
        case 304: return "Not Modified"
        case 305: return "Use Proxy"
        case 400: return "Bad Request"
        case 401: return "Unauthorized"
        case 402: return "Payment Required"
        case 403: return "Forbidden"
        case 404: return "Not Found"
        case 405: return "Method Not Allowed"
        case 406: return "Not Acceptable"
        case 407: return "Proxy Authentication Required"
        case 408: return "Request Time-out"
        case 409: return "Conflict"
        case 410: return "Gone"
        case 411: return "Length Required"
        case 412: return "Precondition Failed"
        case 413: return "Request Entity Too Large"
        case 414: return "Request-URI Too Large"
        case 415: return "Unsupported Media Type"
        case 500: return "Internal Server Error"
        case 501: return "Not Implemented"
        case 502: return "Bad Gateway"
        case 503: return "Service Unavailable"
        case 504: return "Gateway Time-out"
        case 505: return "HTTP Version not supported"
        default: return "Unknown http status code \(code)"
        }
    }
    
}



