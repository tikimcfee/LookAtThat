//
//  CodeGrid+Clones.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 12/12/21.
//

import Foundation
import SceneKit

// MARK: -- CodeClones
extension CodeGrid {
    func makeClone() -> CodeGrid {
        let clone = CodeGrid(
            cloneId,
            glyphCache: glyphCache,
            tokenCache: tokenCache
        )
        clone.codeGridSemanticInfo = codeGridSemanticInfo
        
        clone.rootNode = rootNode.clone()
        clone.rootNode.name = clone.id
        guard let clonedGlyphes = clone.rootNode.childNode(withName: glyphNodeName, recursively: false),
              let clonedBackground = clone.rootNode.childNode(withName: backgroundNodeName, recursively: false),
              let clonedGeometry = clonedBackground.geometry?.deepCopy() as? SCNBox
        else {
            fatalError("Node cloning failed - did not find child nodes")
        }
        clone.rootGlyphsNode = clonedGlyphes
        clone.rootGlyphsNode.name = clone.glyphNodeName
        clone.backgroundGeometryNode = clonedBackground
        clone.backgroundGeometryNode.name = clone.backgroundNodeName
        clone.backgroundGeometry = clonedGeometry
        clone.backgroundGeometryNode.geometry = clone.backgroundGeometry
        // TODO: add the full text stuff as well
        
        if let fullTextNode = clone.rootNode.childNode(
            withName: fullTextBlitter.id,
            recursively: false
        ) { fullTextNode.removeFromParentNode() }
        
        return clone
    }
}
