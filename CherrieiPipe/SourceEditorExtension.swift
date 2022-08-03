//
//  SourceEditorExtension.swift
//  CherrieiPipe
//
//  Created by Ivan Lugo on 7/29/22.
//

import Foundation
import XcodeKit
import OSLog

class SourceEditorExtension: NSObject, XCSourceEditorExtension {
//    var commandDefinitions: [[XCSourceEditorCommandDefinitionKey: Any]] {
//        let namespace = Bundle(for: type(of: self)).bundleIdentifier!
//        let marker = SourceEditorCommand.className()
//        return [[.identifierKey: namespace + marker,
//                 .classNameKey: marker,
//                 .nameKey: NSLocalizedString("SourceEditorCommand", comment: "pipe to CherrieiInstance")]]
//    }
//
    func extensionDidFinishLaunching() {
        os_log("\n\n[CherrieiPipe Launched]\n\n")
    }
    
    /*
    var commandDefinitions: [[XCSourceEditorCommandDefinitionKey: Any]] {
        // If your extension needs to return a collection of command definitions that differs from those in its Info.plist, implement this optional property getter.
        return []
    }
    */
    
}
