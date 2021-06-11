//
//  ParsingState.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 6/10/21.
//

import Foundation
import SwiftSyntax

struct ParsingState {
    var sheet: CodeSheet = CodeSheet()
    
    var sourceFile: URL
    var sourceFileSyntax: SourceFileSyntax
    
    init(sourceFile: URL, sourceFileSyntax: SourceFileSyntax) {
        self.sourceFile = sourceFile
        self.sourceFileSyntax = sourceFileSyntax
    }
}
