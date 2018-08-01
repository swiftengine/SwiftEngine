import NIO


extension SocketAddress {
    var ip: String? {
        let ipSegment = "\(self)".split(separator: "]")
        if ipSegment.count > 1 {
            return String(ipSegment[1].split(separator: ":")[0])
        }
        return nil
    }
}
