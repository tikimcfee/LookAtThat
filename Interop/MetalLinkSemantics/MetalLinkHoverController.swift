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
typealias UpdateConstants = (GlyphNode, inout GlyphConstants, inout Bool) throws -> Void

class MetalLinkHoverController: ObservableObject {
    
    let link: MetalLink
    private var bag = Set<AnyCancellable>()
    
    @Published private var lastGlyphEvent: NodePickingState.Event = .initial
    @Published private var lastGridEvent: GridPickingState.Event = .initial
    
    lazy var sharedGridEvent = $lastGridEvent.share().eraseToAnyPublisher()
    lazy var sharedGlyphEvent = $lastGlyphEvent.share().eraseToAnyPublisher()
    
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

private extension MetalLinkHoverController {
    func setupPickingHoverStream() {
        link.glyphPickingTexture.sharedPickingHover.sink { glyphID in
            self.doGlyphPicking(glyphID: glyphID)
        }.store(in: &bag)
        
        link.gridPickingTexture.sharedPickingHover.sink { gridID in
            self.doGridPicking(gridID: gridID)
        }.store(in: &bag)
    }
    
    func doGlyphPicking(glyphID: InstanceIDType) {
        guard let grid = lastGridEvent.latestState?.targetGrid else { return }
        
        lastGlyphEvent = Self.computeNodePickingEvent(
            in: grid,
            glyphID: glyphID,
            lastGlyphEvent: lastGlyphEvent
        )
    }
    
    func doGridPicking(gridID: InstanceIDType) {
        lastGridEvent = Self.computeGridPickingEvent(
            gridID: gridID,
            lastGridEvent: lastGridEvent,
            allGrids: trackedGrids
        )
    }
}

// MARK: - Grid picking

extension MetalLinkHoverController {
    private static func computeGridPickingEvent(
        gridID: InstanceIDType,
        lastGridEvent: GridPickingState.Event,
        allGrids: ConcurrentDictionary<CodeGrid.ID, CodeGrid>
    ) -> GridPickingState.Event {
        for grid in allGrids.values {
            // Find matching grid
            guard grid.backgroundID == gridID
            else { continue }
            
            // Create and update new state
            let newState = GridPickingState(targetGrid: grid)
            
            // Return new event
            if let oldState = lastGridEvent.latestState,
               oldState.targetGrid.backgroundID == gridID
            {
                return .matchesLast(last: oldState, new: newState)
            } else {
                print("Hovering \(grid.fileName)")
                return .foundNew(last: lastGridEvent.latestState, new: newState)
            }
        }
        
        return .useLast(last: lastGridEvent.latestState)
    }
}

// MARK: - Glyph picking

extension MetalLinkHoverController {
    private static func computeNodePickingEvent(
        in targetGrid: CodeGrid,
        glyphID: InstanceIDType,
        lastGlyphEvent: NodePickingState.Event
    ) -> NodePickingState.Event {
        // Test we found a node in this grid before skipping
        guard let node = targetGrid.rootNode[glyphID] else {
            return .useLast(last: lastGlyphEvent.latestState)
        }
        
        // Create a new state to test against
        let newState = NodePickingState(
            targetGrid: targetGrid,
            nodeID: glyphID,
            node: node
        )

        // Skip matching syntax ids; send last state to allow action on last node
        
        if let oldState = lastGlyphEvent.latestState,
           oldState.parserSyntaxID == newState.parserSyntaxID
        {
            return .matchesLast(last: oldState, new: newState)
        } else {
            return .foundNew(last: lastGlyphEvent.latestState, new: newState)
        }
    }
}
