import Foundation

import SwiftTrace

class OutputTracer {
    var logOutput = [String]()
    
    init(trace instance: AnyObject.Type) {
        SwiftTrace.swiftDecorateArgs = (onEntry: false, onExit: false)
        SwiftTrace.logOutput = onLogOutput
//        SwiftTrace.trace(anInstance: instance)
//        SwiftTrace.traceInstances(ofClass: instance)
    }
    
    func onLogOutput(_ output: String, _ pointer: UnsafeRawPointer?, _ stackDepth: Int) {
//        print(output)
        logOutput.append(output)
    }
}
