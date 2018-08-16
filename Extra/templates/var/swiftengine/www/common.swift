// Import SwiftEngine essentials
import SwiftEngine

class Common{
	
	//get a reference to RequestContext
	// read more at: http://kb.swiftengine.io/RequestContext
	class func printContextInfo(for ctx: RequestContext){
		
		// get refrences to request and response object of current context
		// read more at: http://kb.swiftengine.io/RequestContext
		let req = ctx.request
		let res = ctx.response
		
		// retrieve some server side variables
		// read more at: http://kb.swiftengine.io/Request
		let clientIP = req.server["REMOTE_ADDR"]
		
		// write out some data
		// read more at: http://kb.swiftengine.io/Response
		if let clientIP = clientIP {
			res.write("Your IP is: \(clientIP)")
		}

	}
	
}
