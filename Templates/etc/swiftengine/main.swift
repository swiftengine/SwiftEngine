import SwiftEngine
import Foundation


let ctx = RequestContext()
// Necessary for proper output
ctx.response.write("HTTP/1.1 200\n")
entryPoint(ctx: ctx)

ctx.execValidHandler()

