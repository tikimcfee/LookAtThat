//
//  SearchContainer.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 12/5/21.
//

import Foundation
import SceneKit

class SearchContainer {
    private enum Condition: Error {
        case cancelled(input: String)
    }
    
    private let searchQueue = DispatchQueue(label: "GridTextSearch", qos: .userInitiated)
    private var currentWorkItem = DispatchWorkItem { }
    
    var hovers = TokenHoverInteractionTracker()
    var codeGridFocus: CodeGridFocusController
    var codeGridParser: CodeGridParser
    
    init(codeGridParser: CodeGridParser,
         codeGridFocus: CodeGridFocusController) {
        self.codeGridParser = codeGridParser
        self.codeGridFocus = codeGridFocus
    }
    
    func createNewSearchFocus(_ state: SceneState) {
        print("creating new search focus")
        codeGridFocus.setNewFocus()
    }
        
    func search(_ newInput: String, _ state: SceneState) {
        setupNewSearch(newInput, state)
    }
    
    private func setupNewSearch(_ newInput: String, _ state: SceneState) {
        func searchBlock() {
            do {
                try doSearch(task: currentWorkItem, newInput, state)
            } catch {
                print(error)
            }
        }
        currentWorkItem.cancel()
        currentWorkItem = DispatchWorkItem(block: searchBlock)
        searchQueue.async(execute: currentWorkItem)
    }
    
    private func doSearch(task: DispatchWorkItem, _ newInput: String, _ state: SceneState) throws {
        printStart(newInput)
        
        var toAdd: [CodeGrid] = []
        var toRemove: [CodeGrid] = []
        var focusableSemanticNodes: Set<SCNNode> = []

        hovers.clearCurrent()
        hovers.onFocused = { source, node in
            guard let nodeGlyphsParent = source.parent,
                  let glyphsGridParent = nodeGlyphsParent.parent,
                  let gridContainerParent = glyphsGridParent.parent
            else {
                return
            }
            
            node.geometry?.firstMaterial?.multiply.contents = NSUIColor.red
            
            let glyphsGridWIdth = BoundsWidth(glyphsGridParent.manualBoundingBox)
            let convertedPosition = glyphsGridParent.convertPosition(source.position, to: gridContainerParent)
            node.position = convertedPosition
            node.simdTranslate(dX: -glyphsGridWIdth - 8.0)
            
            node.isHidden = false
            gridContainerParent.addChildNode(node)
        }
        hovers.onUnfocused = { source, node in
            node.removeFromParentNode()
        }
        
        func throwIfCancelled() throws {
            if task.isCancelled { throw Condition.cancelled(input: newInput) }
        }
        
        // Collect all nodes from all semantic info that contributed to passed test
        func onSemanticSetFound(grid foundInGrid: CodeGrid, _ leafInfo: Set<SemanticInfo>) throws {
            try leafInfo.forEach { info in
                try foundInGrid.codeGridSemanticInfo.forAllNodesAssociatedWith(
                    info.syntaxId,
                    codeGridParser.tokenCache
                ) { info, nodes in
                    try throwIfCancelled()
                    nodes.forEach { hovers.cacheNode($0) }
                    focusableSemanticNodes.formUnion(nodes)
                }
            }
        }
        
        // Start search
        codeGridParser.query.walkGridsForSearch(
            newInput,
            onPositive: { foundInGrid, leafInfo in
                try throwIfCancelled()
                
                // Found new grid to add to focus
                toAdd.append(foundInGrid)
                
                try onSemanticSetFound(grid: foundInGrid, leafInfo)
            },
            onNegative: { excludedGrid, leafInfo in
                try throwIfCancelled()
                
                // This grid did not pass; remove from focus
                toRemove.append(excludedGrid)
            }
        )
        
        // Add / remove grids, and set new highlighted nodes
        let displayMode = toAdd.count > 3
            ? CodeGrid.DisplayMode.layers
            : CodeGrid.DisplayMode.glyphs
        
        sceneTransaction {
            toRemove.forEach {
                codeGridFocus.removeGridFromFocus($0)
                $0.displayMode = .layers
            }
            toAdd.enumerated().forEach {
                $0.element.displayMode = displayMode
                codeGridFocus.addGridToFocus($0.element, $0.offset)
            }
            
            // Layout pass on grids to give first set of focus positions
            codeGridFocus.layoutFocusedGrids()
            codeGridFocus.resetBounds()
        }
        
        sceneTransaction {
            for node in focusableSemanticNodes {
                hovers.focusNode(node)
            }
            
            // Resize the focus after all updates
            codeGridFocus.resetBounds()
        }
        
        printStop(newInput)
    }
    
    private func printStart(_ input: String) {
        print("new search ---------------------- [\(input)]")
    }
    
    private func printStop(_ input: String) {
        print("---------------------- [\(input)] finished ")
    }
    
    private func printCancelled(_ input: String) {
        print("XXXXXXXXXXX >> [\(input)] Cancelled")
    }
}
