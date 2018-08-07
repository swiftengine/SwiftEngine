// Essential imports for SwiftEngine
import SwiftEngine


// Entry Point function; where all code begins
func entryPoint(ctx: RequestContext) {
    
    // A `Response` object
    let response = ctx.response
    
    // A `Request` object
    let request = ctx.request
    
    response.write("Hello SwiftEngine!")
    
    
}

