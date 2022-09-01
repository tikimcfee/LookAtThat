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
        resetAllGridFocusLevels()
        kickoffGridWalks()
        printStop(newInput + " ++ end of call")
    }
    
    func resetAllGridFocusLevels() {
        for grid in gridCache.cachedGrids.values {
            if task.isCancelled { return }
            
            grid.updateAllNodeConstants { node, constants, stopFlag in
                constants.addedColor = .zero
                stopFlag = task.isCancelled
                return constants
            }
        }
    }
    
    func kickoffGridWalks() {
        var gridWork = gridCache.cachedGrids.values.makeIterator()
        let workGroup = DispatchGroup()
        let searchText = newInput
        while !task.isCancelled, let next = gridWork.next() {
            workGroup.enter()
            WorkerPool.shared.nextWorker().async {
                defer { workGroup.leave() }
                do { try self.test(grid: next, searchText: searchText) }
                catch { return }
            }
        }
        workGroup.wait()
    }
    
    func test(grid: CodeGrid, searchText: String) throws {
        var foundMatch: Bool = false
        for (_, info) in grid.semanticInfoMap.semanticsLookupBySyntaxId {
            try self.throwIfCancelled()
            
            if info.referenceName.containsMatch(searchText) {
                try self.focusNodesForSemanticInfo(source: grid, info)
                foundMatch = true
            }
        }
        if !foundMatch {
            try self.defocusNodesForSemanticInfo(source: grid)
        }
    }
}

// MARK: - Default Highlighting

private extension RenderTask {
    var focusAddition: LFloat4 { LFloat4(0.1, 0.2, 0.3, 0.0) }
    
    func focusNodesForSemanticInfo(source: CodeGrid, _ matchingSemanticInfo: SemanticInfo) throws {
        try source.semanticInfoMap.walkFlattened(
            from: matchingSemanticInfo.syntaxId,
            in: source.tokenCache
        ) { info, targetNodes in
            for node in targetNodes {
                try self.throwIfCancelled()
                source.rootNode.updateConstants(for: node) {
                    $0.addedColor += self.focusAddition
                    return $0
                }
            }
        }
    }
    
    func defocusNodesForSemanticInfo(source: CodeGrid) throws {
        let clearFocus = newInput.isEmpty
        for rootNode in source.consumedRootSyntaxNodes {
            try source.semanticInfoMap.walkFlattened(
                from: rootNode.id,
                in: source.tokenCache
            ) { info, targetNodes in
                for node in targetNodes {
                    try self.throwIfCancelled()
                    source.rootNode.updateConstants(for: node) {
                        if clearFocus {
                            $0.addedColor = .zero
                        } else {
                            $0.addedColor -= self.focusAddition
                        }
                        return $0
                    }
                }
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
