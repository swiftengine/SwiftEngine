import Foundation
import SEProcessorLib

func main(){
    let environment = ProcessInfo.processInfo.environment
    
    guard let documentRoot = environment["DOCUMENT_ROOT"] else {
        print("No document root")
        exit(0)
    }
    guard let fileRequest = environment["SCRIPT_NAME"] else {
        print("No script name")
        exit(0)
    }
    SEGlobals.DOCUMENT_ROOT = documentRoot
    if let seCoreLocation = getArg("secore-location") {
        SEGlobals.SECORE_LOCATION = seCoreLocation
    }
    
    let seRoute = SERoute()
    let seResponse = SEResponse()
    if seRoute.doesRouterExist() {
        
    }
    else {
      let (excutableType, excutePath) = seRoute.getExecutableType(fileRequest)
      switch excutableType {
        case .swift:
            SECompiler.excuteRequest(path: excutePath)
        case .staticFile:
            seResponse.processStaticFile(path: excutePath)
        default:
            seResponse.fileNotFound(excutePath)
      }
    }
}

func getArg(_ key: String) -> String?{
    for argument in CommandLine.arguments {
        switch true {
        case argument.hasPrefix("-\(key)="):
            let val = argument.components(separatedBy: "=")
            if val.count > 1 {
                return val[1]
            }
        default: continue
        }
        
    }
    
    return nil
}



main()
