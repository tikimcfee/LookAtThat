//
//  StateCapturingVisitor.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 6/13/21.
//

import Foundation
import SwiftSyntax

/////// WARNING 2!
/// Pretty much just don't use this. I have no idea what I could be doing incorrectly but just calling
/// child nodes works. Using the walker doesn't. I'm assuming the 'walk' path makes assumptions about
/// the state of nodes, and since I retain nodes all over the place, I'm likely breaking those assumptions.
//class StateCapturingVisitor: SyntaxAnyVisitor {
//    let onVisit: (Syntax) throws -> SyntaxVisitorContinueKind
//    let onVisitAnyPost: (Syntax) throws -> Void
//    private var vistAnyPostDidThrow: Bool = false
//
//    init(
//        onVisitAny: @escaping (Syntax) throws -> SyntaxVisitorContinueKind = { _ in .visitChildren },
//        onVisitAnyPost: @escaping (Syntax) throws -> Void = { _ in }
//    ) {
//        self.onVisit = onVisitAny
//        self.onVisitAnyPost = onVisitAnyPost
//    }
//
//    public override func visitAny(_ node: Syntax) -> SyntaxVisitorContinueKind {
//        if vistAnyPostDidThrow {
//            return .skipChildren
//        }
//
//        do {
//            return try onVisit(node)
//        } catch {
//            return .skipChildren
//        }
//    }
//
//    public override func visitAnyPost(_ node: Syntax) {
//        do {
//            try onVisitAnyPost(node)
//        } catch {
//            vistAnyPostDidThrow = true
//        }
//    }
//}

// For whatever reason, it's safer to iterate through children than walking and doing things that way.
// Luckily the recursion is super simple, and barring super crazy nesting, the stack should be fine.
class IterativeRecursiveVisitor {
    static func walkRecursiveFromSyntax(
        _ root: Syntax,
        _ receiver: (Syntax) throws -> Void
    ) {
        do {
            try receiver(root)
            try consumeRecursiveStart(root.children, receiver)
        } catch {
            print("Error while recursing: ", error)
        }
    }
    
    static private func consumeRecursiveStart(
        _ allChildNodes: SyntaxChildren,
        _ receiver: (Syntax) throws -> Void
    ) throws {
        for childNode in allChildNodes {
            try receiver(childNode)
            try consumeRecursiveStart(childNode.children, receiver)
        }
    }
}

class FlatteningVisitor {
    let target: SemanticInfoMap
    let builder: SemanticInfoBuilder
    
    init(target: SemanticInfoMap, builder: SemanticInfoBuilder) {
        self.target = target
        self.builder = builder
    }
    
    func walkRecursiveFromSyntax(_ root: Syntax) {
        tryMap(root)
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
