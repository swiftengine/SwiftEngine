import NIO


public extension ByteBuffer {
    static func forString(_ string: String) -> ByteBuffer {
        var buf = ByteBufferAllocator().buffer(capacity: string.utf8.count)
        buf.write(string: string)
        return buf
    }
}

