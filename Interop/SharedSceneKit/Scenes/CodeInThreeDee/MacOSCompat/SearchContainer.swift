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
        
        typealias FocusType = (source: CodeGrid, clone: CodeGrid)
        var toRemove: [CodeGrid] = []
        var toFocus: [FocusType] = []
        codeGridFocus.resetState()
        
        func throwIfCancelled() throws {
            if task.isCancelled { throw Condition.cancelled(input: newInput) }
        }
        
        // Collect all nodes from all semantic info that contributed to passed test
        func onSemanticSetFound(foundInGrid: CodeGrid,
                                clone: CodeGrid,
                                _ matchingSemanticSet: Set<SemanticInfo>) throws {
            var allNodeNames = Set<String>()
            
            for matchingInfo in matchingSemanticSet {
                try foundInGrid.codeGridSemanticInfo.forAllNodesAssociatedWith(
                    matchingInfo.syntaxId,
                    codeGridParser.tokenCache
                ) { info, associatedMatchingNodes in
                    try throwIfCancelled()

                    allNodeNames = associatedMatchingNodes.reduce(into: allNodeNames) {
                        $0.insert($1.name ?? "")
                    }
                }
            }
            
            clone.rootGlyphsNode.enumerateChildNodes { node, stopFlag in
                if task.isCancelled { stopFlag.pointee = true }
                
                guard let nodeName = node.name else {
                    node.isHidden = true
                    print("node is missing name! -> \(node) in \(foundInGrid.id)")
                    return
                }
                
                if allNodeNames.contains(nodeName) {
                    node.isHidden = false
                } else {
                    node.isHidden = true
                }
            }
        }
        
        // Start search
        codeGridParser.query.walkGridsForSearch(
            newInput,
            onPositive: { foundInGrid, clone, leafInfo in
                try throwIfCancelled()
                
                clone.displayMode = .glyphs
                clone.backgroundGeometry.firstMaterial?.diffuse.contents = NSUIColor(displayP3Red: 0, green: 0, blue: 0, alpha: 0.67)
                toFocus.append((foundInGrid, clone))
                
                try onSemanticSetFound(foundInGrid: foundInGrid, clone: clone, leafInfo)
            },
            onNegative: { excludedGrid, clone, leafInfo in
                try throwIfCancelled()
                
                clone.rootNode.removeFromParentNode()
                toRemove.append(excludedGrid)
            }
        )
        
        // Add / remove grids, and set new highlighted nodes
        let displayMode = toFocus.count > 3
            ? CodeGrid.DisplayMode.layers
            : CodeGrid.DisplayMode.glyphs
        
        sceneTransaction {
            toRemove.forEach {
                codeGridFocus.removeGridFromFocus($0)
                $0.displayMode = .layers
            }
            
            toFocus
                .sorted(by: { $0.source.measures.lengthY < $1.source.measures.lengthY})
                .enumerated()
                .forEach {
                    $0.element.source.displayMode = displayMode
                    codeGridFocus.addGridToFocus($0.element.source, $0.offset)
                }
            
            // Layout pass on grids to give first set of focus positions
            codeGridFocus.layoutFocusedGrids()
            codeGridFocus.resetBounds()
        }
        
        sceneTransaction {
            for (sourceGrid, clone) in toFocus {
                clone.displayMode = .glyphs
                clone.rootNode.position = sourceGrid.rootNode.position
                clone.measures.alignedToTrailingOf(sourceGrid)
                codeGridFocus.mainFocus.gridNode.addChildNode(clone.rootNode)
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
