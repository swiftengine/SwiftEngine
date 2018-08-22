import Foundation

public class SEResponse {
    let stdin = FileHandle.standardInput
    let stdout = FileHandle.standardOutput
    let stderror = FileHandle.standardError

    public init() {
        
    }
	
    func stdout(_ string: String) {
        guard let data = string.data(using: .utf8) else { return }
        stdout.write(data)
    }

    func stdout(_ data: Data) {
      stdout.write(data)
    }

    public func fileNotFound(_ name: String) {
        SEResponse.outputHTML(status: 404, title: "File Not Found", style: nil, body: "<h3>404- File Not Found</h3><br>Could not find file: \(name)")
    }

    func fileNotSupported(_ extensionFile: String) {
        SEResponse.outputHTML(status: 500, title: "File Not Supported", style: nil, body: "<h3>500- File Type Not Supported</h3><br>File type not supported: \(extensionFile)")
    }
    
    class func outputHTML(status: Int, title: String?, style: String?, body: String, compilationError: Bool = false) {
        print("HTTP/1.1 \(status)")
        print("Content-type: text/html")
        print("")
        print("<html>")
        print("<head>")
        print("<meta http-equiv='Content-Type' content='text/html; charset=UTF-8'>")
        if let title = title {
            print("<title>\(title)</title>")
        }
        if let style = style {
            print("<style>\(style)</style>")
        }
        print("</head>")
        print("<body>")
        print(body)
        if compilationError {
            print("<br><hr size=1><br>")
        }
        print("</body>")
        print("</html>")
        exit(0)
    }
    

    public func processStaticFile(path: String) {
        let fileExtension = path.components(separatedBy: ".")[1]
        if let contentType = ContentType.shared.getContentType(forExtension: fileExtension) {
            let url = URL(fileURLWithPath: path)
            let data = try! Data(contentsOf: url)
            stdout( "Content-type: \(contentType)\n")
            stdout( "\n")
            stdout(data)
            exit(0)
        }
        else {
            self.fileNotSupported(fileExtension)
        }
    }

    func getRawPostData() -> String? {
        //https://developer.apple.com/documentation/foundation/filehandle
        let data = stdin.readDataToEndOfFile()
        let dataStr = String(data: data, encoding: String.Encoding.utf8)
        return dataStr
    }

    func getBase64Data(path: String) -> String? {
        let data = NSData(contentsOfFile: path)
        let dataStr = data!.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0))
        return dataStr
    }

    func getEnvironmentVar(_ name: String) -> String? {
        return ProcessInfo.processInfo.environment[name]
    }
}
