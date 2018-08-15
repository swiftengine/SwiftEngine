
import Foundation


open class RequestHandler {
    
    public let method : String
    public let route : String
    public let handler : (Request, Response) -> ()
    private let request: Request  // doing this for dependency injection compatibility
    public var routeParams = RouteParams()
    
    init(request: Request, method:String, route:String, handler: @escaping (Request, Response)->()){
        self.request = request
        self.method = method
        self.route = route
        self.handler = handler
    }
    
    open func get(_ endpoint: String, _ handler: @escaping (Request.Type, Response.Type) -> ()) {
        handler(Request.self, Response.self)
    }
    
    func isValid() -> Bool {
        if (!isMethodValid()) {
            return false
        }
        if (!validateRoute()) {
            return false
        }
        return true
    }
    
    
    func validateRoute() -> Bool {
        // first let's split up the current requesr URI
        var requestRoute = self.request.server["REQUEST_URI"]!
        
        // When request have value like 'https://www.abc.com/school?size=5'
        // the validateRoute will return false
        // So to return true we have to remove '?size=5'
        let charset = CharacterSet(charactersIn: "?")
        if requestRoute.rangeOfCharacter(from: charset) != nil {
            requestRoute = requestRoute.components(separatedBy: "?")[0]
        }
        
        let requestRouteArr = requestRoute.components(separatedBy: "/")
        
        // now let's split up our own route
        let handlerRouteArr = self.route.components(separatedBy: "/")
        
        // if the handlerRoute has more parts than the request route then this is no good
        if handlerRouteArr.count > requestRouteArr.count {
            return false
        }
        
        
        var routeParamDict = RouteParams()
        
        // now loop through our array and make sure we match
        for i in 0..<handlerRouteArr.count {
            
            let requestRouteComponent = requestRouteArr[i]
            let handlerRouteComponent = handlerRouteArr[i]
            
            // if both componenets are empty then continue on to the next one
            if (requestRouteComponent.count == 0 && handlerRouteComponent.count == 0) {
                continue
            }
            
            // if this is a wildcard match then just proceed to next item
            if(handlerRouteComponent == "*"){
                continue
            }
            
            // if this component is a param name match
            if (handlerRouteComponent.count > 0 && handlerRouteComponent.first! == ":"){
                
                var paramName = handlerRouteComponent       // get the parameter name
                paramName.remove(at: paramName.startIndex)   // remove the collons mark from the parameter name
                
                routeParamDict[paramName] = requestRouteComponent
                
                continue
            }
            
            // finally if we got here, then the route needs to match
            if(requestRouteComponent.lowercased() != handlerRouteComponent.lowercased()){
                return false
            }
            
        }
        
        // now assign the route parameters if we got some
        self.routeParams = routeParamDict
        
        return true
    }
    
    func isMethodValid() -> Bool {
        
        let reqMethod = request.server["REQUEST_METHOD"] ?? ""
        
        // if this is not a catch all, and does not match the current request method
        if (self.method != "*" && self.method != reqMethod) {
            return false
        }
        
        return true
        
    }
    
}

