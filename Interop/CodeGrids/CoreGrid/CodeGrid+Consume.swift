//
//  CodeGrid+Writing.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 12/12/21.
//

import Foundation
import SceneKit
import SwiftSyntax

// MARK: -- Consume Text
extension CodeGrid {
    // If you call this, you basically draw text like a typewriter from wherevery you last were.
    // it adds caches layer glyphs motivated by display requirements inherited by those clients.
    @discardableResult
    func consume(text: String) -> (CodeGrid, CodeGridNodes) {
        var nodes = CodeGridNodes()
        GlyphCollectionSyntaxConsumer(targetGrid: self)
            .write(text, "raw-text-\(UUID().uuidString)", NSUIColor.white, &nodes)
        rootNode.setRootMesh()
        return (self, nodes)
    }
}

//MARK: -- Consume Syntax
extension CodeGrid {
    @discardableResult
    func consume(rootSyntaxNode: Syntax) -> CodeGrid {
        doSyntaxConsume(rootSyntaxNode: rootSyntaxNode)
        return self
    }
    
    @discardableResult
    private func doSyntaxConsume(rootSyntaxNode: Syntax) -> CodeGrid {
        let consumer = GlyphCollectionSyntaxConsumer(targetGrid: self)
        consumer.consume(rootSyntaxNode: rootSyntaxNode)
        consumedRootSyntaxNodes.append(rootSyntaxNode)
        return self
    }
}
