import NIO


extension SocketAddress {
    var ip: String? {
        let ipSegment = "\(self)".split(separator: "]")
        if ipSegment.count > 1 {
            return ipSegment[1].components(separatedBy: ":")[0]
        }
        return nil
    }
}
