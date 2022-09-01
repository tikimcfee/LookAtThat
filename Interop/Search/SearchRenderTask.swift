//
//  SearchRenderTask.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 7/12/22.
//

import Foundation

class RenderTask {
    typealias SearchReceiver = (
        _ source: CodeGrid,
        _ semantics: Set<SemanticInfo>
    ) throws -> Void
    
    typealias NegativeReceiver = (
        _ source: CodeGrid
    ) throws -> Void
    
    private let newInput: String
    private let gridCache: GridCache
    private let mode: SearchContainer.Mode
    private let onComplete: () -> Void
    lazy var task = DispatchWorkItem(block: sharedDispatchBlock)
    
    private static let _stopwatch = Stopwatch()
    private var stopwatch: Stopwatch { Self._stopwatch }
    
    var matchedInfo: [CodeGrid: Array<Set<SemanticInfo>>] = [:]
    var missedInfo: Set<CodeGrid> = []
    
    init(
        newInput: String,
        gridCache: GridCache,
        mode: SearchContainer.Mode,
        onComplete: @escaping () -> Void
    ) {
        self.newInput = newInput
        self.gridCache = gridCache
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
        stopwatch.reset()
        
        onComplete()
    }
    
    func doSearch() throws {
        printStart(newInput)
        
        do {
            try doSearchWalk()
            switch mode {
            case .inPlace:
                try doInlineGlobalSearch()
            }
        } catch {
            print(error)
        }
        
        printStop(newInput + " ++ end of call")
    }
    
    // Start search
    func doSearchWalk() throws {
        resetAllGridFocusLevels()
        try walkGridsForSearch(
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
    
    func resetAllGridFocusLevels() {
        for grid in gridCache.cachedGrids.values {
            grid.updateAllNodeConstants { node, constants, _ in
                constants.addedColor = .zero
                return constants
            }
        }
    }
    
    func walkGridsForSearch(
        _ searchText: String,
        onPositive: SearchReceiver,
        onNegative: NegativeReceiver
    ) throws {
        for grid in gridCache.cachedGrids.values {
            var matches = Set<SemanticInfo>()
            try throwIfCancelled()
            
            for (_, info) in grid.semanticInfoMap.semanticsLookupBySyntaxId {
                if info.referenceName.containsMatch(searchText) {
                    matches.insert(info)
                }
            }
            
            if matches.isEmpty {
                try onNegative(grid)
            } else {
                try onPositive(grid, matches)
            }
        }
    }
}

// MARK: - In-place Search

extension RenderTask {
    func doInlineGlobalSearch() throws {
        try missedInfo
            .forEach { grid in
                try defocusNodesForSemanticInfo(source: grid)
                try throwIfCancelled()
            }
        
        try matchedInfo
            .forEach { matchPair in
                let matchedGrid = matchPair.key
                let semanticInfo = matchPair.value
                try throwIfCancelled()
                
                for semanticSet in semanticInfo {
                    for info in semanticSet {
                        try focusNodesForSemanticInfo(source: matchedGrid, info)
                        try throwIfCancelled()
                    }
                }
            }
    }
}

// MARK: - Default Highlighting

private extension RenderTask {
    // Collect all nodes from all semantic info that contributed to passed test
    func focusNodesForSemanticInfo(source: CodeGrid, _ matchingSemanticInfo: SemanticInfo) throws {
        var toFocus = [GlyphNode: LFloat4]()
        try source.semanticInfoMap.walkFlattened(
            from: matchingSemanticInfo.syntaxId,
            in: source.tokenCache
        ) { info, targetNodes in
            try targetNodes.forEach {
                toFocus[$0, default: .zero] += LFloat4(0.05, 0.08, 0.1, 0.0)
                try self.throwIfCancelled()
            }
        }
        
        source.updateAllNodeConstants { updateNode, constants, _ in
            constants.addedColor += toFocus[updateNode, default: .zero]
            return constants
        }
    }
    
    func defocusNodesForSemanticInfo(source: CodeGrid) throws {
        // this is oogly
        for rootNode in source.consumedRootSyntaxNodes {
            var toFocus = [GlyphNode: LFloat4]()
            try source.semanticInfoMap.walkFlattened(
                from: rootNode.id,
                in: source.tokenCache
            ) { info, targetNodes in
                try targetNodes.forEach {
                    toFocus[$0, default: .zero] -= LFloat4(0.05, 0.08, 0.1, 0.0)
                    try self.throwIfCancelled()
                }
            }
            
            source.updateAllNodeConstants { updateNode, constants, _ in
                constants.addedColor += toFocus[updateNode, default: .zero]
                return constants
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
