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
    
    var layerFocuses = Set<SCNNode>()
    
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
        func throwIfCancelled() throws {
            if task.isCancelled { throw Condition.cancelled(input: newInput) }
        }
        
        var toAdd: [CodeGrid] = []
        var toRemove: [CodeGrid] = []
        var focusableSemanticNodes: Set<SCNNode> = []
        
        // Start search
        codeGridParser.query.walkGridsForSearch(
            newInput,
            onPositive: { foundInGrid, leafInfo in
                try throwIfCancelled()
                
                // Found new grid to add to focus
                toAdd.append(foundInGrid)
                
                // Collect all nodes from all semantic info that contributed to passed test
                try leafInfo.forEach { info in
                    try foundInGrid.codeGridSemanticInfo.forAllNodesAssociatedWith(
                        info.syntaxId,
                        codeGridParser.tokenCache
                    ) { info, nodes in
                        try throwIfCancelled()
                        focusableSemanticNodes.formUnion(nodes)
                    }
                }
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

            // Do hover tracking stuff
            if displayMode == .glyphs {
                let (toFocus, toUnfocus) = hovers.diff(focusableSemanticNodes)
                for unfocus in toUnfocus {
                    do {
                        try throwIfCancelled()
                    } catch { print(error); return }
                    hovers.unfocusNode(unfocus)
                }
                
                for focus in toFocus {
                    do {
                        try throwIfCancelled()
                    } catch { print(error); return }
                    hovers.focusNode(focus)
                }
            }
            
            // Resize the focus after all updates
            codeGridFocus.finishUpdates()
            
            // Do translated highlighting stuff
            // Always layout the parent grids first when cloning nodes
            layerFocuses.forEach { node in node.removeFromParentNode() }
            layerFocuses.removeAll(keepingCapacity: true)
            
            focusableSemanticNodes.forEach { node in
                guard let nodeGlyphsParent = node.parent,
                      let glyphsGridParent = nodeGlyphsParent.parent,
                      let gridContainerParent = glyphsGridParent.parent
                else {
                    return
                }
                
                let nodeClone = node.clone()
                nodeClone.geometry = nodeClone.geometry?.deepCopy()
                nodeClone.geometry?.firstMaterial?.multiply.contents = NSUIColor.red
                
                let convertedPosition = glyphsGridParent.convertPosition(node.position, to: gridContainerParent)
                nodeClone.position = convertedPosition
                
                nodeClone.simdTranslate(dX: -128.0)
                nodeClone.isHidden = false
                gridContainerParent.addChildNode(nodeClone)
                
                layerFocuses.insert(nodeClone)
            }
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
