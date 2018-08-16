// Import SwiftEngine essentials
// read more at: https://kb.swiftengine.io/SwiftEnginAnatomy
import SwiftEngine


// specify other required files for this file
// read more at: https://kb.swiftengine.io/requires

//se: require /common.swift

// Entry Point function; where all code begins
// read more at: https://kb.swiftengine.io/entryPoint
func entryPoint(ctx: RequestContext) {
	
	// add GET handlers to the request context
	// read more at: https://kb.swiftengine.io/requestHandlers
	ctx.addHandler(forMethod:"GET", withRoute:"*"){
		req, res in
		res.write("Hello from SwiftEngine! ")
		Common.printContextInfo(for: ctx)
	}
	
	// add POST handlers to the request context
	// read more at: https://kb.swiftengine.io/requestHandlers
	ctx.addHandler(forMethod:"POST", withRoute:"*"){
		req, res in
		res.write("Handle for POST request method")
	}
	
	// add catch-all handlers to the request context
	// read more at: https://kb.swiftengine.io/requestHandlers
	ctx.addHandler(forMethod:"*", withRoute:"*"){
		req, res in
		res.write("Handle for catch-all")
	}

}
