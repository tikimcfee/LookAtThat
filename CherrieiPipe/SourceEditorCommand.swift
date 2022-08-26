//
//  SourceEditorCommand.swift
//  CherrieiPipe
//
//  Created by Ivan Lugo on 7/29/22.
//

import Foundation
import XcodeKit
import OSLog

class SourceEditorCommand: NSObject, XCSourceEditorCommand {
    let start = "/*startcv--"
    let end = "endcv--*/"
    
    func perform(
        with invocation: XCSourceEditorCommandInvocation,
        completionHandler: @escaping (Error?) -> Void
    ) {
        // Implement your command here, invoking the completion handler when done. Pass it nil on success, and an NSError on failure.
        let lines = invocation.buffer.lines
        guard let strings = lines as? [String] else {
            completionHandler(nil)
            return
        }
        
        strings.enumerated().forEach { i, line in
            var inserted = line
            inserted.insert(contentsOf: "/* \(i) */", at: line.index(line.endIndex, offsetBy: -1))
            
            let test = inserted
            os_log("\(test)")
            lines[i] = test
        }
        
        lines.add("/* Cherriei-Context */")
        
        completionHandler(nil)
    }
    
}
