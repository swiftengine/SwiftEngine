import Foundation


public typealias RouteParams = [String : Any]

public class Request {

    unowned let ctx : RequestContext
    
    public var headers = [String : String]()
    var server = [String : String]()
    
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
