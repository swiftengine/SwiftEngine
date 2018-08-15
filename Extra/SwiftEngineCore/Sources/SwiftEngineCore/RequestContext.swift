

open class RequestContext {
    
    lazy private (set) public var request: Request = Request(ctx: self)
    lazy private (set) public var response: Response = Response(ctx: self)
    public var requestHandlers = [RequestHandler]()
    
    
    public init() {
        
    }
    
    // url route format users/:userid/books
    // this is the designated initializer method for the handler
    public func addHandler(forMethod method:String = "*", withRoute route:String = "*", handler: @escaping (Request, Response)->() ) {
        
        guard !self.response.httpBodyResponseStarted else {
            //self.response.stderror("Error: Cannot add response handlers after response output has begun", withExitCode: -200)
            return
        }
        
        // restrict the use of the response so it cannot be called outside of request handlers
        self.response.responseRestrictedByRequestHandlers = true
        
        let requestHandler = RequestHandler(request: self.request, method:method, route:route, handler:handler)
        self.requestHandlers.append(requestHandler)
        
    }
    
    // this is a convenience method in case the closer doesnt care about the paramenters
//    public func addHandler(forMethod method:String = "*", withRoute route:String = "*", handler: @escaping (Request, Response)->() ) {
//        let __handler : (Request, Response)->() = {
//            req, res in
//            handler(req, res)
//        }
//        addHandler(forMethod:method, withRoute:route, handler:__handler)
//    }
    
    public func execValidHandler() {
        // clear the response buffer and unrestrict the use of the response library
        self.response.responseBuffer = ""
        self.response.responseRestrictedByRequestHandlers = false
        
        let validHandlers = self.getValidHandlers()
        
        if (validHandlers.count > 0){
            // now call the request
            let requestHandler = validHandlers.first!
            requestHandler.handler(self.request, self.response)
            return
        }
        
        // if we do have request handlers but nothing matched
        if(requestHandlers.count > 0 && validHandlers.count == 0){
            //self.response.stderror("Error: no matching request handler defined for this type of request", withExitCode: -200)
            return
        }
    }
    
    private func getValidHandlers() -> [RequestHandler] {
        let filteredHandlers = requestHandlers.filter{
            (requestHandler: RequestHandler) -> Bool in
            return requestHandler.isValid()
        }
        
        return filteredHandlers
    }

}


// Public convenience methods
extension RequestContext {
    
    public func get(withRoute route:String = "*", handler: @escaping (Request, Response)->() ) {
        self.addHandler(forMethod: "GET", withRoute: route, handler: handler)
    }
    
    public func post(withRoute route:String = "*", handler: @escaping (Request, Response)->() ) {
        self.addHandler(forMethod: "POST", withRoute: route, handler: handler)
    }
    
    public func put(withRoute route:String = "*", handler: @escaping (Request, Response)->() ) {
        self.addHandler(forMethod: "PUT", withRoute: route, handler: handler)
    }
    
    public func delete(withRoute route:String = "*", handler: @escaping (Request, Response)->() ) {
        self.addHandler(forMethod: "DELETE", withRoute: route, handler: handler)
    }
    
    public func patch(withRoute route:String = "*", handler: @escaping (Request, Response)->() ) {
        self.addHandler(forMethod: "PATCH", withRoute: route, handler: handler)
    }

}

