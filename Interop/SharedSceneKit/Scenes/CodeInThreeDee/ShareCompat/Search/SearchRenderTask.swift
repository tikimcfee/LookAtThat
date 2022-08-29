//
//  SearchRenderTask.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 7/12/22.
//

import Foundation

class RenderTask {
    var matchedInfo: [CodeGrid: Array<Set<SemanticInfo>>] = [:]
    var missedInfo: Set<CodeGrid> = []
    lazy var task = DispatchWorkItem(block: sharedDispatchBlock)
    
    let codeGridParser: CodeGridParser
    
    let newInput: String
    let sceneState: SceneState
    let onComplete: () -> Void
    let mode: SearchContainer.Mode
    private let stopwatch = Stopwatch()
    
    init(
        codeGridParser: CodeGridParser,
        newInput: String,
        state: SceneState,
        mode: SearchContainer.Mode,
        onComplete: @escaping () -> Void
    ) {
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
        
        self.onComplete()
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
            onPositive: { source, matchInfo in
                try throwIfCancelled()
                matchedInfo[source, default: []].append(matchInfo)
            },
            onNegative: { source in
                try throwIfCancelled()
                missedInfo.insert(source)
            }
        )
    }
}

// MARK: - In-place Search

extension RenderTask {
    func doInlineGlobalSearch() throws {
        func isFocused(grid: CodeGrid) -> Bool {
            print("Not implemented: \(#function)")
            return false
        }
        
        func updateMeta(grid: CodeGrid, _ op: (SceneState.GridMeta) -> Void) {
            print("Not implemented: \(#function)")
        }
        
        func doMissedInfo() throws {
            try missedInfo
                .forEach { grid in
                    if isFocused(grid: grid) {
                        updateMeta(grid: grid) { $0.searchFocused = false }
                        grid.rootNode.translate(dY: -128.0)
                    }
                    try defocusNodesForSemanticInfo(source: grid)
                }
        }
        
        func doMatchedInfo() throws {
            try matchedInfo
                .forEach { matchPair in
                    let matchedGrid = matchPair.key
                    let semanticInfo = matchPair.value
                    
                    if !isFocused(grid: matchedGrid) {
                        updateMeta(grid: matchedGrid) { $0.searchFocused = true }
                        matchedGrid.rootNode.translate(dY: 128.0)
                    }
                    
                    for semanticSet in semanticInfo {
                        for info in semanticSet {
                            try focusNodesForSemanticInfo(source: matchedGrid, info)
                        }
                    }
                }
        }
        
        try doMissedInfo()
        try doMatchedInfo()
    }
}

// MARK: - Focus Search

private extension RenderTask {
    func doFocusContainerSearch() throws {
        try missedInfo.forEach { missedGrid in
            try defocusNodesForSemanticInfo(source: missedGrid)
        }
        
        try matchedInfo
            .sorted(by: { leftMatch, rightMatch in
                leftMatch.key.measures.lengthY < rightMatch.key.measures.lengthY
            })
            .enumerated()
            .forEach { index, matchPair in
                for semanticSet in matchPair.value {
                    for info in semanticSet {
                        try focusNodesForSemanticInfo(source: matchPair.key, info)
                    }
                }
            }
    }
}

// MARK: - Default Highlighting

private extension RenderTask {
    // Collect all nodes from all semantic info that contributed to passed test
    func focusNodesForSemanticInfo(source: CodeGrid,
                                   _ matchingSemanticInfo: SemanticInfo) throws {
        try source.semanticInfoMap.tokenNodes(
            from: matchingSemanticInfo.syntaxId,
            in: source.tokenCache
        ) { info, associatedMatchingNodes in
            try self.throwIfCancelled()
            for node in associatedMatchingNodes {
                node.focus()
            }
        }
    }
    
    func defocusNodesForSemanticInfo(source: CodeGrid) throws {
        guard let rootSyntax = source.consumedRootSyntaxNodes.first else {
            print("Missing consumed syntax node for: \(source.fileName)")
            return
        }
        try source.semanticInfoMap.walkFlattened(
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
