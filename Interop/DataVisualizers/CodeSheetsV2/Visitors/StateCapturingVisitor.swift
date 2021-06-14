//
//  StateCapturingVisitor.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 6/13/21.
//

import Foundation
import SwiftSyntax

class StateCapturingVisitor: SyntaxAnyVisitor {
    let onVisit: (Syntax) -> SyntaxVisitorContinueKind
    let onVisitAnyPost: (Syntax) -> Void
    
    init(onVisitAny: @escaping (Syntax) -> SyntaxVisitorContinueKind,
         onVisitAnyPost: @escaping (Syntax) -> Void) {
        self.onVisit = onVisitAny
        self.onVisitAnyPost = onVisitAnyPost
    }
    
    public override func visitAny(_ node: Syntax) -> SyntaxVisitorContinueKind {
        onVisit(node)
    }
    
    public override func visitAnyPost(_ node: Syntax) {
        onVisitAnyPost(node)
    }
}
