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
    private var currentRenderTask: RenderTask?
    
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
    
    private func setupNewSearch(_ newInput: String, _ sceneState: SceneState) {
        if currentRenderTask == nil && newInput.isEmpty {
            print("Skipping search; input empty, nothing to reset")
            return
        }
        
        let renderTask = RenderTask(
            codeGridFocus: codeGridFocus,
            codeGridParser: codeGridParser,
            newInput: newInput,
            state: sceneState
        )
        currentRenderTask?.task.cancel()
        currentRenderTask?.task = renderTask.task
        searchQueue.async(execute: renderTask.task)
    }
}

private class RenderTask {
    typealias FocusType = CodeGrid
//    var toRemove: Set<FocusType> = []
//    var toFocus: Set<FocusType> = []
    
    var matchedInfo: [CodeGrid: Set<SemanticInfo>] = [:]
    var missedInfo: [CodeGrid] = []
    
    let codeGridFocus: CodeGridFocusController
    let codeGridParser: CodeGridParser
    let newInput: String
    let sceneState: SceneState
    lazy var task: DispatchWorkItem = DispatchWorkItem(block: { self.start() })
    
    init(
        codeGridFocus: CodeGridFocusController,
        codeGridParser: CodeGridParser,
        newInput: String,
        state: SceneState
    ) {
        self.codeGridFocus = codeGridFocus
        self.codeGridParser = codeGridParser
        self.newInput = newInput
        self.sceneState = state
    }
    
    var displayMode: CodeGrid.DisplayMode {
        CodeGrid.DisplayMode.glyphs
    }
    
    func start() {
        func doIt() {
            do {
                try doSearch()
            } catch {
                print(error)
            }
        }
        doIt()
//        DispatchQueue.main.async { doIt() }
    }
    
    private func doSearch() throws {
        printStart(newInput)
        sceneTransaction {
            codeGridFocus.resetState()
            codeGridFocus.setLayoutModel(.stacked)
            try doSearchWalk()
            try updateGrids()
        }
        printStop(newInput + " ++ end of call")
    }
    
    // Start search
    func doSearchWalk() throws {
        try codeGridParser.query.walkGridsForSearch(
            newInput,
            onPositive: { source, clone, matchInfo in
                try throwIfCancelled()
                matchedInfo[source] = matchInfo
            },
            onNegative: { source, clone in
                try throwIfCancelled()
                missedInfo.append(source)
            }
        )
    }
    
    // Collect all nodes from all semantic info that contributed to passed test
    func onSemanticInfoFound(source: CodeGrid,
                             clone: CodeGrid,
                             _ matchingSemanticInfo: SemanticInfo) throws {
        try source.codeGridSemanticInfo.tokenNodes(
            from: matchingSemanticInfo.syntaxId,
            in: source.tokenCache
        ) { info, associatedMatchingNodes in
            try self.throwIfCancelled()
            for node in associatedMatchingNodes {
                node.focus()
            }
        }
    }
    
    func onSemanticInfoNegative(source: CodeGrid,
                                clone: CodeGrid) throws {
        guard let rootSyntax = source.consumedRootSyntaxNodes.first else {
            print("Missing consumed syntax node for: \(source.fileName)")
            return
        }
        try source.codeGridSemanticInfo.walkFlattened(
            from: rootSyntax.id,
            in: codeGridParser.tokenCache
        ) { info, associatedMatchingNodes in
            try self.throwIfCancelled()
            for node in associatedMatchingNodes {
                node.focus(level: 0)
            }
        }
    }
    
    func removeAllGrids() {
        codeGridParser.gridCache.cachedGrids.values.forEach { (source, clone) in
            codeGridFocus.removeGridFromFocus(source)
            clone.rootNode.removeFromParentNode()
        }
    }
    
    func updateGrids() throws {
        try missedInfo.forEach { missedGrid in
            codeGridFocus.removeGridFromFocus(missedGrid)
            missedGrid.swapOutRootGlyphs()
            missedGrid.unlockGlyphSwapping()
            try onSemanticInfoNegative(source: missedGrid, clone: missedGrid)
        }
        
        let swapIn = matchedInfo.count < 10
        try matchedInfo
            .sorted(by: { leftMatch, rightMatch in
                leftMatch.key.measures.lengthY < rightMatch.key.measures.lengthY
            })
            .enumerated()
            .forEach { index, matchPair in
                if swapIn {
                    matchPair.key.unlockGlyphSwapping()
                    matchPair.key.swapInRootGlyphs()
                    matchPair.key.lockGlyphSwapping()
                }
                codeGridFocus.addGridToFocus(matchPair.key, index)
                
                for info in matchPair.value {
                    try onSemanticInfoFound(source: matchPair.key, clone: matchPair.key, info)
                }
            }
        
        // Layout pass on grids to give first set of focus positions
        codeGridFocus.layoutFocusedGrids()
        codeGridFocus.resetBounds()
        codeGridFocus.setFocusedDepth(0)
    }
}

extension RenderTask {
    func throwIfCancelled() throws {
        if task.isCancelled { throw Condition.cancelled(input: newInput) }
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
