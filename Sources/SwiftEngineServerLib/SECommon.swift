
import Foundation

public class SECommon {
    
    // Check Exits File
    public class func checkExitsFile(filePath path: String) -> Bool {
        return FileManager.default.fileExists(atPath: path)
    }
    
    public struct RuntimeError: Error {
        let message: String
        
        init(_ message: String, file: String = #file, function: String = #function, line: Int = #line, column: Int = #column) {
            self.message = "\(message) (File: \(file) Function: \(function) Line: \(line) Column: \(column))"
        }
        
        public var localizedDescription: String {
            return message
        }
    }
    
    public class func track(_ message: String = "", file: String = #file, function: String = #function, line: Int = #line ) {
        print("Called from \(function) \(file):\(line) :: \(message) ")
    }
    
}
