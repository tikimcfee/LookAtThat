//
//  ParsingState.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 6/10/21.
//

import Foundation
import SwiftSyntax

class ParsingState {
    var sheet = CodeSheet()
    var organizedSourceInfo = OrganizedSourceInfo()
    
    var sourceFile: URL
    var sourceFileSyntax: SourceFileSyntax
    
    init(sourceFile: URL, sourceFileSyntax: SourceFileSyntax) {
        self.sourceFile = sourceFile
        self.sourceFileSyntax = sourceFileSyntax
    }
    
    func appendToRoot(_ codeSheet: CodeSheet) {
        sheet.appendChild(codeSheet)
    }
    
    func setAsRoot(_ codeSheet: CodeSheet) {
        sheet = codeSheet
    }
}
