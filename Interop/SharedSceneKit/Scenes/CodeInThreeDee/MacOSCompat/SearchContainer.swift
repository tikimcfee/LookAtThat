//
//  SearchContainer.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 12/5/21.
//

import Foundation
import SceneKit

class SearchContainer {
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
        currentWorkItem.cancel()
        currentWorkItem = DispatchWorkItem(block: searchBlock)
        searchQueue.async(execute: currentWorkItem)
        
        func searchBlock() {
//            SCNTransaction.lock()
//            SCNTransaction.begin()

            RenderTask(
                codeGridFocus: codeGridFocus,
                codeGridParser: codeGridParser,
                task: currentWorkItem,
                newInput: newInput,
                state: state
            ).start()
            
//            SCNTransaction.flush()
//            SCNTransaction.commit()
//            SCNTransaction.flush()
//            SCNTransaction.unlock()
        }
    }
}

private class RenderTask {
    typealias FocusType = (source: CodeGrid, clone: CodeGrid)
    var toRemove: [FocusType] = []
    var toFocus: [FocusType] = []
    
    let codeGridFocus: CodeGridFocusController
    let codeGridParser: CodeGridParser
    let task: DispatchWorkItem
    let newInput: String
    let state: SceneState
    
    init(
        codeGridFocus: CodeGridFocusController,
        codeGridParser: CodeGridParser,
        task: DispatchWorkItem,
        newInput: String,
        state: SceneState
    ) {
        self.codeGridFocus = codeGridFocus
        self.codeGridParser = codeGridParser
        self.task = task
        self.newInput = newInput
        self.state = state
    }
    
    var displayMode: CodeGrid.DisplayMode {
        toFocus.count > 8
            ? CodeGrid.DisplayMode.layers
            : CodeGrid.DisplayMode.glyphs
    }
    
    func start() {
        do {
            try doSearch()
        } catch {
            print(error)
        }
    }
    
    private func doSearch() throws {
        printStart(newInput)
        
        codeGridFocus.resetState()
        sceneTransaction {
            switch newInput.count {
            case 0:
                removeAllGrids()
            case 3...Int.max:
                try doSearchWalk()
            default:
                break
            }
        }
        sceneTransaction { updateGrids() }
        sceneTransaction { addClones() }
        
        printStop(newInput + " ++ end of call")
    }
    
    func throwIfCancelled() throws {
        if task.isCancelled { throw Condition.cancelled(input: newInput) }
    }
    
    // Collect all nodes from all semantic info that contributed to passed test
    func onSemanticSetFound(foundInGrid: CodeGrid,
                            clone: CodeGrid,
                            _ matchingSemanticSet: Set<SemanticInfo>) throws {
        var allNodeNames = Set<String>()
        
        // Collect all nodes for set
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
        
        // Iterate through all glyphs, and transforms the ones not associated with search
        clone.rootGlyphsNode.enumerateChildNodes { node, stopFlag in
            guard !task.isCancelled else {
                print("early stop on enumerate")
                stopFlag.pointee = true
                return
            }

            guard let nodeName = node.name else {
                node.isHidden = true
                print("node is missing name! -> \(node) in \(foundInGrid.id)")
                return
            }

            if allNodeNames.contains(nodeName) {
                node.isHidden = false
                node.materialMultiply(NSUIColor.red)
            } else {
                node.isHidden = true
                node.materialMultiply(NSUIColor.white)
            }
        }
    }
    
    // Start search
    func doSearchWalk() throws {
        try codeGridParser.query.walkGridsForSearch(
            newInput,
            onPositive: { foundInGrid, clone, leafInfo in
                try throwIfCancelled()
                
                toFocus.append((foundInGrid, clone))
                try onSemanticSetFound(foundInGrid: foundInGrid, clone: clone, leafInfo)
            },
            onNegative: { excludedGrid, clone, leafInfo in
                try throwIfCancelled()
                
                toRemove.append((excludedGrid, clone))
            }
        )
    }
    
    func removeAllGrids() {
        codeGridParser.gridCache.cachedGrids.values.forEach { (source, clone) in
            codeGridFocus.removeGridFromFocus(source)
            source.displayMode = .layers
            clone.rootNode.removeFromParentNode()
        }
    }
    
    func updateGrids() {
        toRemove.forEach { (source, clone) in
            codeGridFocus.removeGridFromFocus(source)
            source.displayMode = .layers
            clone.rootNode.removeFromParentNode()
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
        codeGridFocus.setFocusedDepth(0)
    }
    
    func addClones() {
        guard toFocus.count <= 20 else { return }
        
        // Add search result clones, resize the focus after all updates
        for (sourceGrid, clone) in toFocus {
            clone.displayMode = .glyphs
            clone.backgroundColor(NSUIColor(displayP3Red: 0, green: 0, blue: 0, alpha: 0.166))
            clone.rootNode.position = sourceGrid.rootNode.position
            clone.measures.alignedToTrailingOf(sourceGrid, pad: 4.0)
            codeGridFocus.mainFocus.gridNode.addChildNode(clone.rootNode)
        }
        
        codeGridFocus.resetBounds()
    }
    
    func printStart(_ input: String) {
        print("new search ---------------------- [\(input)]")
    }
    
    func printStop(_ input: String) {
        print("---------------------- [\(input)] finished ")
    }
    
    func printCancelled(_ input: String) {
        print("XXXXXXXXXXX >> [\(input)] Cancelled")
    }
}

private enum Condition: Error {
    case cancelled(input: String)
}
