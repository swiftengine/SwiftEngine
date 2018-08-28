
import Foundation
public class SECommon {
    
    // Check Exits File
    public class func checkExitsFile(filePath path: String) -> Bool {
        return FileManager.default.fileExists(atPath: path)
    }
    
    public struct RuntimeError: Error {
        let message: String
        
        init(_ message: String) {
            self.message = message
        }
        
        public var localizedDescription: String {
            return message
        }
    }
    
}
