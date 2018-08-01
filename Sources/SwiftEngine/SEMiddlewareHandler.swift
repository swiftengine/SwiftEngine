import Foundation
import NIO
import NIOHTTP1 

public enum SEHTTPDataPart<RequestT: Equatable, ResponseT: Equatable> {
	case request(RequestT)
	case response(ResponseT)
	case end()
}

extension SEHTTPDataPart: Equatable {
    public static func ==(lhs: SEHTTPDataPart, rhs: SEHTTPDataPart) -> Bool {
        switch (lhs, rhs) {
        case (.request(let h1), .request(let h2)):
            return h1 == h2
        case (.response(let b1), .response(let b2)):
            return b1 == b2
        case (.end(let h1), .end(let h2)):
            return h1 == h2
        case (.request, _), (.response, _), (.end, _):
            return false
        }
    }
}


public typealias SEHTTPOutboundDataPart = SEHTTPDataPart<SEHTTPDataRequestHeadPart, IOData>

public struct SEHTTPDataRequestHeadPart: Equatable {
	public var headers: HTTPHeaders
}


//////////////////////////

class SEMiddlewareHandler: ChannelOutboundHandler {
    public typealias OutboundIn = ByteBuffer
	public typealias OutboundOut = ByteBuffer

    public func handlerAdded(ctx: ChannelHandlerContext) {
        
    }

    public func channelActive(ctx: ChannelHandlerContext) {
        track()
        ctx.fireChannelActive()
    }

    public func channelInactive(ctx: ChannelHandlerContext) {
        track()
        ctx.fireChannelInactive()
    }


	public func requestHeadDecoded(ctx: ChannelHandlerContext){


	}


    public func write(ctx: ChannelHandlerContext, data: NIOAny, promise: EventLoopPromise<Void>?) {
        track()
        var binaryData = unwrapOutboundIn(data)
        var str = binaryData.getString(at: 0, length: binaryData.readableBytes)
        print("writeData:: \(str)")
        ctx.write(data, promise: promise)
    }

    public func writeAndFlush(ctx: ChannelHandlerContext, data: NIOAny, promise: EventLoopPromise<Void>?) {
        track()
        ctx.writeAndFlush(data, promise: promise)
    }

    public func flush(ctx: ChannelHandlerContext) {
        track()
        ctx.flush()
    }

    public func close(ctx: ChannelHandlerContext, mode: CloseMode, promise: EventLoopPromise<Void>?) {
        track()
        var string = "HTTP/1.1 200 OK\ncontent-length: 12\n\nHello World!"
        var buf = ctx.channel.allocator.buffer(capacity: string.utf8.count)
        buf.set(string: string, at: 0)
        var nio1 = NIOAny(ByteBuffer.forString(string)) //NIOAny(buf)
        print("NIOAny :: \(nio1)")
        ctx.writeAndFlush(nio1, promise: nil)
        //ctx.write(nio1, promise: nil)
        print("\tend\n")
        ctx.close(promise: promise)
    }


}