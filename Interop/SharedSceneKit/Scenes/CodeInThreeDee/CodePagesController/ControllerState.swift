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
        var trackedGridSelections = [CodeGrid: Set<SyntaxIdentifier>]()
        var trackedMapSelections = Set<SyntaxIdentifier>()
        
        func isSelected(_ id: SyntaxIdentifier) -> Bool {
            trackedMapSelections.contains(id)
            || trackedGridSelections.values.contains(where: { $0.contains(id) })
        }
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
        let isSelected = state.trackedMapSelections.toggle(id)
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
        // Update set first
        var selectionSet = state.trackedGridSelections[grid, default: []]
        let isCurrentlySelected = selectionSet.contains(id)
        if isCurrentlySelected {
            selectionSet.remove(id)
        } else {
            selectionSet.insert(id)
        }
        state.trackedGridSelections[grid] = selectionSet
        
        let focusDepth = VectorVal(8.0)
        let updateFocus: (GlyphNode) -> Void = isCurrentlySelected
            ? { $0.translated(dZ: -focusDepth).unfocus() }
            : { $0.translated(dZ: focusDepth).focus() }
        
        // TODO: This is a slightly uglier animation, the drop back in depth
        // gets cut off because it's being removed. Be specific with this placement.
        // Swap in *before* focusing nodes, swap out *out* unfocusing
        switch selectionSet.count {
        case 0: // Updated set is empty; remove glyphs
            grid.swapOutRootGlyphs()
        case 1: // First selection was made; add glyphs
            grid.swapInRootGlyphs()
        default: // Nothing to do; glyphs are already shown
            break
        }
        
        sceneTransaction {
            grid.codeGridSemanticInfo
                .walkFlattened(from: id, in: parser.tokenCache) { info, nodes in
                    nodes.forEach(updateFocus)
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
    
    let parser: CodeGridParser
    
    init(parser: CodeGridParser) {
        self.parser = parser
    }
    
    func updateFocus(
        id newFocusID: SyntaxIdentifier,
        in newFocusGrid: CodeGrid,
        focus: Bool
    ) {
        if focus, !newFocusGrid.showingRawGlyphs {
            newFocusGrid.swapInRootGlyphs()
            newFocusGrid.lockGlyphSwapping()
        }
        
        newFocusGrid
            .codeGridSemanticInfo
            .doOnAssociatedNodes(newFocusID, newFocusGrid.tokenCache) { info, nodes in
                for glyph in nodes {
                    focus ? glyph.focus()
                          : glyph.unfocus()
                }
            }
    }
    
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
            
            if let root = parser.editorWrapper.rootProvider?(),
               let camera = parser.editorWrapper.cameraProvider?() {
                sceneTransaction {
                    camera.look(
                        at: newFocusGrid.rootNode.worldPosition,
                        up: root.worldUp,
                        localFront: SCNNode.localFront
                    )
                }
            }
        } catch {
            print("Failed to find associated nodes during focus: ", error)
        }
    }
    
    private func updateFocusHighlight(_ focus: Focus, isFocused: Bool) {
        // So now we're using wrapper nodes which I think I avoided at the very
        // beginning. So far it's fragile, and now I have SCNNodes and GlyphNodes
        // everywhere, which isn't exactly ideal.
        for (_, nodeSet) in focus {
            for glyph in nodeSet {
                isFocused
                    ? glyph.focus()
                    : glyph.unfocus()
            }
        }
    }
}
