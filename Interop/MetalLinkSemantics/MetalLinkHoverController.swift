//
//  MetalLinkSemantics.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 8/30/22.
//

import Combine
import SwiftSyntax
import SwiftUI

typealias GlyphConstants = InstancedConstants
typealias ConstantsPointer = UnsafeMutablePointer<GlyphConstants>
typealias UpdateConstants = (GlyphNode, inout GlyphConstants, inout Bool) throws -> GlyphConstants

struct PickingState {
    let targetGrid: CodeGrid
    let nodeID: InstanceIDType
    let node: GlyphNode
    var handledAsLast = false
    
    var nodeBufferIndex: Int? { node.meta.instanceBufferIndex }
    var nodeSyntaxID: NodeSyntaxID? { node.meta.syntaxID }
    
    var constantsPointer: ConstantsPointer {
        return targetGrid.rootNode.instanceState.rawPointer
    }
    
    var parserSyntaxID: SyntaxIdentifier? {
        guard let id = nodeSyntaxID else { return nil }
        return targetGrid.semanticInfoMap.syntaxIDLookupByNodeId[id]
    }
}

class MetalLinkHoverController: ObservableObject {
    enum Iteration {
        case stop
        case tryNext
    }
    
    let link: MetalLink
    private var bag = Set<AnyCancellable>()
    
    @Published var lastState: PickingState?
    
    private var trackedGrids: [CodeGrid.ID: CodeGrid] = [:]
    
    init(link: MetalLink) {
        self.link = link
        setupPickingHoverStream()
    }
    
    func attachPickingStream(to newGrid: CodeGrid) {
        guard trackedGrids[newGrid.id] == nil else { return }
        trackedGrids[newGrid.id] = newGrid
    }
    
    func doPickingTest(in targetGrid: CodeGrid, glyphID: InstanceIDType) -> Iteration {
        // Test we found a node in this grid before skipping
        guard let node = targetGrid.rootNode[glyphID] else {
            return .tryNext
        }
        
        // Create a new state to test against
        let newState = PickingState(
            targetGrid: targetGrid,
            nodeID: glyphID,
            node: node
        )
        
        if let lastState = lastState {
            if lastState.parserSyntaxID == newState.parserSyntaxID {
                // If the lastState found the same syntaxID, we can skip doing stuff.
                // At the moment, different glyphs finding the same syntax don't do much
                // for us.
                return .stop
            } else {
                updateState(lastState) {
                    $0.addedColor -= LFloat4(0.0, 0.3, 0.0, 0.0)
                }
            }
        }
        
        updateState(newState) {
            $0.addedColor += LFloat4(0.0, 0.3, 0.0, 0.0)
        }
        
        lastState = newState
        return .stop
    }
    
    func updateState(_ pickingState: PickingState, _ action: (inout GlyphConstants) -> Void) {
        guard let pickedNodeSyntaxID = pickingState.parserSyntaxID else {
            return
        }
        
        let updatePointer = pickingState.constantsPointer
        pickingState.targetGrid.semanticInfoMap.doOnAssociatedNodes(
            pickedNodeSyntaxID, pickingState.targetGrid.tokenCache
        ) { info, nodes in
            for node in nodes {
                guard let index = node.meta.instanceBufferIndex else { continue }
                action(&updatePointer[index])
            }
        }
    }
}

private extension MetalLinkHoverController {
    func setupPickingHoverStream() {
        link.pickingTexture.sharedPickingHover.sink { glyphID in
            let allGrids = self.trackedGrids // this is going to cause threading issues.
            for grid in allGrids.values {
                let flag = self.doPickingTest(in: grid, glyphID: glyphID)
                if flag == .stop { return }
            }
        }.store(in: &bag)
    }
}
