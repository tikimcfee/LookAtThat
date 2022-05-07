//
//  StateCapturingVisitor.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 6/13/21.
//

import Foundation
import SwiftSyntax

// WARNING!
// walking is apparently dangerous as hell when trying to cast between protocols so...
// we use the flattening visitor instead
class StateCapturingVisitor: SyntaxAnyVisitor {
    let onVisit: (Syntax) -> SyntaxVisitorContinueKind
    let onVisitAnyPost: (Syntax) -> Void
    
    init(
        onVisitAny: @escaping (Syntax) -> SyntaxVisitorContinueKind = { _ in .visitChildren },
        onVisitAnyPost: @escaping (Syntax) -> Void = { _ in }
    ) {
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

// For whatever reason, it's safer to iterate through children than walking and doing things that way.
// Luckily the recursion is super simple, and barring super crazy nesting, the stack should be fine.
class FlatteningVisitor {
    let target: CodeGridSemanticMap
    let builder: SemanticInfoBuilder
    
    init(target: CodeGridSemanticMap, builder: SemanticInfoBuilder) {
        self.target = target
        self.builder = builder
    }
    
    func walkRecursiveFromSyntax(_ root: Syntax) {
        consumeRecursiveStart(root.children)
    }
    
    private func consumeRecursiveStart(_ allChildNodes: SyntaxChildren) {
        for childNode in allChildNodes {
            consumeRecursiveStart(childNode.children)
            tryMap(childNode)
        }
    }
    
    private func tryMap(_ syntax: Syntax) {
        let syntaxId = syntax.id
        let type = syntax.as(SyntaxEnum.self)
        
        target.flattenedSyntax[syntaxId] = syntax
        builder[syntax] = type
        
        let info = builder.semanticInfo(for: syntax, type: type)
        target.insertSemanticInfo(syntaxId, info)
        
        // associate it with itself for now; the view just does
        // an Array(dictionary.keys), doesn't even matter
        target.category(for: type) { store in
            store[syntaxId, default: [:]][syntaxId] = 1
        }
    }
}
