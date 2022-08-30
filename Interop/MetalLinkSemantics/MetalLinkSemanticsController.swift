//
//  MetalLinkSemantics.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 8/30/22.
//

import Foundation

typealias ConstantsPointer = UnsafeMutablePointer<MetalLinkInstancedObject<MetalLinkGlyphNode>.InstancedConstants>

struct HighlightedNode {
    let targetGrid: CodeGrid
    let nodeID: InstanceIDType
    let node: GlyphNode
}

class MetalLinkSemanticsController {
    
    
    func getPointerInfo(
        for glyphID: UInt,
        in collection: GlyphCollection
    ) -> (ConstantsPointer, MetalLinkGlyphNode, Int)? {
        guard let pointer = collection.instanceState.getConstantsPointer(),
              let index = collection.instanceCache.findConstantIndex(for: glyphID),
              let node = collection.instanceCache.findNode(for: glyphID)
        else { return nil }
        return (pointer, node, index)
    }
}
