import Foundation
import NIO
import NIOHTTP1 


public final class SEHTTPHandler: ChannelInboundHandler {
    public typealias InboundIn = HTTPServerRequestPart
    //public typealias OutboundOut = HTTPServerResponsePart
    public typealias OutboundOut = ByteBuffer

    private let htdocsPath: String
    private let fileIO: NonBlockingFileIO
    
    // Request information
    private var infoSavedRequestHead: HTTPRequestHead?
    private var keepAlive = false
    
    // CGI information
    private let documentRoot: String
    private let pathToSEProcessor: String
    

    public init(fileIO: NonBlockingFileIO, htdocsPath: String,
                documentRoot: String = "/var/swiftengine/www",
                pathToSEProcessor: String = "/usr/bin/SEProcessor") {
        self.fileIO = fileIO
        self.htdocsPath = htdocsPath
        self.documentRoot = documentRoot
        self.pathToSEProcessor = pathToSEProcessor
    }

    public func handlerAdded(ctx: ChannelHandlerContext) {
    }

    public func channelRead(ctx: ChannelHandlerContext, data: NIOAny) {

        let outboudDataOut = data //self.wrapOutboundOut(data)
        ctx.fireChannelRead(outboudDataOut)

        let reqPart = self.unwrapInboundIn(data)
        switch reqPart {
        case .head(let request):
		    self.keepAlive = request.isKeepAlive
            self.infoSavedRequestHead = request
            break
        case .body:
            break
        case .end:
            // Ensure we got the request head
            guard let request = self.infoSavedRequestHead else {
                let errMsg = "Could not process request"
                var errBuf = ctx.channel.allocator.buffer(capacity: errMsg.utf8.count)
                errBuf.set(string: errMsg, at: 0)
                let errNio = NIOAny(ByteBuffer.forString(errMsg))
                ctx.write(errNio, promise: nil)
                ctx.flush()
                ctx.close(promise: nil)
                return
            }
            //print(request)
            //print("")
            
            // Script name and query string
            let uriComponents = request.uri.split(separator: "?")
            let scriptName = String(uriComponents[0])
            var queryStr = ""
            if uriComponents.count > 1 {
                queryStr = String(uriComponents[1])
            }
            
            // Set CGI environment variables
            var envVars = [ "SCRIPT_NAME" : scriptName,
                            "QUERY_STRING" : queryStr,
                            "REQUEST_URI" : request.uri,
                            "DOCUMENT_ROOT" : self.documentRoot,
                            "REQUEST_METHOD" : "\(request.method)",
                            "GATEWAY_INTERFACE" : "CGI/1.1",
                            "SCRIPT_FILENAME" : "\(self.documentRoot)" + "\(scriptName)",
                            "SERVER_PROTOCOL" : "HTTP/1.1",
                            "SERVER_NAME" : "localhost",
                            
            ]
            
            
            // Change all headers to env vars
            let headers = request.headers
            for header in headers {
                let name = "HTTP_" + header.name.uppercased().replacingOccurrences(of: "-", with: "_")
                envVars[name] = header.value
            }
            
            // Add the server ip and port
            guard let serverAddr = ctx.localAddress, let serverIp = serverAddr.ip, let serverPort = serverAddr.port else {
                return
            }
            envVars["SERVER_ADDR"] = serverIp
            envVars["SERVER_PORT"] = "\(serverPort)"
            
            
            // Add the remote IP and port
            guard let remoteAddr = ctx.remoteAddress, let remoteIp = remoteAddr.ip, let remotePort = remoteAddr.port else {
                return
            }
            envVars["REMOTE_ADDR"] = remoteIp
            envVars["REMOTE_PORT"] = "\(remotePort)"
            

            //self.printEnvVars(envVars)
            var args = [String]()
            if let seProcessorLocation = ProcessInfo.processInfo.environment["SEPROCESSOR_LOCATION"] {
                args.append(seProcessorLocation)
                if !FileManager.default.fileExists(atPath: seProcessorLocation){
                    print("SEProcessor file does not exist: \(seProcessorLocation)")
                }
            }
            else {
                args.append(self.pathToSEProcessor)
            }
            
            if let seCoreLocation = ProcessInfo.processInfo.environment["SECORE_LOCATION"] {
                args.append("-secore-location=\(seCoreLocation)")
            }

            // Run it
            var (stdOut, _, _) = SEShell.run(args, envVars: envVars)
            
            // Log request
            SELogger.log(request: request, ip: remoteIp, stdOut: stdOut)
            
            
            // Write it out
            var buf = ctx.channel.allocator.buffer(capacity: stdOut.utf8.count)
            buf.set(string: stdOut, at: 0)
            let nio = NIOAny(ByteBuffer.forString(stdOut))
            ctx.write(nio, promise: nil)
            ctx.flush()
            ctx.close(promise: nil)
            //self.completeResponse(ctx, trailers: nil, promise: nil)
            break
        }
    }
    
    // Solely for test purposes; remove before deployment
    private func printEnvVars(_ envVars: [String:String]) {
        let keys = envVars.keys.sorted()
        var startedHttp = false
        var finishedHttp = false
        var startedServer = false
        print("\nEnv Vars:")
        for key in keys {
            if !startedHttp && key.starts(with: "HTTP") {
                startedHttp = true
                print("")
            }
            if startedHttp && !finishedHttp && !key.starts(with: "HTTP") {
                finishedHttp = true
                print("")
            }
            else if finishedHttp && !startedServer && key.starts(with: "SERVER") {
                startedServer = true
                print("")
            }
            print("\(key)=\(envVars[key]!)")
        }
    }

    public func channelReadComplete(ctx: ChannelHandlerContext) {
        ctx.flush()
    }
    
    private func completeResponse(_ ctx: ChannelHandlerContext, trailers: HTTPHeaders?, promise: EventLoopPromise<Void>?) {
        //let promise = self.keepAlive ? promise : (promise ?? ctx.eventLoop.newPromise())
        if !self.keepAlive {
            //promise!.futureResult.whenComplete {
            ctx.close(promise: nil)
            //}
        }
        //ctx.writeAndFlush(self.wrapOutboundOut(ByteBuffer.forString("0\r\n\r\n")), promise: promise)
    }

}



