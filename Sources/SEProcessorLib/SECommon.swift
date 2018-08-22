
import Foundation
public class SECommon {
    
    // Check Exits File
    public class func checkExitsFile(filePath path: String) -> Bool {
        return FileManager.default.fileExists(atPath: path)
    }
}
