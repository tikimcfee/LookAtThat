//
//  CodeGridGlyphCollectionBuilder.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 8/27/22.
//

import simd
import Foundation
import MetalLink
import MetalLinkHeaders

public extension CodeGridGlyphCollectionBuilder {
    enum Mode {
//        case monoCollection
        case multiCollection
    }
}

typealias ParentSource = (inout VirtualParentConstants) -> Void
typealias ParentUpdater = (ParentSource) -> Void

public class CodeGridGlyphCollectionBuilder {
    let link: MetalLink
    let atlas: MetalLinkAtlas
    let sharedSemanticMap: SemanticInfoMap
    let sharedTokenCache: CodeGridTokenCache
    let sharedGridCache: GridCache
    let parentBuffer: BackingBuffer<VirtualParentConstants>
    
    var mode: Mode = .multiCollection
    
    public init(
        link: MetalLink,
        sharedSemanticMap semanticMap: SemanticInfoMap,
        sharedTokenCache tokenCache: CodeGridTokenCache,
        sharedGridCache gridCache: GridCache
    ) throws {
        self.link = link
        self.atlas = GlobalInstances.defaultAtlas
        self.sharedSemanticMap = semanticMap
        self.sharedTokenCache = tokenCache
        self.sharedGridCache = gridCache
        self.parentBuffer = try BackingBuffer<VirtualParentConstants>(link: link, initialSize: 256)
        
        // create the first buffer item and set it as identity.
        // this might let 0-parents have an identity to multiply.
        // Not tested, just a hypothesis
        _ = try parentBuffer.createNext {
            $0.modelMatrix = matrix_identity_float4x4
        }
    }
    
    func getCollection(bufferSize: Int = BackingBufferDefaultSize) -> GlyphCollection {
        return try! GlyphCollection(
            link: link,
            linkAtlas: atlas,
            bufferSize: bufferSize
        )
    }
    
    func createGrid(
        bufferSize: Int = BackingBufferDefaultSize
    ) -> CodeGrid {
        let grid = CodeGrid(
            rootNode: getCollection(bufferSize: bufferSize),
            tokenCache: sharedTokenCache
        )
        sharedGridCache.cachedGrids[grid.id] = grid
        
        // TODO: This is whacky and gross. I love it and hate it. Make parent buffers better.
        let parent = try! parentBuffer.createNext()
        func updateParent(_ operation: (inout VirtualParentConstants) -> Void) {
            operation(&parentBuffer.pointer[parent.arrayIndex])
        }
        grid.updateVirtualParentConstants = updateParent(_:)
        
        return grid
    }
    
    func createConsumerForNewGrid() -> GlyphCollectionSyntaxConsumer {
        GlyphCollectionSyntaxConsumer(targetGrid: createGrid())
    }
    
    func makeVirtualParent() -> VirtualGlyphParent {
        let node = VirtualGlyphParent()
        return node
    }
}


class VirtualGlyphParent: MetalLinkNode {
    override var children: [MetalLinkNode] {
        didSet { }
    }
}
