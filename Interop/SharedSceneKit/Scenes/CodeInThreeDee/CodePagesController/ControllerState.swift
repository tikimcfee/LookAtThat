//
//  ControllerState.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 5/8/22.
//

import Combine
import SwiftSyntax
import SceneKit

class CodeGridPointerController: ObservableObject {
    var sceneState: SceneState
    lazy var pointerNode: SCNNode = makePointerNode()
    
    init(sceneState: SceneState) {
        self.sceneState = sceneState
    }
    
    func makePointerNode() -> SCNNode {
        let node = SCNNode()
        node.name = "ExecutionPointer"
        node.geometry = SCNSphere(radius: 4.0)
        node.geometry?.materials.first?.diffuse.contents = NSUIColor(red: 0.2, green: 0.8, blue: 0.3, alpha: 1.0)
        return node
    }
    
    func moveExecutionPointer(id: SyntaxIdentifier, in grid: CodeGrid) {
        sceneTransaction {
            if pointerNode.parent == nil {
                sceneState.rootGeometryNode.addChildNode(pointerNode)
            }
            
            let allCollectedNodes = try? grid.codeGridSemanticInfo.collectAssociatedNodes(id, grid.tokenCache)
            
            if let firstNodeSet = allCollectedNodes?.first,
               let firstNode = firstNodeSet.1.first {
                
                pointerNode.worldPosition = grid.rootNode.worldPosition.translated(
                    dX: firstNode.position.x,
                    dY: firstNode.position.y,
                    dZ: firstNode.position.z
                )
                
                sceneState.cameraNode.worldPosition = SCNVector3(
                    x: pointerNode.worldPosition.x,
                    y: pointerNode.worldPosition.y,
                    z: sceneState.cameraNode.worldPosition.z
                )
                
                sceneState.cameraNode.look(
                    at: pointerNode.worldPosition,
                    up: sceneState.rootGeometryNode.worldUp,
                    localFront: SCNNode.localFront
                )
            }
        }
    }
}

class CodeGridHoverController: ObservableObject {
    struct State {
        var hoveredTokenId: String? = ""
        var hoveredInfo: CodeGridSemanticMap = .init()
        var hoveredGrid: CodeGrid?
    }
    @Published var state: State = State()
}

class CodeGridSelectionController: ObservableObject {
    struct State {
        var selectedIdentifiers = Set<SyntaxIdentifier>()
    }
    @Published var state: State = State()
    
    let parser: CodeGridParser
    
    init(parser: CodeGridParser) {
        self.parser = parser
    }
    
    func selected(
        id: SyntaxIdentifier,
        in source: CodeGridSemanticMap
    ) {
        let isSelected = state.selectedIdentifiers.toggle(id)
        sceneTransaction {
            source.walkFlattened(
                from: id,
                in: parser.tokenCache
            ) { info, nodes in
                nodes.forEach { node in
                    node.translate(dZ: isSelected ? 8 : -8)
                    isSelected ? node.focus() : node.unfocus()
                }
            }
        }
    }
    
    func selected(
        id: SyntaxIdentifier,
        in grid: CodeGrid
    ) {
        let isSelected = state.selectedIdentifiers.toggle(id)
        grid.swapInRootGlyphs() //  TODO: ruh roh. hitting the wall of single selection. Need to track to swap better.
        sceneTransaction {
            grid.codeGridSemanticInfo.walkFlattened(
                from: id,
                in: parser.tokenCache
            ) { info, nodes in
                nodes.forEach { node in
                    node.translate(dZ: isSelected ? 8 : -8)
                    isSelected ? node.focus() : node.unfocus()
                }
            }
        }
    }
}

class CodeGridTraceController: ObservableObject {
    typealias Focus = [(SemanticInfo, SortedNodeSet)]
    
    struct State {
        var currentFocus: Focus?
        var currentFocusGrid: CodeGrid?
    }
    @Published var state: State = State()
    
    func setNewFocus(
        id newFocusID: SyntaxIdentifier,
        in newFocusGrid: CodeGrid
    ) {
        // Swap last highlight
        if let lastFocus = state.currentFocus {
            updateFocusHighlight(lastFocus, isFocused: false)
        }
        
        // Ensure glyphs are visible
        switch state.currentFocusGrid {
        case .none:
            newFocusGrid.swapInRootGlyphs()
        case .some(let lastGrid):
            if lastGrid.id != newFocusGrid.id {
                lastGrid.swapOutRootGlyphs()
                newFocusGrid.swapInRootGlyphs()
            }
        }
        
        do {
            let newFocus = try newFocusGrid
                .codeGridSemanticInfo
                .collectAssociatedNodes(newFocusID, newFocusGrid.tokenCache)
            updateFocusHighlight(newFocus, isFocused: true)
            state.currentFocus = newFocus
            state.currentFocusGrid = newFocusGrid
        } catch {
            print("Failed to find associated nodes during focus: ", error)
        }
    }
    
    private func updateFocusHighlight(_ focus: Focus, isFocused: Bool) {
        // So now we're using wrapper nodes which I think I avoided at the very
        // beginning. So far it's fragile, and now I have SCNNodes and GlyphNodes
        // everywhere, which isn't exactly ideal.
        for (_, nodeSet) in focus {
            for node in nodeSet {
                if let glyph = (node as? GlyphNode) {
                    isFocused
                        ? glyph.focus()
                        : glyph.unfocus()
                }
            }
        }
    }
}
