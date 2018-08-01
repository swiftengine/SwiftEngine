import Foundation
import SEProcessorLib

func main(){
    let environment = ProcessInfo.processInfo.environment
    let fileRequest = environment["SCRIPT_NAME"]!
    guard let documentRoot = environment["DOCUMENT_ROOT"] else { return }
    SEConstant.DOCUMENT_ROOT = documentRoot
    
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


// var requireList: [String] = []
// func getRequireList(content: String) -> [String] {
//   var tempList: [String] = []
//   if content.range(of: SEConstant.REQUIRE_KEY) != nil {
//     let tempArr = content.components(separatedBy: SEConstant.REQUIRE_KEY)
//     for item in tempArr {
//       var require = item.components(separatedBy: "\n")[0]
//       if !require.isEmpty && 
//       SECommon.checkExitsFile(filePath: "\(SEConstant.DOCUMENT_ROOT)/\(require)"){ 
//         if !requireList.contains(require) {
//           tempList.append(require)
//           requireList.append(require)
//           let string = try! SECompiler.getFileContents(path: "\(SEConstant.DOCUMENT_ROOT)/\(require)")
//           var tempRequireList = getRequireList(content: string)
//           if tempRequireList.count > 0 {
//             tempList.append(contentsOf: tempRequireList)
//           }
//         }
//       }
//     }
//   }

//   return tempList
// }


main()
