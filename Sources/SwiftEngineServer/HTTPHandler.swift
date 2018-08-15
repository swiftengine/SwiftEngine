// HTTPHandler.swift
import NIO
import NIOHTTP1

extension String {
    func chopPrefix(_ prefix: String) -> String? {
        if self.unicodeScalars.starts(with: prefix.unicodeScalars) {
            return String(self[self.index(self.startIndex, offsetBy: prefix.count)...])
        } else {
            return nil
        }
    }

    func containsDotDot() -> Bool {
        for idx in self.indices {
            if self[idx] == "." && idx < self.index(before: self.endIndex) && self[self.index(after: idx)] == "." {
                return true
            }
        }
        return false
    }
}

public func httpResponseHead(request: HTTPRequestHead, status: HTTPResponseStatus, headers: HTTPHeaders = HTTPHeaders()) -> HTTPResponseHead {
    var head = HTTPResponseHead(version: request.version, status: status, headers: headers)
    let connectionHeaders: [String] = head.headers[canonicalForm: "connection"].map { $0.lowercased() }

    if !connectionHeaders.contains("keep-alive") && !connectionHeaders.contains("close") {
        // the user hasn't pre-set either 'keep-alive' or 'close', so we might need to add headers
        switch (request.isKeepAlive, request.version.major, request.version.minor) {
        case (true, 1, 0):
            // HTTP/1.0 and the request has 'Connection: keep-alive', we should mirror that
            head.headers.add(name: "Connection", value: "keep-alive")
        case (false, 1, let n) where n >= 1:
            // HTTP/1.1 (or treated as such) and the request has 'Connection: close', we should mirror that
            head.headers.add(name: "Connection", value: "close")
        default:
            // we should match the default or are dealing with some HTTP that we don't support, let's leave as is
            ()
        }
    }
    return head
}



public final class HTTPHandler1: ChannelInboundHandler {
    private enum FileIOMethod {
        case sendfile
        case nonblockingFileIO
    }
    public typealias InboundIn = HTTPServerRequestPart
    public typealias OutboundOut = HTTPServerResponsePart

    private enum State {
        case idle
        case waitingForRequestBody
        case sendingResponse

        mutating func requestReceived() {
            precondition(self == .idle, "Invalid state for request received: \(self)")
            self = .waitingForRequestBody
        }

        mutating func requestComplete() {
            precondition(self == .waitingForRequestBody, "Invalid state for request complete: \(self)")
            self = .sendingResponse
        }

        mutating func responseComplete() {
            precondition(self == .sendingResponse, "Invalid state for response complete: \(self)")
            self = .idle
        }
    }

    private var buffer: ByteBuffer! = nil
    private var keepAlive = false
    private var state = State.idle
    private let htdocsPath: String

    private var infoSavedRequestHead: HTTPRequestHead?
    private var infoSavedBodyBytes: Int = 0

    private var continuousCount: Int = 0

    private var handler: ((ChannelHandlerContext, HTTPServerRequestPart) -> Void)?
    private var handlerFuture: EventLoopFuture<Void>?
    private let fileIO: NonBlockingFileIO

    public init(fileIO: NonBlockingFileIO, htdocsPath: String) {
        self.htdocsPath = htdocsPath
        self.fileIO = fileIO
    }

    func handleInfo(ctx: ChannelHandlerContext, request: HTTPServerRequestPart) {
		print("handleInfo()\n")
        switch request {
        case .head(let request):
            self.infoSavedRequestHead = request
            self.infoSavedBodyBytes = 0
            self.keepAlive = request.isKeepAlive
            self.state.requestReceived()
        case .body(buffer: let buf):
            self.infoSavedBodyBytes += buf.readableBytes
        case .end:
            self.state.requestComplete()
            let response = """
            HTTP method: \(self.infoSavedRequestHead!.method)\r
            URL: \(self.infoSavedRequestHead!.uri)\r
            body length: \(self.infoSavedBodyBytes)\r
            headers: \(self.infoSavedRequestHead!.headers)\r
            client: \(ctx.remoteAddress?.description ?? "zombie")\r
            IO: SwiftNIO Electric Boogaloo™️\r\n
            """
            self.buffer.clear()
            self.buffer.write(string: response)
            var headers = HTTPHeaders()
            headers.add(name: "Content-Length", value: "\(response.utf8.count)")
            ctx.write(self.wrapOutboundOut(.head(httpResponseHead(request: self.infoSavedRequestHead!, status: .ok, headers: headers))), promise: nil)
            ctx.write(self.wrapOutboundOut(.body(.byteBuffer(self.buffer))), promise: nil)
            self.completeResponse(ctx, trailers: nil, promise: nil)
        }
    }

    func handleEcho(ctx: ChannelHandlerContext, request: HTTPServerRequestPart) {
		print("handleEcho()\n")
        self.handleEcho(ctx: ctx, request: request, balloonInMemory: false)
    }

    func handleEcho(ctx: ChannelHandlerContext, request: HTTPServerRequestPart, balloonInMemory: Bool = false) {
		print("handleEcho\n")
        switch request {
        case .head(let request):
            self.keepAlive = request.isKeepAlive
            self.infoSavedRequestHead = request
            self.state.requestReceived()
            if balloonInMemory {
                self.buffer.clear()
            } else {
                ctx.writeAndFlush(self.wrapOutboundOut(.head(httpResponseHead(request: request, status: .ok))), promise: nil)
            }
        case .body(buffer: var buf):
            if balloonInMemory {
                self.buffer.write(buffer: &buf)
            } else {
                ctx.writeAndFlush(self.wrapOutboundOut(.body(.byteBuffer(buf))), promise: nil)
            }
        case .end:
            self.state.requestComplete()
            if balloonInMemory {
                var headers = HTTPHeaders()
                headers.add(name: "Content-Length", value: "\(self.buffer.readableBytes)")
                ctx.write(self.wrapOutboundOut(.head(httpResponseHead(request: self.infoSavedRequestHead!, status: .ok, headers: headers))), promise: nil)
                ctx.write(self.wrapOutboundOut(.body(.byteBuffer(self.buffer))), promise: nil)
                self.completeResponse(ctx, trailers: nil, promise: nil)
            } else {
                self.completeResponse(ctx, trailers: nil, promise: nil)
            }
        }
    }

    func handleJustWrite(ctx: ChannelHandlerContext, request: HTTPServerRequestPart, statusCode: HTTPResponseStatus = .ok, string: String, trailer: (String, String)? = nil, delay: TimeAmount = .nanoseconds(0)) {
        
		print("handleJustWrite\n")
		switch request {
        case .head(let request):
            self.keepAlive = request.isKeepAlive
            self.state.requestReceived()
            ctx.writeAndFlush(self.wrapOutboundOut(.head(httpResponseHead(request: request, status: .ok))), promise: nil)
        case .body(buffer: _):
            ()
        case .end:
            self.state.requestComplete()
            _ = ctx.eventLoop.scheduleTask(in: delay) { () -> Void in
                var buf = ctx.channel.allocator.buffer(capacity: string.utf8.count)
                buf.write(string: string)
                ctx.writeAndFlush(self.wrapOutboundOut(.body(.byteBuffer(buf))), promise: nil)
                var trailers: HTTPHeaders? = nil
                if let trailer = trailer {
                    trailers = HTTPHeaders()
                    trailers?.add(name: trailer.0, value: trailer.1)
                }

                self.completeResponse(ctx, trailers: trailers, promise: nil)
            }
        }
    }

    func handleContinuousWrites(ctx: ChannelHandlerContext, request: HTTPServerRequestPart) {
		print("handleContinuousWrites\n")
        switch request {
        case .head(let request):
            self.keepAlive = request.isKeepAlive
            self.continuousCount = 0
            self.state.requestReceived()
            func doNext() {
                self.buffer.clear()
                self.continuousCount += 1
                self.buffer.write(string: "line \(self.continuousCount)\n")
                ctx.writeAndFlush(self.wrapOutboundOut(.body(.byteBuffer(self.buffer)))).map {
                    _ = ctx.eventLoop.scheduleTask(in: .milliseconds(400), doNext)
                }.whenFailure { (_: Error) in
                    self.completeResponse(ctx, trailers: nil, promise: nil)
                }
            }
            ctx.writeAndFlush(self.wrapOutboundOut(.head(httpResponseHead(request: request, status: .ok))), promise: nil)
            doNext()
        case .end:
            self.state.requestComplete()
        default:
            break
        }
    }

    func handleMultipleWrites(ctx: ChannelHandlerContext, request: HTTPServerRequestPart, strings: [String], delay: TimeAmount) {
		print("handleMultipleWrites\n")
        switch request {
        case .head(let request):
            self.keepAlive = request.isKeepAlive
            self.continuousCount = 0
            self.state.requestReceived()
            func doNext() {
                self.buffer.clear()
                self.buffer.write(string: strings[self.continuousCount])
                self.continuousCount += 1
                ctx.writeAndFlush(self.wrapOutboundOut(.body(.byteBuffer(self.buffer)))).whenSuccess {
                    if self.continuousCount < strings.count {
                        _ = ctx.eventLoop.scheduleTask(in: delay, doNext)
                    } else {
                        self.completeResponse(ctx, trailers: nil, promise: nil)
                    }
                }
            }
            ctx.writeAndFlush(self.wrapOutboundOut(.head(httpResponseHead(request: request, status: .ok))), promise: nil)
            doNext()
        case .end:
            self.state.requestComplete()
        default:
            break
        }
    }

    func dynamicHandler(request reqHead: HTTPRequestHead) -> ((ChannelHandlerContext, HTTPServerRequestPart) -> Void)? {
		print("dynamicHandler\n")
        if let howLong = reqHead.uri.chopPrefix("/dynamic/write-delay/") {
            return { ctx, req in
                self.handleJustWrite(ctx: ctx,
                                     request: req, string: "Hello World\r\n",
                                     delay: TimeAmount.Value(howLong).map { .milliseconds($0) } ?? .seconds(0))
            }
        }

        switch reqHead.uri {
        case "/dynamic/echo":
            return self.handleEcho
        case "/dynamic/echo_balloon":
            return { self.handleEcho(ctx: $0, request: $1, balloonInMemory: true) }
        case "/dynamic/pid":
            return { ctx, req in self.handleJustWrite(ctx: ctx, request: req, string: "\(getpid())") }
        case "/dynamic/write-delay":
            return { ctx, req in self.handleJustWrite(ctx: ctx, request: req, string: "Hello World\r\n", delay: .milliseconds(100)) }
        case "/dynamic/info":
            return self.handleInfo
        case "/dynamic/trailers":
            return { ctx, req in self.handleJustWrite(ctx: ctx, request: req, string: "\(getpid())\r\n", trailer: ("Trailer-Key", "Trailer-Value")) }
        case "/dynamic/continuous":
            return self.handleContinuousWrites
        case "/dynamic/count-to-ten":
            return { self.handleMultipleWrites(ctx: $0, request: $1, strings: (1...10).map { "\($0)" }, delay: .milliseconds(100)) }
        case "/dynamic/client-ip":
            return { ctx, req in self.handleJustWrite(ctx: ctx, request: req, string: "\(ctx.remoteAddress.debugDescription)") }
        default:
            return { ctx, req in self.handleJustWrite(ctx: ctx, request: req, statusCode: .notFound, string: "not found") }
        }
    }

    private func handleFile(ctx: ChannelHandlerContext, request: HTTPServerRequestPart, ioMethod: FileIOMethod, path: String) {
		print("handleFile\n")
        self.buffer.clear()

        func sendErrorResponse(request: HTTPRequestHead, _ error: Error) {
            var body = ctx.channel.allocator.buffer(capacity: 128)
            let response = { () -> HTTPResponseHead in
                switch error {
                case let e as IOError where e.errnoCode == ENOENT:
                    body.write(staticString: "IOError (not found)\r\n")
                    return httpResponseHead(request: request, status: .notFound)
                case let e as IOError:
                    body.write(staticString: "IOError (other)\r\n")
                    body.write(string: e.description)
                    body.write(staticString: "\r\n")
                    return httpResponseHead(request: request, status: .notFound)
                default:
                    body.write(string: "\(type(of: error)) error\r\n")
                    return httpResponseHead(request: request, status: .internalServerError)
                }
            }()
            body.write(string: "\(error)")
            body.write(staticString: "\r\n")
            ctx.write(self.wrapOutboundOut(.head(response)), promise: nil)
            ctx.write(self.wrapOutboundOut(.body(.byteBuffer(body))), promise: nil)
            ctx.writeAndFlush(self.wrapOutboundOut(.end(nil)), promise: nil)
            ctx.channel.close(promise: nil)
        }

        func responseHead(request: HTTPRequestHead, fileRegion region: FileRegion) -> HTTPResponseHead {
            var response = httpResponseHead(request: request, status: .ok)
            response.headers.add(name: "Content-Length", value: "\(region.endIndex)")
            response.headers.add(name: "Content-Type", value: "text/plain; charset=utf-8")
            return response
        }

        switch request {
        case .head(let request):
            self.keepAlive = request.isKeepAlive
            self.state.requestReceived()
            guard !request.uri.containsDotDot() else {
                let response = httpResponseHead(request: request, status: .forbidden)
                ctx.write(self.wrapOutboundOut(.head(response)), promise: nil)
                self.completeResponse(ctx, trailers: nil, promise: nil)
                return
            }
            let path = self.htdocsPath + "/" + path
            let fileHandleAndRegion = self.fileIO.openFile(path: path, eventLoop: ctx.eventLoop)
            fileHandleAndRegion.whenFailure {
                sendErrorResponse(request: request, $0)
            }
            fileHandleAndRegion.whenSuccess { (file, region) in
                switch ioMethod {
                case .nonblockingFileIO:
                    var responseStarted = false
                    let response = responseHead(request: request, fileRegion: region)
                    return self.fileIO.readChunked(fileRegion: region,
                                                   chunkSize: 32 * 1024,
                                                   allocator: ctx.channel.allocator,
                                                   eventLoop: ctx.eventLoop) { buffer in
                                                    if !responseStarted {
                                                        responseStarted = true
                                                        ctx.write(self.wrapOutboundOut(.head(response)), promise: nil)
                                                    }
                                                    return ctx.writeAndFlush(self.wrapOutboundOut(.body(.byteBuffer(buffer))))
                    }.then { () -> EventLoopFuture<Void> in
                        let p: EventLoopPromise<Void> = ctx.eventLoop.newPromise()
                        self.completeResponse(ctx, trailers: nil, promise: p)
                        return p.futureResult
                    }.thenIfError { error in
                        if !responseStarted {
                            let response = httpResponseHead(request: request, status: .ok)
                            ctx.write(self.wrapOutboundOut(.head(response)), promise: nil)
                            var buffer = ctx.channel.allocator.buffer(capacity: 100)
                            buffer.write(string: "fail: \(error)")
                            ctx.write(self.wrapOutboundOut(.body(.byteBuffer(buffer))), promise: nil)
                            self.state.responseComplete()
                            return ctx.writeAndFlush(self.wrapOutboundOut(.end(nil)))
                        } else {
                            return ctx.close()
                        }
                    }.whenComplete {
                        _ = try? file.close()
                    }
                case .sendfile:
                    let response = responseHead(request: request, fileRegion: region)
                    ctx.write(self.wrapOutboundOut(.head(response)), promise: nil)
                    ctx.writeAndFlush(self.wrapOutboundOut(.body(.fileRegion(region)))).then {
                        let p: EventLoopPromise<Void> = ctx.eventLoop.newPromise()
                        self.completeResponse(ctx, trailers: nil, promise: p)
                        return p.futureResult
                    }.thenIfError { (_: Error) in
                        ctx.close()
                    }.whenComplete {
                        _ = try? file.close()
                    }
                }
        }
        case .end:
            self.state.requestComplete()
        default:
            fatalError("oh noes: \(request)")
        }
    }

    private func completeResponse(_ ctx: ChannelHandlerContext, trailers: HTTPHeaders?, promise: EventLoopPromise<Void>?) {
		print("completeResponse\n")
        self.state.responseComplete()

        let promise = self.keepAlive ? promise : (promise ?? ctx.eventLoop.newPromise())
        if !self.keepAlive {
            promise!.futureResult.whenComplete { ctx.close(promise: nil) }
        }
        self.handler = nil

        ctx.writeAndFlush(self.wrapOutboundOut(.end(trailers)), promise: promise)
    }

    public func channelRead(ctx: ChannelHandlerContext, data: NIOAny) {
		print("channelRead \(data)\n")
        let reqPart = self.unwrapInboundIn(data)
        if let handler = self.handler {
            handler(ctx, reqPart)
		    print("\thandler exit\n")
            return
        }

        switch reqPart {
        case .head(let request):
		    print("\thead\n")
            if request.uri.unicodeScalars.starts(with: "/dynamic".unicodeScalars) {
                self.handler = self.dynamicHandler(request: request)
                self.handler!(ctx, reqPart)
                return
            } else if let path = request.uri.chopPrefix("/sendfile/") {
                self.handler = { self.handleFile(ctx: $0, request: $1, ioMethod: .sendfile, path: path) }
                self.handler!(ctx, reqPart)
                return
            } else if let path = request.uri.chopPrefix("/fileio/") {
                self.handler = { self.handleFile(ctx: $0, request: $1, ioMethod: .nonblockingFileIO, path: path) }
                self.handler!(ctx, reqPart)
                return
            }

            self.keepAlive = request.isKeepAlive
            self.state.requestReceived()

            var responseHead = httpResponseHead(request: request, status: HTTPResponseStatus.ok)
            responseHead.headers.add(name: "content-length", value: "12")
            let response = HTTPServerResponsePart.head(responseHead)
            ctx.write(self.wrapOutboundOut(response), promise: nil)
        case .body:
		    print("\tbody\n")
            break
        case .end:
		    print("\tend\n")
            self.state.requestComplete()
            let content = HTTPServerResponsePart.body(.byteBuffer(buffer!.slice()))
            ctx.write(self.wrapOutboundOut(content), promise: nil)
            self.completeResponse(ctx, trailers: nil, promise: nil)
        }
    }

    public func channelReadComplete(ctx: ChannelHandlerContext) {
		print("channelReadComplete\n")
        ctx.flush()
    }

    public func handlerAdded(ctx: ChannelHandlerContext) {
		print("handlerAdded\n")
        self.buffer = ctx.channel.allocator.buffer(capacity: 12)
        self.buffer.write(staticString: "Hello World!")
    }

    public func userInboundEventTriggered(ctx: ChannelHandlerContext, event: Any) {
		print("userInboundEventTriggered\n")
        switch event {
        case let evt as ChannelEvent where evt == ChannelEvent.inputClosed:
            // The remote peer half-closed the channel. At this time, any
            // outstanding response will now get the channel closed, and
            // if we are idle or waiting for a request body to finish we
            // will close the channel immediately.
            switch self.state {
            case .idle, .waitingForRequestBody:
                ctx.close(promise: nil)
            case .sendingResponse:
                self.keepAlive = false
            }
        default:
            ctx.fireUserInboundEventTriggered(event)
        }
    }
}