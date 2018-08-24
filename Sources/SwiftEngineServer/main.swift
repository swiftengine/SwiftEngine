import NIO
import NIOHTTP1
import SwiftEngineServerLib

// First argument is the program path
var arguments = CommandLine.arguments.dropFirst(0) // just to get an ArraySlice<String> from [String]
var allowHalfClosure = true
if arguments.dropFirst().first == .some("--disable-half-closure") {
    allowHalfClosure = false
    arguments = arguments.dropFirst()
}
let arg1 = arguments.dropFirst().first
let arg2 = arguments.dropFirst().dropFirst().first
let arg3 = arguments.dropFirst().dropFirst().dropFirst().first

let defaultHost = "0.0.0.0" //"::1"
let defaultPort = 8887
let defaultHtdocs = "/dev/null/"

enum BindTo {
    case ip(host: String, port: Int)
    case unixDomainSocket(path: String)
}

let htdocs: String
let bindTarget: BindTo

switch (arg1, arg1.flatMap(Int.init), arg2, arg2.flatMap(Int.init), arg3) {
case (.some(let h), _ , _, .some(let p), let maybeHtdocs):
    /* second arg an integer --> host port [htdocs] */
    bindTarget = .ip(host: h, port: p)
    htdocs = maybeHtdocs ?? defaultHtdocs
case (_, .some(let p), let maybeHtdocs, _, _):
    /* first arg an integer --> port [htdocs] */
    bindTarget = .ip(host: defaultHost, port: p)
    htdocs = maybeHtdocs ?? defaultHtdocs
case (.some(let portString), .none, let maybeHtdocs, .none, .none):
    /* couldn't parse as number --> uds-path [htdocs] */
    bindTarget = .unixDomainSocket(path: portString)
    htdocs = maybeHtdocs ?? defaultHtdocs
default:
    htdocs = defaultHtdocs
    bindTarget = BindTo.ip(host: defaultHost, port: defaultPort)
}

let group = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)
let threadPool = BlockingIOThreadPool(numberOfThreads: 6)
threadPool.start()

class CustomResponseHandler : ChannelHandler, ChannelOutboundHandler {
    public typealias OutboundIn = ByteBuffer
	public typealias OutboundOut = ByteBuffer

}

let fileIO = NonBlockingFileIO(threadPool: threadPool)
let bootstrap = ServerBootstrap(group: group)
    // Specify backlog and enable SO_REUSEADDR for the server itself
    .serverChannelOption(ChannelOptions.backlog, value: 256)
    .serverChannelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: 1)

    // Set the handlers that are applied to the accepted Channels
    .childChannelInitializer { channel in
        

        channel.pipeline.add(handler: HTTPRequestDecoder(leftOverBytesStrategy: .dropBytes)).then{
           channel.pipeline.add(handler: SEHTTPHandler(fileIO: fileIO, htdocsPath: htdocs))
        }
    

        //channel.pipeline.add(handler: SEMiddlewareHandler()).then{
            // channel.pipeline.configureHTTPServerPipeline(first: false, 
            //                                 withPipeliningAssistance: true, 
            //                                 withServerUpgrade: nil,
            //                                 withErrorHandling: false, 
            //                                 withCustomResponseHandler: CustomResponseHandler()).then {
            //     channel.pipeline.add(handler: SEHTTPHandler(fileIO: fileIO, htdocsPath: htdocs))
            // }
        //s}
    }

    // Enable TCP_NODELAY and SO_REUSEADDR for the accepted Channels
    .childChannelOption(ChannelOptions.socket(IPPROTO_TCP, TCP_NODELAY), value: 1)
    .childChannelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: 1)
    .childChannelOption(ChannelOptions.maxMessagesPerRead, value: 1)
    .childChannelOption(ChannelOptions.allowRemoteHalfClosure, value: allowHalfClosure)

defer {
    try! group.syncShutdownGracefully()
    try! threadPool.syncShutdownGracefully()
}

print("htdocs = \(htdocs)")

let channel = try { () -> Channel in
    switch bindTarget {
    case .ip(let host, let port):
        return try bootstrap.bind(host: host, port: port).wait()
    case .unixDomainSocket(let path):
        return try bootstrap.bind(unixDomainSocketPath: path).wait()
    }
}()

guard let localAddress = channel.localAddress else {
    fatalError("Address was unable to bind. Please check that the socket was not closed or that the address family was understood.")
}
print("Server started and listening on \(localAddress), htdocs path \(htdocs)")

// This will never unblock as we don't close the ServerChannel
try channel.closeFuture.wait()

print("Server closed")

