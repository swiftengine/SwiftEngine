import Foundation


public typealias RouteParams = [String : Any]

public class Request {

    unowned let ctx : RequestContext
    
    public var headers = CIDictionary<String, String>()
    public var server = CIDictionary<String, String>()

    lazy public var body : RequestBody? = {
        if let requestId = self.server["REQUEST_ID"],
            let fh = FileHandle(forReadingAtPath: "/tmp/\(requestId)")
            {
            let data = fh.readDataToEndOfFile()
            return RequestBody(data:data)
        }
        return nil
    }()
    
    public init(ctx: RequestContext) {
        self.ctx = ctx 
        
        let environment = ProcessInfo.processInfo.environment
        for (key, val) in environment {
            
            if key.starts(with: "HTTP_") {
                self.headers[String(key.dropFirst(5)).replacingOccurrences(of: "_", with: "-").capitalized] = val
            }
            else {
                self.server[key] = val
            }
        }
    }
}



public typealias CIDictionary = Dictionary


public extension CIDictionary where Key == String {

    subscript(caseInsensitive key: Key) -> Value? {
        get {
            if let k = keys.first(where: { $0.caseInsensitiveCompare(key) == .orderedSame }) {
                return self[k]
            }
            return nil
        }
        set {
            if let k = keys.first(where: { $0.caseInsensitiveCompare(key) == .orderedSame }) {
                self[k] = newValue
            } else {
                self[key] = newValue
            }
        }
    }
}


public class RequestBody {
    public let data : Data

    lazy private(set) public var string : String? = {
        return String(data: self.data, encoding: String.Encoding.utf8)
    }()

    init(data: Data){
        self.data = data
    }



}

