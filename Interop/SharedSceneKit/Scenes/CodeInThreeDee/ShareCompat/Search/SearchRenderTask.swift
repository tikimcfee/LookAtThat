//
//  SearchRenderTask.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 7/12/22.
//

import Foundation

class RenderTask {
    var matchedInfo: [CodeGrid: Array<Set<SemanticInfo>>] = [:]
    var missedInfo: [CodeGrid] = []
    lazy var task = DispatchWorkItem(block: sharedDispatchBlock)
    
    let codeGridFocus: CodeGridFocusController
    let codeGridParser: CodeGridParser
    
    let newInput: String
    let sceneState: SceneState
    let onComplete: () -> Void
    let mode: SearchContainer.Mode
    private let stopwatch = Stopwatch()
    
    init(
        codeGridFocus: CodeGridFocusController,
        codeGridParser: CodeGridParser,
        newInput: String,
        state: SceneState,
        mode: SearchContainer.Mode,
        onComplete: @escaping () -> Void
    ) {
        self.codeGridFocus = codeGridFocus
        self.codeGridParser = codeGridParser
        self.newInput = newInput
        self.sceneState = state
        self.mode = mode
        self.onComplete = onComplete
    }
}

private extension RenderTask {
    func sharedDispatchBlock() -> Void {
        stopwatch.start()
        do {
            try doSearch()
        } catch {
            print(error)
        }
        stopwatch.stop()
        print("-- Search finished, \(stopwatch.elapsedTimeString())")
        onComplete()
    }
    
    func doSearch() throws {
        printStart(newInput)
        
        do {
            try doSearchWalk()
            switch mode {
            case .inPlace:
                try doInlineGlobalSearch()
            case .focusBox:
                try doFocusContainerSearch()
            }
        } catch {
            print(error)
        }
        
        printStop(newInput + " ++ end of call")
    }
    
    // Start search
    func doSearchWalk() throws {
        try codeGridParser.query.walkGridsForSearch(
            newInput,
            onPositive: { source, clone, matchInfo in
                try throwIfCancelled()
                matchedInfo[source, default: []].append(matchInfo)
            },
            onNegative: { source, clone in
                try throwIfCancelled()
                missedInfo.append(source)
            }
        )
    }
}

// MARK: - In-place Search

extension RenderTask {
    func doInlineGlobalSearch() throws {
        try missedInfo
            .forEach { missedGrid in
    //            print("Missed \(missedGrid.fileName)")
//                sceneTransaction {
//                    missedGrid.rootNode.opacity = 0.1
                    missedGrid.temporarySwapParentOut()
                    missedGrid.swapOutRootGlyphs()
                    try onSemanticInfoNegative(source: missedGrid, clone: missedGrid)
//                }
            }
        
        try matchedInfo
            .forEach { matchPair in
//                sceneTransaction {
                    
                    matchPair.key.temporarySwapParentIn()
                    matchPair.key.swapInRootGlyphs()
                    for semanticSet in matchPair.value {
                        for info in semanticSet {
                            try onSemanticInfoFound(source: matchPair.key, clone: matchPair.key, info)
                        }
                    }
//                }
            }
    }
}

// MARK: - Focus Search

private extension RenderTask {
    func doFocusContainerSearch() throws {
        try missedInfo.forEach { missedGrid in
            codeGridFocus.removeGridFromFocus(missedGrid)
            missedGrid.swapOutRootGlyphs()
            missedGrid.unlockGlyphSwapping()
            try onSemanticInfoNegative(source: missedGrid, clone: missedGrid)
        }
        
        let swapIn = matchedInfo.count < 15
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
                
                for semanticSet in matchPair.value {
                    for info in semanticSet {
                        try onSemanticInfoFound(source: matchPair.key, clone: matchPair.key, info)
                    }
                }
            }
        
        // Layout pass on grids to give first set of focus positions
        codeGridFocus.layoutFocusedGrids()
        codeGridFocus.resetBounds()
        codeGridFocus.setFocusedDepth(0)
    }
}

// MARK: - Default Highlighting

private extension RenderTask {
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
//                node.focus(level: 0)
                node.unfocus()
            }
        }
    }
}

private extension RenderTask {
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
