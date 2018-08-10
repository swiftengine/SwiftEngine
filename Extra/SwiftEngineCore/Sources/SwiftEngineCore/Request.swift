import Foundation


public typealias RouteParams = [String : Any]

public class Request {

    unowned let ctx : RequestContext
    
    public var headers = CIDictionary<String, String>()
    public var server = CIDictionary<String, String>()
    
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

