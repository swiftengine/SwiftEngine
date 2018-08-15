import Foundation
import NIO
import NIOHTTP1 
import NIOFoundationCompat
#if os(Linux)
import Glibc
#endif
//import Darwin


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

    //Request body file handler
    private var requestId : String!
    private var requestBodyFilePath : String!
    private var requestBodyFileHandle : Foundation.FileHandle!//NIO.FileHandle?
    
    public init(fileIO: NonBlockingFileIO, htdocsPath: String,
                documentRoot: String = "/var/swiftengine/www",
                pathToSEProcessor: String = "/usr/bin/SEProcessor") {
        self.fileIO = fileIO
        self.htdocsPath = htdocsPath
        self.documentRoot = documentRoot
        self.pathToSEProcessor = pathToSEProcessor

        //print("SEHTTPHandler init")
    }

    public func handlerAdded(ctx: ChannelHandlerContext) {
    }

    public func channelRead(ctx: ChannelHandlerContext, data: NIOAny) {

        
        //print("SEHTTPHandler channelRead")
        // let outboudDataOut = data //self.wrapOutboundOut(data)
        // ctx.fireChannelRead(outboudDataOut)

        if self.requestId == nil {
            self.requestId = randomAlphaNumericString(length: 32)
        }

        let reqPart = self.unwrapInboundIn(data)
        switch reqPart {
        case .head(let request):
		    self.keepAlive = request.isKeepAlive
            self.infoSavedRequestHead = request
            break
        case .body(buffer: var buff):

            // create the file handle if it doesnt already exists
            if self.requestBodyFileHandle == nil {
                self.requestBodyFilePath = "/tmp/" + self.requestId
                FileManager.default.createFile(atPath: self.requestBodyFilePath, contents: nil, attributes: nil)
                self.requestBodyFileHandle = FileHandle(forWritingAtPath: self.requestBodyFilePath)
            }

            // write to the file handle
            if let _data = buff.readData(length: buff.readableBytes) {
                requestBodyFileHandle.write(_data)
                // let niofile = NIO.FileHandle(descriptor: _file.fileDescriptor)
                // self.fileIO.write(fileHandle: niofile, buffer: buf, eventLoop: ctx.eventLoop)
            }
            break
        case .end:

            // close the request body filehandle if we have one open
            if self.requestBodyFileHandle != nil {
                self.requestBodyFileHandle.closeFile()
                self.requestBodyFileHandle = nil
            }
            // Ensure we got the request head
            guard let request = self.infoSavedRequestHead else {
                self.errorInChannelRead(ctx)
                return
            }
            
            // Script name and query string
            let uriComponents = request.uri.components(separatedBy: "?")
            var scriptName = uriComponents[0]
            if let lastChar = scriptName.last, lastChar == "/" {
                scriptName = String(scriptName.dropLast())
            }
            
            var queryStr = ""
            if uriComponents.count > 1 {
                queryStr = uriComponents[1]
            }
            
            let fileManager = FileManager.default
            
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

            if let requestId = requestId {
                envVars["REQUEST_ID"] = requestId
            }
            
            
            // Change all headers to env vars
            let headers = request.headers
            for header in headers {
                let name = "HTTP_" + header.name.uppercased().replacingOccurrences(of: "-", with: "_")
                envVars[name] = header.value
            }
            
            // Add the server ip and port
            guard let serverAddr = ctx.localAddress, let serverIp = serverAddr.ip, let serverPort = serverAddr.port else {
                self.errorInChannelRead(ctx)
                return
            }
            envVars["SERVER_ADDR"] = serverIp
            envVars["SERVER_PORT"] = "\(serverPort)"
            
            
            // Add the remote IP and port
            guard let remoteAddr = ctx.remoteAddress, let remoteIp = remoteAddr.ip, let remotePort = remoteAddr.port else {
                self.errorInChannelRead(ctx)
                return
            }
            envVars["REMOTE_ADDR"] = remoteIp
            envVars["REMOTE_PORT"] = "\(remotePort)"
            

            //self.printEnvVars(envVars)
            var args = [String]()
            if let seProcessorLocation = ProcessInfo.processInfo.environment["SEPROCESSOR_LOCATION"] {
                args.append(seProcessorLocation)
                if !fileManager.fileExists(atPath: seProcessorLocation){
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
            var (stdOut, stdErr, status) = SEShell.run(args, envVars: envVars)

            let output = (status == 0 ? stdOut : stdErr)
            
            // Log request
            SELogger.log(request: request, ip: remoteIp, stdOut: output)
            
            
            // Write it out
            var buf = ctx.channel.allocator.buffer(capacity: stdOut.utf8.count)
            buf.set(string: output, at: 0)
            let nio = NIOAny(ByteBuffer.forString(output))
            ctx.write(nio, promise: nil)
            ctx.flush()
            ctx.close(promise: nil)
            //self.completeResponse(ctx, trailers: nil, promise: nil)

            if self.requestBodyFilePath != nil {
                try? fileManager.removeItem(atPath:  self.requestBodyFilePath)
            }
            break
        }
    }
    
    
    // Generic display error function
    private func errorInChannelRead(_ ctx: ChannelHandlerContext) {
        let errMsg = "Could not process request"
        var errBuf = ctx.channel.allocator.buffer(capacity: errMsg.utf8.count)
        errBuf.set(string: errMsg, at: 0)
        let errNio = NIOAny(ByteBuffer.forString(errMsg))
        ctx.write(errNio, promise: nil)
        ctx.flush()
        ctx.close(promise: nil)
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

}


func randomAlphaNumericString(length: Int = 7)->String{

    enum s {
        static let c = Array("abcdefghjklmnpqrstuvwxyz12345789")
        static let k = UInt32(c.count)
    }

    var result = [Character](repeating: "a", count: length)

    for i in 0..<length {
        #if os(OSX)
            let r = Int(arc4random_uniform(s.k))
        #else
            let r = Int(random() % Int(s.k))
        #endif
        result[i] = s.c[r]
    }

    return String(result)
}



