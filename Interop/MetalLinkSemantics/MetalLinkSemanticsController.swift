//
//  MetalLinkSemantics.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 8/30/22.
//

import Foundation
import Combine
import SwiftSyntax

typealias GlyphConstants = MetalLinkInstancedObject<MetalLinkGlyphNode>.InstancedConstants
typealias ConstantsPointer = UnsafeMutablePointer<GlyphConstants>

struct PickingState {
    let targetGrid: CodeGrid
    let nodeID: InstanceIDType
    let node: GlyphNode
    var handledAsLast = false
    
    var nodeBufferIndex: Int? { node.meta.instanceBufferIndex }
    var nodeSyntaxID: NodeSyntaxID? { node.meta.syntaxID }
    
    var constantsPointer: ConstantsPointer? {
        return targetGrid.rootNode.instanceState.getConstantsPointer()
    }
    
    var parserSyntaxID: SyntaxIdentifier? {
        guard let id = nodeSyntaxID else { return nil }
        return targetGrid.semanticInfoMap.syntaxIDLookupByNodeId[id]
    }
}

class MetalLinkSemanticsController {
    enum Iteration {
        case stop
        case tryNext
    }
    
    let link: MetalLink
    private var bag = Set<AnyCancellable>()
    
    private var lastState: PickingState?
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
        guard let node = targetGrid.rootNode[glyphID] else {
            return .tryNext
        }
        
        if var lastState = lastState, !lastState.handledAsLast {
            updateState(lastState) {
                $0.addedColor -= LFloat4(0.0, 0.3, 0.0, 0.0)
            }
            lastState.handledAsLast = true
            self.lastState = lastState
        }
        
        let newState = PickingState(
            targetGrid: targetGrid,
            nodeID: glyphID,
            node: node
        )
        
        updateState(newState) {
            $0.addedColor += LFloat4(0.0, 0.3, 0.0, 0.0)
        }
        
        lastState = newState
        return .stop
    }
    
    func updateState(_ pickingState: PickingState, _ action: (inout GlyphConstants) -> Void) {
        guard let updatePointer = pickingState.constantsPointer else {
            return
        }
        guard let pickedNodeSyntaxID = pickingState.parserSyntaxID else {
            return
        }
        
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

private extension MetalLinkSemanticsController {
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
