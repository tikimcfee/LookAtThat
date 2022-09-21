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

struct NodePickingState {
    let targetGrid: CodeGrid
    let nodeID: InstanceIDType
    let node: GlyphNode
    
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

struct GridPickingState {
    let targetGrid: CodeGrid
}

class MetalLinkHoverController: ObservableObject {
    enum Iteration {
        case stop
        case tryNext
    }
    
    let link: MetalLink
    private var bag = Set<AnyCancellable>()
    
    @Published var lastGlyphState: NodePickingState?
    @Published var lastGridState: GridPickingState?
    
    private var trackedGrids = ConcurrentDictionary<CodeGrid.ID, CodeGrid>()
    
    init(link: MetalLink) {
        self.link = link
        setupPickingHoverStream()
    }
    
    func attachPickingStream(to newGrid: CodeGrid) {
        guard trackedGrids[newGrid.id] == nil else { return }
        trackedGrids[newGrid.id] = newGrid
    }
}

// MARK: - Grid picking
extension MetalLinkHoverController {
    func doGridPicking(gridID: InstanceIDType) {
        let allGrids = trackedGrids // this is going to cause threading issues.
        
        for grid in allGrids.values {
            if grid.backgroundID == gridID {
                if let lastGridState = lastGridState, lastGridState.targetGrid.backgroundID == gridID {
                    return
                }
                
                lastGridState = GridPickingState(targetGrid: grid)
                print("Hovering \(grid.fileName)")
                return
            }
        }
    }
}

// MARK: - Glyph picking

extension MetalLinkHoverController {
    func doGlyphPicking(glyphID: InstanceIDType) {
        let allGrids = trackedGrids // this is going to cause threading issues.
        
        for grid in allGrids.values {
            let flag = pickingTest(in: grid, glyphID: glyphID)
            if flag == .stop { return }
        }
        
        func pickingTest(in targetGrid: CodeGrid, glyphID: InstanceIDType) -> Iteration {
            // Test we found a node in this grid before skipping
            guard let node = targetGrid.rootNode[glyphID] else {
                return .tryNext
            }
            
            // Create a new state to test against
            let newState = NodePickingState(
                targetGrid: targetGrid,
                nodeID: glyphID,
                node: node
            )
            
            if let lastState = lastGlyphState {
                if lastState.parserSyntaxID == newState.parserSyntaxID {
                    // If the lastState found the same syntaxID, we can skip doing stuff.
                    // At the moment, different glyphs finding the same syntax don't do much
                    // for us.
                    return .stop
                } else {
                    updateGlyphState(lastState) {
                        $0.addedColor -= LFloat4(0.0, 0.3, 0.0, 0.0)
                    }
                }
            }
            
            updateGlyphState(newState) {
                $0.addedColor += LFloat4(0.0, 0.3, 0.0, 0.0)
            }
            
            lastGlyphState = newState
            return .stop
        }
        
        func updateGlyphState(_ pickingState: NodePickingState, _ action: (inout GlyphConstants) -> Void) {
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
}

private extension MetalLinkHoverController {
    func setupPickingHoverStream() {
        link.glyphPickingTexture.sharedPickingHover.sink { glyphID in
            self.doGlyphPicking(glyphID: glyphID)
        }.store(in: &bag)
        
        link.gridPickingTexture.sharedPickingHover.sink { gridID in
            self.doGridPicking(gridID: gridID)
        }.store(in: &bag)
    }
}
